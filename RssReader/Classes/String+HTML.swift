//
//  String+HTML.swift
//  RssReader
//
//  Created by Simon Ng on 27/4/15.
//  Copyright (c) 2015 AppCoda Limited. All rights reserved.
//

import Foundation

private let characterEntities:[String: String] = [
    "&nbsp;" : "",
    "&quot;" : "\"",
    "&apos;" : "'",
    "&amp;" : "&",
    "&lt;": "<",
    "&gt;": ">",
    "&hellip;": "...",
    "&ldquo;": "\"",
    "&rdquo;": "\"",
    "&aacute;": "á",
    "&xe1c;": "á",
    "&eacute;": "é",
    "&iacute;": "í",
    "&xed;": "í",
    "&oacute;": "ó",
    "&uacute;": "ú",
    "&ntilde;": "ñ",
    "&xf1;": "ñ",
    "&copy;" : "\u{00A9}",
    "&lsquo;" : "'",
    "&rsquo;" : "'",
    "&mdash;" : "-",
    "&ndash;" : "-",
    "&#34;": "\"",
    "&#35;": "#",
    "&#36;": "$",
    "&#37;": "%",
    "&#38;": "&",
    "&#39;": "'",
    "&#46;": ".",
    "&#034;": "\"",
    "&#035;": "#",
    "&#036;": "$",
    "&#037;": "%",
    "&#038;": "&",
    "&#039;": "'",
    "&#046;": ".",
    "&#124;": "|",
    "&#147;": "\"",
    "&#148;": "\"",
    "&#160;": " ",
    "&#8211;": "-",
    "&#8217;": "'",
    "&#8220;": "\"",
    "&#8221;": "\"",
    "&#8212;": "—",
    "&#8216;": "'",
    "&#8230;": "...",
    "&#8243;": "\"",
    "&#8594;": "→"
]

extension String {
    
    func stringByConvertingFromHTML() -> String {
        let encodedData = self.dataUsingEncoding(NSUTF8StringEncoding)!
        let attributedOptions : [String: AnyObject] = [
            NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
            NSCharacterEncodingDocumentAttribute: NSUTF8StringEncoding
        ]
        let attributedString = try! NSAttributedString(data: encodedData, options: attributedOptions, documentAttributes: nil)
        
        return attributedString.string
    }
    
    func contains(find: String) -> Bool {
        return self.rangeOfString(find) != nil
    }
    
    func stringByDecodingHTMLEscapeCharacters() -> String? {
        var decodedString:String? = ""
        
        // Convert paragraph to newline
        var htmlString = self.stringByReplacingOccurrencesOfString("</p>", withString: "\n\n", options: .CaseInsensitiveSearch)
        
        // Remove all HTML tags
        htmlString = htmlString.stringByReplacingOccurrencesOfString("</a>", withString: " ", options: .CaseInsensitiveSearch)
        while let range = htmlString.rangeOfString("<[^>]+>", options: .RegularExpressionSearch) {
            htmlString = htmlString.stringByReplacingCharactersInRange(range, withString: "")
        }

        // Remove redundant newline characters
        let regex = try? NSRegularExpression(pattern: "(\n){3,}", options: [])
        decodedString = regex?.stringByReplacingMatchesInString(htmlString, options: [], range: NSMakeRange(0, htmlString.characters.count), withTemplate: "\n\n")

        // Remove all percentage escapes
        if let escapedString = decodedString?.stringByRemovingPercentEncoding {
            decodedString = escapedString
        }
        
        // Decode character entities (e.g. &amp;)
        for (encodedEntity, decodedEntity) in characterEntities {
            decodedString = decodedString?.stringByReplacingOccurrencesOfString(encodedEntity, withString: decodedEntity)
        }
        
        return decodedString
    }
    
