 //
//  FeedsService.swift
//  RssReader
//
//  Created by AppCoda on 11/21/14.
//  Copyright (c) 2014 AppCoda Limited. All rights reserved.
//

import UIKit

// MARK: - RSS and ATOM tags
private let rssChannelTag = "channel"
private let atomChannelTag = "feed"
 
private let rssItemTag = "item"
private let rssTitleTag = "title"
private let rssLinkTag = "link"
private let rssAuthorTag = "dc:creator"
private let rssCategoryTag = "category"
private let rssThumbnailTag = "media:thumbnail"
private let rssMediaContentTag = "media:content"
private let rssCommentsCountTag = "slash:comments"
private let rssPubDateTag = "pubDate"
private let rssDescriptionTag = "description"
private let rssContentTag = "content:encoded"
private let rssEnclosureTag = "enclosure"
private let rssGuidTag = "guid"
 
private let atomItemTag = "entry"
private let atomTitleTag = "title"
private let atomLinkTag = "link"
private let atomAuthorTag = "author"
private let atomAuthorNameTag = "name"
private let atomCategoryTag = "category"
private let atomThumbnailTag = "media:thumbnail"
private let atomMediaContentTag = "media:content"
private let atomCommentsCountTag = "slash:comments"
private let atomPubDateTag = "published"
private let atomContentTag = "content"

// MARK: - Feed Types Enumeration

enum FeedType: String {
    case Unknown = "unknown"
    case Atom = "feed"
    case RSS1 = "rdf:RDF"
    case RSS1Alt = "RDF"
    case RSS2 = "rss"
    
    func feedDateFormat() -> String {
        if self == .Atom {
            return "yyyy-MM-dd'T'HH:mm:ssZ"
        } else if self == .RSS1 || self == .RSS1Alt || self == .RSS2 {
            return "EEE, dd MMM yyyy HH:mm:ss ZZZ"
        }
        
        return ""
    }
}
 
typealias FeedsServiceCompletionClosure = (articles: [Article]) -> ()
typealias FeedsServiceFailureClosure = (error: NSError) -> ()

 // MARK: -

class FeedsService: NSObject, NSXMLParserDelegate {
    // MARK: - FeedsService properties
    private var currentElement = ""
    private var title = ""
    private var descriptionImageURL = ""
    private var thumbnailImageURL = ""
    private var mediaContentImageURL = ""
    private var enclosureImageURL = ""
    private var contentImageURL = ""
    
    private var completion: FeedsServiceCompletionClosure!
    private var failure: FeedsServiceFailureClosure!
    
    private var feeds = [Article]()
    private var feedType:FeedType?
    private var currentFeed: Article?
    private var isParsingItem = false
    private var isParsingAuthor = false
    
    private var feedsCount = 0
    private var parser: NSXMLParser!
    
    private var commentsCount = ""
    private var publicationDate = ""

    override init() {
    }

    // MARK: - Helper Methods
    
    func getFeedsWithURL(aUrlString: String, completion: FeedsServiceCompletionClosure!, failure: FeedsServiceFailureClosure!) -> Void {

        self.completion = completion
        self.failure = failure
        
        let manager = AFHTTPRequestOperationManager()
        manager.requestSerializer.setValue("text/html", forHTTPHeaderField: "Content-Type")
        manager.responseSerializer = AFHTTPResponseSerializer()

        manager.GET(aUrlString, parameters: nil, success: { (operation, response) -> Void in
            self.parser = NSXMLParser(data: response as! NSData)
            self.parser.delegate = self
            self.parser?.shouldResolveExternalEntities = true
            self.parser.parse()

        }) { (operation, error) -> Void in
            print(error)
            UIAlertView(title: "Failed to retrieve the articles due to network error", message: error.localizedDescription, delegate: nil, cancelButtonTitle: "OK").show()
            self.failure(error: error)
        }
        
    }
    
     // MARK: - NSXMLParserDelegate Methods
    
    func parserDidStartDocument(parser: NSXMLParser) {
        
        feedsCount = self.feeds.count
        self.feeds = [Article]()
        
    }
    
    func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        currentElement = elementName
        
        // Determine the feed type
        switch elementName {
            case FeedType.Atom.rawValue:
                self.feedType = .Atom
                return
            
            case FeedType.RSS1.rawValue:
                self.feedType = .RSS1
                return
            
            case FeedType.RSS1Alt.rawValue:
                self.feedType = .RSS1
                return
            
            case FeedType.RSS2.rawValue:
                self.feedType = .RSS2
                return
            
            default:
                break
        }
        
