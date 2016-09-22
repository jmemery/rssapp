//
//  ImageAttachment.swift
//  RssReader
//
//  Created by Simon Ng on 14/6/15.
//  Copyright (c) 2015 AppCoda Limited. All rights reserved.
//

import UIKit

class ImageAttachment: NSTextAttachment {
    var imageURL:String = ""
    
    override func attachmentBoundsForTextContainer(textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
        
        var rect:CGRect = lineFrag
        
        var scalingFactor:CGFloat = 1.0
        if let imageSize = self.image?.size {
            if lineFrag.width < imageSize.width {
                scalingFactor = lineFrag.width / imageSize.width
            }
            rect = CGRectMake(0, 0, imageSize.width * scalingFactor, imageSize.height * scalingFactor)
        }
        
        return rect
    }
   
}
