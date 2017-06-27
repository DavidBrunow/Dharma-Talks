//
//  SettingsTableViewController.swift
//  Mission Dharma
//
//  Created by David Brunow on 3/18/17.
//  Copyright © 2017 David Brunow. All rights reserved.
//

import MessageUI
import UIKit

class SettingsTableViewController: UITableViewController, MFMailComposeViewControllerDelegate
{
    struct Constants
    {
        static let DraftEmailBody = ""
        static let DraftEmailSubject = "Help/Feedback for Dharma Talks Version "
        static let AboutScreenSegueIdentifier = "Show About Screen"
    }
    
    @IBOutlet private var headerView: UIView!
    @IBOutlet private var footerView: UIView!
    @IBOutlet private var appIcon: UIImageView!
    @IBOutlet private var versionLabel: UILabel!
    @IBOutlet private var hideTalksSwitch: UISwitch!
    
    @IBAction func changeHideTalksSetting(sender: UISwitch)
    {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate
        {
            appDelegate.shouldHideListenedToAndDeletedTalks = sender.isOn
        }
    }

    @IBAction func dismiss(_ sender: UIBarButtonItem)
    {
        dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        appIcon.layer.cornerRadius = 8
        headerView.frame.size.width = tableView.frame.width
        footerView.frame.size.width = tableView.frame.width
        
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        {
            versionLabel.text = "Version \(version)"
        }
        
        hideTalksSwitch.isOn = Podcast.sharedInstance.isHidingPlayedAndDeletedEpisodes
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        if section == 0
        {
            return headerView
        }
        
        return super.tableView(tableView, viewForHeaderInSection: section)
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        if section == 0
        {
            return headerView.frame.height
        }
        
        return super.tableView(tableView, heightForHeaderInSection: section)
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView?
    {
        if section == 2
        {
            return footerView
        }
        
        return super.tableView(tableView, viewForFooterInSection: section)
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat
    {
        if section == 2
        {
            return footerView.frame.height
        }
        
        return super.tableView(tableView, heightForFooterInSection: section)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 1
        {
            if indexPath.row == 0
            {
                
            }
            else if indexPath.row == 1
            {
                draftEmail()
            }
            else if indexPath.row == 2
            {
//                performSegue(withIdentifier: Constants.AboutScreenSegueIdentifier, sender: self)
            }
        }
        else if indexPath.section == 2
        {
            if indexPath.row == 0
            {
                openAppStore()
            }
        }
    }
    
    func openAppStore()
    {
        let openAppStoreForRating = "itms-apps://itunes.apple.com/us/app/id807331897?action=write-review&mt=8"
        
        if let url = URL(string: openAppStoreForRating)
        {
            if UIApplication.shared.canOpenURL(url)
            {
                UIApplication.shared.openURL(url)
            }
            else
            {
                print("need error message here!")
            }
        }
    }
    
    func draftEmail()
    {
        let mailComposeController = MFMailComposeViewController()
        mailComposeController.mailComposeDelegate = self
        
        mailComposeController.setToRecipients(["helloDavid@brunow.org"])
        
        let emailBody = Constants.DraftEmailBody
        
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        {
            mailComposeController.setSubject(Constants.DraftEmailSubject + version)
        }
        
        mailComposeController.setMessageBody(emailBody, isHTML: true)
        
        self.present(mailComposeController, animated: true, completion: nil)
    }
    
    // MARK: - MFMailComposeViewControllerDelegate
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?)
    {
        switch result
        {
        case .cancelled:
            print("Mail Cancelled")
        case .saved:
            print("Mail Saved")
        case .sent:
            print("Mail Sent")
        case .failed:
            print("Mail Failed")
        }
        
        dismiss(animated: true, completion: nil)
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
