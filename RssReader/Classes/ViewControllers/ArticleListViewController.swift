//
//  ArticleListViewController.swift
//  RssReader
//
//  Created by Simon Ng on 4/6/15.
//  Copyright (c) 2015 AppCoda Limited. All rights reserved.
//

import UIKit
import GoogleMobileAds

class ArticleListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, MenuViewDelegate, GADBannerViewDelegate {

    @IBOutlet weak var headerView:ArticleListHeaderView!
    @IBOutlet weak var tableView:UITableView!
    @IBOutlet weak var navHeaderView:ArticleListNavHeaderView!
    @IBOutlet weak var loadingIndicator: UIImageView!
    @IBOutlet weak var blurringImageView:UIImageView!
    
    private var blurEffectView:UIVisualEffectView?
    private var defaultTableHeaderHeight:CGFloat = 250.0
    private var defaultNavHeaderOffset:CGFloat = 37.0
    private var defaultRowHeight:CGFloat = 138.0
    
    private var transitionAnimator = PopTransitionAnimator()
    
    private var _currentFeeds: (title: String, url: String)?
    private let slideUpTransitionAnimator = SlideUpTransitionAnimator()
    
    private var isRefreshingContent = false
    
    private var articles:[Article] = []
    
    // Ad Banner
    lazy var adBannerView: GADBannerView? = {
        let adBannerView = GADBannerView(adSize: kGADAdSizeSmartBannerPortrait)
        adBannerView.adUnitID = ConfigurationManager.admobAdUnitId()
        adBannerView.delegate = self
        adBannerView.rootViewController = self
        
        return adBannerView
    }()
    
    private var isDragged = false
    
    var currentFeeds: (title: String, url: String)? {
        set (newValue){
            _currentFeeds = newValue
            loadTableView(_currentFeeds?.url, title: _currentFeeds?.title)
        }
        get {
            return _currentFeeds
        }
    }
    
    // Feed URLs - Configure via ReaderConf.plist
    var feedsURLs: [[String: String]] = ConfigurationManager.sharedConfigurationManager().feeds
    
    lazy var service: FeedsService? = {
        return FeedsService()
        }()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize the custom loading indicator
        loadingIndicator.animationImages = [UIImage]()
        for index in 1..<19 {
            loadingIndicator.animationImages?.append(UIImage(named: "loading-\(index)")!)
        }
        
        loadingIndicator.alpha = 0.9
        loadingIndicator.animationDuration = 1.0
        loadingIndicator.tintColor = UIColor.grayColor()
        
