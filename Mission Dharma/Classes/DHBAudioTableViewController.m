//
//  DHBAudioTableViewController.m
//  Mission Dharma
//
//  Created by David Brunow on 8/7/13.
/*
 The MIT License (MIT)
 
 Copyright (c) 2014 David Brunow
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

@class AppDelegate;

#import "DHBPodcast.h"
#import "DHBAudioTableViewCell.h"
#import "DHBAudioTableViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import "Mission_Dharma-Swift.h"

@interface DHBAudioTableViewController ()
@property (strong, nonatomic) IBOutlet UIView *tableFooterView;

@property (strong, nonatomic) AVAudioEngine *audioEngine;
@property (strong, nonatomic) AVAudioFile *audioFile;
@property (strong, nonatomic) AVAudioPlayerNode *audioPlayerNode;
@property (strong, nonatomic) AVAudioOutputNode *audioOutputNode;

@end

@implementation DHBAudioTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];

    [refreshControl setTintColor: AppDelegate.lightColor];
    [refreshControl addTarget:self action:@selector(refreshTable) forControlEvents:UIControlEventValueChanged];

    [self setRefreshControl:refreshControl];
    
    [self.tableView setEstimatedRowHeight:100.0];

    [self.tableView setRowHeight:UITableViewAutomaticDimension];
    
    self.tableView.tableFooterView = self.tableFooterView;
    //[self.tableView setTableFooterView:footerView];
}

- (void) refreshTable
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    dispatch_async(dispatch_get_main_queue(), ^(void)
    {
        [appDelegate.podcast loadEpisodes];
    });
}

- (void) reloadTable
{
    NSLog(@"reloading table based on notification!");
    dispatch_async(dispatch_get_main_queue(), ^(void)
    {
        [[self refreshControl] endRefreshing];
        [self.tableView reloadData];
    });
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTable) name:@"Episodes Fetched From Local Database" object:nil];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidAppear:(BOOL)animated
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];

    [appDelegate.podcast addObserver:self forKeyPath:@"hasLoadedEpisodes" options:NSKeyValueObservingOptionNew context:nil];
    
    if([self.tableView numberOfRowsInSection:0] == 0)
    {
        [self.tableView setContentOffset:CGPointMake(0, -100) animated:YES];
        [[self refreshControl] beginRefreshing];
    }
    else
    {
    }
}

-(void) viewDidDisappear:(BOOL)animated
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];

    [appDelegate.podcast removeObserver:self forKeyPath:@"hasLoadedEpisodes"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    NSMutableArray *yearsOfEpisodesArray = [appDelegate.podcast getUniqueYearsOfEpisodes];

    return yearsOfEpisodesArray.count;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    NSMutableArray *yearsOfEpisodesArray = [appDelegate.podcast getUniqueYearsOfEpisodes];
    
    return [NSString stringWithFormat:@"%@", [yearsOfEpisodesArray objectAtIndex:section]];
}


- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    // Background color
    view.tintColor = AppDelegate.lightColor;
    
    // Text Color
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    [header.textLabel setTextColor:[UIColor whiteColor]];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    NSMutableArray *yearsOfEpisodesArray = [appDelegate.podcast getUniqueYearsOfEpisodes];
    NSMutableArray *episodesForYear = [appDelegate.podcast getEpisodesForYear:[[yearsOfEpisodesArray objectAtIndex:section] longValue]];
    // Return the number of rows in the section.
    return episodesForYear.count;
}

- (DHBAudioTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];

    static NSString *CellIdentifier = @"episodeCell";

    DHBAudioTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    [cell setParentTableView:self.tableView];
    
    if (cell == nil)
    {
        cell = [[DHBAudioTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    NSMutableArray *yearsOfEpisodesArray = [appDelegate.podcast getUniqueYearsOfEpisodes];
    
    NSMutableArray *episodesForYear = [appDelegate.podcast getEpisodesForYear:[[yearsOfEpisodesArray objectAtIndex:indexPath.section] longValue]];
    
    DHBPodcastEpisode *thisEpisode = [episodesForYear objectAtIndex:indexPath.row];

    cell.mainLabel.text = [NSString stringWithFormat:@"%@", thisEpisode.title];
    
    if(thisEpisode.currentPlaybackPosition > 0)
    {
        [cell.progressView setProgress:thisEpisode.currentPlaybackPosition / thisEpisode.duration animated:YES];
        [cell.progressView setHidden:NO];
    }
    else
    {
        [cell.progressView setProgress:0.0];
        [cell.progressView setHidden:YES];
    }
    
    if(thisEpisode.downloadInProgress == 0 || thisEpisode.downloadInProgress == 1.0)
    {
        [cell.downloadProgressView setProgress:0.0];
        [cell.downloadProgressView setHidden:YES];
    }
    else
    {
        [cell.downloadProgressView setProgress:thisEpisode.downloadInProgress];
        [cell.downloadProgressView setHidden:NO];
    }
    
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    NSString *recordDateString = @"";
    
    if(thisEpisode.recordDate != nil) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"dd MMMM yyyy"];
        
        recordDateString = [dateFormatter stringFromDate:thisEpisode.recordDate];
    } else {
        recordDateString = @"Date Unavailable";
    }
    
    cell.subLabel.text = [NSString stringWithFormat:@"%@ - %@", recordDateString, thisEpisode.speaker];
    
    if(thisEpisode.isDownloaded)
    {
        //[cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
        [cell.actionButton setTitle:@"" forState:UIControlStateNormal];
        [cell.actionButton setHidden:YES];
        [cell.progressView setHidden:NO];
    }
    else
    {
        //[cell setAccessoryType:UITableViewCellAccessoryNone];
        [cell.actionButton setTitle:@"DOWNLOAD" forState:UIControlStateNormal];
        [cell.actionButton setHidden:NO];
        [cell.actionButton addTarget:self action:@selector(downloadEpisode:) forControlEvents:UIControlEventTouchUpInside];
        [cell.progressView setHidden:YES];
    }
    
    if(thisEpisode.isUnplayed)
    {
        [cell.unplayedIndicator setHidden:NO];
    }
    else
    {
        [cell.unplayedIndicator setHidden:YES];
    }
    
    if([[[[MPNowPlayingInfoCenter defaultCenter] nowPlayingInfo] objectForKey:MPMediaItemPropertyTitle] isEqualToString:thisEpisode.title] && [self.audioPlayer isPlaying])
    {
        [cell.mainLabel setTextColor:[UIColor whiteColor]];
        [cell setBackgroundColor:AppDelegate.lightColor];
        [cell.progressView setProgressTintColor:[UIColor whiteColor]];
    }
    else
    {
        [cell.mainLabel setTextColor:[UIColor blackColor]];
        [cell setBackgroundColor:[UIColor whiteColor]];
        [cell.progressView setProgressTintColor:AppDelegate.lightColor];
    }
    
    return cell;
}

- (void)downloadEpisode:(id) sender
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    UIView *parent = [sender superview];
    
    while (parent && ![parent isKindOfClass:[DHBAudioTableViewCell class]])
    {
        parent = parent.superview;
    }
    
    DHBAudioTableViewCell *thisParentCell = (DHBAudioTableViewCell *)parent;
    
    NSIndexPath *thisIndexPath = [self.tableView indexPathForCell:thisParentCell];
    NSMutableArray *yearsOfEpisodesArray = [appDelegate.podcast getUniqueYearsOfEpisodes];
    NSMutableArray *episodesForYear = [appDelegate.podcast getEpisodesForYear:[[yearsOfEpisodesArray objectAtIndex:thisIndexPath.section] longValue]];
    
    DHBPodcastEpisode *thisEpisode = [episodesForYear objectAtIndex:thisIndexPath.row];
    
    //self.selectedEpisode = [appDelegate.podCast.podcastEpisodes objectAtIndex:thisIndexPath.row];
    
    [thisEpisode addObserver:thisParentCell forKeyPath:@"downloadInProgress" options:NSKeyValueObservingOptionNew context:nil];
    [thisEpisode downloadEpisode];
    
    [thisParentCell.downloadProgressView setHidden:NO];
    
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if([keyPath isEqualToString:@"hasLoadedEpisodes"]) {
        [self.tableView reloadData];
        [self.refreshControl endRefreshing];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    NSMutableArray *yearsOfEpisodesArray = [appDelegate.podcast getUniqueYearsOfEpisodes];
    NSMutableArray *episodesForYear = [appDelegate.podcast getEpisodesForYear:[[yearsOfEpisodesArray objectAtIndex:indexPath.section] longValue]];
    
    DHBPodcastEpisode *thisEpisode = [episodesForYear objectAtIndex:indexPath.row];
    
    //DHBPodCastEpisode *thisEpisode = [appDelegate.podCast.podcastEpisodes objectAtIndex:indexPath.row];

    if(!thisEpisode.isDownloaded)
    {
        [[tableView cellForRowAtIndexPath:indexPath] setSelected:NO];
    }
    else
    {
        DHBAudioTableViewCell *cell = (DHBAudioTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
        
        [cell setSelected:YES animated:YES];
        
        for (DHBAudioTableViewCell *thisCell in [tableView visibleCells])
        {
            if(thisCell != cell)
            {
                [thisCell setSelected:NO animated:YES];
                [self unselectCell:thisCell];
            }
        }
        
        NSManagedObjectContext *context = [appDelegate managedObjectContext];
        self.selectedEpisode = [NSEntityDescription insertNewObjectForEntityForName:@"PodcastEpisode" inManagedObjectContext:context];

        self.selectedEpisode = thisEpisode;
        
        if(![[[[MPNowPlayingInfoCenter defaultCenter] nowPlayingInfo] objectForKey:MPMediaItemPropertyTitle] isEqualToString:self.selectedEpisode.title])
        {
            if([self.audioPlayerNode isPlaying])
            {
                [self.audioPlayerNode pause];
                [cell.actionButton setTitle:@"" forState:UIControlStateNormal];
                [self unselectCell:cell];
            }
        }
        
        if([self.audioPlayerNode isPlaying])
        {
            [self.audioPlayerNode pause];
            [cell.actionButton setTitle:@"" forState:UIControlStateNormal];
            [self unselectCell:cell];
        }
        else
        {
            [self playEpisode: self.selectedEpisode];
            /*
            [[AVAudioSession sharedInstance] setDelegate: self];
            //[[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryAmbient error: nil];
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
            NSError *activationError = nil;
            [[AVAudioSession sharedInstance] setActive: YES error: &activationError];
            
            [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioRouteChangeListenerCallback) name:AVAudioSessionRouteChangeNotification object:nil];
            //AudioSessionPropertyID routeChangeID = kAudioSessionProperty_AudioRouteChange;
            //AudioSessionAddPropertyListener (routeChangeID, audioRouteChangeListenerCallback, (__bridge void *)(self));
            [self becomeFirstResponder];
        
        
            if(self.selectedEpisode.currentPlaybackPosition > 0) {
                self.selectedEpisode.currentPlaybackPosition = self.selectedEpisode.currentPlaybackPosition - 5;
                [self.audioPlayer setCurrentTime:self.selectedEpisode.currentPlaybackPosition];
            }
            
            [self.audioPlayer setNumberOfLoops:0];
            [self.audioPlayer setDelegate:self];
            [self.audioPlayer prepareToPlay];
            */
            
            /*
            [self.audioPlayer play];
             */
            [self selectCell:cell];
            
        }
    }
}