    func stringByFormattingHTMLString(imageCompletionHandler: (range: NSRange, string: NSAttributedString) -> Void) -> NSAttributedString {
        
        // Remove the first image as it is displayed in the header view
        var htmlString = removeFirstImageFromHTML()
        
        // Convert paragraph to newline
        htmlString = htmlString.stringByReplacingOccurrencesOfString("</p>", withString: "\n\n", options: .CaseInsensitiveSearch)
        htmlString = htmlString.stringByReplacingOccurrencesOfString("<p>", withString: "", options: .CaseInsensitiveSearch)
        
        // Convert <li> tag to "- "
        htmlString = htmlString.stringByReplacingOccurrencesOfString("<li>", withString: "\u{2022} ", options: .CaseInsensitiveSearch)
        
        // Use our own font for rendering the web page
        let textFont = [NSFontAttributeName: UIFont(name: "Lato-Regular", size: 18.0)!]
        let boldFont = [NSFontAttributeName: UIFont(name: "Lato-Bold", size: 18.0)!]

        // Strip off all HTML tags except H1, H2, H3, A, IMG and STRONG
        while let range = htmlString.rangeOfString("<(?!strong|/strong|h1|/h1|h2|/h2|h3|/h3|a|/a|img|/img)[^>]+>", options: .RegularExpressionSearch) {
            htmlString = htmlString.stringByReplacingCharactersInRange(range, withString: "")
        }
        
        // Remove image tags that are smaller than 100 points
        while let range = htmlString.rangeOfString("<img[^>]*(?:height|width)\\s*=\\s*['|\"][1-9]?[0-9]['|\"][^>]*>|<img[^>]*(feedsportal|feedburner)[^>]*>", options: .RegularExpressionSearch) {
            htmlString = htmlString.stringByReplacingCharactersInRange(range, withString: "")
        }
        
        // Decode escape characters
        if let decodedString = htmlString.stringByRemovingPercentEncoding {
            htmlString = decodedString
        }
        
        // Decode character entities (e.g. &amp;)
        for (encodedEntity, decodedEntity) in characterEntities {
            htmlString = htmlString.stringByReplacingOccurrencesOfString(encodedEntity, withString: decodedEntity)
        }
        
        let attributedHTMLString = NSMutableAttributedString(string: htmlString, attributes: textFont)

        // Format the H1, H2, H3 and STRONG tags
        // Backup regex: (<strong.*>(.*?)</strong>|<h[1234].?>(?:<strong>){0,1}(.*?)(?:</strong>){0,1}</h[1234]>)
        if let boldTextRegEx = try? NSRegularExpression(pattern: "(<strong.*>(.*?)</strong>|<h[1234][^>]*>(?:<strong>){0,1}(.*?)(?:</strong>){0,1}</h[1234]>)", options: .CaseInsensitive) {
            let results = boldTextRegEx.matchesInString(htmlString, options: [], range: NSMakeRange(0, htmlString.characters.count))
            
            for match in results {
                _ = (htmlString as NSString).substringWithRange(match.range)
                if match.numberOfRanges > 1 {
                    for index in 2..<match.numberOfRanges {
                        if match.rangeAtIndex(index).length != 0 {
                            _ = (htmlString as NSString).substringWithRange(match.rangeAtIndex(index)) as String
                            attributedHTMLString.addAttributes(boldFont, range: match.rangeAtIndex(index))
                        }
                    }
                }
            }
        }
        
        // Extract link
        if let linkRegEx = try? NSRegularExpression(pattern: "<a\\s+(?:[^>]*?\\s+)?href=\"([^\"]*)\"[^>]*>([^<]+)</a>", options: .CaseInsensitive) {
            let results = linkRegEx.matchesInString(htmlString, options: [], range: NSMakeRange(0, htmlString.characters.count))
            for match in results {
                if match.numberOfRanges == 3 {
                    let link = (htmlString as NSString).substringWithRange(match.rangeAtIndex(1)) as String
                    _ = (htmlString as NSString).substringWithRange(match.rangeAtIndex(2)) as String
                    attributedHTMLString.addAttribute(NSLinkAttributeName, value: link, range: match.rangeAtIndex(2))
                }
            }
        }
        
        // Extract the image source and download the image
        if let imgRegEx = try? NSRegularExpression(pattern: "<img.+?src=[\"'](.+?)[\"'].*?>", options: .CaseInsensitive) {
            let results = imgRegEx.matchesInString(htmlString, options: [], range: NSMakeRange(0, htmlString.characters.count))

            for (index, match) in results.enumerate() {
                var imageSource = (htmlString as NSString).substringWithRange(match.rangeAtIndex(1)) as String
                
                // See if we can get the image from the cache
                let imageCache = CacheManager.sharedCacheManager().cache
                if let cachedImage = imageCache.objectForKey(imageSource) as? UIImage {
                    print("Get image from cache: \(imageSource)")

                    let imageAttachment = ImageAttachment()
                    imageAttachment.image = cachedImage
                    imageAttachment.imageURL = imageSource
                    let attrStringWithImage = NSAttributedString(attachment: imageAttachment)
                    attributedHTMLString.insertAttributedString(attrStringWithImage, atIndex: match.rangeAtIndex(0).location + index)
                
                } else {

                    // Some URLs are encoded with "&amp;". Need to replace it with the actual "&"
                    imageSource = imageSource.stringByReplacingOccurrencesOfString("&amp;", withString: "&")

                    // Otherwise, we download the image from the source
                    if let imageURL = NSURL(string: imageSource.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!) {

                        let imageAttachment = ImageAttachment()
                        imageAttachment.image = UIImage()
                        imageAttachment.imageURL = imageURL.absoluteString!
                        let attrStringWithImage = NSAttributedString(attachment: imageAttachment)
                        attributedHTMLString.insertAttributedString(attrStringWithImage, atIndex: match.rangeAtIndex(0).location + index)
                        
                        NSURLSession.sharedSession().dataTaskWithURL(imageURL, completionHandler: { (data, response, error) -> Void in
                            
                            if error == nil {
                                if let image = UIImage(data: data!) {
                                    imageAttachment.image = image
//                                    print("Caching image: \(imageSource)")
                                    imageCache.setObject(image, forKey: imageSource)
                                    
                                    attributedHTMLString.enumerateAttribute(NSAttachmentAttributeName, inRange: NSMakeRange(0, attributedHTMLString.length), options: [], usingBlock: {(value, range, stop) -> Void in
                                        
                                        if let attachment = value as? ImageAttachment {
                                            if attachment.imageURL == imageURL.absoluteString {
                                                let newAttachmentString = NSAttributedString(attachment: attachment)
                                                imageCompletionHandler(range: range, string: newAttachmentString)
                                            }
                                        }
                                    })
                                }

                            } else {
                                print("Failed to download image: \(error!.localizedDescription)")
                            }

                        }).resume()
                    }
                }
            }
        }

        // Remove the rest of HTML tags
        attributedHTMLString.replaceAllStrings("</(h1|h2|h3)>", replacement: "\n")
        attributedHTMLString.removeHTMLTags()
        attributedHTMLString.replaceAllStrings("^\\s+|\\s+$", replacement: "")
        
        // Remove redundant newline characters
        attributedHTMLString.replaceAllStrings("(\n){3,}", replacement: "\n\n")
        
        return attributedHTMLString
    }
    
