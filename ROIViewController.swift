//
//  ROIViewController.swift
//  mirbot
//
//  Created by Master Móviles on 24/07/2017.
//  Copyright © 2017 Master Móviles. All rights reserved.
//
//  Shows image done by camera to cut the main part of the photo

import Alamofire

class ROIViewController: UIViewController,UINavigationControllerDelegate, ConnectionDelegate{
    
    private var minx: Int = 0
    private var miny: Int = 0
    private var maxx: Int = 0
    private var maxy: Int = 0
    private var activityView: UIView?
    private var help_shown: Bool = false
    private var interactivePop: Bool = false
    var theImage: UIImage?
    var theCroppedImage: UIImage?
    var metadataDict = NSMutableDictionary()
    var theConnection: Connection?
    var theROIView: ROIView?
    var theTouchView: TouchView?
    var spinnerView: UIView?
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UI_USER_INTERFACE_IDIOM() == .pad {
            return .all
        }
        else {
            return .portrait
        }
    }
    
    init(data receivedImage: UIImage, withMetadataDict receivedMetadataDict: NSMutableDictionary) {
        super.init(nibName: nil, bundle: nil)
        
        theImage = receivedImage
        metadataDict = receivedMetadataDict
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        theConnection?.delegate = nil
        theConnection = nil
    }
    
    // Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
    override func viewDidLoad() {
        super.viewDidLoad()
        help_shown = false
        // Show nav buttons
        navigationItem.title = "Select target"
        let nextButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.sendData))
        navigationItem.rightBarButtonItem = nextButton
        navigationItem.rightBarButtonItem?.isEnabled = false
        UIApplication.shared.isStatusBarHidden = false
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
        UIApplication.shared.isStatusBarHidden = false
        if (UI_USER_INTERFACE_IDIOM() == .pad) {
            navigationController?.navigationBar.isTranslucent = true
        }
        else {
            navigationController?.navigationBar.isTranslucent = false
        }
        initROITouchViews()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if UI_USER_INTERFACE_IDIOM() == .pad {
            avoidMainViewRotation()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.interactivePopGestureRecognizer?.isEnabled = interactivePop
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // To avoid swipe with the corners
        interactivePop = (navigationController?.interactivePopGestureRecognizer?.isEnabled)!
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        let appDelegate: AppDelegate? = (UIApplication.shared.delegate as? AppDelegate)
        if !help_shown && appDelegate?.firstTime == true {
            UIApplication.shared.isStatusBarHidden = true
            let help2 = VideoViewController(video: "help2", with: .crossDissolve, withCanBeStopped: false)
            if UI_USER_INTERFACE_IDIOM() == .pad {
                help2.modalPresentationStyle = .pageSheet
            }
            present(help2, animated: false)
            help_shown = true
            appDelegate?.firstTime = false as NSNumber
        }
        UIApplication.shared.isStatusBarHidden = false
    }
    
    @objc func sendData(_ sender: Any) {
        if !checkMinArea() {
            presentAlertWithTitle(title: "Alert", message: "The selected region is too small, I can't see anything there!")
        }
        else {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            convertROICoordinates()
            navigationItem.rightBarButtonItem?.isEnabled = false
            navigationItem.leftBarButtonItem?.isEnabled = false
            theTouchView?.isUserInteractionEnabled = false
            showActivityViewer()
            sendPostString()
        }
    }
    
    func checkMinArea() -> Bool {
        // Screen size
        let screenSize: CGFloat? = (theTouchView?.frame.size.width)! * (theTouchView?.frame.size.height)!
        // Rectangle size
        let roiSize: CGFloat? = (fabs((theTouchView?.locationInit.x)! - (theTouchView?.locationEnd.x)!) * fabs((theTouchView?.locationInit.y)! - (theTouchView?.locationEnd.y)!))
        // Check min selected ROI size
        var ok: Bool = false
        let minRegion: CGFloat? = CGFloat(kMINREGION)
        if roiSize! > screenSize! * minRegion!{
            ok = true
        }
        return ok
    }
    
    func initROITouchViews() {
        let invariant: CGSize = screenSizeOrientationIndependent()
        var rect = CGRect(x: 0, y: 0, width: invariant.width, height: invariant.height)
        if UI_USER_INTERFACE_IDIOM() == .phone {
            if !isPhone4s {
                rect.size.height -= 132 //152-20
            }
            else {
                rect.size.height -= 64
            }
        }
        theROIView = ROIView(frame: rect, theImage: theImage!)
        theTouchView = TouchView(frame: rect)
        theTouchView?.touched = navigationItem.rightBarButtonItem
        view.addSubview(theROIView!)
        view.addSubview(theTouchView!)
    }
    
    func screenSizeOrientationIndependent() -> CGSize {
        let screenSize: CGSize = UIScreen.main.bounds.size
        return CGSize(width: min(screenSize.width, screenSize.height), height: max(screenSize.width, screenSize.height))
    }
    
    // Avoid image rotation of the central view for iPad (iPhone does not rotate with supportedInterfaceOrientations)
    func avoidMainViewRotation() {
        var rotation: Float = 0.0
        let orientation: UIInterfaceOrientation = UIApplication.shared.statusBarOrientation
        switch orientation {
        case .portrait:
            rotation = 0
        case .portraitUpsideDown:
            rotation = -.pi
        case .landscapeRight:
            rotation = .pi + (.pi / 2)
        case .landscapeLeft:
            rotation = .pi / 2
        default:
            print("OTHER!!")
        }
        
        theTouchView?.transform = CGAffineTransform(rotationAngle: CGFloat(rotation))
        theROIView?.transform = CGAffineTransform(rotationAngle: CGFloat(rotation))
        theROIView?.center = view.center
        theTouchView?.center = view.center
    }
    
    func convertROICoordinates() {
        let rect = CGRect(x: (theTouchView?.locationInit.x)!, y: (theTouchView?.locationInit.y)!, width: (theTouchView?.locationEnd.x)! - (theTouchView?.locationInit.x)!, height: (theTouchView?.locationEnd.y)! - (theTouchView?.locationInit.y)!)
        // Scale and transform (rotate) ROI
        let imageSize: CGSize? = theROIView?.theImageView?.image?.size
        let bounds: CGRect? = theTouchView?.bounds
        let source: CGRect? = rect
        var rectTrans: CGRect
        
        let txTranslate = CGAffineTransform(scaleX: (imageSize?.width)! / (bounds?.size.width)!, y: (imageSize?.height)! / (bounds?.size.height)!)
        rectTrans = (source?.applying(txTranslate))!
        
        // Get min and max points of bounding box
        minx = Int(round(rectTrans.minX))
        miny = Int(round(rectTrans.minY))
        maxx = Int(round(rectTrans.maxX))
        maxy = Int(round(rectTrans.maxY))
        // Correct negative minx, miny, maxx, maxy only if ROI coordinates are sent, instead of cropped image
        if minx < 0 {
            minx = 0
        }
        if miny < 0 {
            miny = 0
        }
        if maxx < 0 {
            maxx = 0
        }
        if maxy < 0 {
            maxy = 0
        }
    }
    
    func showActivityViewer() {
        let rect = CGRect(x: (theTouchView?.locationInit.x)!, y: (theTouchView?.locationInit.y)!, width: (theTouchView?.locationEnd.x)! - (theTouchView?.locationInit.x)!, height: (theTouchView?.locationEnd.y)! - (theTouchView?.locationInit.y)!)
        activityView = UIView(frame: rect)
        activityView?.backgroundColor = UIColor.clear
        activityView?.alpha = 1
        let activityWheel = UIActivityIndicatorView(frame: CGRect(x: rect.size.width / 2 - 10, y: rect.size.height / 2 - 10, width: 24, height: 24))
        activityWheel.activityIndicatorViewStyle = .whiteLarge
        activityView?.addSubview(activityWheel)
        theTouchView?.addSubview(activityView!)
        theTouchView?.bringSubview(toFront: activityView!)
        UIView.animate(withDuration: 0.1,
                       delay: 0.1,
                       options: UIViewAnimationOptions.curveEaseIn,
                       animations: { () -> Void in
                        self.activityView?.subviews[0].layoutIfNeeded()
        }, completion: { (finished) -> Void in
            print("WheelView showed!")
        })
        view.setNeedsDisplay()
    }
    
    func drawRectangleOnImage(image: UIImage) -> UIImage {
        let imageSize = image.size
        let scale: CGFloat = 0
        UIGraphicsBeginImageContextWithOptions(imageSize, false, scale)
        let context = UIGraphicsGetCurrentContext()
        
        image.draw(at: .zero)
        
        let rectangle = CGRect(x: minx, y: miny, width: maxx-minx, height: maxy-miny)
        context!.setFillColor(UIColor.red.cgColor)
        context!.addRect(rectangle)
        context!.drawPath(using: .stroke)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }

    func sendPostString(){
        
        let userId = UserDefaults.standard.object(forKey: "userid") as! String
        let urlString: String = Test.getURL()
        let PHPparams: String = "user/\(userId)/images/classify"
        let image = self.theROIView?.theImageView?.image
        var parameters = [String:Any]()
        parameters = ["onlyuser":getUserOption() as Any,
                      "categories":kAllCategoryes as Any,"metadata":prepareMetadata() as Any]//you can add num_results
        self.theConnection = Connection()
        self.theConnection?.delegate = self
        self.theConnection?.startV1(urlString, withPHPParams: PHPparams, image: image!, params: parameters, headers: [:])
    }
    
    func prepareMetadata() -> Data {
        let rectString: String = "\(Int(minx)),\(Int(miny)),\(Int(maxx)),\(Int(maxy))"
        metadataDict["selected_area"] = rectString
        return getStringFromDictionary()
    }
    
    func getUserOption() -> String{
        if UserDefaults.standard.bool(forKey: "onlyuser")==true{
            return "YES"
        }
        return "NO"
    }
    
    func getStringFromDictionary() -> Data {
        var jsonData = Data()
        
        do{
            jsonData = try JSONSerialization.data(withJSONObject: metadataDict, options: [])
        }catch{
            print("Error JSON ROIViewController")
        }
        return jsonData
    }
    
    // MARK: ConnectionDelegate methods
    func didFinishConnection() {
        if self.theConnection?.receivedData != nil{
            theTouchView?.isUserInteractionEnabled = true
            hideActivityViewer()
            let response = String(data: (theConnection?.receivedData)!, encoding: String.Encoding.utf8)
            let theSendController = SendViewController(nibName: "SendView", bundle: nil)
            theSendController.previousResponse = response!
            navigationController?.pushViewController(theSendController, animated: true)
        }
    }
    
    func didFailedConnection() {
        theTouchView?.isUserInteractionEnabled = true
        navigationItem.rightBarButtonItem?.isEnabled = true
        // Hide spinner
        hideActivityViewer()
    }
    
    func hideActivityViewer() {
        //activityView?.subviews[0].stopAnimating()
        activityView?.removeFromSuperview()
        activityView = nil
    }
}

extension ROIViewController{
    func presentAlertWithTitle(title: String, message : String){
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let closeAction = UIAlertAction(title: "Close", style: .default)
        alertController.addAction(closeAction)
        self.present(alertController, animated: true, completion: nil)
    }
}

