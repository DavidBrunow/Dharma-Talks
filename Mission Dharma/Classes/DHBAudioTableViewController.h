//
//  DHBAudioTableViewController.h
//  Mission Dharma
//
//  Created by David Brunow on 8/7/13.
//  Copyright (c) 2013 David Brunow. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "DHBPodcastEpisode.h"

@interface DHBAudioTableViewController : UITableViewController <UITableViewDelegate, UITableViewDataSource, AVAudioSessionDelegate, AVAudioPlayerDelegate>

@property (nonatomic, strong) DHBPodcastEpisode *selectedEpisode;
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) NSTimer *timer;

@end
