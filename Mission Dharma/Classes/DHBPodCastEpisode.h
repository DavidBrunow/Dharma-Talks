//
//  DHBPodcastEpisode.h
//  Mission Dharma
//
//  Created by David Brunow on 8/7/13.
//  Copyright (c) 2013 David Brunow. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DHBPodcastEpisode : NSManagedObject

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *speaker;
@property (nonatomic, strong) NSDate *recordDate;
@property (nonatomic, strong) NSString *URLString;
@property (nonatomic, strong) NSString *localPathString;
@property (nonatomic) NSMutableData *tempEpisodeData;
@property (nonatomic) float currentPlaybackPosition;
@property (nonatomic) float duration;
@property (nonatomic) bool isUnplayed;
@property (nonatomic) bool isDownloaded;
@property (nonatomic) float totalFileSize;
@property (nonatomic) float downloadInProgress;

-(void) downloadEpisode;
-(void) deleteEpisode;
-(void) parseInfo:(NSString *)info;
-(void) save;


@end
