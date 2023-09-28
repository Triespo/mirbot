//
//  TreeViewController.swift
//  mirbot
//
//  Created by Miguel Ángel Jareño Escudero on 26/08/2017.
//  Copyright © 2017 Master Móviles. All rights reserved.
//
//  Shows definition of the lemma, synonims and path of that word

import Alamofire

class TreeViewController: UITableViewController{
    
    var hierarchyArray = [Any]()
    var thelemma: String = ""
    var definition: String = ""
    var synonyms: String = ""
    let generalGroup = DispatchGroup()
    let myGroup = DispatchGroup()
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }
    
    init(id classid: String, withLemma lemma: String) {
        super.init(style: .grouped)
        
        // Get hierarchy
        let hierarchy = WordnetHierarchy(id: classid, delegate: self)
        self.generalGroup.notify(queue: .main){
            self.hierarchyArray = hierarchy.hierarchyArray
            self.thelemma = lemma
            self.performQuery(classid: classid)
            self.myGroup.notify(queue: .main) {
                if (self.synonyms == "") {
                    self.synonyms += kNoSynonyms
                }
                self.tableView.dataSource = self
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View lifecycle
    // Implement loadView to create a view hierarchy programmatically, without using a nib.
    override func loadView() {
        super.loadView()
        tableView.separatorStyle = .none
        tableView.separatorColor = UIColor.clear
        self.myGroup.enter()
        self.myGroup.notify(queue: .main) {
            self.title = self.thelemma
            var navBar: UINavigationBar?
            if UI_USER_INTERFACE_IDIOM() == .pad {
                navBar = UINavigationBar(frame: CGRect(x: 0, y: 0, width: 320, height: kToolbarHeight))
            }
            else {
                navBar = UINavigationBar(frame: CGRect(x: 0, y: 0, width: 320, height: kToolbarHeightModal))
            }
            let item = UINavigationItem(title: self.title!)
            item.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.getBackController))
            navBar?.items = [item]
            self.tableView.tableHeaderView = navBar
        }
    }
    
    @objc func getBackController(){
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIApplication.shared.isStatusBarHidden = true
    }
    
    // Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.reloadData()
        tableView.setNeedsDisplay()
        tableView.setNeedsLayout()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        // Solved resize problem with rotation
        tableView.reloadData()
        tableView.setNeedsDisplay()
        tableView.setNeedsLayout()
    }
    
    func performQuery(classid: String){
        if Int(classid)! > -1{
            let urlString: String = Test.getURL()
            let PHPparams = "wordnet/class/\(classid)"
            Alamofire.request(URL(string: urlString+PHPparams)!, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: nil).responseJSON(completionHandler: {response in
                
                if response.result.isSuccess{
                    do{
                        let jsonParser = try JSONSerialization.jsonObject(with: response.data!, options: []) as? [String : Any]
                        let definition = jsonParser!["definition"] as! String
                        self.definition = Utilities.upperFirstLetter(definition)
                        self.synonyms = jsonParser!["synonyms"] as! String
                    }catch{
                        print("Error Json getting definition in SendViewController")
                    }
                    self.myGroup.leave()
                } else {
                    self.presentAlertWithTitle(title: kErrorConnection, message: (response.result.error?.localizedDescription)!)
                }
            })
        }
    }
    
    // MARK: UITableView data source and delegate methods
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = UIColor.white
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        else if section == 1 {
            return 1
        }
        else {
            return hierarchyArray.count * 2 - 1
        }
        
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let kCellID: String = "cellID"
        var cell: UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: kCellID)
        // Class names at: http://wordnet.princeton.edu/man/lexnames.5WN.html
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: kCellID)
            cell?.accessoryType = .none
            cell?.selectionStyle = .none
            cell?.textLabel?.font = UIFont.systemFont(ofSize: 16)
            cell?.detailTextLabel?.font = UIFont.systemFont(ofSize: 14)
        }
        cell?.textLabel?.numberOfLines = 0
        cell?.detailTextLabel?.numberOfLines = 0
        if indexPath.section == 0 {
            cell?.textLabel?.text = definition
            cell?.detailTextLabel?.text = nil
        }
        else if indexPath.section == 1 {
            cell?.textLabel?.text = synonyms
            cell?.detailTextLabel?.text = nil
        }
        else if indexPath.section == 2 {
            if indexPath.row % 2 == 0 {
                let obj = hierarchyArray[indexPath.row / 2] as? CategoryInfo
                cell?.textLabel?.text = Utilities.upperFirstLetter((obj?.lemma)!)
                cell?.detailTextLabel?.text = Utilities.upperFirstLetter((obj?.definition)!)
                if (cell?.detailTextLabel?.text == cell?.textLabel?.text) {
                    cell?.detailTextLabel?.text = nil
                }
            }
            else {
                cell?.textLabel?.text = "     ↓"
                cell?.detailTextLabel?.text = nil
            }
        }
        
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var width: Float = (Float(self.tableView.bounds.size.width / 16.0 * 14.0))
        if UI_USER_INTERFACE_IDIOM() == .pad {
            width -= 20
        }
        if indexPath.section == 0 {
            return definition.boundingRect(with: CGSize(width: CGFloat(width), height: CGFloat(MAXFLOAT)), options: .usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 16)], context: nil).size.height + 10
        }
        else if indexPath.section == 1 {
            return synonyms.boundingRect(with: CGSize(width: CGFloat(width), height: CGFloat(MAXFLOAT)), options: .usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 16)], context: nil).size.height + 10
        }
        else {
            if indexPath.row % 2 == 0 {
                let obj = hierarchyArray[indexPath.row / 2] as? CategoryInfo ?? CategoryInfo()
                let titleString: String = obj.lemma
                let detailString: String = obj.definition
                let titleSize = titleString.boundingRect(with: CGSize(width: CGFloat(width), height: CGFloat(MAXFLOAT)), options: .usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 16)], context: nil).size
                let detailSize = detailString.boundingRect(with: CGSize(width: CGFloat(width), height: CGFloat(MAXFLOAT)), options: .usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 14)], context: nil).size
                return titleSize.height + detailSize.height + 10
            }
            else {
                let titleSize = "     ↓".boundingRect(with: CGSize(width: CGFloat(width), height: CGFloat(MAXFLOAT)), options: .usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 16)], context: nil).size
                return titleSize.height
            }
        }
        
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionHeader = UILabel(frame: CGRect.zero)
        sectionHeader.font = UIFont.boldSystemFont(ofSize: 17)
        switch section {
        case 0:
            sectionHeader.text = "  Definition"
        case 1:
            sectionHeader.text = "  Synonyms"
        case 2:
            sectionHeader.text = "  Hierarchy"
        default:
            print("Error view header section")
        }
        
        return sectionHeader
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
            case 0:
                return "Definition"
            case 1:
                return "Synonyms"
            case 2:
                return "Hierarchy"
            default:
                print("Error title header section")
        }
        
        return nil
    }
}

extension TreeViewController{
    func presentAlertWithTitle(title: String, message : String){
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let closeAction = UIAlertAction(title: "Close", style: .default)
        alertController.addAction(closeAction)
        var topController = UIApplication.shared.keyWindow!.rootViewController
        
        while ((topController?.presentedViewController) != nil) {
            topController = topController?.presentedViewController;
        }
        topController?.present(alertController, animated:true, completion:nil)
    }
}
