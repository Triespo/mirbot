//
//  UserInfoMain.swift
//  mirbot
//
//  Created by Master Móviles on 21/08/2017.
//  Copyright © 2017 Master Móviles. All rights reserved.
//
//  Send to the gallery all data from server customizing new data to old

import Alamofire

class UserInfoMain: UITableViewController, ConnectionDelegate, FGalleryViewControllerDelegate{
    
    var userImages = NSMutableDictionary()
    var catInfo = [Any]()
    var userStatistics = NSMutableDictionary()
    var globalStatistics = NSMutableDictionary()
    var networkGallery: FGalleryViewController?
    var networkImages = NSMutableArray()
    var delegate: Any?
    var theConnection: Connection?
    var currentIndex: Int = 0
    var currentOperation: Int = 0
    var spinnerView: UIView?

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }
    
    deinit {
        theConnection?.delegate = nil
        theConnection = nil
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        navigationController?.isNavigationBarHidden = false
    }
    
    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "My pictures"
        UIApplication.shared.isStatusBarHidden = false
        let stats = UIBarButtonItem(title: "Stats", style: .plain, target: self, action: #selector(self.showStats))
        navigationItem.rightBarButtonItem = stats
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        // Return the number of sections.
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows in the section.
        return userImages.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let CellIdentifier: String = "Cell"
        var cell: UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: CellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .value1, reuseIdentifier: CellIdentifier)
        }
        let c = catInfo[indexPath.row] as? CategoryInfo
        let lemma: String = Utilities.upperFirstLetter(c!.lemma)
        cell?.textLabel?.text = lemma
        cell?.detailTextLabel?.text = "\(String(describing: c!.n!))"
        cell?.textLabel?.font = UIFont.systemFont(ofSize: 20)
        cell?.accessoryType = .disclosureIndicator
        return cell!
    }
    
    func deleteImageOnServer() {
        let index: Int = (networkGallery?.currentIndex)!
        let ri = (networkImages.object(at: index)) as! RemoteImage
        let imageId: String? = ri.imageid
        let userid: String? = UserDefaults.standard.object(forKey: "userid") as? String
        let urlString: String = Test.getURL()
        let PHPparams: String = "user/\(userid!)/images/\(imageId!)"
        let topView: UIView? = navigationController?.topViewController?.view
        spinnerView = ActivityViewController.showActivityView(topView!)
        currentOperation = 0
        theConnection = Connection()
        theConnection?.delegate = self
        theConnection?.startV1(urlString, withPHPParams: PHPparams, method: "DELETE", params: [:], headers: [:])
    }
    
    @objc func deleteImage(_ sender: Any) {
        let alertDelete = UIAlertController(title: "Delete", message: "Do you want to delete this picture?", preferredStyle: .alert)
        let ok = UIAlertAction(title: "YES", style: .default, handler: {(_ action: UIAlertAction) -> Void in
            self.deleteImageOnServer()
        })
        let cancel = UIAlertAction(title: "NO", style: .default, handler: {(_ action: UIAlertAction) -> Void in
            alertDelete.dismiss(animated: true)
        })
        alertDelete.addAction(ok)
        alertDelete.addAction(cancel)
        parent?.present(alertDelete, animated: true)
    }
    
    //v1.1
    func updateLabel(_ ri: RemoteImage, withLabel label: String) {
        
        // Update label at the server
        var labelString: String = label.replacingOccurrences(of: "\"", with: "\\\"")
        labelString = labelString.replacingOccurrences(of: "\'", with: "\\\'")
        labelString = labelString.replacingOccurrences(of: "<", with: " ")
        // < and > are directly removed
        labelString = labelString.replacingOccurrences(of: ">", with: " ")
        labelString = labelString.replacingOccurrences(of: "&", with: " and ")
        // Start connection
        let userId = UserDefaults.standard.object(forKey: "userid") as! String
        let urlString: String = Test.getURL()
        let PHPparams: String = "user/\(userId)/images/\(ri.imageid)/label"
        theConnection = Connection()
        theConnection?.delegate = self
        let params: Parameters = ["label":"\(labelString)"]
        // Show spinner
        let topView: UIView? = navigationController?.topViewController?.view
        spinnerView = ActivityViewController.showActivityView(topView!)
        currentOperation = 1
        // Local update
        ri.label = label
        theConnection?.startV1(urlString, withPHPParams: PHPparams, method: "PUT", params: params, headers: [:])
    }
    
    // v2.0
    @objc func updateLabelAlert(_ sender: Any) {
        let alertUpdate = UIAlertController(title: "Change label", message: "You can optionally add a label to identify this object", preferredStyle: .alert)
        let ok = UIAlertAction(title: "Ok", style: .default, handler: {(_ action: UIAlertAction) -> Void in
            self.updatedLabel((alertUpdate.textFields?.first?.text!)!)
        })
        let cancel = UIAlertAction(title: "Cancel", style: .default, handler: {(_ action: UIAlertAction) -> Void in
            alertUpdate.dismiss(animated: true)
        })
        alertUpdate.addAction(ok)
        alertUpdate.addAction(cancel)
        alertUpdate.addTextField(configurationHandler: {(_ textField: UITextField) -> Void in
            // Set current image label by default
            let index: Int = self.networkGallery!.currentIndex
            let ri = (self.networkImages.object(at: index)) as! RemoteImage
            if ri.label != "" {
                textField.text = ri.label
            }
        })
        parent?.present(alertUpdate, animated: true)
    }
    
    func showFGallery(_ n: Int) {
        let c = catInfo[n] as! CategoryInfo
        if(userImages["\(c.classid)"] != nil){
            networkImages = userImages.object(forKey: c.classid) as! NSMutableArray
            // v1.1
            let labelButton = UIBarButtonItem(image: UIImage(named: "tag.png"), style: .plain, target: self, action: #selector(self.updateLabelAlert))
            let deleteButton = UIBarButtonItem(image: UIImage(named: "trash.png"), style: .plain, target: self, action: #selector(self.deleteImage))
            let barItems: [Any] = [labelButton, deleteButton]
            networkGallery = FGalleryViewController(photoSource: self, barItems: barItems)
            networkGallery?.classname = Utilities.upperFirstLetter((c.lemma))
            networkGallery?.classid = c.classid
            /*if UI_USER_INTERFACE_IDIOM() == .pad {
             ((delegate) as? iPadUserInfoViewController)?.networkGallery = networkGallery
             }
             else {*/
            navigationController?.pushViewController(networkGallery!, animated: true)
            //}
        }else{
            AlertControllerSingleButton.showAlert("NOT FOUND", withMessage: "This class ID is not found in server", withButtonTitle: "OK", in: self)
        }
    }
    
    // MARK: -
    // MARK: Connection delegate
    // Called when the image deletion or label update requests succeed in the server
    func didFinishConnection() {
        if self.theConnection?.receivedData != nil{
            ActivityViewController.hideActivityView(spinnerView!)
            // Delete operation (v1.1) with currentOperation==0
            if currentOperation == 0 {
                let c = catInfo[currentIndex] as? CategoryInfo
                // Remove image in array
                networkImages.removeObject(at: (networkGallery?.currentIndex)!)
                if networkImages.count != 0 {
                    // Remove image in view
                    networkGallery?.removeImage(at: UInt(bitPattern: (networkGallery?.currentIndex)!))
                    // Update count of images for the given category
                    let value = CInt(truncating: (c?.n)!)
                    c?.n = Int(value - 1) as NSNumber
                }
                else {
                    userImages.removeObject(forKey: c?.classid as Any)
                    catInfo.remove(at: currentIndex)
                    // Come back if this is an iphone
                    /*if UI_USER_INTERFACE_IDIOM() == .pad {
                        ((delegate) as? iPadUserInfoViewController)?.clearNetworkGallery()
                    }
                    else {*/
                    navigationController?.popViewController(animated: true)
                    //}
                }
                tableView.reloadData()
            }
            else {
                // Reload image with the new label
                let index: Int = (networkGallery?.currentIndex)!
                networkGallery?.gotoImage(by: UInt(index), animated: false)
                // Force reload
            }
        }
    }
    
    func didFailedConnection() {
        ActivityViewController.hideActivityView(spinnerView!)
    }
    
    // MARK: - Show stats
    @objc func showStats() {
        let stats = StatisticsViewController(style: .grouped)
        stats.userStatistics = (userStatistics.allValues as NSArray).sortedArray(using: [desc])
        stats.globalStatistics = (globalStatistics.allValues as NSArray).sortedArray(using: [desc])
        navigationController?.pushViewController(stats, animated: true)
    }
    
    //FIXME: it substitutes statistics method
    let desc = NSSortDescriptor(key: "identifier", ascending: true) { // comparator function
        id1, id2 in
        if (id1 as! Int) < (id2 as! Int) { return .orderedAscending }
        if (id1 as! Int) > (id2 as! Int) { return .orderedDescending }
        return .orderedSame
    }
    
    // MARK: - Table view delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        showFGallery(indexPath.row)
        currentIndex = indexPath.row
    }
    
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        showFGallery(indexPath.row)
    }
    
    // MARK: -
    // MARK: Alert View
    // v1.1
    func updatedLabel(_ newLabel: String) {
        if newLabel != "" {
            // Send label to server only if it changed
            let index: Int = (networkGallery?.currentIndex)!
            let ri = (networkImages.object(at: index)) as! RemoteImage
            if !(ri.label == newLabel) {
                updateLabel(ri, withLabel: newLabel)
            }
        }
        else {
            print("Tag vacio")
        }
    }
    
    // MARK: - FGalleryViewControllerDelegate Methods
    func numberOfPhotos(forPhotoGallery gallery: FGalleryViewController) -> Int32 {
        return Int32(networkImages.count)
    }
    
    func photoGallery(_ gallery: FGalleryViewController, sourceTypeForPhotoAt index: UInt) -> FGalleryPhotoSourceType {
        return FGalleryPhotoSourceTypeNetwork
    }
    
    func photoGallery(_ gallery: FGalleryViewController!, captionForPhotoAt index: UInt) -> String! {
        let ri = (networkImages.object(at: Int(index))) as! RemoteImage
        return (ri.label)
    }
    
    func photoGallery(_ gallery: FGalleryViewController!, urlFor size: FGalleryPhotoSize, at index: UInt) -> String! {
        let ri = (networkImages.object(at: Int(index))) as! RemoteImage
        
        return String(describing: ri.url)
    }
    
    func photoGallery(_ gallery: FGalleryViewController!, filePathFor size: FGalleryPhotoSize, at index: UInt) -> String! {
        let ri = (networkImages.object(at: Int(index))) as! RemoteImage
        return String(describing: ri.url)
    }
}
