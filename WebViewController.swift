//
//  WebViewController.swift
//  mirbot
//
//  Created by Master Móviles on 06/08/2017.
//  Copyright © 2017 Master Móviles. All rights reserved.
//
//  It's used like a navigator in the app for visiting webs such as wikipedia or some sponsors

class WebViewController: UIViewController, UITextFieldDelegate, UIWebViewDelegate {
    var myWebView: UIWebView?
    var iniURL: String = ""
    var toolbar: UIToolbar?
    var backButton: UIBarButtonItem?
    var forwardButton: UIBarButtonItem?
    var initURL: String = ""
    var navBar: UINavigationBar?
    var navBarItem: UINavigationItem?
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }
    
    deinit {
        myWebView?.delegate = nil
    }
    
    init(url URL: String) {
        super.init(nibName: nil, bundle: nil)
        
        iniURL = URL
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Show web view
        view.autoresizesSubviews = true
        view.frame = UIScreen.main.bounds
        showNavBar()
        showWebView()
        showToolBar()
        // Load URL
        myWebView?.loadRequest(URLRequest(url: URL(string: iniURL)!))
    }
    
    func showNavBar() {
        // UIBarPosition
        navBar = UINavigationBar(frame: CGRect(x: 0, y: 0, width: Int(view.frame.size.width), height: kToolbarHeightModal))
        navBar?.autoresizingMask = .flexibleWidth
        navBar?.backgroundColor = UIColor.white
        navBarItem = UINavigationItem(title: "Loading...")
        navBarItem?.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.getBackController))
        navBar?.items = [navBarItem!]
        view.addSubview(navBar!)
    }
    
    @objc func getBackController(){
        self.dismiss(animated: true, completion: nil)
    }
    
    func showWebView() {
        // Leave space for toolbar
        var webFrame: CGRect = UIScreen.main.bounds
        webFrame.size.height -= CGFloat(kToolbarHeight - 20)
        // Normalmente, 44
        webFrame.origin.x = 0
        webFrame.origin.y = CGFloat(kToolbarHeight + 20)
        // Init webView
        myWebView = UIWebView(frame: webFrame)
        myWebView?.backgroundColor = UIColor.white
        myWebView?.autoresizingMask = ([.flexibleWidth, .flexibleHeight])
        myWebView?.delegate = self
        myWebView?.autoresizesSubviews = true
        view.addSubview(myWebView!)
    }
    
    func showToolBar() {
        // Toolbar
        let toolbarFrame = CGRect(x: 0, y: view.frame.size.height - CGFloat(kToolbarHeight), width: view.frame.size.width, height: CGFloat(kToolbarHeight))
        toolbar = UIToolbar(frame: toolbarFrame)
        toolbar?.barStyle = .default
        toolbar?.sizeToFit()
        toolbar?.autoresizingMask = [.flexibleWidth, .flexibleHeight, .flexibleTopMargin]
        setupToolbarItems()
        view.addSubview(toolbar!)
    }
    
    // MARK: Toolbar
    func setupToolbarItems() {
        // Create a flexible space button to push the print button to the far right.
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        backButton = UIBarButtonItem(image: UIImage(named: "back.png"), style: .plain, target: self, action: #selector(self.goBack))
        forwardButton = UIBarButtonItem(image: UIImage(named: "forw.png"), style: .plain, target: self, action: #selector(self.goForward))
        // Enable or disable back and forward
        backButton?.isEnabled = (myWebView?.canGoBack)!
        forwardButton?.isEnabled = (myWebView?.canGoForward)!
        toolbar?.items = [flexibleSpace, backButton!, flexibleSpace, forwardButton!, flexibleSpace, flexibleSpace, flexibleSpace, flexibleSpace, flexibleSpace, flexibleSpace, flexibleSpace]
    }
    
    @objc func goBack(_ sender: Any?) {
        myWebView?.goBack()
    }
    
    @objc func goForward(_ sender: Any?) {
        myWebView?.goForward()
    }
    
    // MARK: UIWebViewDelegate
    func webViewDidStartLoad(_ webView: UIWebView) {
        // starting the load, show the activity indicator in the status bar
        title = "Loading..."
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        // Update title
        let title: String? = webView.stringByEvaluatingJavaScript(from: "document.title")
        navBarItem?.title = title
        // finished loading, hide the activity indicator in the status bar
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        // Enable or disable back and forward
        backButton?.isEnabled = (myWebView?.canGoBack)!
        forwardButton?.isEnabled = (myWebView?.canGoForward)!
    }
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        //make sure that the page scales when it is loaded :-)
        myWebView?.scalesPageToFit = true
        return true
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        // load error, hide the activity indicator in the status bar
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        // report the error inside the webview
        let errorString: String? = "<html><center><font size=+5 color='red'>Error:<br>\(error.localizedDescription)</font></center></html>"
        myWebView?.loadHTMLString(errorString!, baseURL: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIApplication.shared.isStatusBarHidden = true
    }
    
    // MARK: UIViewController delegate methods
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        myWebView?.delegate = self
        // setup the delegate as the web view is shown
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        myWebView?.stopLoading()
        // in case the web view is still loading its content
        myWebView?.delegate = nil
        // disconnect the delegate as the webview is hidden
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
    // this helps dismiss the keyboard when the "Done" button is clicked
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        myWebView?.loadRequest(URLRequest(url: URL(string: textField.text!)!))
        return true
    }
}
