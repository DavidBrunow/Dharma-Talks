//
//  Podcast.swift
//  Mission Dharma
//
//  Created by David Brunow on 2/18/17.
//  Copyright © 2017 David Brunow. All rights reserved.
//
/*
 The MIT License (MIT)
 
 Copyright (c) 2017 David Brunow
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import UIKit

class Podcast: NSObject
{
    var podcastEpisodes = [DHBPodcastEpisode]()
    var podcastRootURLString = "http://www.missiondharma.org";
    var hasLoadedEpisodes = false;
    
    func loadEpisodes()
    {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        hasLoadedEpisodes = false

        if podcastEpisodes.count == 0
        {
            let fetchRequest = NSFetchRequest<DHBPodcastEpisode>(entityName: "PodcastEpisode")
            
            if let context = appDelegate.managedObjectContext
            {
                let entity = NSEntityDescription.entity(forEntityName: "PodcastEpisode", in: context)
                
                fetchRequest.entity = entity
                
                let fetchedObjects = try? context.fetch(fetchRequest)
                
                if let coreDataEpisodes = fetchedObjects
                {
                    for outerEpisode in coreDataEpisodes
                    {
                        if let outerURLString = outerEpisode.value(forKey: "urlString") as? String
                        {
                            var isPresentInArray = false
                            
                            for innerEpisode in podcastEpisodes
                            {
                                
                                if let innerURLString = innerEpisode.value(forKey: "urlString") as? String
                                    , outerURLString == innerURLString
                                {
                                    isPresentInArray = true
                                    
                                    break
                                }
                            }
                        
                            if !isPresentInArray && outerEpisode.title != nil && outerEpisode.recordDate != nil
                            {
                                if outerURLString.range(of: podcastRootURLString) == nil
                                {
                                    outerEpisode.urlString = "\(podcastRootURLString)\(outerEpisode.urlString)"
                                }
                                
                                podcastEpisodes.append(outerEpisode)
                            }
                        }
                    }
                    
                    podcastEpisodes.sort(by: { $0.recordDate < $1.recordDate })
                    hasLoadedEpisodes = true
                    
                    NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: AppDelegate.Constants.EpisodesFetchedFromLocalDatabaseNotification)))
                }
            }
        }
        
        if let url = URL(string: ApiClient.Constants.APIEndpointURLString)
        {
            ApiClient.sharedInstance.makeApiRequest(forUrl: url, withMethod: .get, andBody: nil)
            { data, response, error in
                if let thisData = data
                {
                    
                    DispatchQueue.main.async
                    {
                        self.loadNewEpisodes(fromData: thisData)
                        
                        self.podcastEpisodes.sort(by: { $0.recordDate < $1.recordDate })
                    }
                }
            }
        }
    }
    
    func loadNewEpisodes(fromData data: Data)
    {
        do
        {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            
            if let jsonEpisodes = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [[String: String]],
                let managedObjectContext = appDelegate.managedObjectContext
            {
                
                for jsonEpisode in jsonEpisodes
                {
                    //                    print("JSON Episode: \(jsonEpisode)")
                    var url: String?
                    
                    if let this = jsonEpisode["Url"]
                    {
                        print("Url: \(this)")
                        url = this
                    }
                    
                    if let thisURL = url, podcastEpisodes.filter({ $0.urlString == url }).count == 0
                    {
                        if let podcastEpisodeEntity =  NSEntityDescription.entity(forEntityName: "PodcastEpisode", in: managedObjectContext)
                        {
                            let newEpisode = DHBPodcastEpisode(entity: podcastEpisodeEntity, insertInto: managedObjectContext)
                            
                            newEpisode.urlString = thisURL
                            
                            if let this = jsonEpisode["Date"]
                            {
                                let dateFormatterWithMilliseconds = DateFormatter()
                                dateFormatterWithMilliseconds.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
                                
                                if let thisDate = dateFormatterWithMilliseconds.date(from: this)
                                {
                                    newEpisode.recordDate = thisDate
                                }
                                print("Date: \(this)")
                            }
                            
                            if let this = jsonEpisode["Title"]
                            {
                                newEpisode.title = this
                                print("Title: \(this)")
                            }
                            
                            if let this = jsonEpisode["Speaker"]
                            {
                                newEpisode.speaker = this
                                print("Speaker: \(this)")
                            }
                            
                            self.podcastEpisodes.append(newEpisode)
                        }
                    }
                }
                
                do
                {
                    try appDelegate.managedObjectContext?.save()
                }
                catch _
                {
                }
                
                NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: AppDelegate.Constants.EpisodesFetchedFromLocalDatabaseNotification)))
            }
        }
        catch let e as NSError
        {
            print("Error deserializing episodes JSON \(e)")
        }
    }
    
    func downloadAllTalks()
    {
        for episode in podcastEpisodes
        {
            if !episode.isDownloaded
            {
                episode.downloadEpisode()
            }
        }
    }
    
    /*
     
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
 */
}

// class methods
extension Podcast
{

}
