//
//  FeedsViewController.swift
//  RssReader
//
//  Created by AppCoda on 11/20/14.
//  Copyright (c) 2014 AppCoda Limited. All rights reserved.
//

import UIKit
import GoogleMobileAds

class FeedsViewController: UITableViewController, GADBannerViewDelegate {
    @IBOutlet var navigationHeaderButton: UIButton!
    var navigationHeaderLabel:UILabel?
    
    private var _currentFeeds: (title: String, url: String)?
    private let slideUpTransitionAnimator = SlideUpTransitionAnimator()
    
    var currentFeeds: (title: String, url: String)? {
        set (newValue){
            _currentFeeds = newValue
            loadTableView(_currentFeeds?.url, title: _currentFeeds?.title)
        }
        get {
            return _currentFeeds
        }
    }
    
    // Data source for UITableView
    lazy var dataSource: ArticleDataSource? = {
        return ArticleDataSource(configureCellClosure: { (articleCell, article, indexPath) -> () in
           
            // Display article title
            articleCell.titleLabel.text = article.title

            if let authorName = article.authorName {
                articleCell.authorLabel.text = (authorName == "") ? "" : "BY \(authorName)".uppercaseString
            }
            
            articleCell.categoryLabel.text = article.categories.first?.uppercaseString
            
            // Display article date
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "MMM dd HH:mm"
            articleCell.dateTimeLabel.text = dateFormatter.stringFromDate(article.publicationDate)
            
            // If the comment count is zero, hide the comment label
            if article.commentsCount != 0 {
                if articleCell.commentsCountLabel != nil {
                    articleCell.commentsCountLabel.text = String(article.commentsCount)
                }
            } else {
                if articleCell.commentsCountLabel != nil {
                    articleCell.commentsCountLabel.hidden = true
                    articleCell.commentsLabel.hidden = true
                }
            }
            
            // Article Description (Supported by Main_iPhone-2.storyboard and Main_iPad.storyboard
            if articleCell.descriptionLabel != nil {
                articleCell.descriptionLabel.text = article.description
            }

            // Load article image
            if let articleImageURL = article.headerImageURL {
                if articleImageURL != "" {
                    if self.storyboard!.valueForKey("name")! as! String == "Main_iPhone" {
                        if articleCell.imageViewConstraintHeight != nil {
                            articleCell.imageViewConstraintHeight.constant = 252.0
                        }
                        self.tableView.estimatedRowHeight = 357.0
                        
                    } else if self.storyboard!.valueForKey("name")! as! String == "Main_iPhone-2" {
                        if ConfigurationManager.displayMode() == "Image" {
                            articleCell.imageViewConstraintHeight.constant = 171.0
                            articleCell.imageViewConstraintWidth.constant = 120.0
                        } else if ConfigurationManager.displayMode() == "Text" {
                            articleCell.imageViewConstraintHeight.constant = 0.0
                            articleCell.imageViewConstraintWidth.constant = 0.0
                        } else if ConfigurationManager.displayMode() == "Text+Image" {

                            let isText = (indexPath.row % 2 == 0) ? true : false
                            if isText {
                                articleCell.imageViewConstraintHeight.constant = 0.0
                                articleCell.imageViewConstraintWidth.constant = 0.0
                            } else {
                                articleCell.imageViewConstraintHeight.constant = 220.0
                                articleCell.imageViewConstraintWidth.constant = 120.0
                            }
                            
                        }
                        self.tableView.estimatedRowHeight = 171.0
                        
                    } else if self.storyboard!.valueForKey("name")! as! String == "Main_iPad" {
                        if articleCell.imageViewConstraintHeight != nil {
                            articleCell.imageViewConstraintHeight.constant = 420.0
                            self.tableView.estimatedRowHeight = 582.0
                        }
                    }

                    // Download the article image
                    if self.storyboard!.valueForKey("name")! as! String == "Main_iPhone" ||
                        (self.storyboard!.valueForKey("name")! as! String == "Main_iPhone-2" && ConfigurationManager.displayMode() != "Text") || self.storyboard!.valueForKey("name")! as! String == "Main_iPad" {
                        articleCell.headerImageView.sd_setImageWithURL(NSURL(string: articleImageURL)) { (image: UIImage!, error: NSError!, cacheTYpe: SDImageCacheType, url: NSURL!) -> Void in
                            
                            // Sometimes, the default image is too small to display.
                            // In this case, we will hide the thumbnail
                            if image == nil || image.size.width < 10 {
                                if articleCell.imageViewConstraintHeight != nil {
                                    articleCell.imageViewConstraintHeight.constant = 0.0
                                }
                                
                                if articleCell.imageViewConstraintWidth != nil {
                                    articleCell.imageViewConstraintWidth.constant = 0.0
                                }
                                
                            } else {
                                articleCell.headerImageView.image = image
                            }
                        }
                    }
                } else {
                    // In case there is no image, we decrease the width/height constraint to zero
                    articleCell.headerImageView.image = nil
                    if articleCell.imageViewConstraintHeight != nil {
                        articleCell.imageViewConstraintHeight.constant = 0.0
                    }
                    
                    if articleCell.imageViewConstraintWidth != nil {
                        articleCell.imageViewConstraintWidth.constant = 0.0
                    }
                    
                    self.tableView.estimatedRowHeight = 130.0
                }
            } else {
                articleCell.headerImageView.image = nil
            }
        })
    }()
    
