//
//  AwardsViewController.swift
//  mirbot
//
//  Created by Miguel Ángel Jareño Escudero on 14/10/2017.
//  Copyright © 2017 Master Móviles. All rights reserved.
//
//  It manages two view controllers. Classification and Badges.

class AwardsViewController: UITabBarController,ConnectionDelegate {
    
    private var spinnerView: UIView?
    var theConnection: Connection?
    var classificationController: ClassificationViewController?
    var badgesController: BadgesViewController?
    var PHPparams: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        classificationController = ClassificationViewController(navItem: self.navigationItem)
        badgesController = BadgesViewController(navItem: self.navigationItem)
        classificationController?.tabBarItem = UITabBarItem(
            title: "Classification",
            image: UIImage(named: "classification"),
            tag: 1)
        badgesController?.tabBarItem = UITabBarItem(
            title: "Badges",
            image:UIImage(named: "badge") ,
            tag:2)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sendServerInfo(parameter: "badges")
        self.navigationController?.isNavigationBarHidden = false
        self.selectedIndex = 1
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {

        super.viewWillDisappear(animated)
        navigationController?.popViewController(animated: false)
    }
    
//  This function asks information from the server depending what user's tab is interested in
    func sendServerInfo(parameter: String){
        let userid = UserDefaults.standard.object(forKey: "userid") as? String
        theConnection = Connection()
        theConnection?.delegate = self
        let urlString: String = Test.getURL()
        PHPparams = "user/\(userid!)/\(parameter)"
        theConnection?.startV1(urlString, withPHPParams: PHPparams,method: "GET")
        let topView: UIView? = navigationController?.topViewController?.view
        spinnerView = ActivityViewController.showActivityView(topView!)
    }

//  When there's a response by server. The controllers are loaded.
    func didFinishConnection() {
        if self.theConnection?.receivedData != nil{
            ActivityViewController.hideActivityView(spinnerView!)
            let response = String(data: (theConnection?.receivedData)!, encoding: String.Encoding.utf8)
            if (String(PHPparams.suffix(7)) == "ranking"){
                classificationController?.previousResponse = response!
                let controllers = [self.classificationController as Any,self.badgesController as Any] as! [UIViewController]
                self.viewControllers = controllers
            }else if(String(PHPparams.suffix(6)) == "badges"){
                badgesController?.previousResponse = response!
                sendServerInfo(parameter: "ranking")
            }
        }
    }
    
    func didFailedConnection() {
        // Hide spinner
        ActivityViewController.hideActivityView(spinnerView!)
    }
}
