//
//  AlternativesViewController.swift
//  mirbot
//
//  Created by Miguel Ángel Jareño Escudero on 08/09/2017.
//  Copyright © 2017 Master Móviles. All rights reserved.
//
// It shows other lemmas than could be the one user want when user denies the first lemma proposed by robot

import Alamofire

class AlternativesViewController: UITableViewController, ConnectionDelegate {
    var responseDict = [AnyHashable: Any]()
    var classifiedImages = [Any]()
    var listContentReceived = [Any]()
    var oldClassifiedImage: ClassifiedImage?
    var infoView: CustomTextView?
    var listContentDisplayed = [Any]()
    var myFooterView: UIView?
    var myHeaderView: UIView?
    var spinnerView: UIView?
    var selectedClass: String = ""
    var theConnection: Connection?
    var finalVC: FinalViewController?
    var shouldspeak: Bool = false
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        
        if UI_USER_INTERFACE_IDIOM() == .pad {
            return .all
        }
        else {
            return .portrait
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Add message (header and footer button)
        if UI_USER_INTERFACE_IDIOM() != .pad {
            addHeader()
        }
        if shouldspeak {
            Utilities.startspeech(kAlternativesMessage)
            shouldspeak = false
        }
        addFooterButton()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Set done button
        let nextButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.sendData))
        navigationItem.rightBarButtonItem = nextButton
        navigationItem.rightBarButtonItem?.isEnabled = false
        title = "Alternatives"
        // Remove first element from the displayed list
        listContentDisplayed = listContentReceived
        listContentDisplayed.remove(at: 0)
        // Load data
        tableView.reloadData()
        // Global tableView options
        tableView.isScrollEnabled = true
        tableView.dataSource = self
        shouldspeak = true
        tableView.backgroundColor = UIColor.white
    }
    
    // This solved resize problem with rotation
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        let selectedIndex: IndexPath? = tableView.indexPathForSelectedRow
        tableView.reloadData()
        tableView.selectRow(at: selectedIndex, animated: false, scrollPosition: .none)
    }
    
    deinit {
        theConnection?.delegate = nil
        theConnection = nil
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        Utilities.stopspeech()
    }
    
    @objc func sendData(_ sender: Any) {
        navigationItem.rightBarButtonItem?.isEnabled = false
        launchDictViewController()
    }
    
