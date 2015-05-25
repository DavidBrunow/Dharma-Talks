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

#import <MediaPlayer/MediaPlayer.h>
#import "DHBAudioTableViewController.h"
#import "DHBAppDelegate.h"
#import "DHBAudioTableViewCell.h"

@interface DHBAudioTableViewController ()

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

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    MPRemoteCommandCenter *rcc = [MPRemoteCommandCenter sharedCommandCenter];
    
    MPSkipIntervalCommand *skipBackwardIntervalCommand = [rcc skipBackwardCommand];
    [skipBackwardIntervalCommand setEnabled:YES];
    [skipBackwardIntervalCommand addTarget:self action:@selector(skipBackwardEvent:)];
    skipBackwardIntervalCommand.preferredIntervals = @[@(15)];  // Set your own interval
    
    MPSkipIntervalCommand *skipForwardIntervalCommand = [rcc skipForwardCommand];
    skipForwardIntervalCommand.preferredIntervals = @[@(15)];  // Max 99
    [skipForwardIntervalCommand setEnabled:YES];
    [skipForwardIntervalCommand addTarget:self action:@selector(skipForwardEvent:)];
    
    MPRemoteCommand *pauseCommand = [rcc pauseCommand];
    [pauseCommand setEnabled:YES];
    [pauseCommand addTarget:self action:@selector(playOrPauseEvent:)];

    MPRemoteCommand *playCommand = [rcc playCommand];
    [playCommand setEnabled:YES];
    [playCommand addTarget:self action:@selector(playOrPauseEvent:)];
    
    [self.tableView setRowHeight:UITableViewAutomaticDimension];
    
    [self.TableFooterView setFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, 0)];
    [self.tableView setTableFooterView:self.TableFooterView];
}

- (IBAction)refreshTable {
    DHBAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    [appDelegate.podcast loadEpisodes];
}

- (void)viewDidAppear:(BOOL)animated
{
    DHBAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];

    [appDelegate.podcast addObserver:self forKeyPath:@"hasLoadedEpisodes" options:NSKeyValueObservingOptionNew context:nil];
    
    if([self.tableView numberOfRowsInSection:0] == 0) {
        [self.tableView setContentOffset:CGPointMake(0, -100) animated:YES];
        [[self refreshControl] beginRefreshing];
    } else {
    }
}

-(void) viewDidDisappear:(BOOL)animated
{
    DHBAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];

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
    DHBAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    NSMutableArray *yearsOfEpisodesArray = [appDelegate.podcast getUniqueYearsOfEpisodes];

    return yearsOfEpisodesArray.count;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    DHBAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    NSMutableArray *yearsOfEpisodesArray = [appDelegate.podcast getUniqueYearsOfEpisodes];
    
    return [NSString stringWithFormat:@"%@", [yearsOfEpisodesArray objectAtIndex:section]];
}


- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    DHBAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    // Text Color
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    [header.textLabel setTextColor:[UIColor whiteColor]];
    [header.backgroundView setBackgroundColor:[appDelegate lightColor]];
    [header.backgroundView setTintColor:[appDelegate lightColor]];

}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    DHBAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    NSMutableArray *yearsOfEpisodesArray = [appDelegate.podcast getUniqueYearsOfEpisodes];
    NSMutableArray *episodesForYear = [appDelegate.podcast getEpisodesForYear:[[yearsOfEpisodesArray objectAtIndex:section] longValue]];
    // Return the number of rows in the section.
    return episodesForYear.count;
}

