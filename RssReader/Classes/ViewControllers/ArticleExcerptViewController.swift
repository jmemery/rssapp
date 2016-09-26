//
//  ArticleExcerptViewController.swift
//  RssReader
//
//  Created by Simon Ng on 5/6/15.
//  Copyright (c) 2015 AppCoda Limited. All rights reserved.
//

import UIKit
import GoogleMobileAds

let ARTICLE_EXCERPT_LIMIT = 14896

class ArticleExcerptViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, UITextViewDelegate, GADBannerViewDelegate {
    @IBOutlet weak var tableView:UITableView!
    @IBOutlet weak var headerView:ArticleHeaderView!

    var article: Article?
    
    // Header view configuration
    private var defaultTableHeaderHeight:CGFloat = 250.0
    private var lastContentOffset:CGFloat = 0.0
    private let defaultHeaderImageName = "bg-pattern"
  
    // Transition animator for 
    var transitionAnimator:SlideUpTransitionAnimator = SlideUpTransitionAnimator()
    
    private var tappedLink:String = ""

    // Ad Banner
    lazy var adBannerView: GADBannerView? = {
        let adBannerView = GADBannerView(adSize: kGADAdSizeSmartBannerPortrait)
        adBannerView.adUnitID = ConfigurationManager.admobAdUnitId()
        adBannerView.delegate = self
        adBannerView.rootViewController = self
        
        return adBannerView
    }()

    
    private var isDragged = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.separatorStyle = .None
        tableView.rowHeight = UITableViewAutomaticDimension
        
        // Add the header view to the table view background
        defaultTableHeaderHeight = headerView.frame.size.height
        lastContentOffset = -defaultTableHeaderHeight
        
        tableView.tableHeaderView = nil
        tableView.addSubview(headerView)
        tableView.sendSubviewToBack(headerView)
        
        tableView.contentInset = UIEdgeInsets(top: defaultTableHeaderHeight, left: 0, bottom: 0, right: 0)
        tableView.contentOffset = CGPoint(x: 0, y: -defaultTableHeaderHeight)

        // Disable content inset adjustment
        self.automaticallyAdjustsScrollViewInsets = false
        
        if let articleImageURL = article?.headerImageURL {
            if articleImageURL != "" {
                // Download the article image
                headerView.imageView.sd_setImageWithURL(NSURL(string: articleImageURL), completed: { (image, error, SDImageCacheType, url) -> Void in
                    if image != nil {
                        self.headerView.imageView.image = image
                    } else {
                        
                        self.headerView.imageView.image = UIImage(named: self.defaultHeaderImageName)
                    }
                    
                })
            } else {
                headerView.imageView.image = UIImage(named: defaultHeaderImageName)
            }
        }
        
