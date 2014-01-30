//
//  DHBPodcast.m
//  Mission Dharma
//
//  Created by David Brunow on 8/7/13.
//  Copyright (c) 2013 David Brunow. All rights reserved.
//

#import "DHBPodcast.h"
#import <libxml2/libxml/HTMLparser.h>
#import "DHBPodcastEpisode.h"
#import "DHBAppDelegate.h"

@implementation DHBPodcast

-(id)init
{
    self.podcastEpisodes = [[NSMutableArray alloc] init];
    
    [self loadEpisodes];
    
    return self;
}

-(void) loadEpisodes
{
    //self.podcastEpisodes = [[NSMutableArray alloc] init];
    [self setHasLoadedEpisodes:NO];
    
    DHBAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"PodcastEpisode" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    NSError *error;
    NSArray *fetchedObjects = (NSMutableArray *)[appDelegate.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    for (NSManagedObject *info in fetchedObjects) {
        //NSLog(@"Title: %@", info.entity);
        
        //NSLog(@"Speaker: %@", info.speaker);
    }
    
    for (DHBPodcastEpisode *episode in fetchedObjects) {
        bool isPresentInArray = false;
        
        for(DHBPodcastEpisode *thisEpisode in self.podcastEpisodes) {
            if([thisEpisode.title isEqualToString:episode.title]) {
                isPresentInArray = true;
            }
        }
        
        if(!isPresentInArray && episode.title != nil && episode.recordDate != nil) {
            [self.podcastEpisodes addObject:episode];
        }
    }
    
    [self setPodcastRootURLString:@"http://www.missiondharma.org"];
    [self setPodcastURLString:@"http://www.missiondharma.org/dharma-talks.html"];
    
    self.podcastData = [[NSMutableData alloc] init];
    
    NSString *podcastURLString = [NSString stringWithFormat:@"http://www.missiondharma.org/dharma-talks.html"];
    NSURLRequest *podcastURLRequest  = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:podcastURLString]];
    (void)[[NSURLConnection alloc] initWithRequest:podcastURLRequest delegate:self];
    
    NSSortDescriptor *sortDescriptor;
    sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"recordDate"
                                                 ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    NSArray *sortedArray;
    sortedArray = [self.podcastEpisodes sortedArrayUsingDescriptors:sortDescriptors];
    
    self.podcastEpisodes = [[NSMutableArray alloc] initWithArray:sortedArray];
    
    [self setHasLoadedEpisodes:YES];
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
    
    for(int x = 0; x < self.podcastEpisodes.count; x++) {
        DHBPodcastEpisode *thisEpisode = [self.podcastEpisodes objectAtIndex:x];
        
        NSDateComponents *thisComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:thisEpisode.recordDate];
        
        if([thisComponents year] == year) {
            [episodesForYear addObject:thisEpisode];
        }
    }
    
    return episodesForYear;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.podcastData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    
    [self parseEpisodes];
    
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"%@", error);
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
    return nil;
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
    DHBAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    NSString *podcastHTML = [[NSString alloc] initWithData:self.podcastData encoding:NSUTF8StringEncoding];
    
    podcastHTML = [podcastHTML stringByReplacingOccurrencesOfString:@"<br />" withString:@""];
    podcastHTML = [podcastHTML stringByReplacingOccurrencesOfString:@"<u>" withString:@""];
    podcastHTML = [podcastHTML stringByReplacingOccurrencesOfString:@"<u style=\"color: rgb(63, 63, 63);\">" withString:@""];
    podcastHTML = [podcastHTML stringByReplacingOccurrencesOfString:@"<u style=\"\">" withString:@""];
    podcastHTML = [podcastHTML stringByReplacingOccurrencesOfString:@"</u>" withString:@""];
    podcastHTML = [podcastHTML stringByReplacingOccurrencesOfString:@"<em style=\"\">" withString:@""];
    podcastHTML = [podcastHTML stringByReplacingOccurrencesOfString:@"<em>" withString:@""];
    podcastHTML = [podcastHTML stringByReplacingOccurrencesOfString:@"</em>" withString:@""];
    podcastHTML = [podcastHTML stringByReplacingOccurrencesOfString:@"&nbsp;" withString:@""];
    podcastHTML = [podcastHTML stringByReplacingOccurrencesOfString:@"<font color=\"#000000\">" withString:@""];
    podcastHTML = [podcastHTML stringByReplacingOccurrencesOfString:@"<font color=\"#2a2a2a\">" withString:@""];
    podcastHTML = [podcastHTML stringByReplacingOccurrencesOfString:@"<font color=\"#333333\">" withString:@""];
    podcastHTML = [podcastHTML stringByReplacingOccurrencesOfString:@"<font color=\"#333333\" style=\"line-height: 1.5;\">" withString:@""];
    podcastHTML = [podcastHTML stringByReplacingOccurrencesOfString:@"<font color=\"#3f3f3f\">" withString:@""];
    podcastHTML = [podcastHTML stringByReplacingOccurrencesOfString:@"<font color=\"#666666\">" withString:@""];
    podcastHTML = [podcastHTML stringByReplacingOccurrencesOfString:@"<font size=\"2\">" withString:@""];
    podcastHTML = [podcastHTML stringByReplacingOccurrencesOfString:@"<font size=\"3\">" withString:@""];
    podcastHTML = [podcastHTML stringByReplacingOccurrencesOfString:@"<font size=4>" withString:@""];
    podcastHTML = [podcastHTML stringByReplacingOccurrencesOfString:@"</font>" withString:@""];
    podcastHTML = [podcastHTML stringByReplacingOccurrencesOfString:@"<span></span>" withString:@""];
    
    //recentPodcastListRange = [podcastHTML rangeOfString:@"<div class=\"paragraph\" style=\"text-align:left;\">"];
    
    //find index of hr, then find the first <div class="content" after that
    //NSRange firstRange = [podcastHTML rangeOfString:@"<hr"];
    NSMutableArray *hrRangeArray = [self getAllRangesOfString:@"<hr" inString:podcastHTML];
    NSMutableArray *trimmedPodcastHTMLArray = [[NSMutableArray alloc] init];
    
    for(NSValue *thisValue in hrRangeArray) {
        NSString *trimmedPodcastHTML = @"";
        
        NSRange recentPodcastListRange = [podcastHTML rangeOfString:@"<div class=\"paragraph\"" options:NSCaseInsensitiveSearch range:NSMakeRange([thisValue rangeValue].location, podcastHTML.length - [thisValue rangeValue].location)];
        
        if(recentPodcastListRange.location != NSNotFound) {
            NSRange recentPodcastListRangeEnd = [podcastHTML rangeOfString:@"</div>" options:NSCaseInsensitiveSearch range:NSMakeRange(recentPodcastListRange.location, podcastHTML.length - recentPodcastListRange.location)];
            
            trimmedPodcastHTML = [podcastHTML substringWithRange:NSMakeRange(recentPodcastListRange.location, recentPodcastListRangeEnd.location - recentPodcastListRange.location + 6)];
            [trimmedPodcastHTMLArray addObject:trimmedPodcastHTML];
        }
    }
    
    
    //NSLog(@"HTML: %@", trimmedPodcastHTML);
    for(NSString *trimmedPodcastHTML in trimmedPodcastHTMLArray) {
        //NSLog(@"Trimmed HTML: %@", trimmedPodcastHTML);
        const char *charData = [trimmedPodcastHTML UTF8String];
        htmlParserCtxtPtr parser = htmlCreatePushParserCtxt(NULL, NULL, NULL, 0, NULL, 0);
        htmlCtxtUseOptions(parser, HTML_PARSE_NOBLANKS | HTML_PARSE_NONET);
        
        //NSLog(@"Char Data : %s\n", charData);
        
        // char * data : buffer containing part of the web page
        // int len : number of bytes in data
        // Last argument is 0 if the web page isn’t complete, and 1 for the final call.
        htmlParseChunk(parser, charData, (int)[trimmedPodcastHTML lengthOfBytesUsingEncoding:NSUTF8StringEncoding], 0);
        
        htmlParseChunk(parser, NULL, 0, 1);
        
        int currentNodeIndex = 0;
        NSString *lastNode = @"";
        
        xmlNode *cur_node = xmlDocGetRootElement(parser->myDoc);
        xmlAttr *this_node;
        
        //DHBPodCastEpisode *podCastEpisode = [[DHBPodCastEpisode alloc] init];
        NSManagedObjectContext *context = [appDelegate managedObjectContext];
        DHBPodcastEpisode *podcastEpisode = [NSEntityDescription insertNewObjectForEntityForName:@"PodcastEpisode" inManagedObjectContext:context];
        
        //NSError *error;
        //if (![context save:&error]) {
        //    NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
        //}
        
        
        while (cur_node != nil) {
            //printf("Outer Loop : %s\n", cur_node->name);
            
            if (!(xmlStrcmp(cur_node->name, (const xmlChar *)"a")) || !(xmlStrcmp(cur_node->name, (const xmlChar *)"text"))) {
                //NSLog(@"%d", self.currentNodeIndex);
                //printf("Inner If: %s\n", cur_node->name);
                NSString *tempString;
                
                
                if (!xmlStrcmp(cur_node->name, (const xmlChar *)"a")) {
                    this_node = cur_node->properties;

                    if(!xmlStrcmp(this_node->name, (const xmlChar *)"href")) {
                        tempString = [NSString stringWithFormat:@"%@%s", self.podcastRootURLString, this_node->children->content];
                    } else if(!xmlStrcmp(this_node->next->name, (const xmlChar *)"href")) {
                        tempString = [NSString stringWithFormat:@"%@%s", self.podcastRootURLString, this_node->next->children->content];
                    } else if(!xmlStrcmp(this_node->next->next->name, (const xmlChar *)"href")) {
                        tempString = [NSString stringWithFormat:@"%@%s", self.podcastRootURLString, this_node->next->next->children->content];
                    }
                    
                    [podcastEpisode setURLString:tempString];
                    //NSLog(@"Temp String: %@", tempString);
                    
                    if(!xmlStrcmp(cur_node->children->name, (const xmlChar *)"text")) {
                        [podcastEpisode parseInfo:[NSString stringWithFormat:@"%s", cur_node->children->content]];
                    }
                        //if(this_node != nil) {
                            
                        //}
                    
                }
                
                if(podcastEpisode.title != nil) {
                    currentNodeIndex++;
                }
                
                //NSLog(@"Podcast URL: %@, and Title: %@", podCastEpisode.URLString, podCastEpisode.title);
                lastNode = [NSString stringWithFormat:@"%s", cur_node->name];
                
            } else {
            }
            //NSLog(@"Current Node Index: %d", currentNodeIndex);
            if(currentNodeIndex == 1 && podcastEpisode.title != nil) {
                bool isPresentInArray = false;
                
                for(DHBPodcastEpisode *thisEpisode in self.podcastEpisodes) {
                    if([thisEpisode.title isEqualToString:podcastEpisode.title]) {
                        isPresentInArray = true;
                    }
                }
                
                if(!isPresentInArray && podcastEpisode.title != nil && podcastEpisode.recordDate != nil) {
                    NSError *error;
                    [podcastEpisode setIsUnplayed:YES];
                    
                    if (![context save:&error]) {
                        NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
                    }
                    
                    [self.podcastEpisodes addObject:podcastEpisode];
                }
                
                currentNodeIndex = 0;
                podcastEpisode = [NSEntityDescription insertNewObjectForEntityForName:@"PodcastEpisode" inManagedObjectContext:context];
            }
            if (cur_node->next == nil && cur_node->children != nil) {
                cur_node = cur_node->children;
            } else if(cur_node->children != nil) {
                cur_node = cur_node->children;
            } else if(cur_node->next != nil) {
                cur_node = cur_node->next;
            } else if(cur_node->children == nil) {
                if(cur_node->parent->next != nil) {
                    cur_node = cur_node->parent->next;
                } else if(cur_node->parent->parent->next != nil) {
                    cur_node = cur_node->parent->parent->next;
                } else if (cur_node->parent->parent->parent->next != nil) {
                    cur_node = cur_node->parent->parent->parent->next;
                } else if (cur_node->parent->parent->parent->parent->next != nil) {
                    cur_node = cur_node->parent->parent->parent->parent->next;
                } else {
                    cur_node = nil;
                }
            }
            
        }
        xmlFreeDoc(parser->myDoc);
        xmlFreeParserCtxt(parser);
    }
    
    NSSortDescriptor *sortDescriptor;
    sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"recordDate"
                                                 ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    NSArray *sortedArray;
    sortedArray = [self.podcastEpisodes sortedArrayUsingDescriptors:sortDescriptors];
    
    self.podcastEpisodes = [[NSMutableArray alloc] initWithArray:sortedArray];
    
    [self setHasLoadedEpisodes:YES];
}


@end