- (DHBAudioTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DHBAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];

    DHBAudioTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"episodeCell" forIndexPath:indexPath];
    
    NSMutableArray *yearsOfEpisodesArray = [appDelegate.podcast getUniqueYearsOfEpisodes];
    NSMutableArray *episodesForYear = [appDelegate.podcast getEpisodesForYear:[[yearsOfEpisodesArray objectAtIndex:indexPath.section] longValue]];
    
    DHBPodcastEpisode *thisEpisode = [episodesForYear objectAtIndex:indexPath.row];
    
    cell.mainLabel.text = [NSString stringWithFormat:@"%@", thisEpisode.title];
    
    NSString *recordDateString = @"";
    
    if(thisEpisode.recordDate != nil) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"dd MMMM yyyy"];
        
        recordDateString = [dateFormatter stringFromDate:thisEpisode.recordDate];
    } else {
        recordDateString = @"Date Unavailable";
    }
    
    cell.subLabel.text = [NSString stringWithFormat:@"%@ - %@", recordDateString, thisEpisode.speaker];
    
    if(thisEpisode.isUnplayed) {
        [cell.unplayedIndicator setHidden:NO];
    } else {
        [cell.unplayedIndicator setHidden:YES];
    }
    
    if(thisEpisode.isDownloaded) {
        [cell.actionButton setTitle:@"" forState:UIControlStateNormal];
        [cell.actionButton setHidden:YES];
        [cell.actionButton constraints];
        
        [cell.progressView setHidden:NO];
    } else {
        [cell.actionButton setTitle:@"DOWNLOAD" forState:UIControlStateNormal];
        [cell.actionButton setHidden:NO];
        [cell.actionButton addTarget:self action:@selector(downloadEpisode:) forControlEvents:UIControlEventTouchUpInside];
        
        [cell.progressView setHidden:YES];
    }
    
    if(thisEpisode.downloadInProgress == 0 || thisEpisode.downloadInProgress == 1.0) {
        [cell.downloadProgressView setProgress:0.0];
        [cell.downloadProgressView setHidden:YES];
    } else {
        [cell.downloadProgressView setProgress:thisEpisode.downloadInProgress];
        [cell.downloadProgressView setHidden:NO];
    }
    
    if(thisEpisode.currentPlaybackPosition > 0) {
        [cell.progressView setProgress:thisEpisode.currentPlaybackPosition / thisEpisode.duration animated:YES];
        [cell.progressView setHidden:NO];
    } else {
        [cell.progressView setProgress:0.0];
        [cell.progressView setHidden:YES];
    }
    
    if([[[[MPNowPlayingInfoCenter defaultCenter] nowPlayingInfo] objectForKey:MPMediaItemPropertyTitle] isEqualToString:thisEpisode.title] && [self.audioPlayer isPlaying]) {
        [cell.mainLabel setTextColor:[UIColor whiteColor]];
        [cell setBackgroundColor:[appDelegate lightColor]];
        [cell.progressView setProgressTintColor:[UIColor whiteColor]];
    } else {
        [cell.mainLabel setTextColor:[UIColor blackColor]];
        [cell setBackgroundColor:[UIColor whiteColor]];
        [cell.progressView setProgressTintColor:[appDelegate lightColor]];
    }

    return cell;
}


