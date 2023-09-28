//
//  FirstViewController.swift
//  mirbot
//
//  Created by Master Móviles on 18/07/2017.
//  Copyright © 2017 Master Móviles. All rights reserved.
//
//  Centralized view where shows to the camera's screen functionality as a container and make photo sending other information
//  such as metadata and sensor results from device

import CoreLocation
import CoreMotion
import SystemConfiguration

class FirstViewController:UIViewController, UINavigationControllerDelegate, CameraDelegate, CLLocationManagerDelegate, VideoViewControllerDelegate, LicenseViewControllerDelegate, UserInfoInitDelegate{
    
    @IBOutlet var segmentedControl: UISegmentedControl!
    
    var locationMeasurements = [CLLocation]()
    var userinfoinit: UserInfoInit?
    var metadataDict = [AnyHashable: Any]()
    var overlayView: UIView?
    
    //var settingsPopover: UIPopoverController?
    var videoIntro: VideoViewController?
    var licenseIntro: LicenseViewController?
    var camera: CameraViewController?
    
    var motionManager: CMMotionManager?
    var locManager: CLLocationManager?
    var bestEffortAtLocation: CLLocation?
    // Metadata (gyro, GPS, date)
    var roll: Double = 0.0
    var pitch: Double = 0.0
    var yaw: Double = 0.0
    var backgroundImage: UIImageView?
    // To display help
    var show_help: Bool = false
    var spinnerView: UIView?
    var alertController: UIAlertController?
    var info: UIAlertController?
    var awards: AwardsViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCameraController()
        
        // Create camera view
        camera = CameraViewController(overlay: overlayView!)
        camera?.delegate = self
        
        awards = AwardsViewController()
        //added alert in case user don't have any photos
        self.alertController = UIAlertController(title: "Alert", message: "Not images yet", preferredStyle: .alert)
        self.alertController?.addAction(UIAlertAction(title: "Close", style: .default))
        alertController?.view.isHidden = true
        view.addSubview((alertController?.view)!)
        
        //added actionSheet button info
        info = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        setupInfo()
        info?.view.isHidden = true
        view.addSubview((info?.view)!)
        
        // Show spinner
        let topView: UIView? = view
        spinnerView = ActivityViewController.showActivityView(topView!)
        initialize()
        startLocationManager()
        title = "Camera"
        self.navigationController?.isNavigationBarHidden = true
        
