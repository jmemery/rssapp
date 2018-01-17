//
//  String+HTML.swift
//  RssReader
//
//  Created by Simon Ng on 27/4/15.
//  Copyright (c) 2015 AppCoda Limited. All rights reserved.
//

import Foundation
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


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
        let encodedData = self.data(using: String.Encoding.utf8)!
        let attributedOptions : [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html as Any,
            .characterEncoding: String.Encoding.utf8 as Any
        ]
        let attributedString = try! NSAttributedString(data: encodedData, options: attributedOptions, documentAttributes: nil)
        
        return attributedString.string
    }
    
    func contains(_ find: String) -> Bool {
        return self.range(of: find) != nil
    }
    
    func stringByDecodingHTMLEscapeCharacters() -> String? {
        var decodedString:String? = ""
        
        // Convert paragraph to newline
        var htmlString = self.replacingOccurrences(of: "</p>", with: "\n\n", options: .caseInsensitive)
        
        // Remove all HTML tags
        htmlString = htmlString.replacingOccurrences(of: "</a>", with: " ", options: .caseInsensitive)
        while let range = htmlString.range(of: "<[^>]+>", options: .regularExpression) {
            htmlString = htmlString.replacingCharacters(in: range, with: "")
        }

        // Remove redundant newline characters
        let regex = try? NSRegularExpression(pattern: "(\n){3,}", options: [])
        decodedString = regex?.stringByReplacingMatches(in: htmlString, options: [], range: NSMakeRange(0, htmlString.count), withTemplate: "\n\n")

        // Remove all percentage escapes
        if let escapedString = decodedString?.removingPercentEncoding {
            decodedString = escapedString
        }
        
        // Decode character entities (e.g. &amp;)
        for (encodedEntity, decodedEntity) in characterEntities {
            decodedString = decodedString?.replacingOccurrences(of: encodedEntity, with: decodedEntity)
        }
        
        return decodedString
    }
    
    func stringByFormattingHTMLString(_ imageCompletionHandler: @escaping (_ range: NSRange, _ string: NSAttributedString) -> Void) -> NSAttributedString {
        
        // Remove the first image as it is displayed in the header view
        var htmlString = removeFirstImageFromHTML()
        
        // Convert paragraph to newline
        htmlString = htmlString.replacingOccurrences(of: "</p>", with: "\n\n", options: .caseInsensitive)
        htmlString = htmlString.replacingOccurrences(of: "<p>", with: "", options: .caseInsensitive)
        
        // Convert <li> tag to "- "
        htmlString = htmlString.replacingOccurrences(of: "<li>", with: "\u{2022} ", options: .caseInsensitive)
        
        // Use our own font for rendering the web page
        let textFont = [NSAttributedStringKey.font: UIFont(name: "Lato-Regular", size: 18.0)!]
        let boldFont = [NSAttributedStringKey.font: UIFont(name: "Lato-Bold", size: 18.0)!]

        // Strip off all HTML tags except H1, H2, H3, A, IMG and STRONG
        while let range = htmlString.range(of: "<(?!strong|/strong|h1|/h1|h2|/h2|h3|/h3|a|/a|img|/img)[^>]+>", options: .regularExpression) {
            htmlString = htmlString.replacingCharacters(in: range, with: "")
        }
        
        // Remove image tags that are smaller than 100 points
        while let range = htmlString.range(of: "<img[^>]*(?:height|width)\\s*=\\s*['|\"][1-9]?[0-9]['|\"][^>]*>|<img[^>]*(feedsportal|feedburner)[^>]*>", options: .regularExpression) {
            htmlString = htmlString.replacingCharacters(in: range, with: "")
        }
        
        // Decode escape characters
        if let decodedString = htmlString.removingPercentEncoding {
            htmlString = decodedString
        }
        
        // Decode character entities (e.g. &amp;)
        for (encodedEntity, decodedEntity) in characterEntities {
            htmlString = htmlString.replacingOccurrences(of: encodedEntity, with: decodedEntity)
        }
        
        let attributedHTMLString = NSMutableAttributedString(string: htmlString, attributes: textFont)

        // Format the H1, H2, H3 and STRONG tags
        // Backup regex: (<strong.*>(.*?)</strong>|<h[1234].?>(?:<strong>){0,1}(.*?)(?:</strong>){0,1}</h[1234]>)
        if let boldTextRegEx = try? NSRegularExpression(pattern: "(<strong.*>(.*?)</strong>|<h[1234][^>]*>(?:<strong>){0,1}(.*?)(?:</strong>){0,1}</h[1234]>)", options: .caseInsensitive) {
            let results = boldTextRegEx.matches(in: htmlString, options: [], range: NSMakeRange(0, htmlString.count))
            
            for match in results {
                _ = (htmlString as NSString).substring(with: match.range)
                if match.numberOfRanges > 1 {
                    for index in 2..<match.numberOfRanges {
                        if match.range(at: index).length != 0 {
                            _ = (htmlString as NSString).substring(with: match.range(at: index)) as String
                            attributedHTMLString.addAttributes(boldFont, range: match.range(at: index))
                        }
                    }
                }
            }
        }
        
        // Extract link
        if let linkRegEx = try? NSRegularExpression(pattern: "<a\\s+(?:[^>]*?\\s+)?href=\"([^\"]*)\"[^>]*>([^<]+)</a>", options: .caseInsensitive) {
            let results = linkRegEx.matches(in: htmlString, options: [], range: NSMakeRange(0, htmlString.count))
            for match in results {
                if match.numberOfRanges == 3 {
                    let link = (htmlString as NSString).substring(with: match.range(at: 1)) as String
                    _ = (htmlString as NSString).substring(with: match.range(at: 2)) as String
                    attributedHTMLString.addAttribute(NSAttributedStringKey.link, value: link, range: match.range(at: 2))
                }
            }
        }
        
        // Extract the image source and download the image
        if let imgRegEx = try? NSRegularExpression(pattern: "<img.+?src=[\"'](.+?)[\"'].*?>", options: .caseInsensitive) {
            let results = imgRegEx.matches(in: htmlString, options: [], range: NSMakeRange(0, htmlString.count))

            for (index, match) in results.enumerated() {
                var imageSource = (htmlString as NSString).substring(with: match.range(at: 1)) as String
                
                // See if we can get the image from the cache
                let imageCache = CacheManager.sharedCacheManager().cache
                if let cachedImage = imageCache.object(forKey: imageSource as AnyObject) as? UIImage {
                    print("Get image from cache: \(imageSource)")

                    let imageAttachment = ImageAttachment()
                    imageAttachment.image = cachedImage
                    imageAttachment.imageURL = imageSource
                    let attrStringWithImage = NSAttributedString(attachment: imageAttachment)
                    attributedHTMLString.insert(attrStringWithImage, at: match.range(at: 0).location + index)
                
                } else {

                    // Some URLs are encoded with "&amp;". Need to replace it with the actual "&"
                    imageSource = imageSource.replacingOccurrences(of: "&amp;", with: "&")

                    // Otherwise, we download the image from the source
                    if let imageURL = URL(string: imageSource.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!) {

                        let imageAttachment = ImageAttachment()
                        imageAttachment.image = UIImage()
                        imageAttachment.imageURL = imageURL.absoluteString
                        let attrStringWithImage = NSAttributedString(attachment: imageAttachment)
                        attributedHTMLString.insert(attrStringWithImage, at: match.range(at: 0).location + index)
                        
                        URLSession.shared.dataTask(with: imageURL, completionHandler: { (data, response, error) -> Void in
                            
                            if error == nil {
                                if let image = UIImage(data: data!) {
                                    imageAttachment.image = image
//                                    print("Caching image: \(imageSource)")
                                    imageCache.setObject(image, forKey: imageSource as AnyObject)
                                    
                                    attributedHTMLString.enumerateAttribute(NSAttributedStringKey.attachment, in: NSMakeRange(0, attributedHTMLString.length), options: [], using: {(value, range, stop) -> Void in
                                        
                                        if let attachment = value as? ImageAttachment {
                                            if attachment.imageURL == imageURL.absoluteString {
                                                let newAttachmentString = NSAttributedString(attachment: attachment)
                                                imageCompletionHandler(range, newAttachmentString)
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
        
        if htmlString.range(of: "&lt;", options: .caseInsensitive) != nil {
            // Decode character entities (e.g. &amp;)
            for (encodedEntity, decodedEntity) in characterEntities {
                htmlString = htmlString.replacingOccurrences(of: encodedEntity, with: decodedEntity)
            }
        }

        // Check if the given string contains an image
        // If it's not found, we just return an empty string
        if htmlString.range(of: "<img", options: .caseInsensitive) == nil {
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
        
        if let imageTagRegEx = try? NSRegularExpression(pattern: "<img[^>]+>", options: .caseInsensitive) {
            let result = imageTagRegEx.firstMatch(in: self, options: [], range: NSMakeRange(0, self.count))
            
            if let range = result?.range {
                htmlString = (htmlString as NSString).replacingCharacters(in: range, with: "")
            }
        }
        
        return htmlString
    }
    
    func truncate(_ length:Int) -> String {
        let index = self.index(self.startIndex, offsetBy: length)
        return String(self[..<index])
//        return self.substring(to: index)
    }

    // Scan the possible featured photo of an article in the give HTML string
    fileprivate func scanImage(_ htmlString: String) -> String? {
        var htmlString = htmlString
        var htmlScanner = Scanner(string: htmlString)
        var imageSrc: NSString?
        var imageURL:String?

        
        // Set the scanner to case insensitive
        htmlScanner.caseSensitive = false
        
        // First check if there is any feature figure. If a <figure> tag is found, we will use
        // that image as the featured image. Otherwise, we just pick the first image.
        var isFeaturedPhotoFound = false
        let featuredTag = (htmlString as NSString).range(of: "<figure")
        if featuredTag.location != NSNotFound {
            let html = (htmlString as NSString).substring(from: featuredTag.location)

            // Even if we find the <figure> tag, it may not contain an image
            // This is why we first check if it contains the <img> tag
            isFeaturedPhotoFound = html.contains("<img")
            if isFeaturedPhotoFound {
                htmlScanner = Scanner(string: html)
                htmlScanner.caseSensitive = false
                htmlString = html
            }
        }

        htmlScanner.scanUpTo("<img", into: nil)
        
        if htmlScanner.scanLocation < htmlString.count {
            htmlScanner.scanUpTo("src=", into: nil)
            htmlScanner.scanLocation += 5
            if htmlScanner.scanLocation < htmlString.count {
//                let index = htmlString.startIndex.advancedBy(htmlScanner.scanLocation - 1)
//                htmlScanner.scanUpToString("\(htmlString[index])", intoString: &imageSrc)
                htmlScanner.scanUpTo("\"", into: &imageSrc)
                if (imageSrc?.range(of: "http://").location != NSNotFound ||
                    imageSrc?.range(of: "https://").location != NSNotFound ||
                    imageSrc?.range(of: "//").location != NSNotFound ) &&
                    imageSrc?.length > 7 {
                        imageURL = imageSrc! as String

                        // Some image links do not start with HTTP
                        // So, we need to add it manually
                        if let url = imageURL, url.truncate(4).lowercased() != "http" {
                            imageURL = "http:\(url)"
                        }
    
                }
            }
        }
        
        return imageURL
    }
}
