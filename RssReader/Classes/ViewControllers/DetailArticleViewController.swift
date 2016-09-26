//
//  DetailViewController.swift
//  RssReader
//
//  Created by AppCoda on 11/25/14.
//  Copyright (c) 2014 AppCoda Limited. All rights reserved.
//

import UIKit
import GoogleMobileAds

class DetailArticleViewController: UIViewController, UIWebViewDelegate, UIScrollViewDelegate, GADBannerViewDelegate {
    
    var article: Article?
    var statusBarHidden = false
    @IBOutlet var webView: UIWebView!
    @IBOutlet var loadingIndicator: UIImageView!
    
    lazy var adBannerView: GADBannerView? = {
        let adBannerView = GADBannerView(adSize: kGADAdSizeSmartBannerPortrait)
        adBannerView.adUnitID = ConfigurationManager.admobAdUnitId()
        adBannerView.delegate = self
        adBannerView.rootViewController = self
        
        return adBannerView
    }()
    
    private var hasSetWebViewContentInset = false
    
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
        if ConfigurationManager.isDetailViewAdsEnabled() {
            adBannerView?.loadRequest(GADRequest())
        }
        
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
    
    // MARK: - Google Admob
    
    func adViewDidReceiveAd(bannerView: GADBannerView!) {
        print("Banner loaded successfully")
        
        guard let adBannerView = adBannerView else {
            return
        }
        
        webView.addSubview(adBannerView)
        
        // To prevent the banner ad from blocking the content
        // The contentInset should be changed once when the ad banner is first loaded.
        // We don't want to change it again when the ad is reloaded.
        if !hasSetWebViewContentInset {
            webView.scrollView.contentInset = UIEdgeInsets(top: webView.scrollView.contentInset.top, left: webView.scrollView.contentInset.left, bottom: webView.scrollView.contentInset.bottom + adBannerView.bounds.height, right: webView.scrollView.contentInset.right)
            hasSetWebViewContentInset = true
        }
        
        // Auto layout constraints for the ad banner
        // It is placed at the bottom of the screen (or web view)
        adBannerView.translatesAutoresizingMaskIntoConstraints = false
        let bottomSpaceConstraint = NSLayoutConstraint(item: adBannerView, attribute: .Bottom, relatedBy: NSLayoutRelation.Equal, toItem: self.webView, attribute: .Bottom, multiplier: 1.0, constant: 0)
        bottomSpaceConstraint.active = true
        let leadingSpaceConstraint = NSLayoutConstraint(item: adBannerView, attribute: .Leading, relatedBy: NSLayoutRelation.Equal, toItem: self.webView, attribute: .Leading, multiplier: 1.0, constant: 0)
        leadingSpaceConstraint.active = true
        let trailingSpaceConstraint = NSLayoutConstraint(item: adBannerView, attribute: .Trailing, relatedBy: NSLayoutRelation.Equal, toItem: self.webView, attribute: .Trailing, multiplier: 1.0, constant: 0)
        trailingSpaceConstraint.active = true


    }
    
    func adView(bannerView: GADBannerView!, didFailToReceiveAdWithError error: GADRequestError!) {
        print("Fail to receive ads")
        print(error)
    }
}