- (void) playEpisode:(DHBPodcastEpisode *) episode
{
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    self.audioEngine = [[AVAudioEngine alloc] init];
    self.audioPlayerNode = [[AVAudioPlayerNode alloc] init];
    
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioRouteChangeListenerCallback:) name:AVAudioSessionRouteChangeNotification object:nil];
    
    [self.audioEngine attachNode:self.audioPlayerNode];
    
    AVAudioMixerNode *mixerNode = [self.audioEngine mainMixerNode];
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    [audioSession setActive:true error:nil];
    
    NSString *fullPathString = [NSString stringWithFormat:@"%@/%@", appDelegate.applicationHome, episode.localPathString];
    NSURL *localFileURL = [[NSURL alloc] initFileURLWithPath:fullPathString];
    self.audioFile = [[AVAudioFile alloc] initForReading:localFileURL error:nil];
    
    if(episode.currentPlaybackPosition > 5)
    {
        episode.currentPlaybackPosition = episode.currentPlaybackPosition - 5;
        
        [self.audioFile setFramePosition:(episode.currentPlaybackPosition * self.audioFile.processingFormat.sampleRate)];
        
        //[self.audioPlayer setCurrentTime:self.selectedEpisode.currentPlaybackPosition];
    }
    
    AVAudioPCMBuffer *audioPCMBuffer = [self createAndLoadBuffer];
    
    [self.audioEngine connect:self.audioPlayerNode to:mixerNode format:audioPCMBuffer.format];
    
    [self scheduleBuffer:audioPCMBuffer];
    
    [self.audioEngine startAndReturnError:nil];
    [self.audioPlayerNode play];
    
    [self setNowPlayingInfoCenterInfo];
}