//  Confirmed one of the alternative lemmas from user to the server.
    func launchDictViewController() {
        let selected = listContentDisplayed[(tableView.indexPathForSelectedRow?.row)!] as? ClassifiedImage
        let ident: String = self.responseDict["imageID"] as! String
        let userId = UserDefaults.standard.object(forKey: "userid") as! String
        let urlString: String = Test.getURL()
        let PHPparams: String = "user/\(userId)/images/\(ident)/confirm"
        theConnection = Connection()
        theConnection?.delegate = self
        let params: Parameters = ["class":"\(selected!.classid)"]
        theConnection?.startV1(urlString, withPHPParams: PHPparams, method: "POST", params: params, headers: [:])
        // Show spinner
        let topView: UIView? = navigationController?.topViewController?.view
        spinnerView = ActivityViewController.showActivityView(topView!)
    }

    func addHeader() {
        var rectFrameResponse: CGRect
        rectFrameResponse = CGRect(x: 10, y: 10, width: tableView.frame.size.width - 20, height: 150)
        myHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: 75))
        infoView = CustomTextView(frame: rectFrameResponse, withText: kAlternativesMessage, withParentView: myHeaderView!)
        tableView.sizeToFit()
        tableView.tableHeaderView = myHeaderView
        tableView?.tableHeaderView?.sizeToFit()
    }
    
    func addFooterButton() {
        let btn = UIButton(type: .custom)
        if UI_USER_INTERFACE_IDIOM() == .pad {
            btn.frame = CGRect(x: 30, y: 15, width: tableView.bounds.size.width - 60, height: 40)
        }
        else {
            btn.frame = CGRect(x: 10, y: -5, width: tableView.bounds.size.width - 20, height: 40)
        }
        btn.addTarget(self, action: #selector(self.launchDictionaryView), for: .touchUpInside)
        btn.setTitle("It is not in this list", for: .normal)
        btn.backgroundColor = UIColor.white
        btn.setTitleColor(UIColor.red, for: .normal)
        btn.layer.borderColor = UIColor.gray.cgColor
        btn.layer.cornerRadius = 5.0
        btn.layer.borderWidth = 0.75
        btn.autoresizingMask = .flexibleWidth
        myFooterView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 70))
        myFooterView?.backgroundColor = UIColor.clear
        myFooterView?.addSubview(btn)
        // note this will override UITableView's 'sectionFooterHeight' property
        tableView.tableFooterView = myFooterView
    }
    
    @objc func launchDictionaryView() {
        let theDictViewController = DictViewController()
        theDictViewController.responseDict = responseDict
        theDictViewController.oldClassifiedImage = oldClassifiedImage
        navigationController?.pushViewController(theDictViewController, animated: true)
        /*if UI_USER_INTERFACE_IDIOM() == .pad {
            let theiPadDictViewController = iPadDictViewController(dictController: theDictViewController)
            navigationController?.pushViewController(theiPadDictViewController as? UIViewController ?? UIViewController(), animated: true)
        }
        else {
            navigationController?.pushViewController(theDictViewController as? UIViewController ?? UIViewController(), animated: true)
        }*/
    }
    
    // MARK: ConnectionDelegate
    func didFinishConnection() {
        if self.theConnection?.receivedData != nil{
            // Hide spinner
            ActivityViewController.hideActivityView(spinnerView!)
            finalVC = FinalViewController(oldClassifiedImage: oldClassifiedImage!, withNewClassifiedImage: listContentDisplayed[tableView.indexPathForSelectedRow!.row] as! ClassifiedImage, withIdent: responseDict["imageID"] as! String, withReceivedData: theConnection!.receivedData!, withLabelOfFirstObject: "")
            navigationController?.pushViewController(finalVC!, animated: true)
        }
    }
    
    func didFailedConnection() {
        // Hide spinner
        ActivityViewController.hideActivityView(spinnerView!)
    }
    
    // MARK: Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        // Return the number of sections.
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows in the section.
        return listContentDisplayed.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let kCellID: String = "cellID"
        var cell: UITableViewCell?
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: kCellID)
            cell?.textLabel?.font = UIFont.systemFont(ofSize: 18)
            cell?.detailTextLabel?.font = UIFont.systemFont(ofSize: 14)
            cell?.textLabel?.numberOfLines = 0
            cell?.detailTextLabel?.numberOfLines = 0
        }
        let im = listContentDisplayed[indexPath.row] as? ClassifiedImage
        cell?.textLabel?.text = Utilities.upperFirstLetter((im?.lemma)!)
        let definition: String = Utilities.upperFirstLetter((im?.definition)!)
        if im?.definition != nil {
            cell?.detailTextLabel?.text = definition
        }
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var width: Float = (Float(self.tableView.bounds.size.width / 16.0 * 14.0))
        if UI_USER_INTERFACE_IDIOM() == .pad {
            width -= 20
        }
        let im = listContentDisplayed[indexPath.row] as? ClassifiedImage
        // iOS11
        let rect: CGRect = (im?.lemma.boundingRect(with: CGSize(width: CGFloat(width), height: CGFloat(MAXFLOAT)), options: .usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 18)], context: nil))!
        let titleSize: CGSize = rect.size
        let rect2: CGRect = (im?.definition.boundingRect(with: CGSize(width: CGFloat(width), height: CGFloat(MAXFLOAT)), options: .usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 14)], context: nil))!
        let detailSize: CGSize = rect2.size
        return titleSize.height + detailSize.height + 5
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        navigationItem.rightBarButtonItem?.isEnabled = true
    }
}
