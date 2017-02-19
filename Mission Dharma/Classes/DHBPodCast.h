//
//  DHBPodcast.h
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

#import <Foundation/Foundation.h>

@interface DHBPodcast : NSObject <NSURLConnectionDataDelegate>

@property (nonatomic, strong) NSMutableArray *podcastEpisodes;
@property (nonatomic) NSMutableData *podcastData;
@property (nonatomic, strong) NSString *podcastURLString;
@property (nonatomic, strong) NSString *podcastRootURLString;
@property (nonatomic) bool hasLoadedEpisodes;

-(void)downloadAllTalks;
-(void) loadEpisodes;
-(NSMutableArray *)getUniqueYearsOfEpisodes;
-(NSMutableArray *)getEpisodesForYear:(NSInteger) year;

@end