- (void) scheduleBuffer: (AVAudioPCMBuffer *) buffer
{
    [self.audioPlayerNode scheduleBuffer:buffer atTime:nil options:AVAudioPlayerNodeBufferInterruptsAtLoop completionHandler:^
     {
         if([self.audioPlayerNode isPlaying])
         {
             [self loadBuffer];
         }
     }];
}

- (void) loadBuffer
{
    AVAudioPCMBuffer *buffer = [self createAndLoadBuffer];
    
    [self scheduleBuffer:buffer];
}

- (AVAudioPCMBuffer *) createAndLoadBuffer
{
    AVAudioPCMBuffer *audioPCMBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:self.audioFile.processingFormat frameCapacity:self.audioFile.processingFormat.sampleRate];
    
    [self.audioFile readIntoBuffer:audioPCMBuffer error:nil];
    
    return audioPCMBuffer;
}

// Override to support conditional editing of the table view.
// This only needs to be implemented if you are going to be returning NO
// for some items. By default, all items are editable.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return YES if you want the specified item to be editable.
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSMutableArray *yearsOfEpisodesArray = [appDelegate.podcast getUniqueYearsOfEpisodes];
    NSMutableArray *episodesForYear = [appDelegate.podcast getEpisodesForYear:[[yearsOfEpisodesArray objectAtIndex:indexPath.section] longValue]];
    
    DHBPodcastEpisode *thisEpisode = [episodesForYear objectAtIndex:indexPath.row];
    //DHBPodCastEpisode *thisEpisode = [appDelegate.podCast.podcastEpisodes objectAtIndex:indexPath.row];
    
    bool canEditRow = NO;
    
    if((thisEpisode.isDownloaded && ![[[[MPNowPlayingInfoCenter defaultCenter] nowPlayingInfo] objectForKey:MPMediaItemPropertyTitle] isEqualToString:thisEpisode.title] && [self.audioPlayerNode isPlaying]) || (thisEpisode.isDownloaded && ![self.audioPlayerNode isPlaying]))
    {
        canEditRow = YES;
    }
    
    return canEditRow;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return @"Remove Download";
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        //add code here for when you hit delete
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        NSManagedObjectContext *context = [appDelegate managedObjectContext];
        DHBPodcastEpisode *episodeToDelete = [NSEntityDescription insertNewObjectForEntityForName:@"PodcastEpisode" inManagedObjectContext:context];
        NSMutableArray *yearsOfEpisodesArray = [appDelegate.podcast getUniqueYearsOfEpisodes];
        NSMutableArray *episodesForYear = [appDelegate.podcast getEpisodesForYear:[[yearsOfEpisodesArray objectAtIndex:indexPath.section] longValue]];
        
        episodeToDelete = [episodesForYear objectAtIndex:indexPath.row];
        //episodeToDelete = [appDelegate.podCast.podcastEpisodes objectAtIndex:indexPath.row];
        
        [episodeToDelete deleteEpisode];
        
        NSArray *rowsToReload = [[NSArray alloc] initWithObjects:indexPath, nil];
        
        [self.tableView reloadRowsAtIndexPaths:rowsToReload withRowAnimation:UITableViewRowAnimationRight];
    }
}

