//
//  FlatColor.swift
//  RssReader
//
//  Created by Simon Ng on 29/6/15.
//  Copyright (c) 2015 AppCoda Limited. All rights reserved.
//

import Foundation

enum FlatColor: Int {

    case LightGreen, DarkGreen, LightBlue, DarkBlue, LightPurple, DarkPurple, LightOrange, DarkOrange, PaleOrange, LightRed, DarkRed, BrightYellow, PaleYellow, Silver
    
    func color() -> UIColor {
        switch(self) {
        case .LightGreen: return UIColor(red: 41.0/255.0, green: 128.0/255.0, blue: 185.0/255.0, alpha: 1.0)
        case .DarkGreen: return UIColor(red: 142.0/255.0, green: 68.0/255.0, blue: 173.0/255.0, alpha: 1.0)
        case .LightBlue: return UIColor(red: 52.0/255.0, green: 152.0/255.0, blue: 219.0/255.0, alpha: 1.0)
        case .DarkBlue: return UIColor(red: 41.0/255.0, green: 128.0/255.0, blue: 185.0/255.0, alpha: 1.0)
        case .LightPurple: return UIColor(red: 155.0/255.0, green: 89.0/255.0, blue: 182.0/255.0, alpha: 1.0)
        case .DarkPurple: return UIColor(red: 142.0/255.0, green: 68.0/255.0, blue: 173.0/255.0, alpha: 1.0)
        case .LightRed: return UIColor(red: 231.0/255.0, green: 76.0/255.0, blue: 60.0/255.0, alpha: 1.0)
        case .DarkRed: return UIColor(red: 192.0/255.0, green: 57.0/255.0, blue: 43.0/255.0, alpha: 1.0)
        case .LightOrange: return UIColor(red: 243.0/255.0, green: 156.0/255.0, blue: 18.0/255.0, alpha: 1.0)
        case .DarkOrange: return UIColor(red: 211.0/255.0, green: 84.0/255.0, blue: 0.0/255.0, alpha: 1.0)
        case .PaleOrange: return UIColor(red: 250.0/255.0, green: 117.0/255.0, blue: 30.0/255.0, alpha: 1.0)
        case .BrightYellow: return UIColor(red: 248.0/255.0, green: 223.0/255.0, blue: 100.0/255.0, alpha: 1.0)
        case .PaleYellow: return UIColor(red: 255.0/255.0, green: 243.0/255.0, blue: 182.0/255.0, alpha: 1.0)
        case .Silver: return UIColor(red: 189.0/255.0, green: 195.0/255.0, blue: 199.0/255.0, alpha: 1.0)
        }
    }
}