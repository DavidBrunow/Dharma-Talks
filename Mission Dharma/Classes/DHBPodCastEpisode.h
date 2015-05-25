//
//  DHBPodcastEpisode.h
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
@property (nonatomic, strong) NSString *cacheFolderPathString;

-(void) downloadEpisode;
-(void) deleteEpisode;
-(void) parseInfo:(NSString *)info;
-(void) save;


@end