- (BOOL)isHeadsetPluggedIn
{
    // Get array of current audio outputs (there should only be one)
    NSArray *outputs = [[AVAudioSession sharedInstance] currentRoute].outputs;
    
    NSString *portName = [[outputs objectAtIndex:0] portName];
    
    if ([portName isEqualToString:@"Headphones"])
    {
        return YES;
    }
    
    return NO;
}

- (void) audioRouteChangeListenerCallback: (NSNotification *) notification
{
    NSUInteger routeChangeReason = [[notification.userInfo valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    NSLog(@"Route Change Reason: %lu", (unsigned long)routeChangeReason);
    
    if(routeChangeReason == AVAudioSessionRouteChangeReasonNewDeviceAvailable)
    {
        NSLog(@"route change reason was new device available!");
        [self.audioPlayerNode pause];
        [self playEpisode:self.selectedEpisode];
    }
    else if (routeChangeReason == AVAudioSessionRouteChangeReasonOldDeviceUnavailable)
    {
        NSLog(@"route change reason was old device unavailable");
        [self.audioPlayerNode pause];
    }
    else if (routeChangeReason == AVAudioSessionRouteChangeReasonCategoryChange)
    {
        NSLog(@"route change reason was category change");
    }
    else if (routeChangeReason == AVAudioSessionRouteChangeReasonOverride)
    {
        NSLog(@"route change reason was route override");
    }
}
/*
void audioRouteChangeListenerCallback (void *inUserData, AudioSessionPropertyID inPropertyID, UInt32 inPropertyValueSize, const void *inPropertyValue) {
    if (inPropertyID != kAudioSessionProperty_AudioRouteChange)
    {
         return; // 5
    }
    
    DHBAudioTableViewController *controller = (__bridge DHBAudioTableViewController *) inUserData; // 6
    
    if (controller.audioPlayer.playing == 0 )
    {                      // 7
        return;
    }
    else
    {
        CFDictionaryRef routeChangeDictionary = inPropertyValue;        // 8
        CFNumberRef routeChangeReasonRef =
        CFDictionaryGetValue (
                              routeChangeDictionary,
                              CFSTR (kAudioSession_AudioRouteChangeKey_Reason)
                              );
        
        SInt32 routeChangeReason;
        CFNumberGetValue (
                          routeChangeReasonRef, kCFNumberSInt32Type, &routeChangeReason
                          );
        
        if (routeChangeReason ==
            kAudioSessionRouteChangeReason_OldDeviceUnavailable)
        {  // 9
            
            [controller.audioPlayer pause];
            
        }
    }
}
*/
-(void)selectCell:(DHBAudioTableViewCell *) cell
{
    [UIView animateWithDuration:0.2 animations:^
    {
        [cell.mainLabel setTextColor:[UIColor whiteColor]];
        [cell setBackgroundColor:AppDelegate.lightColor];
        [cell.progressView setProgressTintColor:[UIColor whiteColor]];
        [cell.progressView setHidden:YES];
        [cell.nowPlayingLabel setHidden:NO];
        
        //[cell.nowPlayingLabel setText:[NSString stringWithFormat:@"%02.f:%02.f - %02.f:%02.f", floor(self.selectedEpisode.currentPlaybackPosition / 60), floor(self.selectedEpisode.currentPlaybackPosition) - (floor(self.selectedEpisode.currentPlaybackPosition / 60) * 60), floor(self.audioPlayer.duration / 60), self.audioPlayer.duration - (floor(self.audioPlayer.duration / 60) * 60) ]];
        
        double sampleRate = self.audioFile.processingFormat.sampleRate;
        NSTimeInterval episodeLength = self.audioFile.length / sampleRate;
        
        [self.selectedEpisode setDuration:episodeLength];
        
        if(self.selectedEpisode.currentPlaybackPosition > episodeLength)
        {
            self.selectedEpisode.currentPlaybackPosition = episodeLength;
        }
        
        [self.selectedEpisode save];
        
        [cell.nowPlayingLabel setText:[NSString stringWithFormat:@"%02.f:%02.f - %02.f:%02.f", floor(self.selectedEpisode.currentPlaybackPosition / 60), floor(self.selectedEpisode.currentPlaybackPosition) - (floor(self.selectedEpisode.currentPlaybackPosition / 60) * 60), floor(episodeLength / 60), ((episodeLength / 60) - floor(episodeLength / 60)) * 60 ]];
    }];
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateAudioProgressForCell) userInfo:cell repeats:YES];
}

