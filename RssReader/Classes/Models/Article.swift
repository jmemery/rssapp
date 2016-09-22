//
//  Article.swift
//  RssReader
//
//  Created by AppCoda on 11/20/14.
//  Copyright (c) 2014 AppCoda Limited. All rights reserved.
//

import Foundation

class Article {
    var link: String? = ""
    var categories = [String]()
    var headerImageURL: String? = "" {
        didSet {
            headerImageURL = headerImageURL?.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
//            headerImageURL = headerImageURL?.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
            headerImageURL = headerImageURL?.stringByRemovingPercentEncoding!
//            headerImageURL = headerImageURL?.stringByReplacingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
            headerImageURL = headerImageURL?.stringByReplacingOccurrencesOfString("&amp;", withString: "&")
        }
    }
    var commentsCount = 0
    var authorName: String? = ""
    var title: String? = "" {
        didSet {
            title = title?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        }
    }
    var isFavorite = false
    var publicationDate = NSDate()
    var description: String? = ""
    var rawDescription: String? = "" /*{
        didSet {
            description = rawDescription?.stringByDecodingHTMLEscapeCharacters()
        }
    }*/
    var readAt: NSDate?
    var favoritedAt: NSDate?
    var content: String? = ""
    var guid: String? = ""
    
    init() {

    }
}