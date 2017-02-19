//
//  DHBPodcast.m
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
#import "DHBPodcastEpisode.h"
//#import <libxml2/libxml/HTMLparser.h>
#import "Mission_Dharma-Swift.h"

@implementation DHBPodcast

-(id)init
{
    self.podcastEpisodes = [[NSMutableArray alloc] init];
    [self setPodcastRootURLString:@"http://www.missiondharma.org"];
    
    return self;
}

-(void) loadEpisodes
{
    //self.podcastEpisodes = [[NSMutableArray alloc] init];
    [self setHasLoadedEpisodes:NO];
    NSLog(@"Load episodes is being called");
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if(0 == self.podcastEpisodes.count)
    {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSManagedObjectContext *context = [appDelegate managedObjectContext];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"PodcastEpisode" inManagedObjectContext:context];
        [fetchRequest setEntity:entity];
        NSError *error;
        NSArray *fetchedObjects = (NSMutableArray *)[context executeFetchRequest:fetchRequest error:&error];
    
        NSLog(@"You have %d episodes pulled from CoreData", (int)fetchedObjects.count);
        for (DHBPodcastEpisode *episode in fetchedObjects) {
            bool isPresentInArray = false;
            
            for(DHBPodcastEpisode *thisEpisode in self.podcastEpisodes) {
                if([thisEpisode valueForKey:@"urlString"] != nil && [episode valueForKey:@"urlString"] != nil){
                    if([[thisEpisode valueForKey:@"urlString"] isEqualToString:[episode valueForKey:@"urlString"]]) {
                        isPresentInArray = true;
                        
                        break;
                    }
                }
            }
            
            if(!isPresentInArray && [episode valueForKey:@"urlString"] != nil && episode.title != nil && episode.recordDate != nil) {
                if([(NSString *)[episode valueForKey:@"urlString"] rangeOfString:self.podcastRootURLString].location == NSNotFound)
                {
                    [episode setURLString:[NSString stringWithFormat:@"%@%@", self.podcastRootURLString, [episode valueForKey:@"urlString"]]];
                }
                
                
                [self.podcastEpisodes addObject:episode];
            }
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"Episodes Fetched From Local Database" object:nil];
    }
    
    [self setPodcastURLString:@"http://www.missiondharma.org/dharma-talks.html"];
    [self setPodcastURLString:@"https://api.brunow.org/node/dharma-talks-v1/talks"];
    
    self.podcastData = [[NSMutableData alloc] init];
    
    NSString *podcastURLString = [NSString stringWithFormat:@"http://www.missiondharma.org/dharma-talks.html"];
    
    podcastURLString = @"https://api.brunow.org/node/dharma-talks-v1/talks";
    
    NSURLRequest *podcastURLRequest  = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:podcastURLString]];
    
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:podcastURLRequest delegate:self startImmediately:NO];
    
    [connection scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    [connection start];
    
    NSLog(@"Initing connection!");
    NSSortDescriptor *sortDescriptor;
    sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"recordDate"
                                                 ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    NSArray *sortedArray;
    sortedArray = [self.podcastEpisodes sortedArrayUsingDescriptors:sortDescriptors];
    
    self.podcastEpisodes = [[NSMutableArray alloc] initWithArray:sortedArray];
    
    [self setHasLoadedEpisodes:YES];
}

-(void)downloadAllTalks
{
    for(DHBPodcastEpisode *episode in self.podcastEpisodes)
    {
        if(!episode.isDownloaded)
        {
            [episode downloadEpisode];
        }
    }
}

-(NSMutableArray *)getUniqueYearsOfEpisodes
{
    NSMutableArray *uniqueYears = [[NSMutableArray alloc] init];
    
    if(self.podcastEpisodes.count > 0) {
        DHBPodcastEpisode *thisEpisode = [self.podcastEpisodes objectAtIndex:0];
        
        NSDateComponents *thisComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:thisEpisode.recordDate];
        [uniqueYears addObject:[NSNumber numberWithLong:[thisComponents year]]];
        
        for(int x = 1; x < self.podcastEpisodes.count; x++) {
            DHBPodcastEpisode *previousEpisode = [self.podcastEpisodes objectAtIndex:x - 1];
            thisEpisode = [self.podcastEpisodes objectAtIndex:x];
            NSDateComponents *previousComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:previousEpisode.recordDate];
            thisComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:thisEpisode.recordDate];
            
            if([thisComponents year] != [previousComponents year]) {
                [uniqueYears addObject:[NSNumber numberWithLong:[thisComponents year]]];
            }
        }
    }
    
    return uniqueYears;
}

