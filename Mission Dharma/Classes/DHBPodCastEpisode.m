//
//  DHBPodcastEpisode.m
//  Mission Dharma
//
//  Created by David Brunow on 8/7/13.
//  Copyright (c) 2013 David Brunow. All rights reserved.
//

#import "DHBPodcastEpisode.h"
#import "DHBAppDelegate.h"

@implementation DHBPodcastEpisode

@synthesize totalFileSize = _totalFileSize, isDownloaded = _isDownloaded, downloadInProgress = _downloadInProgress, tempEpisodeData = _tempEpisodeData;
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
    
    if([fileManager fileExistsAtPath:self.localPathString]) {
        [self setIsDownloaded:YES];
    } else {
        [self setIsDownloaded:NO];
    }
}

-(void)save
{
    DHBAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
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
    
    if([info rangeOfString:@"2014"].location != NSNotFound) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"MMM dd, yyyy"];
        
        [self setValue:[dateFormatter dateFromString:[info substringWithRange:NSMakeRange(0, [info rangeOfString:@"2014"].location + 4)]] forKey:@"recordDate"];
        
        if(info.length >= [info rangeOfString:@"2014"].location + 6) {
            [self setValue:[info substringFromIndex:[info rangeOfString:@"2014"].location + 6] forKey:@"title"];
        }
    }
    
    if([info rangeOfString:@"2013"].location != NSNotFound) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"MMM dd, yyyy"];
        
        [self setValue:[dateFormatter dateFromString:[info substringWithRange:NSMakeRange(0, [info rangeOfString:@"2013"].location + 4)]] forKey:@"recordDate"];
        
        if(info.length >= [info rangeOfString:@"2013"].location + 6) {
            [self setValue:[info substringFromIndex:[info rangeOfString:@"2013"].location + 6] forKey:@"title"];
        }
    }
    
    if([info rangeOfString:@"2012"].location != NSNotFound) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"MMM dd, yyyy"];
        
        [self setValue:[dateFormatter dateFromString:[info substringWithRange:NSMakeRange(0, [info rangeOfString:@"2012"].location + 4)]] forKey:@"recordDate"];
        
        if(info.length >= [info rangeOfString:@"2012"].location + 6) {
            [self setValue:[info substringFromIndex:[info rangeOfString:@"2012"].location + 6] forKey:@"title"];
        }
    }
    
    if([info rangeOfString:@"2011"].location != NSNotFound) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"MMM dd, yyyy"];
        
        [self setValue:[dateFormatter dateFromString:[info substringWithRange:NSMakeRange(0, [info rangeOfString:@"2011"].location + 4)]] forKey:@"recordDate"];
        
        if(info.length >= [info rangeOfString:@"2011"].location + 6) {
            [self setValue:[info substringFromIndex:[info rangeOfString:@"2011"].location + 6] forKey:@"title"];
        }
    }
    
    if([info rangeOfString:@"2010"].location != NSNotFound) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"MMM dd, yyyy"];
        
        [self setValue:[dateFormatter dateFromString:[info substringWithRange:NSMakeRange(0, [info rangeOfString:@"2010"].location + 4)]] forKey:@"recordDate"];
        
        if(info.length >= [info rangeOfString:@"2010"].location + 6) {
            [self setValue:[info substringFromIndex:[info rangeOfString:@"2010"].location + 6] forKey:@"title"];
        }
    }
}

-(void)setURLString:(NSString *)URLString
{
    [self setValue:URLString forKey:@"urlString"];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    
    NSURL *fileNameURL = [NSURL URLWithString:URLString];
    
    NSString *fileName = [fileNameURL lastPathComponent];
    
    [self setValue:[NSString stringWithFormat:@"%@/%@", documentsPath, fileName] forKey:@"localPathString"];
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    fileManager = [NSFileManager defaultManager];
    
    if([fileManager fileExistsAtPath:self.localPathString]) {
        [self setIsDownloaded:YES];
    } else {
        [self setIsDownloaded:NO];
    }
}

-(void) downloadEpisode
{
    //DHBAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];

    /* if(!appDelegate.isConnectedViaWifi) {
        UIAlertView * alert  = [[UIAlertView alloc] initWithTitle:@"Not Connected to Wifi" message:[NSString stringWithFormat:@"Sorry, due to the size of each episode, they can only be downloaded if you are connected to wifi."] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil ];
        [alert show];
    } else { */
        self.tempEpisodeData = [[NSMutableData alloc] init];
        
        NSURLRequest *episodeURLRequest  = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:[self valueForKey:@"urlString"]]];
        (void)[[NSURLConnection alloc] initWithRequest:episodeURLRequest delegate:self];
    //}
}

-(void) deleteEpisode
{
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    fileManager = [NSFileManager defaultManager];
    
    [fileManager removeItemAtPath:[self valueForKey:@"localPathString"] error:nil];
    [self setIsDownloaded:NO];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
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
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    fileManager = [NSFileManager defaultManager];
    
    if([fileManager createFileAtPath:self.localPathString contents:self.tempEpisodeData attributes:nil]) {
        [self setIsDownloaded:YES];
    } else {
        [self setIsDownloaded:NO];
    }
    
    self.tempEpisodeData = nil;
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"%@", error);
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
    return nil;
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
