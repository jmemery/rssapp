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
 
typealias FeedsServiceCompletionClosure = (_ articles: [Article]) -> ()
typealias FeedsServiceFailureClosure = (Error) -> ()

 // MARK: -

class FeedsService: NSObject, XMLParserDelegate {
    // MARK: - FeedsService properties
    fileprivate var currentElement = ""
    fileprivate var title = ""
    fileprivate var descriptionImageURL = ""
    fileprivate var thumbnailImageURL = ""
    fileprivate var mediaContentImageURL = ""
    fileprivate var enclosureImageURL = ""
    fileprivate var contentImageURL = ""
    
    fileprivate var completion: FeedsServiceCompletionClosure!
    fileprivate var failure: FeedsServiceFailureClosure!
    
    fileprivate var feeds = [Article]()
    fileprivate var feedType:FeedType?
    fileprivate var currentFeed: Article?
    fileprivate var isParsingItem = false
    fileprivate var isParsingAuthor = false
    
    fileprivate var feedsCount = 0
    fileprivate var parser: XMLParser!
    
    fileprivate var commentsCount = ""
    fileprivate var publicationDate = ""

    override init() {
    }

    // MARK: - Helper Methods
    
    func getFeedsWithURL(_ aUrlString: String, completion: FeedsServiceCompletionClosure!, failure: FeedsServiceFailureClosure!) -> Void {

        self.completion = completion
        self.failure = failure
        
//        let manager = AFHTTPRequestOperationManager()
        let manager = AFHTTPSessionManager()
        manager.requestSerializer.setValue("text/html", forHTTPHeaderField: "Content-Type")
        manager.responseSerializer = AFHTTPResponseSerializer()

        manager.get(aUrlString, parameters: nil, progress: { (progress) in
            
        }, success: { (dataTask, response) in
            self.parser = XMLParser(data: response as! Data)
            self.parser.delegate = self
            self.parser?.shouldResolveExternalEntities = true
            self.parser.parse()
            
        }) { (dataTask, error) in
            print(error)
            UIAlertView(title: "Failed to retrieve the articles due to network error", message: error.localizedDescription, delegate: nil, cancelButtonTitle: "OK").show()
            self.failure(error)
        }
        
    }
    
     // MARK: - NSXMLParserDelegate Methods
    
    func parserDidStartDocument(_ parser: XMLParser) {
        
        feedsCount = self.feeds.count
        self.feeds = [Article]()
        
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
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
    
    func parseRSSStartElement(_ elementName: String, attributes attributeDict: [AnyHashable: Any]) {
        
        if currentElement == rssItemTag {
            currentFeed = Article();
            descriptionImageURL = ""
            thumbnailImageURL = ""
            mediaContentImageURL = ""
            enclosureImageURL = ""
        }
        
        if currentElement == rssThumbnailTag {
            if var url = attributeDict["url"] as? String {
                url = url.components(separatedBy: "?")[0]
                currentFeed?.headerImageURL = url
                thumbnailImageURL = url
            }
        }
        
        if currentElement == rssMediaContentTag {
            if var url = attributeDict["url"] as? String {
                url = url.components(separatedBy: "?")[0]
                if mediaContentImageURL == "" || mediaContentImageURL.contains("gravatar.com") {
                    currentFeed?.headerImageURL = url
                    mediaContentImageURL = url
                }
            }
        }
        
        if currentElement == rssEnclosureTag {
            if var url = attributeDict["url"] as? String {
                url = url.components(separatedBy: "?")[0]
                currentFeed?.headerImageURL = url
                enclosureImageURL = url
            } else if let type = attributeDict["type"] as? String {
                if type.contains("video") && type.contains("audio") {
                    var url = attributeDict["url"] as! String
                    url = url.components(separatedBy: "?")[0]
                    currentFeed?.headerImageURL = url
                    enclosureImageURL = url
                }
            }
        }
    }
    
    func parseAtomStartElement(_ elementName: String, attributes attributeDict: [AnyHashable: Any]) {
        
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
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {

        // Perform parsing based on the feed type
        if self.feedType == .RSS2 || self.feedType == .RSS1 || self.feedType == .RSS1Alt {
            parseRSSEndElement(elementName)
        } else if self.feedType == .Atom {
            parseAtomEndElement(elementName)
        }

    }
    
    func parseRSSEndElement(_ elementName: String) {
        
        if elementName == rssCommentsCountTag {
            commentsCount = commentsCount.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            currentFeed?.commentsCount = Int(commentsCount)!
            if let count = Int(commentsCount) {
                currentFeed?.commentsCount = count
                commentsCount = ""
            }
        }
        
        if elementName == rssItemTag {
            currentFeed?.title = currentFeed?.title?.convertingHTMLToPlainText()
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
            if let _str = currentFeed?.authorName!.convertingHTMLToPlainText() {
                currentFeed?.authorName! = _str
            }
        }
        
        if elementName == rssPubDateTag {
            let pubDate = publicationDate.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = feedType?.feedDateFormat()
            if let pubDate = dateFormatter.date(from: pubDate) {
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

    func parseAtomEndElement(_ elementName: String) {
        
        if elementName == atomItemTag {
            currentFeed?.title = currentFeed?.title?.convertingHTMLToPlainText()
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
            if let author = currentFeed?.authorName!.convertingHTMLToPlainText() {
                currentFeed?.authorName! = author
            }
        }
        
        if elementName == atomPubDateTag {
            let pubDate = publicationDate.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = feedType?.feedDateFormat()
            if let pubDate = dateFormatter.date(from: pubDate) {
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

    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        
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
                let category = currentString.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                if category != "" {
                    currentFeed?.categories.append(category)
                }
            case rssLinkTag:
                currentFeed?.link! += currentString.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            case rssCommentsCountTag:
                commentsCount += currentString
            case rssPubDateTag:
                publicationDate += currentString
            case rssDescriptionTag:
                currentFeed?.rawDescription! += currentString
            case rssContentTag:
                currentFeed?.content! += currentString
            case rssGuidTag:
                currentFeed?.guid! += currentString.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            default:
                break;
                
            }
        }
    }
    
    func parseAtomFoundCharacters(foundCharacters string: String?) {
        
        if !isParsingItem {
            return
        }
        
        if let currentString = string?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) {
            switch currentElement {
                case atomTitleTag :
                    currentFeed?.title! += currentString
                case atomAuthorNameTag:
                    currentFeed?.authorName! += currentString
                case atomCategoryTag:
                    let category = currentString.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    if category != "" {
                        currentFeed?.categories.append(category)
                    }
                case atomLinkTag:
                    currentFeed?.link! += currentString.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
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

    func parserDidEndDocument(_ parser: XMLParser) {
        completion?(feeds)
        
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        self.failure(parseError)
    }
    
    func isImage(_ imagePath:String) -> Bool {
        if imagePath == "" ||
            imagePath.range(of: ".png", options: .caseInsensitive) == nil ||
            imagePath.range(of: ".jpg", options: .caseInsensitive) == nil ||
            imagePath.range(of: ".jpeg", options: .caseInsensitive) == nil ||
            imagePath.range(of: ".gif", options: .caseInsensitive) == nil {
                
            return false
        }
        
        return true
    }
    
}






