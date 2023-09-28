//
//  SetupViewController.swift
//  mirbot
//
//  Created by Master Móviles on 16/08/2017.
//  Copyright © 2017 Master Móviles. All rights reserved.
//
//  Options where user can customize robot's name, change server, robot can speak or not and use only its images

import Alamofire

class SetupViewController: UITableViewController,ConnectionDelegate, UITextFieldDelegate {
    
    var theConnection: Connection?
    var txtField: UITextField?
    
    // MARK: - View lifecycle
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UI_USER_INTERFACE_IDIOM() == .pad {
            return .all
        }
        else {
            return .portrait
        }
    }
    
    @objc func dismiss(_ sender: Any) {
        UserDefaults.standard.synchronize()
        dismiss(animated: true, completion: nil)
    }
    
    init() {
        super.init(style: .grouped)
        title = "Settings"
        tableView.isScrollEnabled = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if UI_USER_INTERFACE_IDIOM() != .pad {
            UIApplication.shared.isStatusBarHidden = false
        }
        if(UserDefaults.standard.string(forKey: "robotName") == nil){
            sendServerInfo(method: "GET")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.isStatusBarHidden = true
    }
    
    @objc func ona(_ sender: UISwitch) {
        var value: String
        if sender.isOn {
            value = "true"
        }
        else {
            value = "false"
        }
        switch sender.tag {
        case 0:
            UserDefaults.standard.set(value, forKey: "onlyuser")
        case -2:
            UserDefaults.standard.set(value, forKey: "speech")
            //#if isTest
        case -1:
            UserDefaults.standard.set(value, forKey: "test")
            //#endif
        default:
            break
        }
        
    }
    
    override func loadView() {
        super.loadView()
        var navBar: UINavigationBar?
        if UI_USER_INTERFACE_IDIOM() == .pad {
            navBar = UINavigationBar(frame: CGRect(x: 0, y: 0, width: 320, height: kToolbarHeight))
        }
        else {
            navBar = UINavigationBar(frame: CGRect(x: 0, y: 0, width: 320, height: kToolbarHeightModal))
        }
        let item = UINavigationItem(title: title!)
        item.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.dismiss))
        navBar?.items = [item]
        tableView.tableHeaderView = navBar
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    @objc func keyboardWillHide(_ sender: Any) {
        sendServerInfo(method: "PUT")
    }
    
    // MARK: -
    // MARK: Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        if isTest{
            return 4
        }
        return 3
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
            case 0:
                return 1
            case 1:
                return 1
            case 2:
                return 1
            //#if isTest
            case 3:
                return 1
            //#endif
            default:
                return 0
        }
    }
            
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
            case 0:
                return "Robot"
            case 1:
                return "Speech"
            case 2:
                return "General"
            //#if isTest
            case 3:
                return "Web redirection"
            //#endif
            default:
                return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let CellIdentifier: String = "\(String(describing: indexPath[0])):\(String(describing: indexPath[1]))"
        var cell: UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: CellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: CellIdentifier)
            cell?.selectionStyle = .none
            let u = UISwitch(frame: CGRect(x: 1, y: 1, width: 20, height: 20))
            u.addTarget(self, action: #selector(self.ona), for: .valueChanged)
            switch indexPath[0] {
            case 0: if indexPath[1] == 0 {
                        txtField = UITextField(frame: CGRect(x: 18, y: 0, width: (cell?.frame.size.width)!, height: (cell?.frame.size.height)!));
                        txtField?.text = UserDefaults.standard.object(forKey: "robotName") as? String
                        txtField?.inputView?.isUserInteractionEnabled = true
                        txtField?.keyboardType = .default
                        txtField?.delegate = self
                        cell?.contentView.addSubview(txtField!)
                    }
            case 1:
                    if indexPath[1] == 0 {
                        u.isOn = UserDefaults.standard.bool(forKey: "speech")
                        u.tag = -2
                        cell?.textLabel?.text = "Speech enabled"
                        cell?.accessoryView = u
                    }
            case 2:
                    switch indexPath[1] {
                    case 0:
                            u.isOn = UserDefaults.standard.bool(forKey: "onlyuser")
                            u.tag = 0
                            cell?.textLabel?.text = "Only my classes"
                            cell?.accessoryView = u
                        default:
                            break
                    }
                
                //#if isTest
            case 3:
                    if indexPath[1] == 0 {
                        u.isOn = UserDefaults.standard.bool(forKey: "test")
                        u.tag = -1
                        cell?.textLabel?.text = "Test"
                        cell?.accessoryView = u
                    }
                //#endif
                default:
                    print("Error settings")
            }
        }
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 0{
            return "Push robot's name for customing"
        }
        else if section == 1 {
            return "This option makes your robot to talk"
        }
        else if section == 2 {
            return "If enabled, classification is done considering only your images. Otherwise, images from all users will be considered."
        }
        return nil
    }
    
    func sendServerInfo(method: String){
        let userid = UserDefaults.standard.object(forKey: "userid") as? String
        theConnection = Connection()
        theConnection?.delegate = self
        let urlString: String = Test.getURL()
        let PHPparams = "user/\(userid!)/robot"
        if(method == "GET"){
            theConnection?.startV1(urlString, withPHPParams: PHPparams,method: method)
        }else if(method == "PUT"){
            let params: Parameters = ["name":"\(self.txtField!.text!)"]
            theConnection?.startV1(urlString, withPHPParams: PHPparams, method: "PUT", params: params, headers: [:])
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
    
    func didFinishConnection() {
        if self.theConnection?.receivedData != nil{
            let response = String(data: (theConnection?.receivedData)!, encoding: String.Encoding.utf8)
            let data = response?.data(using: String.Encoding.utf8)
            do {
                if(String(response!.prefix(1))=="{" && String(response!.suffix(1))=="}"){
                    let jsonParser = try JSONSerialization.jsonObject(with: data!, options: []) as? [String : Any]
                    if(jsonParser!["robot_name"] != nil){
                        UserDefaults.standard.set(jsonParser!["robot_name"] as! String, forKey: "robotName")
                    }
                }else{
                    UserDefaults.standard.set(txtField?.text, forKey: "robotName")
                }
            } catch {
                print("Error JSON")
            }
        }
    }
    
    func didFailedConnection() {
    }
}
