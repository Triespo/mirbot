//
//  BadgesViewController.swift
//  mirbot
//
//  Created by Miguel Ángel Jareño Escudero on 14/10/2017.
//  Copyright © 2017 Master Móviles. All rights reserved.
//
//  It shows badges obtained and not by the current user.

class BadgeInfo: NSObject {
    var key: String = ""
    var title: String = ""
    var desc: String = ""
    var desc_dis: String = ""
    var image: String = ""
    var image_dis: String = ""
    
    init(key: String, title: String, desc: String, desc_dis: String, image: String, image_dis: String){
        self.key = key
        self.title = title
        self.desc = desc
        self.desc_dis = desc_dis
        self.image = image
        self.image_dis = image_dis
    }
}
class BadgesViewController: UITableViewController{
    
    private var activityView: UIView?
    var previousResponse: String?
    var jsonParser: [String:Any]?
    var navItem: UINavigationItem?
    var badges: [BadgeInfo] = []
    var user_badges: [BadgeInfo] = []
    var image_OK: UIImage?
    var image_dis: UIImage?
    
    init(navItem: UINavigationItem){
        super.init(style: .grouped)
        self.navItem = navItem
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navItem?.title = "Badges"
        parseData(self.previousResponse!)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Obtained (\(user_badges.count))"
        case 1:
            return "Unresolved (\(badges.count))"
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var id = ""
        
        if(indexPath.section == 0){
            id = "Cell \(user_badges[indexPath.row].key)"
        }else if (indexPath.section == 1){
            id = "Cell \(badges[indexPath.row].key)"
        }
        var cell = tableView.dequeueReusableCell(withIdentifier: id)
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: id)
            cell?.selectionStyle = .none
            cell?.imageView?.image = nil
            cell?.accessoryType = .none
        }
        
        switch indexPath.section{
            
            case 0: cell?.textLabel?.text = self.user_badges[indexPath.row].title
                    cell?.detailTextLabel?.text = self.user_badges[indexPath.row].desc
                    cell?.detailTextLabel?.numberOfLines = 2
                    cell?.imageView?.image = self.image_OK
            case 1: cell?.textLabel?.text = self.badges[indexPath.row].title
                    cell?.detailTextLabel?.text = self.badges[indexPath.row].desc_dis
                    cell?.detailTextLabel?.numberOfLines = 2
                    cell?.imageView?.image = self.image_dis
            default:
                print("There's no section")
        }
        
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == 0{
            return user_badges.count
        }else if section == 1 {
            return badges.count
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 62
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
//  Classify from server's response which badges are in one or other section (obtained or not)
    func parseData(_ input: String) {
        let data = input.data(using: String.Encoding.utf8)
        
        do {
            try jsonParser = JSONSerialization.jsonObject(with: data!, options: []) as? [String : Any]
        } catch {
            print("Error JSON")
        }
        
        badges = [BadgeInfo]()
        self.user_badges = []
        
        for (key,value) in jsonParser! {
            if let badges = value as? [[String : String]]{
                for badge:[String:String] in badges{
                    self.badges.append(BadgeInfo(key: badge["key"]!, title: badge["title"]!, desc: badge["description"]!,
                        desc_dis: badge["description_disabled"]!, image: badge["image"]!, image_dis: badge["image_disabled"]!))
                }
            }else if key == "user_badges"{
                if let user = value as? [String]{
                    for obtained in user{
                        if let index = self.badges.index(where: { $0.key == obtained }) {
                            self.user_badges.append(self.badges[index])
                            self.badges.remove(at: index)
                        }
                    }
                }
            }
        }
        do {
            if(self.user_badges.count > 0){
                image_OK = try UIImage(data: Data(contentsOf: URL(string: self.user_badges[0].image)!))
                image_dis = try UIImage(data: Data(contentsOf: URL(string: self.user_badges[0].image_dis)!))
            }
        } catch {
            print("Error getting image obtained")
        }
    }
}
