//
//  CameraViewController.swift
//  mirbot
//
//  Created by Master Móviles on 21/07/2017.
//  Copyright © 2017 Master Móviles. All rights reserved.
//
//  It shows an overlay in FirstViewController with an image in real time from device's camera

import AVFoundation

protocol CameraDelegate: class {
    func didTakePhoto(_ photo: UIImage, withEXIFData exif: [AnyHashable: Any])
}

class CameraViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    
    private var simulatorIsCameraRunning: Bool = false
    private var _noCameraInSimulatorMessage: UILabel?
    private(set) var isCameraRunning: Bool = false
    var overlay: UIView?
    weak var delegate: CameraDelegate?
    // By default, flash is off
    var flash: Bool = false
    var isFrontCamera: Bool = false
    var settings: AVCapturePhotoSettings?
    var captureSession: AVCaptureSession?
    var cameraOutput: AVCapturePhotoOutput?
    var captureVideoPreviewLayer: AVCaptureVideoPreviewLayer?
    var isTakingPhoto: Bool = false
    var device: AVCaptureDevice?
    var autoExposureTimer: Timer?
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UI_USER_INTERFACE_IDIOM() == .pad {
            return .all
        }
        else {
            return .portrait
        }
    }
    
    var noCameraInSimulatorMessage: UILabel? {
        if !(_noCameraInSimulatorMessage != nil) {
            let labelWidth: CGFloat = view.bounds.size.width * 0.75
            let labelHeight: CGFloat = 60
            _noCameraInSimulatorMessage = UILabel(frame: CGRect(x: view.center.x - labelWidth / 2.0, y: view.bounds.size.height - 75 - labelHeight, width: labelWidth, height: labelHeight))
            _noCameraInSimulatorMessage?.numberOfLines = 0
            // wrap
            _noCameraInSimulatorMessage?.text = "Sorry, no camera in the simulator... Crying allowed."
            _noCameraInSimulatorMessage?.backgroundColor = UIColor.clear
            _noCameraInSimulatorMessage?.isHidden = true
            _noCameraInSimulatorMessage?.textColor = UIColor.white
            _noCameraInSimulatorMessage?.shadowOffset = CGSize(width: 1, height: 1)
            _noCameraInSimulatorMessage?.textAlignment = .center
            view.addSubview(_noCameraInSimulatorMessage!)
        }
        return _noCameraInSimulatorMessage
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        #if arch(i386) || arch(x86_64)
            noCameraInSimulatorMessage?.isHidden = false
        #endif
    }
    
    deinit {
        //3
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
    }

    init(overlay overlayView: UIView) {
        super.init(nibName: nil, bundle: nil)
        
        overlay = overlayView
        flash = false
        // Default flash mode
        isFrontCamera = false
        // Default camera mode
        // To correct orientation bug in iOS
        /*if UI_USER_INTERFACE_IDIOM() == .pad {
            NotificationCenter.default.addObserver(self, selector: #selector(self.orientationChanged), name: UIDeviceOrientationDidChangeNotification, object: nil)
        }*/
        
    }
    
    convenience init(from photoSettings: AVCapturePhotoSettings){
        self.init(from: photoSettings)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setup()
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopCamera()
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    func setup() {
        isTakingPhoto = false
        startCamera()
    }
    
    func startCamera() {
        overlay?.isUserInteractionEnabled = true

        #if arch(i386) || arch(x86_64)
            simulatorIsCameraRunning = true
            return
        #endif

        if !view.subviews.contains(overlay!) {
            view.addSubview(overlay!)
        }
        if !isCameraRunning {
            DispatchQueue.global(qos: .default).async(execute: {() -> Void in
                self.device = AVCaptureDevice.default(for: AVMediaType.video)
                
                if (self.captureSession == nil) {
                    self.captureSession = AVCaptureSession()
                    self.captureSession?.sessionPreset = AVCaptureSession.Preset.photo
                    let error: Error? = nil
                    let newVideoInput = try? AVCaptureDeviceInput(device: self.device!)
                    if newVideoInput == nil {
                        // Handle the error appropriately.
                        print("ERROR: trying to open camera: \(error.debugDescription)")
                    }else{
                        self.captureSession?.addInput(newVideoInput!)
                    }
                    
                    self.cameraOutput = AVCapturePhotoOutput()
                    
                    //moved to the photoOutput
                    if (self.captureSession?.canAddOutput(self.cameraOutput!))! {
                        self.captureSession?.addOutput(self.cameraOutput!)
                    }
                    
                    let notificationCenter = NotificationCenter.default
                    notificationCenter.addObserver(self, selector: #selector(self.onVideoError), name: NSNotification.Name.AVCaptureSessionRuntimeError, object: self.captureSession)
                    if (self.captureVideoPreviewLayer == nil) {
                        self.captureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession!)
                        
                        DispatchQueue.main.async {
                            self.captureVideoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
                            self.captureVideoPreviewLayer?.frame = (self.overlay?.bounds)!
                            self.overlay?.layer.insertSublayer(self.captureVideoPreviewLayer!, at: 0)
                        }
                    }
                }
                // this will block the thread until camera is started up
                self.captureSession?.startRunning()
            })
        }
    }
    
    @objc func onVideoError(_ notification: Notification) {
        print("Video error: \(String(describing: notification.userInfo?[AVCaptureSessionErrorKey]))")
    }
    
    func stopCamera() {
        overlay?.isUserInteractionEnabled = false
        #if arch(i386) || arch(x86_64)
            simulatorIsCameraRunning = false
            return
        #endif
        autoExposureTimer?.invalidate()
        autoExposureTimer = nil
        if (captureSession != nil) && (captureSession?.isRunning)! {
            DispatchQueue.global(qos: .default).async(execute: {() -> Void in
                self.captureSession?.stopRunning()
            })
        }
    }
    
    @objc func orientationChanged() {
        let previewLayer: AVCaptureVideoPreviewLayer? = self.captureVideoPreviewLayer
        let connection: AVCaptureConnection? = previewLayer?.connection
        //let orientation: UIDeviceOrientation = UIDevice.current.orientation
        let orientation = UIInterfaceOrientation(rawValue: UIApplication.shared.statusBarOrientation.rawValue)
        if connection != nil {
            if orientation == .landscapeLeft {
                connection?.videoOrientation = .landscapeLeft
            }
            else if orientation == .landscapeRight {
                connection?.videoOrientation = .landscapeRight
            }
            else if orientation == .portrait {
                connection?.videoOrientation = .portrait
            }
            else if orientation == .portraitUpsideDown {
                connection?.videoOrientation = .portraitUpsideDown
            }
        }
        captureVideoPreviewLayer?.connection?.videoOrientation = (connection?.videoOrientation)!
        captureVideoPreviewLayer?.frame = (overlay?.bounds)!
        captureVideoPreviewLayer?.setNeedsDisplay()
        captureVideoPreviewLayer?.setNeedsLayout()
    }
    
    func takePhoto() {
        if !isTakingPhoto {
            isTakingPhoto = true
            
            self.settings = AVCapturePhotoSettings()
            if flash{
                settings?.flashMode = .on
            }else{
                settings?.flashMode = .off
            }
            let previewPixelType = self.settings?.__availablePreviewPhotoPixelFormatTypes.first!
            let previewFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
                                 kCVPixelBufferWidthKey as String: 160,
                                 kCVPixelBufferHeightKey as String: 160,
                                 ]
            self.settings?.previewPhotoFormat = previewFormat as Any as? [String : Any]
            
            DispatchQueue.global(qos: .default).async(execute: {() -> Void in
                #if arch(i386) || arch(x86_64)
                    self.delegate?.didTakePhoto(UIImage(named: "Simulator_OriginalPhoto@2x.jpg")!, withEXIFData: [:])
                    return
                #else
                    var videoConnection: AVCaptureConnection? = nil
                    
                    for connection: AVCaptureConnection in (self.cameraOutput?.connections)! {
                        for port: AVCaptureInput.Port in connection.inputPorts {
                            if port.mediaType._rawValue.isEqual(to: AVMediaType.video.rawValue) {
                                videoConnection = connection
                                break
                            }
                        }
                        if videoConnection != nil {
                            break
                        }
                    }
                    self.cameraOutput?.capturePhoto(with: self.settings!, delegate: self)
                #endif
            })
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        if(error != nil){
            self.presentAlertWithTitle(title: "Camera error", message: error!.localizedDescription)
        }
    }
     
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingLivePhotoToMovieFileAt outputFileURL: URL, duration: CMTime, photoDisplayTime: CMTime, resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        if(error != nil){
            self.presentAlertWithTitle(title: "Camera error", message: error!.localizedDescription)
        }
    }
    
    func setFlashOn() {
        if !flash {
            flash = true
        }
    }
    
    func setFlashOff() {
        if flash {
            flash = false
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error:Error?){
        let imageData: Data? = photo.fileDataRepresentation()
        let orientation: UIDeviceOrientation = UIDevice.current.orientation
        // Ok, well captured
        let image = UIImage.init(data: imageData!)
        // Add correct orientation
        let orientedImage: UIImage? = self.store(image!, with: orientation)
        let exif = photo.metadata["{Exif}"] as? [String: Any]
        delegate?.didTakePhoto(orientedImage!, withEXIFData: (exif)!)
    }
    
    func store(_ oldimage: UIImage, with orientation: UIDeviceOrientation) -> UIImage {
        var newImage: UIImage? = nil,oldImageAux: UIImage? = nil
        var imageOrientation: UIImageOrientation = .up
        // Flip (mirroring) for front camera
        if isFrontCamera {
            oldImageAux = flip(oldimage)
        }

        switch orientation {
            case .portrait,.faceUp,.faceDown,.unknown:
                imageOrientation = .up
            case .portraitUpsideDown:
                imageOrientation = .down
            case .landscapeLeft:
                imageOrientation = .left
            case .landscapeRight:
                imageOrientation = .right
        }
        
        if oldImageAux == nil{
            oldImageAux = oldimage
        }
        newImage = UIImage(cgImage: (oldImageAux?.cgImage)!, scale: (oldImageAux?.scale)!, orientation: imageOrientation)
        
        return newImage!
    }
    
    func flip(_ image: UIImage) -> UIImage {
        UIGraphicsBeginImageContext(image.size)
        UIGraphicsGetCurrentContext()?.draw(image.cgImage!, in: CGRect(x: 0.0, y: 0.0, width: image.size.width, height: image.size.height))
        let i: UIImage? = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return i!
    }
}

extension CameraViewController{
    func presentAlertWithTitle(title: String, message : String){
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let closeAction = UIAlertAction(title: "Close", style: .default)
        alertController.addAction(closeAction)
        self.present(alertController, animated: true, completion: nil)
    }
}