        // Perform parsing based on the feed type
        if self.feedType == .RSS2 || self.feedType == .RSS1 || self.feedType == .RSS1Alt {
            parseRSSStartElement(elementName, attributes: attributeDict)
        } else if self.feedType == .Atom {
            parseAtomStartElement(elementName, attributes: attributeDict)
        }
        
    }
    
    func parseRSSStartElement(elementName: String, attributes attributeDict: [NSObject : AnyObject]) {
        
        if currentElement == rssItemTag {
            currentFeed = Article();
            descriptionImageURL = ""
            thumbnailImageURL = ""
            mediaContentImageURL = ""
            enclosureImageURL = ""
        }
        
        if currentElement == rssThumbnailTag {
            if var url = attributeDict["url"] as? String {
                url = url.componentsSeparatedByString("?")[0]
                currentFeed?.headerImageURL = url
                thumbnailImageURL = url
            }
        }
        
        if currentElement == rssMediaContentTag {
            if var url = attributeDict["url"] as? String {
                url = url.componentsSeparatedByString("?")[0]
                if mediaContentImageURL == "" || mediaContentImageURL.contains("gravatar.com") {
                    currentFeed?.headerImageURL = url
                    mediaContentImageURL = url
                }
            }
        }
        
        if currentElement == rssEnclosureTag {
            if var url = attributeDict["url"] as? String {
                url = url.componentsSeparatedByString("?")[0]
                currentFeed?.headerImageURL = url
                enclosureImageURL = url
            } else if let type = attributeDict["type"] as? String {
                if type.contains("video") && type.contains("audio") {
                    var url = attributeDict["url"] as! String
                    url = url.componentsSeparatedByString("?")[0]
                    currentFeed?.headerImageURL = url
                    enclosureImageURL = url
                }
            }
        }
    }
    
    func parseAtomStartElement(elementName: String, attributes attributeDict: [NSObject : AnyObject]) {
        
        if currentElement == atomItemTag {
            currentFeed = Article();
            descriptionImageURL = ""
            thumbnailImageURL = ""
            mediaContentImageURL = ""
            isParsingItem = true
        }
        
        if isParsingItem {
            if currentElement == atomLinkTag {
                let url = attributeDict["href"] as! String
                currentFeed?.link = url
            }
            
            if currentElement == atomAuthorTag {
                isParsingAuthor = true
            }
        }
    }
    
    func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {

        // Perform parsing based on the feed type
        if self.feedType == .RSS2 || self.feedType == .RSS1 || self.feedType == .RSS1Alt {
            parseRSSEndElement(elementName)
        } else if self.feedType == .Atom {
            parseAtomEndElement(elementName)
        }

    }
    
    func parseRSSEndElement(elementName: String) {
        
        if elementName == rssCommentsCountTag {
            commentsCount = commentsCount.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            currentFeed?.commentsCount = Int(commentsCount)!
            if let count: Int! = Int(commentsCount) {
                currentFeed?.commentsCount = count!
                commentsCount = ""
            }
        }
        
        if elementName == rssItemTag {
            currentFeed?.title = currentFeed?.title?.stringByConvertingHTMLToPlainText()
            currentFeed?.title! += "\n"
            feeds.append(currentFeed!)
            if let headerImageURL = currentFeed?.headerImageURL {
                if headerImageURL == "" {
                    if thumbnailImageURL != "" {
                        currentFeed?.headerImageURL = thumbnailImageURL
                    } else if mediaContentImageURL != "" {
                        currentFeed?.headerImageURL = mediaContentImageURL
                    } else if enclosureImageURL != "" {
                        currentFeed?.headerImageURL = enclosureImageURL
                    } else if descriptionImageURL != "" {
                        currentFeed?.headerImageURL = descriptionImageURL
                    } else if contentImageURL != "" {
                        currentFeed?.headerImageURL = contentImageURL
                    }
                }
            }
        }
        
        if elementName == rssAuthorTag {
            if let _str = currentFeed?.authorName!.stringByConvertingHTMLToPlainText() {
                currentFeed?.authorName! = _str
            }
        }
        
        if elementName == rssPubDateTag {
            let pubDate = publicationDate.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = feedType?.feedDateFormat()
            if let pubDate = dateFormatter.dateFromString(pubDate) {
                currentFeed?.publicationDate = pubDate
                publicationDate = ""
            }
        }
        
        if currentElement == rssDescriptionTag {
            currentFeed?.description = currentFeed?.rawDescription?.stringByDecodingHTMLEscapeCharacters()
            if let headerImageURL = currentFeed?.headerImageURL {
                if !isImage(headerImageURL) {
                    if let html = currentFeed?.rawDescription {
                        currentFeed?.headerImageURL = html.parseFirstImage()
                        descriptionImageURL = html.parseFirstImage()!
                    }
                }
            }
        }
        
        if currentElement == rssContentTag {
            if let headerImageURL = currentFeed?.headerImageURL {
                if !isImage(headerImageURL) {
                    if let html = currentFeed?.content {
                        currentFeed?.headerImageURL = html.parseFirstImage()
                        contentImageURL = html.parseFirstImage()!
                    }
                }
            }

        }
        
    }

    func parseAtomEndElement(elementName: String) {
        
        if elementName == atomItemTag {
            currentFeed?.title = currentFeed?.title?.stringByConvertingHTMLToPlainText()
            currentFeed?.title! += "\n"
            feeds.append(currentFeed!)
            if let headerImageURL = currentFeed?.headerImageURL {
                if headerImageURL == "" {
                    if thumbnailImageURL != "" {
                        currentFeed?.headerImageURL = thumbnailImageURL
                    } else if mediaContentImageURL != "" {
                        currentFeed?.headerImageURL = mediaContentImageURL
                    } else if enclosureImageURL != "" {
                        currentFeed?.headerImageURL = enclosureImageURL
                    } else if descriptionImageURL != "" {
                        currentFeed?.headerImageURL = descriptionImageURL
                    }
                }
            }

            isParsingItem = false
            isParsingAuthor = false
        }

        if isParsingAuthor && elementName == atomAuthorNameTag {
            if let author = currentFeed?.authorName!.stringByConvertingHTMLToPlainText() {
                currentFeed?.authorName! = author
            }
        }
        
        if elementName == atomPubDateTag {
            let pubDate = publicationDate.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = feedType?.feedDateFormat()
            if let pubDate = dateFormatter.dateFromString(pubDate) {
                currentFeed?.publicationDate = pubDate
                publicationDate = ""
            }
        }
        
        if currentElement == atomContentTag {
            if let headerImageURL = currentFeed?.headerImageURL {
                if !isImage(headerImageURL) {
                    if let html = currentFeed?.rawDescription {
                        currentFeed?.headerImageURL = html.parseFirstImage()
                        descriptionImageURL = html.parseFirstImage()!
                    }
                }
            }
        }
    

    }

    
    func parser(parser: NSXMLParser, foundCharacters string: String) {
        
        // Perform parsing based on the feed type
        if self.feedType == .RSS2 || self.feedType == .RSS1 || self.feedType == .RSS1Alt {
            parseRSSFoundCharacters(foundCharacters: string)
        } else if self.feedType == .Atom {
            parseAtomFoundCharacters(foundCharacters: string)
        }

    }
    
    func parseRSSFoundCharacters(foundCharacters string: String?) {
        if let currentString = string {
            switch currentElement {
            case rssTitleTag :
                currentFeed?.title! += currentString
            case rssAuthorTag:
                currentFeed?.authorName! += currentString
            case rssCategoryTag:
                let category = currentString.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                if category != "" {
                    currentFeed?.categories.append(category)
                }
            case rssLinkTag:
                currentFeed?.link! += currentString.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            case rssCommentsCountTag:
                commentsCount += currentString
            case rssPubDateTag:
                publicationDate += currentString
            case rssDescriptionTag:
                currentFeed?.rawDescription! += currentString
            case rssContentTag:
                currentFeed?.content! += currentString
            case rssGuidTag:
                currentFeed?.guid! += currentString.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            default:
                break;
                
            }
        }
    }
    
    func parseAtomFoundCharacters(foundCharacters string: String?) {
        
        if !isParsingItem {
            return
        }
        
        if let currentString = string?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) {
            switch currentElement {
                case atomTitleTag :
                    currentFeed?.title! += currentString
                case atomAuthorNameTag:
                    currentFeed?.authorName! += currentString
                case atomCategoryTag:
                    let category = currentString.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                    if category != "" {
                        currentFeed?.categories.append(category)
                    }
                case atomLinkTag:
                    currentFeed?.link! += currentString.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                case atomCommentsCountTag:
                    commentsCount += currentString
                case atomPubDateTag:
                    publicationDate += currentString
                case atomContentTag:
                    currentFeed?.rawDescription! += currentString
                default:
                    break;
            }
        }
        
    }

    func parserDidEndDocument(parser: NSXMLParser) {
        completion?(articles: feeds)
        
    }
    
    func parser(parser: NSXMLParser, parseErrorOccurred parseError: NSError) {
        self.failure(error: parseError)
    }
    
    func isImage(imagePath:String) -> Bool {
        if imagePath == "" ||
            imagePath.rangeOfString(".png", options: .CaseInsensitiveSearch) == nil ||
            imagePath.rangeOfString(".jpg", options: .CaseInsensitiveSearch) == nil ||
            imagePath.rangeOfString(".jpeg", options: .CaseInsensitiveSearch) == nil ||
            imagePath.rangeOfString(".gif", options: .CaseInsensitiveSearch) == nil {
                
            return false
        }
        
        return true
    }
    
}