-(void)unselectCell:(DHBAudioTableViewCell *) cell
{
    [self.timer invalidate];
    self.timer = nil;
    
    [UIView animateWithDuration:0.2 animations:^
    {
        [cell.mainLabel setTextColor:[UIColor blackColor]];
        
        [cell setBackgroundColor:[UIColor whiteColor]];
        [cell.progressView setProgressTintColor:AppDelegate.lightColor];
        [cell.progressView setHidden:NO];
        [cell.nowPlayingLabel setHidden:YES];
    }];
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)event
{
    if (event.type == UIEventTypeRemoteControl) {
        DHBAudioTableViewCell *cell = (DHBAudioTableViewCell *)[self.tableView cellForRowAtIndexPath:[self.tableView indexPathForSelectedRow]];
        
        switch (event.subtype) {
            case UIEventSubtypeRemoteControlPause:
                [self.audioPlayerNode pause];
                [self unselectCell:cell];
                break;
                
            case UIEventSubtypeRemoteControlPlay:
                if(self.selectedEpisode != nil)
                {
                    [self playEpisode:self.selectedEpisode];
                }
                //[self.audioPlayer play];
                [self selectCell:cell];
                break;
            case UIEventSubtypeRemoteControlPreviousTrack:
                //[self.audioPlayer previousTrack: nil];
                NSLog(@"Skip 15 second back");
                //self.selectedEpisode.currentPlaybackPosition -= 15;
                //[self.audioPlayer setCurrentTime:self.selectedEpisode.currentPlaybackPosition];
                
                if(self.selectedEpisode != nil)
                {
                    self.selectedEpisode.currentPlaybackPosition -= 10;
                    [self playEpisode:self.selectedEpisode];
                }
                break;
                
            case UIEventSubtypeRemoteControlNextTrack:
                //[self.audioPlayer nextTrack: nil];
                NSLog(@"Skip 15 seconds forward");
                //self.selectedEpisode.currentPlaybackPosition += 15;
                if(self.selectedEpisode != nil)
                {
                    self.selectedEpisode.currentPlaybackPosition += 20;
                    [self playEpisode:self.selectedEpisode];
                }
                break;
            default:
                break;
        }
        
        //[self.audioPlayer setCurrentTime:self.selectedEpisode.currentPlaybackPosition];
        
        [self setNowPlayingInfoCenterInfo];
        
    }
}

