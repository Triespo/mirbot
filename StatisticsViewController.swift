//
//  StatisticsViewController.swift
//  mirbot
//
//  Created by Miguel Ángel Jareño Escudero on 26/08/2017.
//  Copyright © 2017 Master Móviles. All rights reserved.
//
//  Shows statistics from user's robot and global's robots from all users use this app

class StatisticsViewController: UITableViewController {
    var userStatistics = [Any]()
    var globalStatistics = [Any]()
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }
    
    override init(style: UITableViewStyle) {
        super.init(style: style)
        
        title = "Statistics"
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return userStatistics.count
        }
        else {
            return globalStatistics.count
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
            case 0:
                return "User"
            case 1:
                return "Global"
            default:
                print("No Statistics")
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let CellIdentifier: String = "Cell"
        var cell: UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: CellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: CellIdentifier)
            cell?.selectionStyle = .none
        }
        // Configure the cell...
        var stats: Statistics?
        if indexPath.section == 0 {
            stats = userStatistics[indexPath.row] as? Statistics
        }
        else {
            stats = globalStatistics[indexPath.row] as? Statistics
        }
        cell?.textLabel?.text = stats?.message
        cell?.detailTextLabel?.text = stats?.value
        return cell!
    }
}
