//
//  CameraViewiPhone.swift
//  mirbot
//
//  Created by Master Móviles on 08/08/2017.
//  Copyright © 2017 Master Móviles. All rights reserved.
//

import AVFoundation

class CameraViewiPhone: UIView {
    weak var delegate: FirstViewController?
    var cameraButtonImageView: UIImageView?
    var flashButton: UIBarButtonItem?
    var infoButton: UIBarButtonItem?
    var classificationButton: UIBarButtonItem?
    var theToolBar: UIToolbar?
    var theTopBar: UIToolbar?
    var camButton: UIButton?

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // Initialization code
        createToolBar()
        createTopBar()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func createToolBar() {
        let fullScreenRect: CGRect = UIScreen.main.bounds
        if !isPhone4s {
            theToolBar = UIToolbar(frame: CGRect(x: 0, y: fullScreenRect.size.height - 100, width: fullScreenRect.size.width, height: 100))
        }
        else {
            theToolBar = UIToolbar(frame: CGRect(x: 0, y: fullScreenRect.size.height - 55, width: fullScreenRect.size.width, height: 55))
        }
        theToolBar?.barStyle = .blackOpaque
        // Config button
        let configButton = UIBarButtonItem(image: UIImage(named: "preferences.png"), style: .plain, target: self, action: #selector(self.showSetupViewController))
        configButton.tintColor = UIColor.white
        // iOS7
        // Camera button
        var cameraButton: UIBarButtonItem?
        if !isPhone4s {
            createCamButtonPhone5()
        }
        else {
            createCamButton()
        }
        cameraButton = UIBarButtonItem(customView: camButton!)
        // Library button
        let libraryButton = UIBarButtonItem(image: UIImage(named: "photos.png"), style: .plain, target: self, action: #selector(self.showUserInfoViewController))
        libraryButton.tintColor = UIColor.white
        // iOS7
        let items: [Any] = [libraryButton, UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), cameraButton!, UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), configButton]
        theToolBar?.items = items as? [UIBarButtonItem] //as? [AVMetadataItem]
        // Camera button implemented using a UIImageView for rotation
        let camImage = UIImage(named: "camera-icon.png")
        cameraButtonImageView = UIImageView(image: camImage)
        if !isPhone4s {
            cameraButtonImageView?.frame = CGRect(x: bounds.size.width / 2 - (32 / 2), y: 38, width: 30, height: 24)
        }
        else {
            cameraButtonImageView?.frame = CGRect(x: bounds.size.width / 2 - (27 / 2), y: 17, width: 27, height: 22)
        }
        theToolBar?.addSubview(cameraButtonImageView!)
        addSubview(theToolBar!)
    }
    
    func createTopBar() {
        let fullScreenRect: CGRect = UIScreen.main.bounds
        if !isPhone4s {
            theTopBar = UIToolbar(frame: CGRect(x: 0, y: -5, width: fullScreenRect.size.width, height: 45))
        }
        else {
            theTopBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: fullScreenRect.size.width, height: 45))
        }
        // Set transparent
        theTopBar?.barStyle = .default
        theTopBar?.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
        // Create flash button
        let device = AVCaptureDevice.default(for: AVMediaType.video)
        if device?.hasFlash == true {
            flashButton = UIBarButtonItem(image: UIImage(named: "flashoff.png"), style: .plain, target: self, action: #selector(self.toggleFlash))
            flashButton?.tintColor = UIColor.white
            // iOS7
        }else{
            flashButton = UIBarButtonItem(image: UIImage(named: "flashoff.png"), style: .plain, target: self, action: nil)
            flashButton?.tintColor = UIColor.white
        }
        // Create info button
        let iButton = UIButton(type: .infoLight)
        iButton.tintColor = UIColor.white
        iButton.addTarget(self, action: #selector(self.showInfoViewController), for: .touchUpInside)
        infoButton = UIBarButtonItem(customView: iButton)
        
        // Create classification button
        classificationButton = UIBarButtonItem(image: UIImage(named: "trophy.png"), style: .plain, target: self, action: #selector(showAwards))
        classificationButton?.tintColor = UIColor.white
        
        // Insert items into bar
        let items: [Any] = [flashButton!,UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),classificationButton! ,UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), infoButton!]
        theTopBar?.items = items as? [UIBarButtonItem]
        addSubview(theTopBar!)
    }
    
    @objc func showAwards() {
        delegate?.showAwards()
    }
    
    @objc func showSetupViewController() {
        delegate?.showSetupViewController()
    }
    
    @objc func showUserInfoViewController() {
        delegate?.showUserInfoViewController()
    }
    
    @objc func showInfoViewController() {
        delegate?.showInfoViewController()
    }
    
    func createCamButton() {
        camButton = UIButton(type: .custom)
        camButton?.frame = CGRect(x: 0, y: 0, width: 90, height: 40)
        camButton?.addTarget(self, action: #selector(self.shootPicture), for: .touchUpInside)
        camButton?.showsTouchWhenHighlighted = true
        let imageBackground = UIImage(named: "camera-button.png")
        let imageCustom = imageBackground?.resizeWith(width: 90)
        camButton?.setBackgroundImage(imageCustom, for: .normal)
    }
    
    func createCamButtonPhone5() {
        camButton = UIButton(type: .custom)
        camButton?.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
        camButton?.addTarget(self, action: #selector(self.shootPicture), for: .touchUpInside)
        camButton?.showsTouchWhenHighlighted = true
        let imageBackground = UIImage(named: "camera-phone5-button.png")
        let imageCustom = imageBackground?.resizeWith(width: 80)
        camButton?.setBackgroundImage(imageCustom, for: .normal)
    }
    
    @objc func toggleFlash() {
        if delegate?.camera?.flash == false {
            let flashOnImage = UIImage(named: "flashon.png")
            flashButton?.image = flashOnImage
            delegate?.camera?.setFlashOn()
        }
        else {
            let flashOffImage = UIImage(named: "flashoff.png")
            flashButton?.image = flashOffImage
            delegate?.camera?.setFlashOff()
        }
    }
    
    @objc func shootPicture() {
        delegate?.camera?.takePhoto()
    }
}

extension UIImage{

    func resizeWith(width: CGFloat) -> UIImage? {
        let imageView = UIImageView(frame: CGRect(origin: .zero, size: CGSize(width: width, height: CGFloat(ceil(width/size.width * size.height)))))
        imageView.contentMode = .scaleAspectFit
        imageView.image = self
        UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        imageView.layer.render(in: context)
        guard let result = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
        UIGraphicsEndImageContext()
        return result
    }
}
