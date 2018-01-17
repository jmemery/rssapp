//
//  ConfigurationManager.swift
//  RssReader
//
//  Created by Simon Ng on 5/12/14.
//  Copyright (c) 2014 AppCoda Limited. All rights reserved.
//

import UIKit


class ConfigurationManager: NSObject {
    var configuration:AnyObject?
    lazy var feeds: [[String: String]] = ConfigurationManager.initFeeds()

    override init() {
        super.init()
        
        if let confPath = Bundle.main.path(forResource: "ReaderConf", ofType: "plist") {
            configuration = NSDictionary(contentsOfFile: confPath)
        }
    }
    
    class func sharedConfigurationManager() -> ConfigurationManager {
        return _sharedConfigurationManager
    }
    
    class func initFeeds() -> [[String: String]] {
        return ConfigurationManager.sharedConfigurationManager().configuration?.object(forKey: "Feeds") as! [[String: String]]
        
    }
    
    class func getCategoryFeeds(_ category: String) -> [[String: String]]? {
        
        var categoryFeeds:[[String: String]]?
        
        if let categories = ConfigurationManager.sharedConfigurationManager().configuration?.object(forKey: "CategoryFeeds") as? [String: AnyObject]{

            categoryFeeds = categories[category] as? [[String: String]]
        }
        
        return categoryFeeds
    }
    
    class func isDetailViewAdsEnabled() -> Bool {
        return ConfigurationManager.sharedConfigurationManager().configuration?.object(forKey: "DetailViewAdsEnabled") as! Bool
    }

    class func isHomeScreenAdsEnabled() -> Bool {
        return ConfigurationManager.sharedConfigurationManager().configuration?.object(forKey: "HomeScreenAdsEnabled") as! Bool
    }

    class func isDropdownMenuEnabled() -> Bool {
        return ConfigurationManager.sharedConfigurationManager().configuration?.object(forKey: "DropdownMenu") as! Bool
    }
    
    class func displayMode() -> String {
        return ConfigurationManager.sharedConfigurationManager().configuration?.object(forKey: "DisplayMode") as! String
    }
    
    class func defaultCellFont() -> String {
        if let defaultFont = ConfigurationManager.sharedConfigurationManager().configuration?.object(forKey: "DefaultCellFont") as? String{

            return defaultFont
        }
        
        return "Raleway"
    }

    class func defaultBarFont() -> String {
        
        if let defaultFont = ConfigurationManager.sharedConfigurationManager().configuration?.object(forKey: "DefaultBarFont") as? String {
            return defaultFont
        }
        
        return "Coustard-Regular"
    }

    class func defaultTheme() -> String {
        
        if let defaultTheme = ConfigurationManager.sharedConfigurationManager().configuration?.object(forKey: "Theme") as? String {
            return defaultTheme
        }
        
        return "Dark"
    }
    
    class func admobAppId() -> String {
        return ConfigurationManager.sharedConfigurationManager().configuration?.object(forKey: "AdmobAppId") as! String
    }
    
    class func admobAdUnitId() -> String {
        return ConfigurationManager.sharedConfigurationManager().configuration?.object(forKey: "AdmobAdUnitId") as! String
    }

}

let _sharedConfigurationManager: ConfigurationManager = { ConfigurationManager() }()
