//
//  UIImage+Async.swift
//  RssReader
//
//  Created by Simon Ng on 16/6/15.
//  Copyright (c) 2015 AppCoda Limited. All rights reserved.
//

import UIKit

extension UIImage {
    
    func asyncGetImage(url: NSURL, completionHandler: ((data: NSData?, error: NSError?) -> Void)) {
        NSURLSession.sharedSession().dataTaskWithURL(url, completionHandler: { (data, response, error) -> Void in
            completionHandler(data: data, error: error)
        }).resume()
    }
}