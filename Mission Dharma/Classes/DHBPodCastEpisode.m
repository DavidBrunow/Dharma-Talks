//
//  DHBPodcastEpisode.m
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

#import "DHBPodcastEpisode.h"
#import "Mission_Dharma-Swift.h"

@implementation DHBPodcastEpisode

@synthesize totalFileSize = _totalFileSize, isDownloaded = _isDownloaded, downloadInProgress = _downloadInProgress, tempEpisodeData = _tempEpisodeData, cacheFolderPathString = _cacheFolderPathString;
@dynamic currentPlaybackPosition, speaker, localPathString, recordDate, title, URLString, duration, isUnplayed;

- (id)initWithEntity:(NSEntityDescription *)entity insertIntoManagedObjectContext:(NSManagedObjectContext *)context
{
    self = [super initWithEntity:entity insertIntoManagedObjectContext:context];
    
    if (self) {
        //initializations
    }
    
    return self;
}

-(void)awakeFromFetch
{
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    fileManager = [NSFileManager defaultManager];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    self.cacheFolderPathString = [NSString stringWithFormat:@"%@/%@", appDelegate.applicationHome, [self.localPathString lastPathComponent]];
    
    if([fileManager fileExistsAtPath:self.cacheFolderPathString]) {
        
        [self setIsDownloaded:YES];
        [self addSkipBackupAttributeToItemAtURL:[NSURL fileURLWithPath:self.cacheFolderPathString]];
    } else {
        [self setIsDownloaded:NO];
    }
}

-(void)save
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
    
    NSError *error;
    if (![context save:&error]) {
        NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
    }
}

-(void)parseInfo:(NSString *)info
{
    if([info rangeOfString:@","].location != NSNotFound) {
        if(info.length >= [info rangeOfString:@"," options:NSBackwardsSearch].location + 2) {
            [self setValue:[info substringFromIndex:[info rangeOfString:@"," options:NSBackwardsSearch].location + 2] forKey:@"speaker"];
        }
    
        info = [info substringToIndex:[info rangeOfString:@"," options:NSBackwardsSearch].location];
    }
    
    [self setValue:info forKey:@"title"];
    
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:[NSDate date]];
    
    int thisYear = (int)components.year;
    
    for(int i = thisYear; i > 2009; i--)
    {
        NSString *yearString = [NSString stringWithFormat:@"%d", i];
        
        if([info rangeOfString:yearString].location != NSNotFound) {
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"MMM dd, yyyy"];
            
            [self setValue:[dateFormatter dateFromString:[info substringWithRange:NSMakeRange(0, [info rangeOfString:yearString].location + 4)]] forKey:@"recordDate"];
            
            if(info.length >= [info rangeOfString:yearString].location + 6) {
                [self setValue:[info substringFromIndex:[info rangeOfString:yearString].location + 6] forKey:@"title"];
            }
        }
    }
    
    }

-(void)setURLString:(NSString *)URLString
{
    [self setValue:URLString forKey:@"urlString"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    BOOL isDir;

    if(![fileManager fileExistsAtPath:documentsPath isDirectory:&isDir])
    {
        [fileManager createDirectoryAtPath:documentsPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSURL *fileNameURL = [NSURL URLWithString:URLString];
    
    NSString *fileName = [fileNameURL lastPathComponent];
    [self setValue:fileName forKey:@"localPathString"];
    
    if([fileManager fileExistsAtPath:self.cacheFolderPathString]) {
        [self setIsDownloaded:YES];
        [self addSkipBackupAttributeToItemAtURL:[NSURL fileURLWithPath:self.localPathString]];
    } else {
        [self setIsDownloaded:NO];
    }
}

-(void) downloadEpisode
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];

    /* if(!appDelegate.isConnectedViaWifi) {
        UIAlertView * alert  = [[UIAlertView alloc] initWithTitle:@"Not Connected to Wifi" message:[NSString stringWithFormat:@"Sorry, due to the size of each episode, they can only be downloaded if you are connected to wifi."] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil ];
        [alert show];
    } else { */
    self.tempEpisodeData = [[NSMutableData alloc] init];
    self.cacheFolderPathString = [NSString stringWithFormat:@"%@/%@", appDelegate.applicationHome, [self.localPathString lastPathComponent]];
    
    NSURLRequest *episodeURLRequest  = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:[self valueForKey:@"urlString"]]];
    (void)[[NSURLConnection alloc] initWithRequest:episodeURLRequest delegate:self];
    //}
}

-(void) deleteEpisode
{
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    fileManager = [NSFileManager defaultManager];
    
    [fileManager removeItemAtPath:[self valueForKey:@"cacheFolderPathString"] error:nil];
    [self setIsDownloaded:NO];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response
{
    //[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    int statusCode = (int)[response statusCode];
    if (statusCode == 200) {
        self.totalFileSize = [response expectedContentLength];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.tempEpisodeData appendData:data];
    [self setDownloadInProgress:(_tempEpisodeData.length / self.totalFileSize)];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    //[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];

    if([fileManager createFileAtPath:self.cacheFolderPathString contents:self.tempEpisodeData attributes:nil]) {
        [self setIsDownloaded:YES];
        [self addSkipBackupAttributeToItemAtURL:[NSURL fileURLWithPath:self.cacheFolderPathString]];
    } else {
        [self setIsDownloaded:NO];
    }
    
    self.tempEpisodeData = nil;
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"%@", error);
    if([error.description.lowercaseString containsString:@"the request timed out"])
    {
        [self downloadEpisode];
    }
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
    return nil;
}

- (BOOL)addSkipBackupAttributeToItemAtURL:(NSURL *)URL
{
    assert([[NSFileManager defaultManager] fileExistsAtPath: [URL path]]);
    
    NSError *error = nil;
    BOOL success = [URL setResourceValue: [NSNumber numberWithBool: YES]
                                  forKey: NSURLIsExcludedFromBackupKey error: &error];

    if(!success){
        NSLog(@"Error excluding %@ from backup %@", [URL lastPathComponent], error);
    }
    
    return success;
}

/*
- (BOOL)isEqual:(id)object
{
    if([object isKindOfClass:[self class]]) {
        DHBPodcastEpisode *tempEpisode = object;
        
        if(self.localPathString == tempEpisode.localPathString) {
            return YES;
        }
    }
    
    return NO;
}
 */

@end