    // Dropdown Menu Configuration
    lazy var navigationMenu: REMenu = {
        var dropdownMenu = REMenu()
        dropdownMenu.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.8)
        dropdownMenu.separatorColor = UIColor.clearColor()
        dropdownMenu.highlightedBackgroundColor = UIColor.blackColor()
        dropdownMenu.highlightedSeparatorColor = UIColor.whiteColor()
        dropdownMenu.borderColor = UIColor.clearColor()
        dropdownMenu.textColor = UIColor.whiteColor()
        dropdownMenu.highlightedTextColor = UIColor.whiteColor()
        dropdownMenu.font = UIFont(name: ConfigurationManager.defaultBarFont(), size: 17.0)
        dropdownMenu.separatorHeight = 0

        // Uncomment if you want to use live blur
        /*
        dropdownMenu.liveBlur = true
        dropdownMenu.liveBlurTintColor = UIColor.blackColor()
        */
        
        return dropdownMenu
    }()
    
    // Feed URLs - Configure via ReaderConf.plist
    var feedsURLs: [[String: String]] = ConfigurationManager.sharedConfigurationManager().feeds
    
    lazy var feedsMenuItems: [DropdownMenuItem] = {
        var feedsItems = [DropdownMenuItem]()
        
        for feed in self.feedsURLs {
            let title = feed["name"]
            let url = feed["url"]
            
            var item = DropdownMenuItem(title: title, image: UIImage(), highlightedImage: UIImage(), action: { [unowned self] (item: REMenuItem!) -> Void in
                let _item = item as! DropdownMenuItem
                let urlPath = _item.url?.relativePath
                self.currentFeeds = (title: item.title, url: urlPath!)
            })
            item.url = NSURL(fileURLWithPath: url!)
            feedsItems.append(item);
        }

        return feedsItems
    }()
    
    lazy var service: FeedsService? = {
        return FeedsService()
    }()
    
    lazy var adBannerView: GADBannerView? = {
        let adBannerView = GADBannerView(adSize: kGADAdSizeSmartBannerPortrait)
        adBannerView.adUnitID = ConfigurationManager.admobAdUnitId()
        adBannerView.delegate = self
        adBannerView.rootViewController = self

        return adBannerView
    }()
    
    
    // MARK: - ViewController overrides
    override func viewDidLoad() {
        super.viewDidLoad();
        
        // Get the first feed in the list
        currentFeeds = (title: feedsURLs[0]["name"]!, url: feedsURLs[0]["url"]!)
        
        // Configure title label/dropdown menu depending on your settings
        if ConfigurationManager.isDropdownMenuEnabled() {
            navigationItem.titleView = navigationHeaderButton;
            navigationHeaderButton.titleLabel?.font = UIFont(name: ConfigurationManager.defaultBarFont(), size: 17.0)
            switch ConfigurationManager.defaultTheme() {
                case "dark":
                    navigationHeaderButton.tintColor = UIColor.whiteColor()
                case "light":
                    navigationHeaderButton.tintColor = UIColor(red: 166.0/255.0, green: 37.0/255.0, blue: 15.0/255.0, alpha: 1.0)
                default: break
            }
            
        } else {
            navigationHeaderLabel = UILabel(frame: CGRectMake(0, 0, 200, 40))
            navigationHeaderLabel?.text = feedsURLs[0]["name"]!
            navigationHeaderLabel?.textAlignment = .Center
            navigationHeaderLabel?.font = UIFont(name: ConfigurationManager.defaultBarFont(), size: 17.0)
            switch ConfigurationManager.defaultTheme() {
                case "dark":
                    navigationHeaderLabel?.textColor = UIColor.whiteColor()
                case "light":
                    navigationHeaderLabel?.textColor = UIColor(red: 166.0/255.0, green: 37.0/255.0, blue: 15.0/255.0, alpha: 1.0)
                default: break
            }
            
            navigationItem.titleView = navigationHeaderLabel
        }
        
        // Configure the slide-out menu
        if UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Phone {
            revealViewController().draggableBorderWidth = view.frame.width
            revealViewController().rearViewRevealWidth = view.frame.width * 0.7
            navigationController?.navigationBar.addGestureRecognizer(revealViewController().panGestureRecognizer())
            view.addGestureRecognizer(revealViewController().panGestureRecognizer())
            view.addGestureRecognizer(revealViewController().tapGestureRecognizer())
        }
        
        // Pull-to-refresh
        refreshControl = UIRefreshControl()
        switch ConfigurationManager.defaultTheme() {
            case "dark":
                refreshControl?.backgroundColor = UIColor(red: 0.0/255.0, green: 174.0/255.0, blue: 239.0/255.0, alpha: 1.0)
                refreshControl?.tintColor = UIColor.whiteColor()
            case "light":
                refreshControl?.backgroundColor = UIColor(red: 166.0/255.0, green: 37.0/255.0, blue: 15.0/255.0, alpha: 1.0)
                refreshControl?.tintColor = UIColor.whiteColor()
            default:
                break
        }
        
        refreshControl?.addTarget(self, action: #selector(FeedsViewController.refreshTableView), forControlEvents: UIControlEvents.ValueChanged)
        
        // Add dropdown menu to navigation bar
        navigationHeaderButton?.setTitle(feedsURLs[0]["name"]! + " ▾", forState: UIControlState.Normal);
        navigationMenu.items = feedsMenuItems
        navigationHeaderButton?.hidden = !ConfigurationManager.isDropdownMenuEnabled()

        // Define table view delegate
        tableView.dataSource = self.dataSource
        
        // Enable Ad (depending on the settings)
        if ConfigurationManager.isHomeScreenAdsEnabled() {
            print("Google Mobile Ads SDK version: \(GADRequest.sdkVersion())")
        }

        // Enable self sizing cells
        self.tableView.rowHeight = UITableViewAutomaticDimension

    }
    
    override func viewDidAppear(animated: Bool) {
        // Make sure the navigation bar is not hidden
        navigationController?.hidesBarsOnSwipe = false
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    // MARK: - Button handlers
    @IBAction func navigationHeaderButtonDidPressed(sender: UIButton) {
        if !navigationMenu.isOpen {
            navigationMenu.showFromNavigationController(self.navigationController);
        } else {
            navigationMenu.close()
        }
    }
    
    @IBAction func sideMenuButtonDidpressed(sender: UIBarButtonItem) {
        if UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Phone {
            revealViewController().revealToggleAnimated(true)
        }
    }
    
    // MARK: - Table reload handlers
    func loadTableView(url: String!, title: String?) {
        self.service?.getFeedsWithURL(url, completion: { [unowned self] (articles) -> () in
            // Table rows to delete
            let countOfCurrentArticles = self.dataSource?.articles.count
            var indexPathsToDelete = [NSIndexPath]()
            for _index in 0..<countOfCurrentArticles! {
                indexPathsToDelete.append(NSIndexPath(forRow: _index, inSection: 0))
            }

            // Table rows to insert
            var indexPathsToInsert = [NSIndexPath]()
            for row in 0..<articles.count {
                indexPathsToInsert.append(NSIndexPath(forRow: row, inSection: 0))
            }
            
            // Update the table view to display the articles
            if indexPathsToInsert.count > 0 {
                self.dataSource?.articles = articles
                self.tableView.beginUpdates()
                self.tableView.deleteRowsAtIndexPaths(indexPathsToDelete, withRowAnimation: .None)
                self.tableView.insertRowsAtIndexPaths(indexPathsToInsert, withRowAnimation: .None)
                self.tableView.endUpdates()
            }
            
            // Scroll to the top of the table view
            self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), atScrollPosition: UITableViewScrollPosition.Top, animated: true)
            
            
            // Hide refreshing control
            if let isRefreshing = self.refreshControl?.refreshing {
                if isRefreshing {
                    NSOperationQueue.mainQueue().addOperationWithBlock({
                        self.refreshControl?.endRefreshing()
                    })
                }
            }
            
            // let headerButton = self.navigationHeaderButton!
            if let menuTitle = title {
                self.navigationHeaderButton?.setTitle(menuTitle + " ▾", forState: UIControlState.Normal)
                self.navigationHeaderLabel?.text = menuTitle
            }
            
            // Enable banner ad
            if ConfigurationManager.isHomeScreenAdsEnabled() {
                self.adBannerView?.loadRequest(GADRequest())
                print("Request ad banner")
                print("Ad unit ID: \(self.adBannerView?.adUnitID)")
            }

        }) { (error: NSError) -> (Void) in
            print("Error: \(error.localizedDescription)", terminator: "")
            
            // Display alert
            let alertController = UIAlertController(title: "Download Error", message: "Failed to retrieve articles from \(title!). Please try again later.", preferredStyle: UIAlertControllerStyle.Alert)
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil)
            alertController.addAction(okAction)
            self.presentViewController(alertController, animated: true, completion: nil)

            // Hide refreshing control
            if let isRefreshing = self.refreshControl?.refreshing {
                if isRefreshing {
                    NSOperationQueue.mainQueue().addOperationWithBlock({
                        self.refreshControl?.endRefreshing()
                    })
                }
            }
        }
        
    }
    
    // Action method when the user triggers a refresh
    func refreshStatusDidChange() {
        refreshTableView()
    }
    
    // Reload the table data from the selected feed
    func refreshTableView() {
        // Update last-update date
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "MMM d, h:mm a"
        let currentDateTime = dateFormatter.stringFromDate(NSDate())
        refreshControl?.attributedTitle = NSAttributedString(string: "Last Updated: \(currentDateTime)", attributes: [NSForegroundColorAttributeName: UIColor.whiteColor()])
        
        loadTableView(currentFeeds?.url, title: currentFeeds?.title)
    }

    // MARK: - Segues
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let destinationViewController:DetailArticleViewController
                destinationViewController = segue.destinationViewController as! DetailArticleViewController
                destinationViewController.article = dataSource?[indexPath.row] // selectedArticle
                
                // Use custom transition animator for Main_iPhone-2.storyboard
                if self.storyboard!.valueForKey("name")! as! String == "Main_iPhone-2" {
                    UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: UIStatusBarAnimation.Slide)
                    destinationViewController.transitioningDelegate = slideUpTransitionAnimator
                }
            }
        }

    }
    
    @IBAction func unwindToFeedScreen(segue: UIStoryboardSegue) {
        if UIApplication.sharedApplication().statusBarHidden {
            UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: UIStatusBarAnimation.Slide)
        }
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
