//
//  VideoViewController.swift
//  mirbot
//
//  Created by Master Móviles on 06/08/2017.
//  Copyright © 2017 Master Móviles. All rights reserved.
//
//  Show video at the beginning if user is new or in the alert of FirstViewController

import AVKit

protocol VideoViewControllerDelegate: class {
    func didFinishVideoViewController(_ videofilename: String)
}

class VideoViewController: UIViewController {
    var videoFilename: String = ""
    var moviePlayerController: AVPlayerViewController?
    var moviePlayer: AVPlayer?
    var isCanBeStopped: Bool = false
    var stopView: UITextView?
    var delegate: FirstViewController?
    
    init(video videoName: String, with style: UIModalTransitionStyle, withCanBeStopped stop: Bool) {
        super.init(nibName: nil, bundle: nil)
        
        videoFilename = videoName
        modalTransitionStyle = style
        isCanBeStopped = stop
        
        if isCanBeStopped == true{
            self.createStopView()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UI_USER_INTERFACE_IDIOM() == .pad {
            return .all
        }
        else {
            return .portrait
        }
    }
    
    override func viewDidLoad() {
        // Create and setup the view
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        view.isUserInteractionEnabled = true
        view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
        tap.numberOfTapsRequired = 2
        view.addGestureRecognizer(tap)
        // Notification handling for background/resume states
        NotificationCenter.default.addObserver(self, selector: #selector(self.resignActive),
                                               name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.becomeActive),
                                               name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    }
    
    @objc func doubleTapped() {
        if delegate != nil{
            self.moviePlayerController?.view.isHidden = true
            delegate?.didFinishVideoViewController(videoFilename)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if (moviePlayerController == nil) {
            self.setup()
        }
    }
    
    // New in 2.4
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if isCanBeStopped {
            stopView?.center = CGPoint(x: view.frame.size.width - 110, y: view.frame.size.height - 70)
            stopView?.backgroundColor = UIColor.black
            view.addSubview(stopView!)
            showMessage()
        }
        playVideo()
    }
    
    @objc func resignActive(_ notification: Notification) {
        moviePlayer?.pause()
    }
    
    @objc func becomeActive(_ notification: Notification) {
        moviePlayer?.play()
    }
    
    func setup() {
        guard let filepath = Bundle.main.path(forResource: videoFilename, ofType: kVideoType)else{
            print("\(videoFilename) not found")
            return
        }
        let fileURL = URL.init(fileURLWithPath: filepath)
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: filepath) {
            print("File \(videoFilename+kVideoType) AVAILABLE")
        } else {
            print("File \(videoFilename+kVideoType) NOT AVAILABLE")
        }
        self.moviePlayer = AVPlayer.init(url: fileURL)
        moviePlayerController = AVPlayerViewController()
        moviePlayerController?.showsPlaybackControls = false
        moviePlayerController?.player = self.moviePlayer
        moviePlayerController?.view.isUserInteractionEnabled = false
        moviePlayerController?.view.frame = view.frame
        moviePlayerController?.view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        view.addSubview((moviePlayerController?.view)!)
            
        NotificationCenter.default.addObserver(self, selector: #selector(self.moviePlaybackComplete), name: .AVPlayerItemDidPlayToEndTime, object: moviePlayerController?.player?.currentItem)
    }
    
    func showMessage() {
        stopView?.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        stopView?.alpha = 0
        UIView.beginAnimations("showAlert", context: nil)
        UIView.setAnimationDelegate(self)
        stopView?.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        stopView?.alpha = 1
        UIView.commitAnimations()
        // Hide message after 3 seconds
        perform(#selector(self.hideMessage), with: nil, afterDelay: 3.0)
    }
    
    @objc func hideMessage() {
        UIView.beginAnimations("hideAlert", context: nil)
        UIView.setAnimationDelegate(self)
        stopView?.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        stopView?.alpha = 0
        UIView.commitAnimations()
    }
    
    func playVideo(){
        self.moviePlayer?.play()
    }
    
    func createStopView() {
        stopView = UITextView(frame: CGRect(x: 0, y: 0, width: 200, height: 30))
        stopView?.text = "[ Double tap to skip ]"
        stopView?.isUserInteractionEnabled = false
        stopView?.font = UIFont(name: "Verdana", size: 15)
        stopView?.isEditable = false
        stopView?.textAlignment = .center
        stopView?.backgroundColor = UIColor.clear
        stopView?.textColor = UIColor.gray
        stopView?.alpha = 0.5
    }
    
    @objc func moviePlaybackComplete(_ notification: Notification) {
        
        moviePlayerController = notification.object as? AVPlayerViewController
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: moviePlayerController?.player?.currentItem)
        moviePlayerController?.view.removeFromSuperview()
        
        if delegate != nil{
            delegate?.didFinishVideoViewController(videoFilename)
        }
    }
}
