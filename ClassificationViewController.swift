//
//  ClassificationViewController.swift
//  mirbot
//
//  Created by Miguel Ángel Jareño Escudero on 14/10/2017.
//  Copyright © 2017 Master Móviles. All rights reserved.
//
//  Clasification of top 10 robots in IQ. Also reflects position of user.

class RobotInfo: NSObject {
    var rank: Int = 0
    var robotIQ: Int = 0
    var robotName: String = ""
    
    init(rank: Int, robotIQ: Int, robotName: String){
        self.rank = rank
        self.robotIQ = robotIQ
        self.robotName = robotName
    }
}
class ClassificationViewController: UITableViewController{
    
    private var activityView: UIView?
    var previousResponse: String?
    var jsonParser: [String:Any]?
    var robots:[RobotInfo] = []
    var navItem: UINavigationItem?
    
    init(navItem: UINavigationItem){
        super.init(style: .grouped)
        self.navItem = navItem
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navItem?.title = "Classification"
        parseData(self.previousResponse!)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Top"
        case 1:
            return "User"
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let id = "Cell \(robots[indexPath.row].rank)"
        var cell = tableView.dequeueReusableCell(withIdentifier: id)
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: id)
            cell?.selectionStyle = .none
            cell?.imageView?.image = nil
            cell?.accessoryType = .none
        }
        
//      Depend of digits it will tabulate one or another form. Only for esthetic.
        var tabulations = "", tabulationsUser = ""
        if numOfDigits(number: robots[robots.count-1].rank) > 2{
            tabulations = "\t\t"
            tabulationsUser = "\t"
        }else{
            tabulations = "\t"
            tabulationsUser = tabulations
        }
        
        switch indexPath.section{
            
            case 0: cell?.textLabel?.text = "\(robots[indexPath.row].rank)\(tabulations)\(robots[indexPath.row].robotName)"
                    cell?.detailTextLabel?.text = "\(tabulations)\(robots[indexPath.row].robotIQ) IQ"
            case 1: cell?.textLabel?.text = "\(robots[robots.count-1].rank)\(tabulationsUser)\(robots[robots.count-1].robotName)"
                    cell?.detailTextLabel?.text = "\(tabulations)\(robots[robots.count-1].robotIQ) IQ"
            default:
                    print("There's no section")
        }
        
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == 0{
            return robots.count-1
        }else if section == 1 {
            return 1
        }
        return 0
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func parseData(_ input: String) {
        let data = input.data(using: String.Encoding.utf8)
        
        do {
            try jsonParser = JSONSerialization.jsonObject(with: data!, options: []) as? [String : Any]
        } catch {
            print("Error JSON")
        }

        robots = [RobotInfo]()
        
        for (key,value) in jsonParser! {
            if let top = value as? [[String : Any]]{
                for robot:[String:Any] in top{
                    robots.append(RobotInfo(rank: Int(robot["rank"] as! String)!,robotIQ: Int(robot["robot_iq"] as! String)!, robotName: (robot["robot_name"] as? String)!))
                }
            }else if key == "user"{
                if let user = value as? [String:Any]{
                    robots.append(RobotInfo(rank: Int(user["rank"] as! String)!,robotIQ: Int(user["robot_iq"] as! String)!, robotName: (user["robot_name"] as? String)!))
                }
            }
        }
    }
    
    func numOfDigits(number: Int?) -> Int{
        if number! < 10 {
            return 1
        }
        else {
            return 1 + numOfDigits(number:)(number!/10)
        }
    }
}