- (void)downloadEpisode:(id) sender
{
    DHBAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    UIView *parent = [sender superview];
    while (parent && ![parent isKindOfClass:[DHBAudioTableViewCell class]]) {
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
    DHBAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    NSMutableArray *yearsOfEpisodesArray = [appDelegate.podcast getUniqueYearsOfEpisodes];
    NSMutableArray *episodesForYear = [appDelegate.podcast getEpisodesForYear:[[yearsOfEpisodesArray objectAtIndex:indexPath.section] longValue]];
    
    DHBPodcastEpisode *thisEpisode = [episodesForYear objectAtIndex:indexPath.row];
    
    //DHBPodCastEpisode *thisEpisode = [appDelegate.podCast.podcastEpisodes objectAtIndex:indexPath.row];
    
    if(!thisEpisode.isDownloaded) {
        [[tableView cellForRowAtIndexPath:indexPath] setSelected:NO];
    } else {
        DHBAudioTableViewCell *cell = (DHBAudioTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
        
        [cell setSelected:YES animated:YES];
        
        for (DHBAudioTableViewCell *thisCell in [tableView visibleCells]) {
            if(thisCell != cell) {
                [thisCell setSelected:NO animated:YES];
                [self unselectCell:thisCell];
            }
        }
        
        NSManagedObjectContext *context = [appDelegate managedObjectContext];
        self.selectedEpisode = [NSEntityDescription insertNewObjectForEntityForName:@"PodcastEpisode" inManagedObjectContext:context];

        self.selectedEpisode = thisEpisode;
        
        if(self.audioPlayer == nil) {
            NSFileManager *fileManager = [[NSFileManager alloc] init];
            fileManager = [NSFileManager defaultManager];
            
            NSData *audioData = [fileManager contentsAtPath:self.selectedEpisode.cacheFolderPathString];

            self.audioPlayer = [[AVAudioPlayer alloc] initWithData:audioData error:nil];
        } else if(![[[[MPNowPlayingInfoCenter defaultCenter] nowPlayingInfo] objectForKey:MPMediaItemPropertyTitle] isEqualToString:self.selectedEpisode.title]) {
            NSFileManager *fileManager = [[NSFileManager alloc] init];
            fileManager = [NSFileManager defaultManager];
            
            NSData *audioData = [fileManager contentsAtPath:self.selectedEpisode.cacheFolderPathString];
            
            self.audioPlayer = [[AVAudioPlayer alloc] initWithData:audioData error:nil];
            if([self.audioPlayer isPlaying]) {
                [self.audioPlayer pause];
                [cell.actionButton setTitle:@"" forState:UIControlStateNormal];
                [self unselectCell:cell];
            }
        }
        
        if([self.audioPlayer isPlaying]) {
            [self.audioPlayer pause];
            [cell.actionButton setTitle:@"" forState:UIControlStateNormal];
            [self unselectCell:cell];
        } else {
            [[AVAudioSession sharedInstance] setDelegate: self];

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
            
            NSArray *keys = [NSArray arrayWithObjects:MPMediaItemPropertyArtwork, MPMediaItemPropertyMediaType, MPMediaItemPropertyAlbumTitle, MPMediaItemPropertyPodcastPersistentID, MPMediaItemPropertyArtist, MPMediaItemPropertyTitle, MPMediaItemPropertyPodcastTitle, MPMediaItemPropertyPlaybackDuration, MPNowPlayingInfoPropertyPlaybackRate, MPNowPlayingInfoPropertyElapsedPlaybackTime, nil];
            NSArray *values = [NSArray arrayWithObjects:[[MPMediaItemArtwork alloc] initWithImage:[UIImage imageNamed:@"dharma talk icon 1024"]], [NSNumber numberWithInteger:MPMediaTypePodcast], @"Mission Dharma - Dharma Talks", @"Mission Dharma - Dharma Talks", self.selectedEpisode.speaker, self.selectedEpisode.title, self.selectedEpisode.title, [NSNumber numberWithFloat:[self.audioPlayer duration]], [NSNumber numberWithInt:1], [NSNumber numberWithFloat:self.selectedEpisode.currentPlaybackPosition], nil];
            NSDictionary *mediaInfo = [NSDictionary dictionaryWithObjects:values forKeys:keys];
            [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:mediaInfo];
            
            [self.audioPlayer play];
            [self selectCell:cell];
            
        }
    }
}

// Override to support conditional editing of the table view.
// This only needs to be implemented if you are going to be returning NO
// for some items. By default, all items are editable.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return YES if you want the specified item to be editable.
    DHBAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    NSMutableArray *yearsOfEpisodesArray = [appDelegate.podcast getUniqueYearsOfEpisodes];
    NSMutableArray *episodesForYear = [appDelegate.podcast getEpisodesForYear:[[yearsOfEpisodesArray objectAtIndex:indexPath.section] longValue]];
    
    DHBPodcastEpisode *thisEpisode = [episodesForYear objectAtIndex:indexPath.row];
    //DHBPodCastEpisode *thisEpisode = [appDelegate.podCast.podcastEpisodes objectAtIndex:indexPath.row];
    
    bool canEditRow = NO;
    
    if((thisEpisode.isDownloaded && ![[[[MPNowPlayingInfoCenter defaultCenter] nowPlayingInfo] objectForKey:MPMediaItemPropertyTitle] isEqualToString:thisEpisode.title] && [self.audioPlayer isPlaying]) || (thisEpisode.isDownloaded && ![self.audioPlayer isPlaying])) {
        canEditRow = YES;
    }
    
    return canEditRow;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return @"Remove Download";
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        //add code here for when you hit delete
        DHBAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
        NSManagedObjectContext *context = [appDelegate managedObjectContext];
        DHBPodcastEpisode *episodeToDelete = [NSEntityDescription insertNewObjectForEntityForName:@"PodcastEpisode" inManagedObjectContext:context];
        NSMutableArray *yearsOfEpisodesArray = [appDelegate.podcast getUniqueYearsOfEpisodes];
        NSMutableArray *episodesForYear = [appDelegate.podcast getEpisodesForYear:[[yearsOfEpisodesArray objectAtIndex:indexPath.section] longValue]];
        
        episodeToDelete = [episodesForYear objectAtIndex:indexPath.row];
        
        [episodeToDelete deleteEpisode];
        
        [self.tableView reloadData];
    }
}

- (BOOL)isHeadsetPluggedIn
{
    // Get array of current audio outputs (there should only be one)
    NSArray *outputs = [[AVAudioSession sharedInstance] currentRoute].outputs;
    
    NSString *portName = [[outputs objectAtIndex:0] portName];
    
    if ([portName isEqualToString:@"Headphones"]) {
        return YES;
    }
    
    return NO;
}

- (void) audioRouteChangeListenerCallback
{
    [self.audioPlayer pause];
}

