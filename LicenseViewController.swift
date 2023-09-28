//
//  LicenseViewController.swift
//  mirbot
//
//  Created by Master Móviles on 07/08/2017.
//  Copyright © 2017 Master Móviles. All rights reserved.
//
//  Shows license from this app and must be accepted from user for continuing

protocol LicenseViewControllerDelegate: class {
    func didFinishLicenseViewController()
}

class LicenseViewController: UIViewController, UIWebViewDelegate {
    var toolBar: UIToolbar?
    var webView: UIWebView?
    var delegate: LicenseViewControllerDelegate?
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }
    
    @objc func accept(_ sender: Any) {
        if delegate != nil {
            delegate?.didFinishLicenseViewController()
        }
        else {
            dismiss(animated: true)
        }
    }
    
    func showWebView() {
        // Leave space for toolbar
        var webFrame: CGRect = UIScreen.main.bounds
        webFrame.size.height -= CGFloat(kToolbarHeight)
        // Init webView
        webView = UIWebView(frame: webFrame)
        webView?.backgroundColor = UIColor.white
        webView?.autoresizingMask = ([.flexibleWidth, .flexibleHeight])
        webView?.delegate = self
        // For rotation (not working anyways...)
        webView?.autoresizesSubviews = true
        webView?.autoresizingMask = ([.flexibleHeight, .flexibleWidth])
        guard let filepath = Bundle.main.path(forResource: "TermsOfUse", ofType: kWebType)else{
            print("TermsOfUse not found")
            return
        }
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: filepath) {
            print("File \(filepath) AVAILABLE")
        } else {
            print("File \(filepath) NOT AVAILABLE")
        }
        // Load contents of file TermsOfUse.html
        webView?.loadRequest(URLRequest(url: URL.init(fileURLWithPath: filepath)))
        view.addSubview(webView!)
        // Setup toolbar
        let toolbarFrame = CGRect(x: 0, y: webFrame.origin.y + webFrame.size.height, width: view.frame.size.width, height: CGFloat(kToolbarHeight))
        toolBar = UIToolbar(frame: toolbarFrame)
        toolBar?.barStyle = .default
        // Allow the toolbar location and size to adjust properly as the orientation changes.
        toolBar?.autoresizingMask = [.flexibleWidth, .flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin]
        toolBar?.backgroundColor = UIColor.white
        // Add buttons to toolbar
        let acceptButton = UIBarButtonItem(title: kButtonAcceptTerms, style: .done, target: self, action: #selector(self.accept))
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolBar?.items = [flexibleSpace, acceptButton, flexibleSpace]
        view.addSubview(toolBar!)
    }
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        //make sure that the page scales when it is loaded :-)
        return true
    }
    
    // MARK: - View lifecycle
    init() {
        super.init(nibName: nil, bundle: nil)
        
        // Show status bar, navigationBar? XXX
        navigationItem.title = "Terms of use"
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showWebView()
    }
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        webView?.reload()
    }
    
    deinit {
        webView?.delegate = nil
    }
}
