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

import CoreData
import UIKit

class Podcast: NSObject
{
    var podcastEpisodes = [PodcastEpisode]()
    var podcastRootURLString = "http://www.missiondharma.org";
    var hasLoadedEpisodes = false;
    var isHidingPlayedAndDeletedEpisodes = true;
    var managedObjectContext: NSManagedObjectContext!
    
    static let sharedInstance = Podcast()
    
    fileprivate override init() {} //This prevents others from using the default '()' initializer for this class.
    
    var episodesDictionary: [Int: [PodcastEpisode]]
    {
        var dictionary = [Int: [PodcastEpisode]]()
        var keys = [Int]()
        
        for episode in podcastEpisodes
        {
            let year = Calendar.current.component(.year, from: episode.recordDate!)
            
            if !keys.contains(year)
            {
                keys.append(year)
            }
        }
        
        for key in keys
        {
            var episodes = [PodcastEpisode]()
            
            for episode in podcastEpisodes
            {
                let year = Calendar.current.component(.year, from: episode.recordDate!)
                
                if year == key
                {
                    episodes.append(episode)
                }
            }
            
            episodes.sort(by: { $0.recordDate! > $1.recordDate! })
            
            
            if isHidingPlayedAndDeletedEpisodes
            {
                episodes = episodes.filter({ !($0.isUnplayed == 0 && $0.isDownloaded == false) })
            }
            
            dictionary[key] = episodes
        }
        
        return dictionary
    }
    
    func loadEpisodes()
    {
        hasLoadedEpisodes = false

        if podcastEpisodes.count == 0
        {
            let fetchRequest = NSFetchRequest<PodcastEpisode>(entityName: "PodcastEpisode")
            
            if let context = managedObjectContext
            {
                let entity = NSEntityDescription.entity(forEntityName: "PodcastEpisode", in: context)
                
                fetchRequest.entity = entity
                
                let fetchedObjects = try? context.fetch(fetchRequest)
                
                if let coreDataEpisodes = fetchedObjects
                {
                    for outerEpisode in coreDataEpisodes
                    {
                        if let outerURLString = outerEpisode.urlString
                        {
                            var isPresentInArray = false
                            
                            for innerEpisode in podcastEpisodes
                            {
                                
                                if let innerURLString = innerEpisode.urlString
                                    , outerURLString == innerURLString
                                {
                                    isPresentInArray = true
                                    
                                    break
                                }
                            }
                        
                            if !isPresentInArray
                                && outerEpisode.title != nil
                                && outerEpisode.recordDate != nil
                            {
                                if outerURLString.range(of: podcastRootURLString) == nil
                                {
                                    if let urlString = outerEpisode.urlString
                                    {
                                        outerEpisode.urlString = "\(podcastRootURLString)\(urlString)"
                                    }
                                }
                                
                                podcastEpisodes.append(outerEpisode)
                            }
                        }
                    }
                    
                    podcastEpisodes.sort(by: { $0.recordDate! < $1.recordDate! })
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
                        
                        self.podcastEpisodes.sort(by: { $0.recordDate! < $1.recordDate! })
                    }
                }
            }
        }
    }
    
    private func loadNewEpisodes(fromData data: Data)
    {
        do
        {
            if let jsonEpisodes = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [[String: String]],
                let managedObjectContext = managedObjectContext
            {
                for jsonEpisode in jsonEpisodes
                {
                    var url: String?
                    
                    if let this = jsonEpisode["Url"]
                    {
                        url = this
                    }
                    
                    if url?.range(of: podcastRootURLString) == nil
                    {
                        if let urlString = url
                        {
                            url = "\(podcastRootURLString)\(urlString)"
                        }
                    }
                    
                    if let thisURL = url, podcastEpisodes.filter({ $0.urlString == thisURL || thisURL.range(of: $0.urlString!) != nil }).count == 0
                    {
                        if let podcastEpisodeEntity =  NSEntityDescription.entity(forEntityName: "PodcastEpisode", in: managedObjectContext)
                        {
                            let newEpisode = PodcastEpisode(entity: podcastEpisodeEntity, insertInto: managedObjectContext)
                            
                            newEpisode.urlString = thisURL
                            newEpisode.localPathString = URL(string: thisURL)?.lastPathComponent
                            newEpisode.isUnplayed = 1
                            
                            if let this = jsonEpisode["Date"]
                            {
                                let dateFormatterWithMilliseconds = DateFormatter()
                                dateFormatterWithMilliseconds.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
                                
                                if let thisDate = dateFormatterWithMilliseconds.date(from: this)
                                {
                                    newEpisode.recordDate = thisDate
                                }
                            }
                            
                            if let this = jsonEpisode["Title"]
                            {
                                newEpisode.title = this
                            }
                            
                            if let this = jsonEpisode["Speaker"]
                            {
                                newEpisode.speaker = this
                            }
                            
                            self.podcastEpisodes.append(newEpisode)
                        }
                    }
                }
                
                do
                {
                    try managedObjectContext.save()
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
                episode.download(completionHandler: { error in })
            }
        }
    }
}

// class methods
extension Podcast
{

}