void audioRouteChangeListenerCallback (void *inUserData, AudioSessionPropertyID inPropertyID, UInt32 inPropertyValueSize, const void *inPropertyValue) {
    if (inPropertyID != kAudioSessionProperty_AudioRouteChange) return; // 5
    
    DHBAudioTableViewController *controller = (__bridge DHBAudioTableViewController *) inUserData; // 6
    
    if (controller.audioPlayer.playing == 0 ) {                      // 7
        return;
    } else {
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
            kAudioSessionRouteChangeReason_OldDeviceUnavailable) {  // 9
            
            [controller.audioPlayer pause];
            
        }
    }
}

-(void)selectCell:(DHBAudioTableViewCell *) cell
{
    DHBAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    [UIView animateWithDuration:0.2 animations:^{
        [cell.mainLabel setTextColor:[UIColor whiteColor]];
        [cell.subLabel setTextColor:[UIColor whiteColor]];
        [cell setBackgroundColor:[appDelegate lightColor]];
        [cell.progressView setProgressTintColor:[UIColor whiteColor]];
        //[cell.progressView setHidden:YES];
        [cell.nowPlayingLabel setHidden:NO];
        
        [cell.nowPlayingLabel setText:[NSString stringWithFormat:@"%02.f:%02.f - %02.f:%02.f", floor(self.selectedEpisode.currentPlaybackPosition / 60), floor(self.selectedEpisode.currentPlaybackPosition) - (floor(self.selectedEpisode.currentPlaybackPosition / 60) * 60), floor(self.audioPlayer.duration / 60), self.audioPlayer.duration - (floor(self.audioPlayer.duration / 60) * 60) ]];
    }];
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateAudioProgressForCell) userInfo:cell repeats:YES];
}

-(void)unselectCell:(DHBAudioTableViewCell *) cell
{
    DHBAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    [self.timer invalidate];
    self.timer = nil;
    
    [UIView animateWithDuration:0.2 animations:^{
        [cell.mainLabel setTextColor:[UIColor blackColor]];
        [cell.subLabel setTextColor:[UIColor lightGrayColor]];
        
        [cell setBackgroundColor:[UIColor whiteColor]];
        [cell.progressView setProgressTintColor:[appDelegate lightColor]];
        [cell.progressView setHidden:NO];
        [cell.nowPlayingLabel setHidden:YES];
    }];
}

- (void)skipBackwardEvent:(UIEvent *) event
{
    if(nil != self.audioPlayer)
    {
        self.selectedEpisode.currentPlaybackPosition -= 15;
        [self.audioPlayer setCurrentTime:self.selectedEpisode.currentPlaybackPosition];
    
        [self updateNowPlayingInfoCenter];
    }
}

- (void)skipForwardEvent:(UIEvent *) event
{
    if(nil != self.audioPlayer)
    {
        self.selectedEpisode.currentPlaybackPosition += 15;
        [self.audioPlayer setCurrentTime:self.selectedEpisode.currentPlaybackPosition];
    
        [self updateNowPlayingInfoCenter];
    }
}

- (void)playOrPauseEvent:(UIEvent *) event
{
    DHBAudioTableViewCell *cell = (DHBAudioTableViewCell *)[self.tableView cellForRowAtIndexPath:[self.tableView indexPathForSelectedRow]];
    
    if(nil != self.audioPlayer)
    {
        if([self.audioPlayer isPlaying]) {
            [self.audioPlayer pause];
            [self unselectCell:cell];
        } else {
            [self.audioPlayer play];
            [self selectCell:cell];
        }
        
        [self updateNowPlayingInfoCenter];
    }
    
}

