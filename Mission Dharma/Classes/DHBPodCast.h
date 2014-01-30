//
//  DHBPodcast.h
//  Mission Dharma
//
//  Created by David Brunow on 8/7/13.
//  Copyright (c) 2013 David Brunow. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DHBPodcast : NSObject <NSURLConnectionDataDelegate>

@property (nonatomic, strong) NSMutableArray *podcastEpisodes;
@property (nonatomic) NSMutableData *podcastData;
@property (nonatomic, strong) NSString *podcastURLString;
@property (nonatomic, strong) NSString *podcastRootURLString;
@property (nonatomic) bool hasLoadedEpisodes;

-(void) loadEpisodes;
-(NSMutableArray *)getUniqueYearsOfEpisodes;
-(NSMutableArray *)getEpisodesForYear:(NSInteger) year;

@end
