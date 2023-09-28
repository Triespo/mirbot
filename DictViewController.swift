//
//  DictViewController.swift
//  mirbot
//
//  Created by Miguel Ángel Jareño Escudero on 08/09/2017.
//  Copyright © 2017 Master Móviles. All rights reserved.
//
//  Table showing 100 first lemmas from remote dictionary. It is filtered by searcher.

class DictViewController: UITableViewController, ConnectionDelegate{
    
    var listContent = [String]()
    var responseDict = [AnyHashable: Any]()
    var oldClassifiedImage: ClassifiedImage?
    var delegate: Any?
    var searchController: UISearchController?
    var searchResults = [String]()
    var theConnection: Connection?
    var spinnerView: UIView?
    var topView: UIView?
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UI_USER_INTERFACE_IDIOM() == .pad {
            return .all
        }
        else {
            return .portrait
        }
    }
    
    // MARK: -
    override func viewDidLoad() {
        super.viewDidLoad()
        let appDelegate: AppDelegate? = (UIApplication.shared.delegate as? AppDelegate)
        listContent = (appDelegate?.listContent)!
        // Navigation bar title and buttons
        navigationItem.title = "Select"
        navigationItem.hidesSearchBarWhenScrolling = false
        navigationItem.hidesBackButton = false
        // Resizing
        view.autoresizesSubviews = true
        view.autoresizingMask = [.flexibleHeight, .flexibleWidth, .flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
        // Create a mutable array to contain products for the search results table.
        searchResults = [String]()
        let searchResultsController = UITableViewController(style: .plain)
        searchResultsController.tableView.dataSource = self
        searchResultsController.tableView.delegate = self
        searchController = UISearchController(searchResultsController: searchResultsController)
        searchController?.searchResultsUpdater = self as? UISearchResultsUpdating
        if(floor(NSFoundationVersionNumber) >= floor(NSFoundationVersionNumber_iOS_9_0)){
            searchController?.hidesNavigationBarDuringPresentation = false
        }
        // iOS9
        searchController?.searchBar.frame = CGRect(x: (searchController?.searchBar.frame.origin.x)!, y: (searchController?.searchBar.frame.origin.y)!, width: (searchController?.searchBar.frame.size.width)!, height: 44.0)
        tableView.tableHeaderView = searchController?.searchBar
        tableView.isScrollEnabled = true
        definesPresentationContext = true
        if UI_USER_INTERFACE_IDIOM() == .pad {
            searchController?.hidesNavigationBarDuringPresentation = false
        }
        topView = navigationController?.topViewController?.view
        NotificationCenter.default.addObserver(self, selector: #selector(self.changeSearch), name: NSNotification.Name.UITextFieldTextDidChange, object: nil)
    }
    
    @objc func changeSearch(_ sender: Any) {
        if(CGFloat((self.searchController?.searchBar.text?.count)!) > 2){
            self.searchSubstring()
        }else if(self.searchController!.searchBar.text!.count < 1 && spinnerView != nil){
            ActivityViewController.hideActivityView(spinnerView!)
            spinnerView?.removeFromSuperview()
        }
    }
    
    func searchSubstring(){
        theConnection = Connection()
        theConnection?.delegate = self
        let urlString: String = Test.getURL()
        var PHPparams = ""
        
        if(self.searchController!.searchBar.text!.contains(" ")){
            let searchURL = self.searchController!.searchBar.text!.replacingOccurrences(of: " ", with: "+")
            PHPparams = "wordnet?search=\(searchURL)"
        }else{
            PHPparams = "wordnet?search=\(self.searchController!.searchBar.text!)"
        }
        if(self.searchController!.searchBar.text!.count > 2){
            theConnection?.startV1(urlString, withPHPParams: PHPparams,method: "GET")
            //let topView: UIView? = navigationController?.topViewController?.view
            spinnerView = ActivityViewController.showActivityView(self.topView!)
        }
    }
    
    //MARK: TableView
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let detailsViewController = DetailViewController()
        detailsViewController.responseDict = responseDict
        detailsViewController.oldClassifiedImage = oldClassifiedImage
        // If the requesting table view is the search display controller's table view, configure the next view
        // controller using the filtered content, otherwise use the main list.
        var sourceArray: [String]
        if tableView == (searchController?.searchResultsController as? UITableViewController)?.tableView {
            sourceArray = searchResults
        }
        else {
            sourceArray = listContent
        }
        let object: String = sourceArray[indexPath.row]
        detailsViewController.lemma = object
        /*if UI_USER_INTERFACE_IDIOM() == .pad {
            detailsViewController.delegate = delegate
            ((delegate) as? iPadDictViewController)?.detailView = detailsViewController
        }
        else {*/
            navigationController?.pushViewController(detailsViewController, animated: true)
        //}
    }
    
    // MARK: - UITableViewDataSource
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        /*  If the requesting table view is the search controller's table view, return the count of
         the filtered list, otherwise return the count of the main list.
         */
        if tableView == (searchController?.searchResultsController as? UITableViewController)?.tableView {
            return searchResults.count
        }
        else {
            return listContent.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let CellIdentifier: String = "cellID"
        // Dequeue a cell from self's table view.
        var cell: UITableViewCell? = self.tableView.dequeueReusableCell(withIdentifier: CellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: CellIdentifier)
            cell?.accessoryType = .disclosureIndicator
        }
//      If the requesting table view is the search controller's table view, configure the cell using the search results array, otherwise use the product array.
        var object: String? = nil
        if tableView == (searchController?.searchResultsController as? UITableViewController)?.tableView {
            object = searchResults[indexPath.row]
        }
        else {
            object = listContent[indexPath.row]
        }
        cell?.textLabel?.text = object
        return cell!
    }
    
    func didFinishConnection() {
        if(spinnerView != nil){
            ActivityViewController.hideActivityView(spinnerView!)
            spinnerView?.removeFromSuperview()
        }
        if self.theConnection?.receivedData != nil{
            let response = String(data: (theConnection?.receivedData)!, encoding: String.Encoding.utf8)
            let data = response?.data(using: String.Encoding.utf8)
            do {
                if(String(response!.prefix(1))=="{" && String(response!.suffix(1))=="}"){
                    let jsonParser = try JSONSerialization.jsonObject(with: data!, options: []) as? [String : Any]
                    if(jsonParser!["lemmas"] != nil){
                        let lemmas = jsonParser!["lemmas"] as! [String]
                        self.searchResults = lemmas
                    }
                }
            } catch {
                print("Error JSON")
            }
            (self.searchController?.searchResultsController as? UITableViewController)?.tableView?.reloadData()
        }
    }
    
    func didFailedConnection() {
    }
}