    func parseFirstImage() -> String? {
        
        var htmlString = self
        
        if htmlString.rangeOfString("&lt;", options: .CaseInsensitiveSearch) != nil {
            // Decode character entities (e.g. &amp;)
            for (encodedEntity, decodedEntity) in characterEntities {
                htmlString = htmlString.stringByReplacingOccurrencesOfString(encodedEntity, withString: decodedEntity)
            }
        }

        // Check if the given string contains an image
        // If it's not found, we just return an empty string
        if htmlString.rangeOfString("<img", options: .CaseInsensitiveSearch) == nil {
            return ""
        }
        
        // Parse the given string and look for the first image
        guard let imageURL = scanImage(htmlString) else {
            return ""
        }
        
        return imageURL
    }
    
    
    func removeFirstImageFromHTML() -> String {
        
        var htmlString = self
        
        if let imageTagRegEx = try? NSRegularExpression(pattern: "<img[^>]+>", options: .CaseInsensitive) {
            let result = imageTagRegEx.firstMatchInString(self, options: [], range: NSMakeRange(0, self.characters.count))
            
            if let range = result?.range {
                htmlString = (htmlString as NSString).stringByReplacingCharactersInRange(range, withString: "")
            }
        }
        
        return htmlString
    }
    
    func truncate(length:Int) -> String {
        let index = self.startIndex.advancedBy(length)
        return self.substringToIndex(index)
    }

    // Scan the possible featured photo of an article in the give HTML string
    private func scanImage(htmlString: String) -> String? {
        var htmlString = htmlString
        var htmlScanner = NSScanner(string: htmlString)
        var imageSrc: NSString?
        var imageURL:String?

        
        // Set the scanner to case insensitive
        htmlScanner.caseSensitive = false
        
        // First check if there is any feature figure. If a <figure> tag is found, we will use
        // that image as the featured image. Otherwise, we just pick the first image.
        var isFeaturedPhotoFound = false
        let featuredTag = (htmlString as NSString).rangeOfString("<figure")
        if featuredTag.location != NSNotFound {
            let html = (htmlString as NSString).substringFromIndex(featuredTag.location)

            // Even if we find the <figure> tag, it may not contain an image
            // This is why we first check if it contains the <img> tag
            isFeaturedPhotoFound = html.contains("<img")
            if isFeaturedPhotoFound {
                htmlScanner = NSScanner(string: html)
                htmlScanner.caseSensitive = false
                htmlString = html
            }
        }

        htmlScanner.scanUpToString("<img", intoString: nil)
        
        if htmlScanner.scanLocation < htmlString.characters.count {
            htmlScanner.scanUpToString("src=", intoString: nil)
            htmlScanner.scanLocation += 5
            if htmlScanner.scanLocation < htmlString.characters.count {
//                let index = htmlString.startIndex.advancedBy(htmlScanner.scanLocation - 1)
//                htmlScanner.scanUpToString("\(htmlString[index])", intoString: &imageSrc)
                htmlScanner.scanUpToString("\"", intoString: &imageSrc)
                if (imageSrc?.rangeOfString("http://").location != NSNotFound ||
                    imageSrc?.rangeOfString("https://").location != NSNotFound ||
                    imageSrc?.rangeOfString("//").location != NSNotFound ) &&
                    imageSrc?.length > 7 {
                        imageURL = imageSrc! as String

                        // Some image links do not start with HTTP
                        // So, we need to add it manually
                        if imageURL?.truncate(4).lowercaseString != "http" {
                            imageURL = "http:\(imageURL)"
                        }
    
                }
            }
        }
        
        return imageURL
    }
}
