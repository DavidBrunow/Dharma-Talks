//
//  PodcastEpisode+CoreDataClass.swift
//  Mission Dharma
//
//  Created by David Brunow on 2/19/17.
//  Copyright © 2017 David Brunow. All rights reserved.
//
/*
 The MIT License (MIT)
 
 Copyright (c) 2017 David Brunow
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import Foundation
import CoreData

@objc(PodcastEpisode)
public class PodcastEpisode: NSManagedObject, DownloadClientDelegate
{
    struct Constants
    {
        static let PodcastDownloadProgressUpdateNotification = "Podcast Download Progress Updated"
    }
    
    var isDownloaded = false
    var cacheFolderPath = ""
    var downloadClient: DownloadClient?
    var downloadCompletionHandler: ((_ error: Error?) -> ())?
    var downloadProgress = Float(0)
    
    public override func awakeFromFetch()
    {
        super.awakeFromFetch()
        
        if let this = localPathString
        {
            cacheFolderPath = "\(AppDelegate.applicationHome)/\(this)"
            
            if FileManager.default.fileExists(atPath: cacheFolderPath)
            {
                isDownloaded = true
                try? FileManager.default.addSkipBackupAttributeToItemAtURL(url: URL(fileURLWithPath: cacheFolderPath))
            }
            else
            {
                isDownloaded = false
            }
        }
    }
    
    func download(completionHandler: @escaping (_ error: Error?) -> ())
    {
        if let this = urlString
            , let thisLocalPathString = localPathString
        {
            cacheFolderPath = "\(AppDelegate.applicationHome)/\(thisLocalPathString)"
                
            if let url = URL(string: this)
            {
                downloadCompletionHandler = completionHandler
                
                downloadClient = DownloadClient(url, withDelegate: self)

                downloadClient?.start()
                
                //ApiClient.sharedInstance.makeApiRequest(forUrl: url, withMethod: .get, andBody: nil)
                //{ data, response, error in
                //    if let thisData = data
                //    {
                //        if FileManager.default.createFile(atPath: self.cacheFolderPath, contents: thisData, attributes: nil)
                //        {
                //            self.isDownloaded = true
                //            try? FileManager.default.addSkipBackupAttributeToItemAtURL(url: URL(fileURLWithPath: self.cacheFolderPath))
                //        }
                //        else
                //        {
                //            self.isDownloaded = false
                //        }
                //
                //        completionHandler(error)
                //    }
                // }
            }
        }
    }
    
    func downloadClient(_ downloadClient: DownloadClient, didCompleteWithData data: Data?, orError error: Error?)
    {
        if let thisData = data
        {
            if FileManager.default.createFile(atPath: self.cacheFolderPath, contents: thisData, attributes: nil)
            {
                self.isDownloaded = true
                try? FileManager.default.addSkipBackupAttributeToItemAtURL(url: URL(fileURLWithPath: self.cacheFolderPath))
                
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.PodcastDownloadProgressUpdateNotification), object: self, userInfo: nil)
            }
            else
            {
                self.isDownloaded = false
            }
        }
        
        downloadCompletionHandler?(error)
    }
    
    func downloadClient(_ downloadClient: DownloadClient, didUpdateProgress progress: Float)
    {
        downloadProgress = progress
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.PodcastDownloadProgressUpdateNotification), object: self, userInfo: nil)
    }
    
    func delete()
    {
        try? FileManager.default.removeItem(atPath: cacheFolderPath)
        
        isDownloaded = false
    }
    
    func save()
    {
        try? managedObjectContext?.save()
    }
}

extension FileManager
{
    func addSkipBackupAttributeToItemAtURL(url: URL) throws
    {
        var fileURL = url
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        
        try? fileURL.setResourceValues(resourceValues)
    }
}
