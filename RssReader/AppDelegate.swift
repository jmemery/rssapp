//
//  AppDelegate.swift
//  RssReader
//
//  Created by AppCoda on 11/20/14.
//  Copyright (c) 2014 AppCoda Limited. All rights reserved.
//

import UIKit
import GoogleMobileAds

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        if let infoDict = NSBundle.mainBundle().infoDictionary {
            let storyboardName:String = infoDict["UIMainStoryboardFile"] as! String
            
            // Change navigation bar appearance
            if storyboardName == "Main_iPhone" || storyboardName == "Main_iPhone-2" || storyboardName == "Main_iPad" {
                if ConfigurationManager.defaultTheme() == "dark" {
                    UINavigationBar.appearance().barTintColor = UIColor(red: 0.0/255.0, green: 174.0/255.0, blue: 239.0/255.0, alpha: 1.0)
                    UINavigationBar.appearance().tintColor = UIColor.whiteColor()
                    
                    // Change status bar style
                    UIApplication.sharedApplication().statusBarStyle = .LightContent
                    
                    // Default bar font
                    if let barFont = UIFont(name: ConfigurationManager.defaultBarFont(), size: 17.0) {
                        UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName:UIColor.whiteColor(), NSFontAttributeName:barFont]
                    }
                    
                    
                } else if ConfigurationManager.defaultTheme() == "light" {
                    UINavigationBar.appearance().barTintColor = UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0)
                    UINavigationBar.appearance().tintColor = UIColor(red: 166.0/255.0, green: 37.0/255.0, blue: 15.0/255.0, alpha: 1.0)

                    //            UINavigationBar.appearance().tintColor = UIColor(red: 25.0/255.0, green: 150.0/255.0, blue: 93.0/255.0, alpha: 1.0)
                    
                    // Change status bar style
                    UIApplication.sharedApplication().statusBarStyle = .Default
                    
                    if let barFont = UIFont(name: ConfigurationManager.defaultBarFont(), size: 17.0) {
                        UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName:UIColor(red: 166.0/255.0, green: 37.0/255.0, blue: 15.0/255.0, alpha: 1.0), NSFontAttributeName:barFont]
                    }
                    
                }
                
                // Configure the default fonts
                UILabel.appearance().font = ConfigurationManager.defaultCellFont() != "default" ? UIFont(name: "Raleway", size: 14.0) : UIFont(name: ConfigurationManager.defaultCellFont(), size: 14.0)
            }
        }
        
        // Setup AdMob
        if ConfigurationManager.isHomeScreenAdsEnabled() || ConfigurationManager.isDetailViewAdsEnabled() {
            
            GADMobileAds.configureWithApplicationID(ConfigurationManager.admobAppId())
        }
        
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