        // Second video should be shown if the first is called from this function
        show_help = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    
        metadataDict.removeAll()
        UIApplication.shared.isStatusBarHidden = true
        if (motionManager?.isDeviceMotionAvailable)! {
            motionManager?.startGyroUpdates()
            motionManager?.startAccelerometerUpdates()
            motionManager?.startDeviceMotionUpdates()
        }
        // Hide spinner
        ActivityViewController.hideActivityView(spinnerView!)
        if backgroundImage != nil {
            backgroundImage?.removeFromSuperview()
            backgroundImage = nil
        }
        // If it is the first time, display videos and Terms of Use
        let appDelegate: AppDelegate? = (UIApplication.shared.delegate as? AppDelegate)
        if appDelegate?.firstTime == true && show_help {
            videoIntro = VideoViewController(video: "video_intro", with: .crossDissolve, withCanBeStopped: true)
            videoIntro?.delegate = self
            // For iPad
            if UI_USER_INTERFACE_IDIOM() == .pad {
                videoIntro?.modalPresentationStyle = .pageSheet
            }
            present(videoIntro!, animated: false)
        }
        else {
            camera?.modalTransitionStyle = .crossDissolve
            present(camera!, animated: false)
        }
    }
    
    func setupCameraController() {
        // iPhone and iPod touch interface here
        overlayView = CameraViewiPhone(frame: UIScreen.main.bounds)
        (overlayView as? CameraViewiPhone)?.delegate = self
        // For rotation issues
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(self.deviceOrientationDidChange), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
    }
    
    // Needed (only) to rotate the camera button
    @objc func deviceOrientationDidChange(_ notification: Notification) {
        //Obtaining the current device orientation
        let orientation: UIDeviceOrientation = UIDevice.current.orientation
        var rotation: Float
        switch orientation {
            case .portrait:
                rotation = 0
            case .portraitUpsideDown:
                rotation = .pi
            case .landscapeLeft:
                rotation = Float.pi/2
            case .landscapeRight:
                rotation = -Float.pi/2
            default:
                rotation = 0
        }
        
        UIView.beginAnimations(nil, context: nil)
        if UI_USER_INTERFACE_IDIOM() == .phone {
            (overlayView as? CameraViewiPhone)?.cameraButtonImageView?.transform = CGAffineTransform(rotationAngle: CGFloat(rotation))
            // Rotate UIBarButtonItems
            let tmp = (overlayView as? CameraViewiPhone)?.flashButton?.value(forKey: "view") as? UIView
            tmp?.transform = CGAffineTransform(rotationAngle: CGFloat(rotation))
            let tmp2 = (overlayView as? CameraViewiPhone)?.infoButton?.value(forKey: "view") as? UIView
            tmp2?.transform = CGAffineTransform(rotationAngle: CGFloat(rotation))
            let tmp3 = (overlayView as? CameraViewiPhone)?.classificationButton?.value(forKey: "view") as? UIView
            tmp3?.transform = CGAffineTransform(rotationAngle: CGFloat(rotation))
        }
        UIView.commitAnimations()
    }
    
    func didTakePhoto(_ theImage: UIImage, withEXIFData exif: [AnyHashable: Any]) {
        // Store metadata
        storeAttitude()
        // should be inmediate
        storeAngle(theImage.imageOrientation)
        storeWifiReachability()
        storeDate()
        storeModel()
        storeFlashMode()
        storeExifMetadata(exif)
        if bestEffortAtLocation != nil{
            storeLocation()
        }
        // Stop motion
        if motionManager != nil {
            stopMotionManager()
        }
        // Dismiss and present ROI View.
        let mutableDictionary = NSMutableDictionary(dictionary: metadataDict)
        let rvc = ROIViewController(data: theImage, withMetadataDict: mutableDictionary)
        navigationController?.pushViewController(rvc, animated: false)
        dismiss(animated: true)
    }
    
    func storeDate() {
        // Convert date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        let dateString: String = dateFormatter.string(from: Date())
        dateFormatter.dateFormat = "HH:mm:ss"
        let timeString: String = dateFormatter.string(from: Date())
        metadataDict["date"] = dateString
        metadataDict["time"] = timeString
    }
    
    func initialize() {
        // Init location manager
        locationMeasurements = [CLLocation]()
        locManager = CLLocationManager()
        // Init motion manager
        motionManager = CMMotionManager()
        motionManager?.deviceMotionUpdateInterval = 1.0 / 60.0
        motionManager?.gyroUpdateInterval = 1.0 / 60.0
        motionManager?.accelerometerUpdateInterval = 1.0 / 60.0
        // Init metadata dictionary
        metadataDict = [AnyHashable: Any]()
    }
    
    func storeAttitude() {
        if (motionManager?.isDeviceMotionAvailable)! {
            roll = (motionManager?.deviceMotion?.attitude.roll)!
            pitch = (motionManager?.deviceMotion?.attitude.pitch)!
            yaw = (motionManager?.deviceMotion?.attitude.yaw)!
        }
        else {
            yaw = -1
            pitch = yaw
            roll = pitch
        }
        let ax: Double? = motionManager?.deviceMotion?.userAcceleration.x
        let ay: Double? = motionManager?.deviceMotion?.userAcceleration.y
        let az: Double? = motionManager?.deviceMotion?.userAcceleration.z
        metadataDict["roll"] = String(Float(roll))
        metadataDict["pitch"] = String(Float(pitch))
        metadataDict["yaw"] = String(Float(yaw))
        metadataDict["accelerationx"] = String(Float(ax!))
        metadataDict["accelerationy"] = String(Float(ay!))
        metadataDict["accelerationz"] = String(Float(az!))
        let globalacc: Double = fabs(ax!) + fabs(ay!) + fabs(az!)
        metadataDict["globalacceleration"] = String(Float(globalacc))
    }
    
    func storeAngle(_ orientation: UIImageOrientation) {
        var imgAngle: Double

        switch orientation {
        case .up:
            if roll < 1.0 && roll > -1.0 {
                imgAngle = pitch * 180 / .pi
            }
            else {
                imgAngle = 90 + cos(pitch) * 180 / .pi
            }
        case .down:
            imgAngle = roll * 180 / .pi
        case .left:
            if roll < 1.0 && roll > -1.0 {
                imgAngle = -pitch * 180 / .pi
            }
            else {
                imgAngle = 90 + cos(-pitch) * 180 / .pi
            }
        case .right:
            if roll < 1.0 && roll > -1.0 {
                imgAngle = pitch * 180 / .pi
            }
            else {
                imgAngle = 90 + cos(pitch) * 180 / .pi
            }
        default:
            // Shouldn't happen
            imgAngle = 0
        }
        
        if imgAngle < 0 {
            imgAngle = 0
        }
        // This happens when UIImageOrientation values have just changed (angle close to 0), causing a negative result, typically in [-1,0]
        metadataDict["angle"] = String(Float(imgAngle))
    }
    
    func storeWifiReachability()
    {
        var zeroAddress = sockaddr_in()
        var wifi: String
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        
        var flags = SCNetworkReachabilityFlags()
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
            wifi = "NO"
        }
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        if(isReachable && !needsConnection){
            wifi = "YES"
        }else{
            wifi = "NO"
        }
        metadataDict["wifi"] = wifi
    }
    
    func storeModel() {
        metadataDict["model"] = UIDevice.current.model
        metadataDict["osversion"] = UIDevice.current.systemVersion
        metadataDict["mirbotversion"] = Bundle.main.infoDictionary?["CFBundleVersion"]
    }
    
    func storeFlashMode() {
        var flash: String
        if (camera?.flash)! {
            flash = "ON"
        }
        else {
            flash = "OFF"
        }
        metadataDict["flash"] = flash
    }
    
    func storeExifMetadata(_ metaData: [AnyHashable: Any]) {
        for key: Any in metaData.keys {
            let name: String = "exif_\(key)".lowercased()
            let value: Any = metaData["\(key)"]!
            let stringValue: String = "\(String(describing: value))"
            // Remove EOL, (, ) from string
            let stringWithoutEOL: String = stringValue.replacingOccurrences(of: "\n", with: "")
            let stringWithoutLPar: String = stringWithoutEOL.replacingOccurrences(of: "(", with: "")
            let stringWithoutRPar: String = stringWithoutLPar.replacingOccurrences(of: ")", with: "")
            metadataDict[name] = stringWithoutRPar
        }
    }
    
    func storeLocation() {
        metadataDict["lat"] = Float((bestEffortAtLocation?.coordinate.latitude)!)
        metadataDict["lng"] = Float((bestEffortAtLocation?.coordinate.longitude)!)
        metadataDict["horizontalerror"] = String(Float((bestEffortAtLocation?.horizontalAccuracy)!))
        if Int((locManager?.location?.verticalAccuracy)!) >= 0 {
            metadataDict["altitude"] = String(Float((bestEffortAtLocation?.altitude)!))
            metadataDict["verticalerror"] = String(Float((bestEffortAtLocation?.verticalAccuracy)!))
        }
    }
    
    func stopMotionManager() {
        motionManager?.stopGyroUpdates()
        motionManager?.stopAccelerometerUpdates()
        motionManager?.stopDeviceMotionUpdates()
    }
    
    func didFinishVideoViewController(_ videofilename: String) {
        // Present license
        if (videofilename == "video_intro") && show_help{
            showLicense()
        }
        else if show_help{
            show_help = false
            dismiss(animated: false)
            if (locManager?.responds(to: #selector(locManager?.requestWhenInUseAuthorization)))! {
                locManager?.requestWhenInUseAuthorization()
                if CLLocationManager.locationServicesEnabled() {
                    NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.stopUpdatingLocation), object: "Timed Out")
                    startLocationManager()
                }
                else {
                    metadataDict["reliablelocation"] = "false"
                }
            }
            // Force reload view for iPad (viewDidAppear not called automatically as it is in the background)
            if UI_USER_INTERFACE_IDIOM() == .pad {
                viewDidAppear(false)
            }
        }else {
            self.videoIntro?.dismiss(animated: false)
        }
    }
    
    func showLicense() {
        licenseIntro = LicenseViewController()
        licenseIntro?.delegate = self
        // For iPad
        if UI_USER_INTERFACE_IDIOM() == .pad {
            licenseIntro?.modalPresentationStyle = .pageSheet
        }
        videoIntro?.present(licenseIntro!, animated: true)
    }
    
    func showAwards(){
        self.navigationController?.pushViewController(awards!, animated: true)
        self.camera?.dismiss(animated: true)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let newLocation = locations.last
        locationMeasurements.append(newLocation!)
        let locationAge: TimeInterval = -newLocation!.timestamp.timeIntervalSinceNow
        if locationAge > 5.0 {
            return
        }
        // Cached, discard
        if newLocation!.horizontalAccuracy < 0 {
            return
        }
        metadataDict["reliablelocation"] = "YES"
        if bestEffortAtLocation == nil || (bestEffortAtLocation?.horizontalAccuracy)! > (newLocation?.horizontalAccuracy)! {
            //NSLog(@"Acc= %f",newLocation.horizontalAccuracy);
            bestEffortAtLocation = newLocation!
            reverseGeocoding(bestEffortAtLocation!)
            //storeLocation()
            if newLocation!.horizontalAccuracy <= (locManager?.desiredAccuracy)! {
                stopUpdatingLocation("Reliable")
                NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.stopUpdatingLocation), object: "Timed Out")
            }
        }
    }
    
    func startLocationManager() {
        locManager?.delegate = self
        locManager?.startUpdatingLocation()
        locManager?.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locManager?.distanceFilter = 20
        perform(#selector(self.stopUpdatingLocation), with: "Timed Out", afterDelay: 30.0)
        if bestEffortAtLocation == nil || -(bestEffortAtLocation?.timestamp.timeIntervalSinceNow)! > 600 {
            // 600 seconds from previous reliable location is fine
            metadataDict["reliablelocation"] = "false"
        }
        else {
            metadataDict["reliablelocation"] = "true"
        }
    }
    
    @objc func stopUpdatingLocation(_ state: String) {
        locManager?.stopUpdatingLocation()
        locManager?.delegate = nil
    }
    
    func didFinishLicenseViewController() {
        let appDelegate: AppDelegate? = (UIApplication.shared.delegate as? AppDelegate)
        
        if(appDelegate?.firstTime == true && show_help){
            showSecondVideo()
            appDelegate?.firstTime = false
        }else{
            self.presentedViewController?.dismiss(animated: false, completion: nil)
        }
    }
    
    // MARK: VideoViewControllerDelegate
    func showSecondVideo() {
        let help1 = VideoViewController(video: "help1", with: .crossDissolve, withCanBeStopped: false)
        help1.delegate = self
        // For iPad
        if UI_USER_INTERFACE_IDIOM() == .pad {
            help1.modalPresentationStyle = .pageSheet
        }
        licenseIntro?.present(help1, animated: true, completion: nil)
    }
    
    func showSetupViewController() {
        let sv = SetupViewController()
        //[self.camera stopCamera];
        sv.modalTransitionStyle = .flipHorizontal
        camera?.present(sv, animated: true)
    }
    
    func showUserInfoViewController() {
        // Show spinner
        let topView: UIView? = camera?.view
        spinnerView = ActivityViewController.showActivityView(topView!)
        userinfoinit = UserInfoInit()
        userinfoinit?.delegate = self
    }
    
    func showInfoViewController() {
        info?.view.isHidden = false
        self.presentedViewController?.present(info!,animated:true)
    }
    
    // MARK: UserInfoInitDelegate
    func didFinishUserInfoInitDelegate() {
        let userinfo = UserInfoMain()
        userinfo.userImages =  (userinfoinit?.userImages)!
        userinfo.userStatistics = (userinfoinit?.userStatistics)!
        userinfo.globalStatistics = (userinfoinit?.globalStatistics)!
        userinfo.catInfo = (userinfoinit?.catInfo)! as! [Any]
        // Hide spinner
        ActivityViewController.hideActivityView(spinnerView!)
        if userinfo.userImages.count != 0 {
            /*if UI_USER_INTERFACE_IDIOM() == .pad {
                let iPadUserInfo = iPadUserInfoViewController(userInfo: userinfo)
                navigationController?.pushViewController(iPadUserInfo, animated: true)
            }
            else {*/
            navigationController?.pushViewController(userinfo, animated: true)
            //}
            camera?.dismiss(animated: true)
        }
        else {
            alertController?.view.isHidden = false
            self.presentedViewController?.present(self.alertController!, animated: true, completion: nil)
        }
    }
    
    func didFailedUserInfoInitDelegate() {
        // Hide spinner
        ActivityViewController.hideActivityView(spinnerView!)
    }
    
    func setupInfo(){
        
        var videoName = ""
        for i in ["Intro video", "Help", "About", "Terms of use", "Cancel"] {
            switch(i){
            case "Intro video":
                info?.addAction(UIAlertAction(title: i, style: .default, handler: {(action:UIAlertAction) in
                    videoName = "video_intro"
                    self.executeVideo(videoName: videoName)
                }));
            case "Help":
                info?.addAction(UIAlertAction(title: i, style: .default, handler: {(action:UIAlertAction) in
                    videoName = "help3"
                    self.executeVideo(videoName: videoName)
                }));
            case "About":
                info?.addAction(UIAlertAction(title: i, style: .default, handler: {(action:UIAlertAction) in
                    let about = AboutViewController(style: .grouped)
                    self.navigationController?.pushViewController(about, animated: true)
                    self.camera?.dismiss(animated: true)
                }));
            case "Terms of use":
                info?.addAction(UIAlertAction(title: i, style: .default, handler: {(action:UIAlertAction) in
                    self.licenseIntro = LicenseViewController()
                    self.licenseIntro?.delegate = self
                    // For iPad
                    if UI_USER_INTERFACE_IDIOM() == .pad {
                        self.licenseIntro?.modalPresentationStyle = .pageSheet
                    }
                    self.presentedViewController?.present(self.licenseIntro!, animated: false, completion: nil)
                }));
            case "Cancel":
                info?.addAction(UIAlertAction(title: i, style: .cancel, handler: nil));
            default:
                print("Button in UISheet not supported")
            }
        }
    }
    
    func reverseGeocoding(_ location: CLLocation) {
        // http://developer.apple.com/library/prerelease/ios/#documentation/UserExperience/Conceptual/LocationAwarenessPG/UsingGeocoders/UsingGeocoders.html#//apple_ref/doc/uid/TP40009497-CH4-SW1
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location, completionHandler: {(placemarks,error) -> Void in
            if placemarks != nil && placemarks!.count > 0 {
                let pl = placemarks![0]
                if pl.isoCountryCode != nil {
                    self.metadataDict["country"] = pl.isoCountryCode
                }
                if pl.administrativeArea != nil {
                    self.metadataDict["admin_area"] = pl.administrativeArea
                }
                if pl.subLocality != nil {
                    self.metadataDict["sublocality"] = pl.subLocality
                }
                if pl.subThoroughfare != nil {
                    self.metadataDict["subthroroughfare"] = pl.subThoroughfare
                }
                if pl.thoroughfare != nil {
                    self.metadataDict["throroughfare"] = pl.thoroughfare
                }
                if pl.name != nil {
                    self.metadataDict["name"] = pl.name
                }
                if pl.inlandWater != nil {
                    self.metadataDict["inlandwater"] = pl.inlandWater
                }
                if pl.ocean != nil {
                    self.metadataDict["ocean"] = pl.ocean
                }
                if pl.areasOfInterest != nil && pl.areasOfInterest!.count > 0 {
                    self.metadataDict["closestaoi"] = pl.areasOfInterest?[0]
                    self.metadataDict["numaoi"] = "\(pl.areasOfInterest!.count)"
                }
                if pl.locality != nil {
                    self.metadataDict["locality"] = pl.locality
                }
                if pl.postalCode != nil {
                    self.metadataDict["pc"] = pl.postalCode
                }
            }
        })
    }
    
    func executeVideo(videoName:String){
        self.videoIntro = VideoViewController(video: videoName, with: .crossDissolve, withCanBeStopped: false)
        show_help = false
        self.videoIntro?.delegate = self
        self.presentedViewController?.present(self.videoIntro!, animated: false, completion: nil)
    }
}
