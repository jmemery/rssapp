//
//  MenuViewController.swift
//  RssReader
//
//  Created by Simon Ng on 4/6/15.
//  Copyright (c) 2015 AppCoda Limited. All rights reserved.
//

import UIKit

protocol MenuViewDelegate {
    func didSelectMenuItem(feed:[String: String])
}

class MenuViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, SectionHeaderViewDelegate {
    @IBOutlet weak var tableView:UITableView!
    @IBOutlet weak var headerView:UIView!
    
    let feedsURLs: [[String: String]] = ConfigurationManager.sharedConfigurationManager().feeds
    private var isMenuItemShown:[Bool]!
    var isSectionExpanded:[Bool] = []
    
    var delegate:MenuViewDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the menu background based on the preferred theme
        switch ConfigurationManager.defaultTheme().lowercaseString {
        case "dark":
            tableView.backgroundColor = FlatColor.DarkOrange.color()
            headerView.backgroundColor = FlatColor.DarkOrange.color()
        case "light":
            tableView.backgroundColor = FlatColor.BrightYellow.color()
            headerView.backgroundColor = FlatColor.BrightYellow.color()
        default: break
        }
        
        isMenuItemShown = [Bool](count: self.feedsURLs.count, repeatedValue: false)
        isSectionExpanded = [Bool](count: feedsURLs.count, repeatedValue: false)
        
        // Hide status bar
        UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: UIStatusBarAnimation.Slide)

        // Register section header view
        tableView.registerNib(UINib(nibName: "SectionHeaderView", bundle: nil), forHeaderFooterViewReuseIdentifier: "SectionHeaderView")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // Return the number of sections.
        return feedsURLs.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows in the section.
        if isSectionExpanded[section] {
            let category = feedsURLs[section]["name"]!
            guard let categoryFeeds = ConfigurationManager.getCategoryFeeds(category) else {
                return 0
            }
            
            return categoryFeeds.count
        }
        
        return 0
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return 70.0
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let headerView = tableView.dequeueReusableHeaderFooterViewWithIdentifier("SectionHeaderView") as! SectionHeaderView
        
        headerView.titleButton.setTitle(feedsURLs[section]["name"], forState: UIControlState.Normal)
        headerView.sectionID = section
        headerView.delegate = self
                
        return headerView
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("MenuCell", forIndexPath: indexPath) as! CustomLabelTableViewCell
        
        // Set the menu background based on the preferred theme
        switch ConfigurationManager.defaultTheme().lowercaseString {
        case "dark":
            cell.backgroundColor = FlatColor.PaleOrange.color()
        case "light":
            cell.backgroundColor = FlatColor.PaleYellow.color()
        default: break
        }

        // Get category and display the category feeds
        if let category = feedsURLs[indexPath.section]["name"] {
            let categoryFeeds = ConfigurationManager.getCategoryFeeds(category)
            cell.label.text = categoryFeeds?[indexPath.row]["name"]
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        
        cell.alpha = 0.0
        cell.transform = CGAffineTransformMakeTranslation(0, 100)
        UIView.animateWithDuration(0.2, delay: 0.02 * Double(indexPath.row), options: [], animations: {
            cell.transform = CGAffineTransformIdentity
            cell.alpha = 1.0
            }, completion: nil)
        isMenuItemShown[indexPath.row] = true
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let category = feedsURLs[indexPath.section]["name"] {
            let categoryFeeds = ConfigurationManager.getCategoryFeeds(category)
            let feed = categoryFeeds![indexPath.row]
            didSelectMenuItem(feed)
        }
    }
    
    // MARK: - Common methods
    
    func didSelectMenuItem(feed:[String: String]) {
        delegate?.didSelectMenuItem(feed)
        UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: UIStatusBarAnimation.Slide)
        performSegueWithIdentifier("unwindToMainScreen", sender: self)
    }

    // MARK: - SectionHeaderDelegate Methods
    
    func didSelectSectionHeaderView(sectionHeaderView: SectionHeaderView) {
        
        if feedsURLs[sectionHeaderView.sectionID]["url"] == "CategoryFeed" {
            
            // Update the status of the category (expanded / collapsed) and reload the section
            isSectionExpanded[sectionHeaderView.sectionID] = isSectionExpanded[sectionHeaderView.sectionID] ? false : true
            tableView.reloadSections(NSIndexSet(index: sectionHeaderView.sectionID), withRowAnimation: UITableViewRowAnimation.None)
            
            return
        }
        
        // For items without sub-menu items, just call didSelectMenuItem to display the feed
        let feed = feedsURLs[sectionHeaderView.sectionID]
        didSelectMenuItem(feed)

    }
    
}