- (void)updateNowPlayingInfoCenter
{
    [self.audioPlayer setCurrentTime:self.selectedEpisode.currentPlaybackPosition];
    
    NSArray *keys = [NSArray arrayWithObjects:MPMediaItemPropertyArtwork, MPMediaItemPropertyMediaType, MPMediaItemPropertyAlbumTitle, MPMediaItemPropertyPodcastPersistentID, MPMediaItemPropertyArtist, MPMediaItemPropertyTitle, MPMediaItemPropertyPodcastTitle, MPMediaItemPropertyPlaybackDuration, MPNowPlayingInfoPropertyPlaybackRate, MPNowPlayingInfoPropertyElapsedPlaybackTime, nil];
    NSArray *values = [NSArray arrayWithObjects:[[MPMediaItemArtwork alloc] initWithImage:[UIImage imageNamed:@"dharma talk icon 1024"]], [NSNumber numberWithInteger:MPMediaTypePodcast], @"Mission Dharma - Dharma Talks", @"Mission Dharma - Dharma Talks", self.selectedEpisode.speaker, self.selectedEpisode.title, self.selectedEpisode.title, [NSNumber numberWithFloat:[self.audioPlayer duration]], [NSNumber numberWithInt:1], [NSNumber numberWithFloat:self.selectedEpisode.currentPlaybackPosition], nil];
    NSDictionary *mediaInfo = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:mediaInfo];
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)event
{
    /*
    if (event.type == UIEventTypeRemoteControl) {
        DHBAudioTableViewCell *cell = (DHBAudioTableViewCell *)[self.tableView cellForRowAtIndexPath:[self.tableView indexPathForSelectedRow]];
        
        switch (event.subtype) {
            case UIEventSubtypeRemoteControlPause:
                [self.audioPlayer pause];
                [self unselectCell:cell];
                break;
                
            case UIEventSubtypeRemoteControlPlay:
                [self.audioPlayer play];
                [self selectCell:cell];
                break;
            case UIEventSubtypeRemoteControlPreviousTrack:
                //[self.audioPlayer previousTrack: nil];
                NSLog(@"Skip 15 second back");
                self.selectedEpisode.currentPlaybackPosition -= 15;
                [self.audioPlayer setCurrentTime:self.selectedEpisode.currentPlaybackPosition];
                break;
                
            case UIEventSubtypeRemoteControlNextTrack:
                //[self.audioPlayer nextTrack: nil];
                NSLog(@"Skip 15 seconds forward");
                self.selectedEpisode.currentPlaybackPosition += 15;
                break;
            default:
                break;
        }
        
        [self.audioPlayer setCurrentTime:self.selectedEpisode.currentPlaybackPosition];
        
        NSArray *keys = [NSArray arrayWithObjects:MPMediaItemPropertyArtwork, MPMediaItemPropertyMediaType, MPMediaItemPropertyAlbumTitle, MPMediaItemPropertyPodcastPersistentID, MPMediaItemPropertyArtist, MPMediaItemPropertyTitle, MPMediaItemPropertyPodcastTitle, MPMediaItemPropertyPlaybackDuration, MPNowPlayingInfoPropertyPlaybackRate, MPNowPlayingInfoPropertyElapsedPlaybackTime, nil];
        NSArray *values = [NSArray arrayWithObjects:[[MPMediaItemArtwork alloc] initWithImage:[UIImage imageNamed:@"dharma talk icon 1024"]], [NSNumber numberWithInteger:MPMediaTypePodcast], @"Mission Dharma - Dharma Talks", @"Mission Dharma - Dharma Talks", self.selectedEpisode.speaker, self.selectedEpisode.title, self.selectedEpisode.title, [NSNumber numberWithFloat:[self.audioPlayer duration]], [NSNumber numberWithInt:1], [NSNumber numberWithFloat:self.selectedEpisode.currentPlaybackPosition], nil];
        NSDictionary *mediaInfo = [NSDictionary dictionaryWithObjects:values forKeys:keys];
        [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:mediaInfo];
        
    }
     */
}

-(void) updateAudioProgressForCell
{
    DHBAudioTableViewCell *cell = [self.timer userInfo];
    
    float audioPlayerPercentComplete = (self.audioPlayer.currentTime / self.audioPlayer.duration);
    
    [cell.nowPlayingLabel setText:[NSString stringWithFormat:@"%02.f:%02.f - %02.f:%02.f", floor(self.selectedEpisode.currentPlaybackPosition / 60), floor(self.selectedEpisode.currentPlaybackPosition) - (floor(self.selectedEpisode.currentPlaybackPosition / 60) * 60), floor(self.audioPlayer.duration / 60), self.audioPlayer.duration - (floor(self.audioPlayer.duration / 60) * 60) ]];

    [cell.progressView setProgress:audioPlayerPercentComplete animated:NO];
    [self.selectedEpisode setCurrentPlaybackPosition:self.audioPlayer.currentTime];
    if(self.selectedEpisode.duration == 0) {
        [self.selectedEpisode setDuration:self.audioPlayer.duration];
    }
    if(self.selectedEpisode.isUnplayed) {
        self.selectedEpisode.isUnplayed = NO;
        [cell.unplayedIndicator setHidden:YES];
    }
    [self.selectedEpisode save];
    
    if(audioPlayerPercentComplete == 1.0) {
        [self.timer invalidate];
        self.timer = nil;
        [self unselectCell:cell];
        [self.audioPlayer stop];
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