        // Initialize blurring image view
        // This image view is used to display a blurring effect while loading the RSS feed
        blurringImageView.image = UIImage(named: "nav_bg")
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.ExtraLight)
        blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView?.frame = view.bounds
        blurringImageView.hidden = false
        blurringImageView.alpha = 0.9
        blurringImageView.addSubview(blurEffectView!)
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = defaultRowHeight
        
        // Add the header view to the table view background
        defaultTableHeaderHeight = headerView.frame.size.height
        headerView.imageView.image = nil
        headerView.titleLabel.text = ""
        headerView.authorLabel.text = ""
        headerView.columnLabel.text = ""
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ArticleListViewController.showDetailScreen))
        headerView.titleLabel.addGestureRecognizer(tapGestureRecognizer)
        headerView.titleLabel.userInteractionEnabled = true
        
        // Dim the header image view
        headerView.backgroundColor = UIColor.blackColor()
        headerView.imageView.layer.opacity = 0.75

        
        tableView.tableHeaderView = nil
        tableView.addSubview(headerView)
        tableView.sendSubviewToBack(headerView)
        
        tableView.contentInset = UIEdgeInsets(top: defaultTableHeaderHeight, left: 0, bottom: 0, right: 0)
        tableView.contentOffset = CGPoint(x: 0, y: -defaultTableHeaderHeight)
        
        // Set up navigation header view
        navHeaderView.titleLabel.text = feedsURLs[0]["name"]!
        
        // Get the first feed in the list
        currentFeeds = (title: feedsURLs[0]["name"]!, url: feedsURLs[0]["url"]!)

        // Enable Ad (depending on the settings)
        if ConfigurationManager.isHomeScreenAdsEnabled() {
            adBannerView?.loadRequest(GADRequest())
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // Return the number of sections.
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows in the section.
        return (articles.count > 0) ? articles.count : 0
    }
 
    /*
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if !ConfigurationManager.isHomeScreenAdsEnabled() {
            return nil
        }
        
        // The ad banner is only displayed in the first section (i.e. section #0). For the
        // rest of the sections, a nil is returned.
        if section != 0 {
            return nil
        }
        
        return adBannerView
    }
    */
    
    /*
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        // 1. The ad banner is only displayed in the first section (i.e. section #0). For the
        //    rest of the sections, we return a height of zero.
        // 2. If the ad banner can't be loaded (i.e. isAdDisplayed sets to false), we also return
        //    a height of zero.
        if section != 0 || !isAdDisplayed {
            return 0.0
        }
        
        guard let bannerView = adBannerView else {
            return 0.0
        }
        
        return bannerView.frame.size.height
    }
    */
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let article = articles[indexPath.row]
        
        if (indexPath.row + 1) % 4 != 0 {
            let thumbnailCell = tableView.dequeueReusableCellWithIdentifier("ThumbnailCell", forIndexPath: indexPath) as! ArticleListThumbnailCell
            
            if indexPath.row == 0 {
                thumbnailCell.hidden = true
            }
            
            thumbnailCell.titleLabel.text = article.title
            if let authorName = article.authorName {
                thumbnailCell.authorLabel.text = (authorName == "") ? "" : "BY \(authorName)".uppercaseString
            }
            
            if let articleImageURL = article.headerImageURL {
                thumbnailCell.thumbnailImageViewConstraintHeight.constant = 110.0
                thumbnailCell.thumbnailImageViewConstraintWidth.constant = 110.0
                
                if articleImageURL != "" {
                    // Download the article image
                    thumbnailCell.thumbnailImageView.sd_setImageWithURL(NSURL(string: articleImageURL), completed: { (image, error, SDImageCacheType, url) -> Void in
                        if image != nil {
                            // Load the image with a cross dissolve effect
                            UIView.transitionWithView(thumbnailCell.thumbnailImageView, duration: 0.3, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: {
                                
                                thumbnailCell.thumbnailImageView.image = image
                                }, completion: nil)
                            
                        } else {
                            // Minimize the thumbnail image view if there is no image
                            print("Failed to load \(articleImageURL): \(error.localizedDescription)")
                            if thumbnailCell.thumbnailImageViewConstraintHeight != nil {
                                thumbnailCell.thumbnailImageViewConstraintHeight.constant = 0.0
                            }
                            
                            if thumbnailCell.thumbnailImageViewConstraintWidth != nil {
                                thumbnailCell.thumbnailImageViewConstraintWidth.constant = 0.0
                            }
                        }
    
                    })
                } else {
                    // Minimize the thumbnail image view if there is no image
                    thumbnailCell.thumbnailImageView.image = nil
                    if thumbnailCell.thumbnailImageViewConstraintHeight != nil {
                        thumbnailCell.thumbnailImageViewConstraintHeight.constant = 0.0
                    }
                    
                    if thumbnailCell.thumbnailImageViewConstraintWidth != nil {
                        thumbnailCell.thumbnailImageViewConstraintWidth.constant = 0.0
                    }
                    
                }

            }
            
            return thumbnailCell
            
        } else {
            let descriptionCell = tableView.dequeueReusableCellWithIdentifier("DescriptionCell", forIndexPath: indexPath) as! ArticleListDescriptionCell
            descriptionCell.titleLabel.text = article.title

            if let authorName = article.authorName {
                descriptionCell.authorLabel.text = (authorName == "") ? "" : "BY \(authorName)".uppercaseString
            }
            
            descriptionCell.descriptionLabel.text = article.description?.stringByReplacingOccurrencesOfString("\n", withString: "").stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
            
            return descriptionCell
        }
    }

    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        showDetailScreen()
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return 0
        } else {
            return UITableViewAutomaticDimension
        }
    }
    
    // MARK: - Table reload handlers
    func loadTableView(url: String!, title: String?) {
        
        tableView.contentInset = UIEdgeInsets(top: defaultTableHeaderHeight, left: 0, bottom: 0, right: 0)
        isDragged = false

        blurringImageView.hidden = false
        blurringImageView.alpha = 0.9
        
        loadingIndicator.hidden = false
        tableView.userInteractionEnabled = false
        loadingIndicator.startAnimating()
        
        self.service?.getFeedsWithURL(url, completion: { [unowned self] (articles) -> () in
            
            // Table rows to delete
            let countOfCurrentArticles = self.articles.count
            var indexPathsToDelete = [NSIndexPath]()
            if countOfCurrentArticles != 0 {
                for index in 0..<countOfCurrentArticles {
                    indexPathsToDelete.append(NSIndexPath(forRow: index, inSection: 0))
                }
            }
            
            // Table rows to insert
            var indexPathsToInsert = [NSIndexPath]()
            for row in 0..<articles.count {
                indexPathsToInsert.append(NSIndexPath(forRow: row, inSection: 0))
            }
            
            // Update the table view to display the articles
            if indexPathsToInsert.count > 0 {
                self.articles = articles
                self.tableView.beginUpdates()
                self.tableView.deleteRowsAtIndexPaths(indexPathsToDelete, withRowAnimation: .None)
                self.tableView.insertRowsAtIndexPaths(indexPathsToInsert, withRowAnimation: .None)
                self.tableView.endUpdates()
            }
            
            // Update the featured article
            self.updateHeaderView()
            
            // Scroll to the top of the table view
            self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), atScrollPosition: UITableViewScrollPosition.Top, animated: true)
            
            UIView.transitionWithView(self.blurringImageView, duration: 0.35, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: {
                
            self.blurringImageView.alpha = 0.0
            self.blurringImageView.hidden = true
            }, completion: nil)

            self.loadingIndicator.stopAnimating()
            self.loadingIndicator.hidden = true
            self.tableView.userInteractionEnabled = true
            self.isRefreshingContent = false
            
            if let menuTitle = title {
                self.navHeaderView.titleLabel.text = menuTitle
            }
        
        }) { (error: NSError) -> (Void) in
            print("Error: \(error.localizedDescription)", terminator: "")
            
            // Display alert
            let alertController = UIAlertController(title: "Download Error", message: "Failed to retrieve articles from \(title!). Please try again later.", preferredStyle: UIAlertControllerStyle.Alert)
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil)
            alertController.addAction(okAction)
            self.presentViewController(alertController, animated: true, completion: nil)
            
            // Hide the loading indicator
            self.loadingIndicator.stopAnimating()
            self.loadingIndicator.hidden = true
            self.tableView.userInteractionEnabled = true
            self.isRefreshingContent = false
            
            // Hide blurring view
            self.blurringImageView.alpha = 0.0
            self.blurringImageView.hidden = true

        }
    }
    
    
    override func viewDidLayoutSubviews() {
        updateHeaderView()
    }
    
    func updateHeaderView() {
        let headerViewFrame = CGRect(x: 0, y: -defaultTableHeaderHeight, width: tableView.bounds.size.width, height: defaultTableHeaderHeight)
        headerView.frame = headerViewFrame
        
        // The first article is set as the feature article
        if articles.count > 0 {
            let article = articles[0]
            if let articleImageURL = article.headerImageURL {
                if articleImageURL != "" {
                    // Download the article image
                    headerView.imageView.sd_setImageWithURL(NSURL(string: articleImageURL), completed: { (image, error, SDImageCacheType, url) -> Void in
                        if image != nil {
                            self.headerView.imageView.image = image
                        }
                        
                    })
                } else {
                    headerView.imageView.image = nil
                }
                
            }

            headerView.titleLabel.text = article.title
            if let authorName = article.authorName {
                headerView.authorLabel.text = (authorName == "") ? "" : "BY \(authorName)".uppercaseString
            }
            headerView.columnLabel.text = (article.categories.count > 0) ? article.categories[0].uppercaseString : ""
        }

    }
    
    // MARK: - UIScrollViewDelegate
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
        // Stretchy header
        var headerViewFrame = CGRect(x: 0, y: -defaultTableHeaderHeight, width: tableView.bounds.size.width, height: defaultTableHeaderHeight)
        
        // Keep the view origin to the top
        if scrollView.contentOffset.y < -defaultTableHeaderHeight {
            headerViewFrame.origin.y = scrollView.contentOffset.y
            headerViewFrame.size.height =  -scrollView.contentOffset.y
        }
        
        headerView.frame = headerViewFrame
        
        // Change the background color of the navigation header as the user scrolls up
        let offsetY = scrollView.contentOffset.y + defaultTableHeaderHeight
        
        if offsetY < defaultNavHeaderOffset {
            navHeaderView.backgroundColor = UIColor.clearColor()
        } else if offsetY > defaultTableHeaderHeight {
            navHeaderView.backgroundColor = UIColor.blackColor()
        } else {
            navHeaderView.backgroundColor = UIColor(white: 0.0, alpha: (offsetY - defaultNavHeaderOffset) / (defaultTableHeaderHeight - defaultNavHeaderOffset))
        }
        
        // The ad banner is put in the section header view of the table view.
        // To correctly position the ad banner, we have to change the contentInset property as users scrolls through the table
        if ConfigurationManager.isHomeScreenAdsEnabled() {
            if isDragged {
            let contentOffsetY = scrollView.contentOffset.y
                if -contentOffsetY < defaultTableHeaderHeight && -contentOffsetY > navHeaderView.frame.size.height {
                    tableView.contentInset = UIEdgeInsets(top: -contentOffsetY, left: 0, bottom: 0, right: 0)
                } else if contentOffsetY > 0 {
                    // Keep the ad baner
                    tableView.contentInset = UIEdgeInsets(top: navHeaderView.frame.size.height, left: 0, bottom: 0, right: 0)
                }
            }
        }

        
        // Pull to refresh
        if !isRefreshingContent {
            if -offsetY > 60 {
                blurringImageView.hidden = false
                blurringImageView.alpha = (-offsetY - 60) / 40
                
            } else {
                blurringImageView.hidden = true
                blurringImageView.alpha = 0.0

            }
        }
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        let offsetY = scrollView.contentOffset.y + defaultTableHeaderHeight
        if -offsetY > 100 {
            isRefreshingContent = true
            loadTableView(currentFeeds?.url, title: currentFeeds?.title)
        }
    }
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        // Indicate the user has interacted with the table view
        isDragged = true
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        
        // Update the size of the header image
        coordinator.animateAlongsideTransition({ (context) -> Void in
            self.updateHeaderView()
            }, completion: {(context) -> Void in
        })
    }
    
    override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        // Update the bounds of the blur effect view when the orientation change
        blurEffectView?.frame = view.bounds
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showMenu" {
            let menuViewController = segue.destinationViewController as! MenuViewController
            menuViewController.delegate = self
        } else if segue.identifier == "showDetail" {
            let destinationViewController = segue.destinationViewController as! ArticleExcerptViewController
            destinationViewController.transitioningDelegate = transitionAnimator
            if let indexPath = tableView.indexPathForSelectedRow {
                destinationViewController.article = articles[indexPath.row]
            } else {
                destinationViewController.article = articles[0]
            }
        }
    }
    
    func showDetailScreen() {
        self.performSegueWithIdentifier("showDetail", sender: self)
    }
    
    @IBAction func unwindToMainScreen(segue: UIStoryboardSegue) {
        if UIApplication.sharedApplication().statusBarHidden {
            UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: UIStatusBarAnimation.Slide)
        }
    }
    
    // MARK: - Status bar
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }

    // MARK: - MenuViewDelegate
    
    func didSelectMenuItem(feed:[String: String]) {
        currentFeeds = (title: feed["name"]!, url: feed["url"]!)
    }


    // MARK: - Google Admob
    
    func adViewDidReceiveAd(bannerView: GADBannerView!) {
        print("Banner loaded successfully")
        
        // Reset the content offset
        tableView.contentOffset = CGPointMake(0, -tableView.contentInset.top)
        
        // Reposition the banner ad to create a slide down effect
        let translateTransform = CGAffineTransformMakeTranslation(0, -bannerView.bounds.size.height)
        bannerView.transform = translateTransform
        
        UIView.animateWithDuration(0.5) {
            self.tableView.tableHeaderView?.frame = bannerView.frame
            bannerView.transform = CGAffineTransformIdentity
            self.tableView.tableHeaderView = bannerView
        }
        
    }
    
    func adView(bannerView: GADBannerView!, didFailToReceiveAdWithError error: GADRequestError!) {
        print("Fail to receive ads")
        print(error)
    }

}
