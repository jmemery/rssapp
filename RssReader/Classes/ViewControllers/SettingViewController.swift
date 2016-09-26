//
//  SettingViewController.swift
//  RssReader
//
//  Created by Simon Ng on 5/12/14.
//  Copyright (c) 2014 AppCoda Limited. All rights reserved.
//

import UIKit
import MessageUI

class SettingViewController: UITableViewController, MFMailComposeViewControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func sendUsFeedback() {
        if MFMailComposeViewController.canSendMail() {
            let composer = MFMailComposeViewController()
            
            composer.mailComposeDelegate = self

            // Uncomment if you need to set a default email
            // composer.setToRecipients(["<your email>"])
            //composer.navigationBar.tintColor = UIColor.whiteColor()
            
            presentViewController(composer, animated: true, completion: {
                switch ConfigurationManager.defaultTheme() {
                    case "dark":
                        UIApplication.sharedApplication().setStatusBarStyle(.LightContent, animated: false)
                    case "light":
                        UIApplication.sharedApplication().setStatusBarStyle(.Default, animated: false)
                    default:
                        break
                }
                
            })
        }
    }
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        
        switch result {
        case MFMailComposeResult.Cancelled:
            print("Mail cancelled")
            
        case MFMailComposeResult.Saved:
            print("Mail saved")
            
        case MFMailComposeResult.Sent:
            print("Mail sent")
            
        case MFMailComposeResult.Failed:
            print("Failed to send mail: \(error!.localizedDescription)")
        }
        
        // Dismiss the Mail interface
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 75.0
    }
    
    @IBAction func dismissController() {
        // Dismiss the current interface
        dismissViewControllerAnimated(true, completion: nil)

    }
    
    // MARK: - Table view data source

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if (indexPath.row == 0) {
            sendUsFeedback()
        }
    }
    

}
