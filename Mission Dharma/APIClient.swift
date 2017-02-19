//
//  APIClient.swift
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

import Foundation

class ApiClient: NSObject
{
    struct Constants
    {
        static let APIEndpointURLString = "https://api.brunow.org/node/dharma-talks-v1/talks"
    }
    
    static let sharedInstance = ApiClient()
    
    fileprivate override init() {} //This prevents others from using the default '()' initializer for this class.
    
    func makeApiRequest(forUrl url: URL, withMethod method: HTTPMethod, andBody body: String?, completionHandler: @escaping (_ data: Data?, _ response: URLResponse?, _ error: Error?) -> ())
    {
        var request = URLRequest(url: url)
        
        request.httpMethod = method.rawValue
        
        let postData = body?.data(using: .utf8)
        
        let config = URLSessionConfiguration.default
        
        let urlSession = URLSession(configuration: config)
        
        let task = urlSession.dataTask(with: request)
        { (data, response, error) in
            completionHandler(data, response, error)
        }
        
        task.resume()
    }
}

enum HTTPMethod: String
{
    case get = "GET"
    case post = "POST"
}

enum APIError: Error
{
    case serverResponseError(errorMessage: String)
}