        // Enable Ad (depending on the settings)
        if ConfigurationManager.isDetailViewAdsEnabled() {
//            adBannerView = ADBannerView(adType: ADAdType.Banner)
//            adBannerView?.delegate = self
            adBannerView?.loadRequest(GADRequest())
        }
    }
    
    override func viewDidLayoutSubviews() {
        updateHeaderView()
    }
    
    func updateHeaderView() {
        let headerViewFrame = CGRect(x: 0, y: -defaultTableHeaderHeight, width: tableView.bounds.size.width, height: defaultTableHeaderHeight)
        headerView.frame = headerViewFrame
    }
    
    // MARK: - UIScrollViewDelegate
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        // Indicate the user has interacted with the table view
        isDragged = true
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        var headerViewFrame = CGRect(x: 0, y: -defaultTableHeaderHeight, width: tableView.bounds.size.width, height: defaultTableHeaderHeight)
        
        // The ad banner is put in the section header view of the table view.
        // To correctly position the ad banner, we have to change the contentInset property as users scrolls through the table
        if ConfigurationManager.isDetailViewAdsEnabled() {
            if isDragged {
                if -offsetY < defaultTableHeaderHeight && -offsetY > 0 {
                    tableView.contentInset = UIEdgeInsets(top: -offsetY, left: 0, bottom: 0, right: 0)
                } else if offsetY > 0 {
                    // Keep the ad baner
                    tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
                }
            }
        }

        // Keep the view origin to the top and scale the height of the frame
        // to create a stretchy effect
        //        if offsetY < -defaultTableHeaderHeight {
        if offsetY < 0 {
            headerViewFrame.origin.y = offsetY
            headerViewFrame.size.height =  -offsetY
        }
        
        headerView.frame = headerViewFrame
        
        // Hide the status bar when scrolling up
        if offsetY + defaultTableHeaderHeight > 10 {
            UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation:
                .Fade)
        } else {
            UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation:
                .Fade)
        }
  /*
        if -offsetY >= defaultTableHeaderHeight || lastContentOffset > offsetY {
            // Scroll down
            navHeaderView.closeButton.alpha = 0.5
        } else if lastContentOffset < offsetY {
            // Scroll up
            UIView.animateWithDuration(0.2, delay: 0.0, options: nil, animations: {
                self.navHeaderView.closeButton.alpha = 0.0
                }, completion: nil)
        }

        lastContentOffset = offsetY */
        

    }
    
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        
        coordinator.animateAlongsideTransition({ (context) -> Void in
            self.updateHeaderView()
            }, completion: {(context) -> Void in
        })
        
        
    }
    
    
    // MARK: - Table view data source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // Return the number of sections.
        return 2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows in the section.
        return 1
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            let headerCell = tableView.dequeueReusableCellWithIdentifier("HeaderCell", forIndexPath: indexPath) as! ArticleMetaViewCell
            headerCell.titleLabel.text = article?.title
            if let authorName = article?.authorName {
                headerCell.authorLabel.text = (authorName == "") ? "" : "BY \(authorName)".uppercaseString
            }
            
            return headerCell
            
        } else if indexPath.section == 1 {
            let contentCell = tableView.dequeueReusableCellWithIdentifier("ContentCell", forIndexPath: indexPath) as! ArticleTextLabelViewCell
            
            contentCell.descriptionTextView.delegate = self
            contentCell.descriptionTextView.attributedText = NSAttributedString(string: "")
            
            var articleDescription:String?
            if article?.content != "" {
                articleDescription = article?.content
            } else {
                articleDescription = article?.rawDescription
            }
            
            // The article description is originally in HTML format. Here we call up
            // the stringByFormattingHTMLString() to generate the attributed string.
            let textDescription = articleDescription?.stringByFormattingHTMLString({ (range, string) -> Void in

                NSOperationQueue.mainQueue().addOperationWithBlock({

                    // Once the image is downloaded, replace the image with the empty image
                    // generated by default
                    contentCell.descriptionTextView.textStorage.replaceCharactersInRange(range, withAttributedString: string)
                    
                    // Ask the table view cell to update its size
                    let currentSize = contentCell.descriptionTextView.bounds.size
                    let newSize = contentCell.descriptionTextView.sizeThatFits(CGSize(width: currentSize.width, height: CGFloat.max))
                    
                    if newSize.height != currentSize.height {
                        self.tableView.beginUpdates()
                        self.tableView.endUpdates()
                    }

                })

            })

            contentCell.descriptionTextView.attributedText = textDescription
            
            return contentCell
        }
        
        return UITableViewCell()
    }
    
    
    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        var cellHeight:CGFloat = 44.0
        
        if indexPath.section == 0 {
            cellHeight = 70.0
            
        } else if indexPath.section == 1 {
            cellHeight = 281.0
        }
        
        return cellHeight
        
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "showArticle" {
            let destinationViewController:DetailArticleViewController
            destinationViewController = segue.destinationViewController as! DetailArticleViewController
            destinationViewController.article = article // selectedArticle

            UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: UIStatusBarAnimation.Slide)
            destinationViewController.transitioningDelegate = transitionAnimator
        
        } else if segue.identifier == "showLink" {
            let destinationViewController:DetailArticleViewController
            destinationViewController = segue.destinationViewController as! DetailArticleViewController
            let articleToDisplay = Article()
            articleToDisplay.link = tappedLink
            destinationViewController.article = articleToDisplay // selectedArticle
            
            UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: UIStatusBarAnimation.Slide)
            destinationViewController.transitioningDelegate = transitionAnimator
            
        }

    }
    
    @IBAction func unwindToExcerptScreen(segue: UIStoryboardSegue) {
        if UIApplication.sharedApplication().statusBarHidden {
            UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: UIStatusBarAnimation.Slide)
        }
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

    // MARK: - UITextViewDelegate
    func textView(textView: UITextView, shouldInteractWithURL URL: NSURL, inRange characterRange: NSRange) -> Bool {
        
        tappedLink = URL.absoluteString!
        performSegueWithIdentifier("showLink", sender: self)

        return false
    }
    
    
    func textViewDidChange(textView: UITextView) {
        let currentSize = textView.bounds.size
        let newSize = textView.sizeThatFits(CGSize(width: currentSize.width, height: CGFloat.max))
        
        if newSize.height != currentSize.height {
            tableView.beginUpdates()
            tableView.endUpdates()
        }
    }

    
    // MARK: - Google Admob
    
    func adViewDidReceiveAd(bannerView: GADBannerView!) {
        print("Banner loaded successfully")
        
        // Reset the content offset
        tableView.contentOffset = CGPointMake(0, -tableView.contentInset.top)
        
        // Reposition the banner ad to create a slide down effect
        let translateTransform = CGAffineTransformMakeTranslation(bannerView.bounds.size.width, 0)
        bannerView.transform = translateTransform
        
        UIView.animateWithDuration(0.3) {
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