-(void) setNowPlayingInfoCenterInfo
{
    double sampleRate = self.audioFile.processingFormat.sampleRate;
    NSTimeInterval episodeLength = self.audioFile.length / sampleRate;
    
    NSArray *keys = [NSArray arrayWithObjects:MPMediaItemPropertyArtwork, MPMediaItemPropertyMediaType, MPMediaItemPropertyAlbumTitle, MPMediaItemPropertyPodcastPersistentID, MPMediaItemPropertyArtist, MPMediaItemPropertyTitle, MPMediaItemPropertyPodcastTitle, MPMediaItemPropertyPlaybackDuration, MPNowPlayingInfoPropertyPlaybackRate, MPNowPlayingInfoPropertyElapsedPlaybackTime, nil];
    NSArray *values = [NSArray arrayWithObjects:[[MPMediaItemArtwork alloc] initWithImage:[UIImage imageNamed:@"dharma talk icon 1024"]], [NSNumber numberWithInteger:MPMediaTypePodcast], @"Mission Dharma - Dharma Talks", @"Mission Dharma - Dharma Talks", self.selectedEpisode.speaker, self.selectedEpisode.title, self.selectedEpisode.title, [NSNumber numberWithFloat:episodeLength], [NSNumber numberWithInt:1], [NSNumber numberWithFloat:self.selectedEpisode.currentPlaybackPosition], nil];
    
    NSDictionary *mediaInfo = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:mediaInfo];
}

-(void) updateAudioProgressForCell
{
    DHBAudioTableViewCell *cell = [self.timer userInfo];
    
    double sampleRate = self.audioFile.processingFormat.sampleRate;
    NSTimeInterval episodeLength = self.audioFile.length / sampleRate;
    
    AVAudioTime *nodeTime = self.audioPlayerNode.lastRenderTime;
    AVAudioTime *playerTime = [self.audioPlayerNode playerTimeForNodeTime:nodeTime];
    
    NSTimeInterval seconds = (double)playerTime.sampleTime / playerTime.sampleRate;
    seconds = self.audioFile.framePosition / self.audioFile.processingFormat.sampleRate;
    
    float audioPlayerPercentComplete = (seconds / episodeLength);
    
    [self.selectedEpisode setCurrentPlaybackPosition:seconds];
    
    [cell.nowPlayingLabel setText:[NSString stringWithFormat:@"%02.f:%02.f - %02.f:%02.f", floor(self.selectedEpisode.currentPlaybackPosition / 60), floor(self.selectedEpisode.currentPlaybackPosition) - (floor(self.selectedEpisode.currentPlaybackPosition / 60) * 60), floor(episodeLength / 60), ((episodeLength / 60) - floor(episodeLength / 60)) * 60 ]];

    [cell.progressView setProgress:audioPlayerPercentComplete animated:NO];
    
    if(self.selectedEpisode.isUnplayed)
    {
        self.selectedEpisode.isUnplayed = NO;
        
        [cell.unplayedIndicator setHidden:YES];
    }
    
    [self.selectedEpisode save];
    
    if(audioPlayerPercentComplete > 0.99)
    {
        [self.timer invalidate];
        self.timer = nil;
        [self unselectCell:cell];
        [self.audioPlayerNode stop];
        //[cell.progressView removeFromSuperview];
        //[self.tableView reloadData];
    }
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */

@end
