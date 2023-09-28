//
//  DetailViewController.swift
//  mirbot
//
//  Created by Miguel Ángel Jareño Escudero on 19/09/2017.
//  Copyright © 2017 Master Móviles. All rights reserved.
//
//  Get different definitions from lemma selected by user.

import Alamofire

class DetailViewController: UITableViewController, ConnectionDelegate {
    
    var responseDict = [AnyHashable: Any]()
    var lemma: String = ""
    var oldClassifiedImage: ClassifiedImage?
    var delegate: Any?
    
    var listContent = [String]()
    var listContent2 = [String]()
    var listLemmas = [String]()
    var selectedClass: String = ""
    var newClassifiedImage: ClassifiedImage?
    var theConnection: Connection?
    var finalVC: FinalViewController?
    var showFooter = Bool()
    var spinnerView: UIView?
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UI_USER_INTERFACE_IDIOM() == .pad {
            return .all
        }
        else {
            return .portrait
        }
    }
    
    deinit {
        theConnection?.delegate = nil
        theConnection = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = lemma
        // Set done button
        let nextButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.sendData))
        navigationItem.rightBarButtonItem = nextButton
        /*if UI_USER_INTERFACE_IDIOM() == .pad {
            ((delegate) as? iPadDictViewController)?.navigationItem?.rightBarButtonItem?.isEnabled = false
        }
        else {*/
        navigationItem.rightBarButtonItem?.isEnabled = false
        // Show spinner
        let topView: UIView? = navigationController?.topViewController?.view
        spinnerView = ActivityViewController.showActivityView(topView!)
        //Fill definition and idClass into ListContent
        let myGroup = DispatchGroup()
        listContent = [String]()
        listContent2 = [String]()
        getObjectInfo(group: myGroup)
        myGroup.notify(queue: .main) {
            let footer = UIView(frame: CGRect.zero)
            self.tableView.tableFooterView = footer
            self.tableView.reloadData()
            // TableView options
            self.tableView.isScrollEnabled = true
            self.tableView.backgroundColor = UIColor.lightGray
            ActivityViewController.hideActivityView(self.spinnerView!)
        }
    }
    
    @objc func sendData(_ sender: Any) {
        navigationItem.rightBarButtonItem?.isEnabled = false
        newClassifiedImage = ClassifiedImage()
        newClassifiedImage?.classid = listContent2[tableView.indexPathForSelectedRow!.row]
        newClassifiedImage?.lemma = listLemmas[tableView.indexPathForSelectedRow!.row]
        newClassifiedImage?.definition = listContent[(tableView.indexPathForSelectedRow?.row)!]
        newClassifiedImage?.score = -1 as NSNumber
        let ident: String = responseDict["imageID"] as? String ?? ""
        let userId = UserDefaults.standard.object(forKey: "userid") as! String
        let urlString: String = Test.getURL()
        let PHPparams: String = "user/\(userId)/images/\(ident)/confirm"
        theConnection = Connection()
        theConnection?.delegate = self
        let params: Parameters = ["class":"\(newClassifiedImage!.classid)"]
        theConnection?.startV1(urlString, withPHPParams: PHPparams, method: "POST", params: params, headers: [:])
    }
    
//  Get all the information from lemma selected in DictViewControler from remote dictionary
    func getObjectInfo(group: DispatchGroup) {
        
        var PHPparams = ""
        let urlString: String = Test.getURL()
        if(lemma.contains(" ")){
            let lemmaURL = lemma.replacingOccurrences(of: " ", with: "+")
            PHPparams = "wordnet/lemma/\(lemmaURL)"
        }else{
            PHPparams = "wordnet/lemma/\(lemma)"
        }
        group.enter()
        Alamofire.request(URL(string: urlString+PHPparams)!, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: nil).responseJSON(completionHandler: {response in
            
            if response.result.isSuccess{
                
                do{
                    let jsonParser = try JSONSerialization.jsonObject(with: response.data!, options: []) as? NSArray
                    if let array = jsonParser{
                        for obj in array {
                            if let dict = obj as? NSDictionary {
                                self.listLemmas.append(self.lemma)
                                self.listContent.append(Utilities.upperFirstLetter(dict.value(forKey: "definition") as! String))
                                self.listContent2.append(dict.value(forKey: "class_id") as! String)
                            }
                        }
                        group.leave()
                    }
                }catch{
                    print("Error Json getting definitions DetailViewController")
                }
            } else {
                self.theConnection?.presentAlertWithTitle(title: kErrorConnection, message: (response.result.error?.localizedDescription)!)
            }
        })
    }
    
    // MARK: Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        // Return the number of sections.
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows in the section.
        return listContent.count
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = UIColor.white
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let kCellID: String = "cellID"
        var cell: UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: kCellID)
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: kCellID)
            cell?.textLabel?.font = UIFont.systemFont(ofSize: 20)
            cell?.textLabel?.numberOfLines = 0
        }
        cell?.textLabel?.text = listContent[indexPath.row]
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let titleString: String = listContent[indexPath.row]
        // iOS7
        let rect: CGRect = titleString.boundingRect(with: CGSize(width: view.bounds.size.width - 20, height: CGFloat(MAXFLOAT)), options: .usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 20)], context: nil)
        return rect.size.height + 10
    }
    
    // MARK: -
    // MARK: Table view delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        /*if UI_USER_INTERFACE_IDIOM() == .pad {
            ((delegate) as? iPadDictViewController)?.navigationItem?.rightBarButtonItem?.isEnabled = true
        }
        else {*/
        navigationItem.rightBarButtonItem?.isEnabled = true
        //}
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if UI_USER_INTERFACE_IDIOM() == .pad {
            return nil
        }
        else {
            return "Select definition and press Done"
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if UI_USER_INTERFACE_IDIOM() == .pad {
            return lemma
        }
        else {
            return nil
        }
    }
    
    // MARK: -
    // MARK: ConnectionDelegate
    func didFinishConnection() {
        if self.theConnection?.receivedData != nil{
            // Hide spinner
            ActivityViewController.hideActivityView(spinnerView!)
            //let response = String(data: (theConnection?.receivedData)!, encoding: String.Encoding.utf8)
            finalVC = FinalViewController(oldClassifiedImage: oldClassifiedImage!, withNewClassifiedImage: newClassifiedImage!, withIdent: responseDict["imageID"] as! String, withReceivedData: theConnection!.receivedData!, withLabelOfFirstObject: "")
            navigationController?.pushViewController(finalVC!, animated: true)
        }
    }
    
    func didFailedConnection() {
        // Hide spinner
        ActivityViewController.hideActivityView(spinnerView!)
    }
}
