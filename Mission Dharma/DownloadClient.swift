//
//  DownloadClient.swift
//  Mission Dharma
//
//  Created by David Brunow on 4/30/17.
//  Copyright © 2017 David Brunow. All rights reserved.
//

import UIKit

class DownloadClient: NSObject, URLSessionTaskDelegate, URLSessionDataDelegate, URLSessionDelegate
{
    struct Constants
    {
        static let APIEndpointURLString         = "https://api.brunow.org/node/dharma-talks-v1/talks"
        static let BackgroundSessionIdentifier  = "Background Session Identifier"
    }
    
    fileprivate override init() {} //This prevents others from using the default '()' initializer for this class.
    
    init(_ url: URL, withDelegate delegate: DownloadClientDelegate)
    {
        self.url = url
        self.delegate = delegate
    }
    
    var delegate: DownloadClientDelegate?
    var downloadData = Data()
    var downloadProgress = Float(0)
    var downloadSize = Int64(0)
    var url: URL!
    
    func start()
    {
        var request = URLRequest(url: url)
        
        request.httpMethod = HTTPMethod.get.rawValue
        
        let config = URLSessionConfiguration.default
        
        let dataSession = URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue.main)
        
        let dataTask = dataSession.dataTask(with: request)
        
        dataTask.resume()
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data)
    {
        downloadData.append(data)
        
        downloadProgress = Float(downloadData.count) / Float(downloadSize)
        
        delegate?.downloadClient(self, didUpdateProgress: downloadProgress)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?)
    {
        delegate?.downloadClient(self, didCompleteWithData: downloadData, orError: error)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void)
    {
        downloadSize = response.expectedContentLength
        
        completionHandler(.allow)
    }
}

protocol DownloadClientDelegate
{
    func downloadClient(_ downloadClient: DownloadClient, didUpdateProgress progress: Float)
    func downloadClient(_ downloadClient: DownloadClient, didCompleteWithData data: Data?, orError error: Error?)
}
