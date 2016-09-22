//
//  NSMutableAttributedString+HTML.swift
//  RssReader
//
//  Created by Simon Ng on 15/6/15.
//  Copyright (c) 2015 AppCoda Limited. All rights reserved.
//

import Foundation

extension NSMutableAttributedString {
    
    func removeHTMLTags() {
        replaceAllStrings("<[^>]+>", replacement: "")
    }
    
    func replaceAllStrings(pattern: String, replacement: String) {
        var range = (self.string as NSString).rangeOfString(pattern, options: .RegularExpressionSearch)
        while range.location != NSNotFound {
            self.replaceCharactersInRange(range, withString: replacement)
            range = (self.string as NSString).rangeOfString(pattern, options: .RegularExpressionSearch)
        }
    }
}