-(NSMutableArray *)getEpisodesForYear:(NSInteger) year
{
    NSMutableArray *episodesForYear = [[NSMutableArray alloc] init];
    
    for(int x = 0; x < self.podcastEpisodes.count; x++)
    {
        DHBPodcastEpisode *thisEpisode = [self.podcastEpisodes objectAtIndex:x];
        
        NSDateComponents *thisComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:thisEpisode.recordDate];
        
        if([thisComponents year] == year)
        {
            [episodesForYear addObject:thisEpisode];
        }
    }
    
    return episodesForYear;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSLog(@"Did receive response: %@", response);
    //[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSLog(@"Did receive data");
    [self.podcastData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    //[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    NSLog(@"Connection did finish loading");
    dispatch_async(dispatch_get_main_queue(), ^{
        [self parseEpisodes];
    });
    
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"%@", error);
}

-(NSMutableArray *) getAllRangesOfString:(NSString *) stringToFind inString:(NSString *) input
{
    NSMutableArray *allRanges = [[NSMutableArray alloc] init];
    NSUInteger count = 0, length = [input length];
    NSRange range = NSMakeRange(0, length);
    
    while(range.location != NSNotFound)
    {
        range = [input rangeOfString:stringToFind options:0 range:range];
        if(range.location != NSNotFound) {
            //[mutableAttributedString setTextColor:color range:NSMakeRange(range.location, [word length])];
            [allRanges addObject:[NSValue valueWithRange:NSMakeRange(range.location, [stringToFind length])]];
            range = NSMakeRange(range.location + range.length, length - (range.location + range.length));
            count++;
        }
    }
    
    return allRanges;
}

-(void) parseEpisodes
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if([self.podcastURLString isEqualToString:@"https://api.brunow.org/node/dharma-talks-v1/talks"])
    {     
        NSMutableArray *podcastArray = [NSJSONSerialization JSONObjectWithData:self.podcastData options:0 error:nil];
        NSError *error;
        NSManagedObjectContext *context = [appDelegate managedObjectContext];

        if(podcastArray == nil)
        {
            [self loadEpisodes];
            return;
        }
        else
        {
            for(NSDictionary *thisDictionary in podcastArray)
            {
                bool isPresentInArray = false;

                for(DHBPodcastEpisode *thisEpisode in self.podcastEpisodes) {
                    
                    if([thisEpisode valueForKey:@"urlString"] != nil)
                    {
                        if([[thisEpisode valueForKey:@"urlString"] isEqualToString:[NSString stringWithFormat:@"%@%@", self.podcastRootURLString, [thisDictionary valueForKey:@"Url"]]]) {
                            isPresentInArray = true;
                            
                            NSDateFormatter *isoDateFormatter = [NSDateFormatter new];
                            [isoDateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.mmm'Z'"];
                            [isoDateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
                            [isoDateFormatter setFormatterBehavior:NSDateFormatterBehaviorDefault];
                            
                            thisEpisode.title = [thisDictionary valueForKey:@"Title"];
                            thisEpisode.speaker = [thisDictionary valueForKey:@"Speaker"];
                            thisEpisode.recordDate = [isoDateFormatter dateFromString:[thisDictionary valueForKey:@"Date"]];
                            
                            if (![context save:&error]) {
                                NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
                            }
                            break;
                        }
                    }
                }
                
                if(!isPresentInArray)
                {
                    NSDateFormatter *isoDateFormatter = [NSDateFormatter new];
                    [isoDateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.mmm'Z'"];
                    [isoDateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
                    [isoDateFormatter setFormatterBehavior:NSDateFormatterBehaviorDefault];

                    
                    if([thisDictionary valueForKey:@"Date"] != nil)
                    {
                        DHBPodcastEpisode *newEpisode = [NSEntityDescription insertNewObjectForEntityForName:@"PodcastEpisode" inManagedObjectContext:context];
                        
                        newEpisode.title = [thisDictionary valueForKey:@"Title"];
                        newEpisode.speaker = [thisDictionary valueForKey:@"Speaker"];
                        newEpisode.recordDate = [isoDateFormatter dateFromString:[thisDictionary valueForKey:@"Date"]];
                        newEpisode.isUnplayed = YES;
                        
                        [newEpisode setURLString:[NSString stringWithFormat:@"%@%@", self.podcastRootURLString, [thisDictionary valueForKey:@"Url"]]];
                        
                        if (![context save:&error]) {
                            NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
                        }
                        
                        [self.podcastEpisodes addObject:newEpisode];
                        
                    }
                    else
                    {
                        NSLog(@"Episode: %@", thisDictionary);
                    }
                }
            }
        }
    }
    
    self.podcastData = nil;
    
    NSSortDescriptor *sortDescriptor;
    sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"recordDate"
                                                 ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    NSArray *sortedArray;
    sortedArray = [self.podcastEpisodes sortedArrayUsingDescriptors:sortDescriptors];
    
    self.podcastEpisodes = [[NSMutableArray alloc] initWithArray:sortedArray];
    
    [self setHasLoadedEpisodes:YES];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Episodes Fetched From Local Database" object:nil];
}

@end
