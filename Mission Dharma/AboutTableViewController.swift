//
//  AboutTableViewController.swift
//  Mission Dharma
//
//  Created by David Brunow on 3/19/17.
//  Copyright © 2017 David Brunow. All rights reserved.
//

import UIKit

class AboutTableViewController: UITableViewController
{
    @IBOutlet private var headerView: UIView!
    @IBOutlet private var headerImageView: UIImageView!

    override func viewDidLoad()
    {
        super.viewDidLoad()

        headerImageView.layer.cornerRadius = headerImageView.bounds.height / 2
        title = "About"
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        tableView.deselectRow(at: indexPath, animated: false)
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
