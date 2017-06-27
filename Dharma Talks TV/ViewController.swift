//
//  ViewController.swift
//  Dharma Talks TV
//
//  Created by David Brunow on 1/1/16.
//  Copyright © 2016 David Brunow. All rights reserved.
//

import MediaPlayer
import UIKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate
{
    struct Constants
    {
        static let DharmaTalkTableViewCellIdentifier = "Dharma Talk Table View Cell"
    }
    
    var appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var audioEngine: AVAudioEngine!
    var audioFile = AVAudioFile()
    var audioPlayerNode: AVAudioPlayerNode!
    var playbackTimer = NSTimer()
    var selectedEpisode: PodcastEpisode?
    
    @IBOutlet weak var dharmaTalksTableView: UITableView!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        dharmaTalksTableView.delegate = self
        dharmaTalksTableView.dataSource = self
    }
    
    func downloadAllFiles()
    {
        appDelegate.podcast.downloadAllTalks()
    }
    
    override func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(animated)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadTable", name: "Episodes Fetched From Local Database", object: nil)
        
        reloadTable()
    }
    
    override func viewWillDisappear(animated: Bool)
    {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func reloadTable()
    {
        dispatch_async(dispatch_get_main_queue())
        { [unowned self] in
             self.dharmaTalksTableView.reloadData()
        }
        
        //downloadAllFiles()
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        var numberOfEpisodes = 0
        
        if(appDelegate.podcast != nil)
        {
            numberOfEpisodes = appDelegate.podcast.getUniqueYearsOfEpisodes().count
        }
        
        return numberOfEpisodes
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        var header = ""
        
        if appDelegate.podcast != nil
        {
            header = "\(appDelegate.podcast.getUniqueYearsOfEpisodes()[section])"
        }
        
        return header
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        var numberOfRows = 0
        
        if appDelegate.podcast != nil
        {
            let yearsOfEpisodes = appDelegate.podcast.getUniqueYearsOfEpisodes()
            let episodesForYear = appDelegate.podcast.getEpisodesForYear(yearsOfEpisodes.objectAtIndex(section) as! Int)
            numberOfRows = episodesForYear.count
        }
        
        return numberOfRows
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCellWithIdentifier(Constants.DharmaTalkTableViewCellIdentifier, forIndexPath: indexPath)
        
        if appDelegate.podcast != nil
        {
            let yearsOfEpisodes = appDelegate.podcast.getUniqueYearsOfEpisodes()
            let episodesForYear = appDelegate.podcast.getEpisodesForYear(yearsOfEpisodes.objectAtIndex(indexPath.section) as! Int)
            
            let episode = episodesForYear[indexPath.row] as! PodcastEpisode
            
            cell.textLabel?.text = episode.title
            
            var recordDateString = ""
            
            if episode.recordDate != nil
            {
                let dateFormatter = NSDateFormatter()
                dateFormatter.dateFormat = "dd MMMM yyyy"
                
                recordDateString = dateFormatter.stringFromDate(episode.recordDate)
            }
            else
            {
                recordDateString = "Date Unavailable"
            }
            
            if !episode.isDownloaded
            {
                episode.downloadEpisode()
            }
            
            cell.detailTextLabel?.text = "\(recordDateString) – \(episode.speaker) - \(episode.isDownloaded)"
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        if appDelegate.podcast != nil
        {
            let yearsOfEpisodes = appDelegate.podcast.getUniqueYearsOfEpisodes()
            let episodesForYear = appDelegate.podcast.getEpisodesForYear(yearsOfEpisodes.objectAtIndex(indexPath.section) as! Int)
            
            let episode = episodesForYear[indexPath.row] as! PodcastEpisode
            
            if audioPlayerNode == nil || !audioPlayerNode.playing
            {
                selectedEpisode = episode
                playEpisode(episode)
            }
            else
            {
                audioPlayerNode.pause()
                playbackTimer.invalidate()
            }
        }
    }
    
    func playEpisode(episode: PodcastEpisode)
    {
        audioEngine = AVAudioEngine()
        audioPlayerNode = AVAudioPlayerNode()
        
        audioEngine.attachNode(audioPlayerNode)
        
        let mixerNode = audioEngine.mainMixerNode
        let audioSession = AVAudioSession.sharedInstance()
        
        do
        {
            try audioSession.setCategory(AVAudioSessionCategoryPlayback)
            try audioSession.setActive(true)
            
            let fullPathString = "\(appDelegate.applicationHome)/\(episode.localPathString)"
            let fileURL = NSURL(fileURLWithPath: fullPathString)
            
            try audioFile = AVAudioFile(forReading: fileURL)
            
            if episode.currentPlaybackPosition > 5
            {
                episode.currentPlaybackPosition -= 5
                
                audioFile.framePosition = AVAudioFramePosition(episode.currentPlaybackPosition) * AVAudioFramePosition(audioFile.processingFormat.sampleRate)
            }
            
            let audioPCMBuffer = createAndLoadBuffer()

            audioEngine.connect(audioPlayerNode, to: mixerNode, format: audioPCMBuffer.format)
            
            scheduleBuffer(audioPCMBuffer)
            
            try audioEngine.start()
            
            audioPlayerNode.play()
            
            playbackTimer = NSTimer.scheduledTimerWithTimeInterval(NSTimeInterval(1), target: self, selector: "updateAudioProgress", userInfo: nil, repeats: true)
            
            UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
        }
        catch let exception
        {
            print("Error in PlayEpisode: \(exception)")
        }
    }
    
    func updateAudioProgress()
    {
        let sampleRate = audioFile.processingFormat.sampleRate
        let episodeLength = Float(audioFile.length) / Float(sampleRate)
        let episodePosition = Float(audioFile.framePosition) / Float(sampleRate)
        let percentComplete = episodePosition / episodeLength
        
        if selectedEpisode != nil
        {
            selectedEpisode?.currentPlaybackPosition = Float(episodePosition)
            
            if selectedEpisode!.isUnplayed == [NSNumber numberWithBool: YES]
            {
                selectedEpisode?.isUnplayed = [NSNumber numberWithBool: NO]
            }
            
            selectedEpisode?.save()
        }
        
        if percentComplete > 0.99
        {
            playbackTimer.invalidate()
            
            audioPlayerNode.stop()
        }
    }
    
    func scheduleBuffer(buffer: AVAudioPCMBuffer)
    {
        audioPlayerNode.scheduleBuffer(buffer, atTime: nil, options: AVAudioPlayerNodeBufferOptions.InterruptsAtLoop)
        { [unowned self] in
            if self.audioPlayerNode.playing
            {
                self.loadBuffer()
            }
        }
    }
    
    func loadBuffer()
    {
        let buffer = createAndLoadBuffer()
        
        scheduleBuffer(buffer)
    }
    
    func createAndLoadBuffer() -> AVAudioPCMBuffer
    {
        let audioPCMBuffer = AVAudioPCMBuffer(PCMFormat: audioFile.processingFormat, frameCapacity: AVAudioFrameCount(audioFile.processingFormat.sampleRate))
        
        do
        {
            try audioFile.readIntoBuffer(audioPCMBuffer)
        }
        catch let exception
        {
            print("Error creating and loading buffer: \(exception)")
        }
        
        return audioPCMBuffer
    }
    
    /*
    
    - (void) playEpisode:(PodcastEpisode *) episode
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
    [self scheduleBuffer:audioPCMBuffer];
    
    [self.audioEngine connect:self.audioPlayerNode to:mixerNode format:audioPCMBuffer.format];
    
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
*/
    
    override func remoteControlReceivedWithEvent(event: UIEvent?)
    {
        if let thisEvent = event
        {
            switch thisEvent.subtype
            {
            case .RemoteControlPause:
                if audioPlayerNode.playing
                {
                    audioPlayerNode.pause()
                }
                else if let episode = selectedEpisode
                {
                    playEpisode(episode)
                }
            default:
                break
            }
        }
    }

    /*
    
    -(void) setNowPlayingInfoCenterInfo
    {
    double sampleRate = self.audioFile.processingFormat.sampleRate;
    NSTimeInterval episodeLength = self.audioFile.length / sampleRate;
    
    NSArray *keys = [NSArray arrayWithObjects:MPMediaItemPropertyArtwork, MPMediaItemPropertyMediaType, MPMediaItemPropertyAlbumTitle, MPMediaItemPropertyPodcastPersistentID, MPMediaItemPropertyArtist, MPMediaItemPropertyTitle, MPMediaItemPropertyPodcastTitle, MPMediaItemPropertyPlaybackDuration, MPNowPlayingInfoPropertyPlaybackRate, MPNowPlayingInfoPropertyElapsedPlaybackTime, nil];
    NSArray *values = [NSArray arrayWithObjects:[[MPMediaItemArtwork alloc] initWithImage:[UIImage imageNamed:@"dharma talk icon 1024"]], [NSNumber numberWithInteger:MPMediaTypePodcast], @"Mission Dharma - Dharma Talks", @"Mission Dharma - Dharma Talks", self.selectedEpisode.speaker, self.selectedEpisode.title, self.selectedEpisode.title, [NSNumber numberWithFloat:episodeLength], [NSNumber numberWithInt:1], [NSNumber numberWithFloat:self.selectedEpisode.currentPlaybackPosition], nil];
    
    NSDictionary *mediaInfo = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:mediaInfo];
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
    */
}

