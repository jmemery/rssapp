//
//  DetailViewController.swift
//  RssReader
//
//  Created by AppCoda on 11/25/14.
//  Copyright (c) 2014 AppCoda Limited. All rights reserved.
//

import UIKit
import iAd

class DetailArticleViewController: UIViewController, UIWebViewDelegate, UIScrollViewDelegate {
    
    var article: Article?
    var statusBarHidden = false
    @IBOutlet var webView: UIWebView!
    @IBOutlet var loadingIndicator: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the navigation bar title
        self.title = article?.title
        
        // Initialize custom loading indicator
        loadingIndicator.animationImages = [UIImage]()
        for index in 1..<19 {
            loadingIndicator.animationImages?.append(UIImage(named: "loading-\(index)")!)
        }
        
        loadingIndicator.hidden = false
        loadingIndicator.alpha = 0.5
        loadingIndicator.animationDuration = 1.0
        loadingIndicator.startAnimating()
        
        // Load the web content
        self.webView.delegate = self
        self.webView.scrollView.delegate = self
        if var articlelink = article?.link {
            
            // In case the link is missing, we use the GUID instead
            if articlelink == "" {
                if let guid = article?.guid {
                    articlelink = guid
                }
            }
            
            if articlelink.rangeOfString("redirect.mp4") != nil {
                loadingIndicator.stopAnimating()
                loadingIndicator.hidden = true
            }
            
            if let webPageURL = NSURL(string: articlelink) {
                self.webView?.loadRequest(NSURLRequest(URL: webPageURL))
            }
        }
        
        // Enable iAd (depends on the settings)
        canDisplayBannerAds = ConfigurationManager.isDetailViewAdsEnabled()
        
    }
    
    override func viewDidAppear(animated: Bool) {
        navigationController?.hidesBarsOnSwipe = true
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        // When the web view finishes loading, we stop and hide the loading indicator
        loadingIndicator.stopAnimating()
        loadingIndicator.hidden = true
    }
    
    // Action method for activating the share actions
    @IBAction func shareAction(sender: UIBarButtonItem) {
        
        var sharingItems = [AnyObject]()
        if let title = article?.title {
            if let link = article?.link {
                sharingItems.append(title)
                sharingItems.append(NSURL(string: link)!)
            } else {
                sharingItems.append(title)
            }
        }
        
        let activityViewController = UIActivityViewController(activityItems: sharingItems, applicationActivities: [SafariActivity()])
        
        if UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad {
                activityViewController.popoverPresentationController?.barButtonItem = self.navigationItem.rightBarButtonItem
        }
        
        self.presentViewController(activityViewController, animated: true, completion: nil)
    }
    
    // Toggle the status bar
    // - Hide the status bar when the navigation bar is hidden
    // - Show the status bar when the navigation bar is displayed
    func toggleStatusBar() {
        if let navigationBarHidden = navigationController?.navigationBarHidden {
            if navigationBarHidden && !UIApplication.sharedApplication().statusBarHidden {
                UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: UIStatusBarAnimation.Fade)
            } else if !navigationBarHidden && UIApplication.sharedApplication().statusBarHidden {
                UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: UIStatusBarAnimation.Fade)
            }
        }
    }
    
    // MARK: - UIScrollViewDelegate Methods
    func scrollViewDidScroll(scrollView: UIScrollView) {
        toggleStatusBar()
    }
}
