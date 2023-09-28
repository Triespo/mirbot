//
//  FinalViewController.swift
//  mirbot
//
//  Created by Miguel Ángel Jareño Escudero on 19/09/2017.
//  Copyright © 2017 Master Móviles. All rights reserved.
//
//  Represent reaction from robot in case it is right or not with lemma choosen. User can put a label on the image sended

import Alamofire

class FinalViewController: UIViewController, UITextFieldDelegate, ConnectionDelegate {
    
    var ident: String = ""
    @IBOutlet weak var robotMessageTextView: CustomTextView!
    var oldClassifiedImage: ClassifiedImage?
    var newClassifiedImage: ClassifiedImage?
    var catLabel: String = ""
    var receivedData: Data?
    var labelOfFirstObject: String = ""
    // v1.1
    var robotText: String = ""
    var similarity: String = ""
    var activeTextField: UITextField?
    var textField: UITextField?
    var infoView: CustomTextView?
    @IBOutlet var robotView: UIImageView!
    // Response dictionary
    var responseDict = [AnyHashable: Any]()
    // Wiki button
    var wikiButton: UISegmentedControl?
    @IBOutlet var toolBar: UIToolbar!
    @IBOutlet var theScrollView: UIScrollView!
    // Connection
    var theConnection: Connection?
    var robotImageName: String = ""
    var shouldspeak: Bool = false
    var spinnerView: UIView?
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UI_USER_INTERFACE_IDIOM() == .pad {
            return .all
        }
        else {
            return .portrait
        }
    }
    
    func parseMetadata(_ input: String) {
        var jsonObject = [String:Any]()
        
        if let data = input.data(using: String.Encoding.utf8) {
            do {
                jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as! [String:Any]
                let similarity = jsonObject["similarity"] as! [String:Any]
                let new_badges = jsonObject["new_badges"] as! [[String:Any]]
                
                responseDict["similarity"] = jsonObject["similarity"]
                responseDict["similarity_level"] = similarity["similarity_level"]
                self.similarity = String(describing: responseDict["similarity_level"]!)
                responseDict["similarity_lemma"] = similarity["similarity_lemma"]
                responseDict["new_badges"] = new_badges
            } catch {
                print(error.localizedDescription)
            }
            didEndParsing()
        }
    }
    
    func showAlert(_ title: String, _ message: String,_ photo: String) {
        AlertControllerSingleButton.showAlertWithImage(title, withPhoto: photo, withMessage: message, withButtonTitle: "OK", in: self)
    }
    
    init(oldClassifiedImage: ClassifiedImage, withNewClassifiedImage newClassifiedImage: ClassifiedImage, withIdent ident: String, withReceivedData receivedData: Data, withLabelOfFirstObject labelOfFirstObject: String) {
        super.init(nibName: nil, bundle: nil)
        
        // Init dictionary
        responseDict = [AnyHashable: Any]()
        // Get data
        self.oldClassifiedImage = oldClassifiedImage
        self.newClassifiedImage = newClassifiedImage
        self.ident = ident
        self.labelOfFirstObject = labelOfFirstObject
        self.receivedData = receivedData
        // Parse response
        let response = String(data: self.receivedData!, encoding: String.Encoding.utf8)
        parseMetadata(response!)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        Utilities.stopspeech()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        theScrollView.setContentOffset(CGPoint.zero, animated: false)
        // Speech
        if shouldspeak {
            Utilities.startspeech(robotText)
            shouldspeak = false
        }
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShown), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if wikiButton != nil {
            wikiButton?.selectedSegmentIndex = UISegmentedControlNoSegment
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Show done button
        showDoneButton()
        shouldspeak = true
        showToolBar()
        showInfoButton()
        showTextField()
        textField?.delegate = self
        // Dynamic interface
        robotMessageTextView.text = robotText
        robotView.image = UIImage(named: robotImageName)
        if UI_USER_INTERFACE_IDIOM() == .pad {
            robotView.autoresizingMask = ([.flexibleTopMargin, .flexibleBottomMargin, .flexibleLeftMargin, .flexibleRightMargin])
        }
        
        do {
            let jsonParser = try JSONSerialization.jsonObject(with: self.receivedData!, options: []) as? [String : Any]
            for (key,value) in jsonParser! {
                if key == "new_badges"{
                    if let badges = value as? [[String : String]]{
                        for badge:[String:String] in badges{
                            self.showAlert(badge["title"]!, badge["description"]!, badge["image"]!)
                        }
                    }
                }
            }
        } catch {
            print("Error JSON")
        }
    }
    
    func showDoneButton() {
        navigationItem.hidesBackButton = true
        view.backgroundColor = UIColor.white
        navigationItem.title = "Result"
        let nextButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.restart))
        navigationItem.rightBarButtonItem = nextButton
    }
    
    func showToolBar() {
        toolBar.barStyle = .default
        toolBar.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        let wiki = UIBarButtonItem(image: UIImage(named: "wikipedia.png"), style: .plain, target: self, action: #selector(self.showWikiView))
        let tree = UIBarButtonItem(image: UIImage(named: "book.png"), style: .plain, target: self, action: #selector(self.showTreeView))
        toolBar.items = [UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), wiki, UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), tree, UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)]
    }
    
    func showInfoButton() {
        var infoButtonFrame: CGRect
        if UI_USER_INTERFACE_IDIOM() == .phone {
            infoButtonFrame = CGRect(x: 260, y: theScrollView.frame.size.height - 50, width: 18, height: 18)
        }
        else {
            infoButtonFrame = CGRect(x: (textField?.frame.origin.x)! + (textField?.frame.size.width)! + 60, y: theScrollView.frame.size.height - 110, width: 18, height: 18)
        }
        let infoButton = UIButton(type: .infoDark)
        infoButton.autoresizingMask = [.flexibleTopMargin, .flexibleLeftMargin, .flexibleRightMargin]
        infoButton.frame = infoButtonFrame
        infoButton.showsTouchWhenHighlighted = true
        infoButton.backgroundColor = UIColor.clear
        infoButton.addTarget(self, action: #selector(self.showHelp), for: .touchUpInside)
        theScrollView.addSubview(infoButton)
    }
    
    func showTextField() {
        var textFieldFrame: CGRect
        if UI_USER_INTERFACE_IDIOM() == .phone {
            textFieldFrame = CGRect(x: 20, y: theScrollView.frame.size.height - 60, width: 225, height: 40)
        }
        else {
            textFieldFrame = CGRect(x: theScrollView.center.x - 80, y: theScrollView.frame.size.height - 120, width: 160, height: 40)
        }
        textField = UITextField(frame: textFieldFrame)
        textField?.borderStyle = .roundedRect
        textField?.font = UIFont.systemFont(ofSize: 15)
        textField?.placeholder = "Label (optional)"
        if(labelOfFirstObject != ""){
            textField?.text = labelOfFirstObject
        }
        // v1.1
        textField?.autocorrectionType = .no
        textField?.keyboardType = .default
        textField?.returnKeyType = .done
        textField?.clearButtonMode = .whileEditing
        textField?.contentVerticalAlignment = .center
        textField?.delegate = self
        textField?.autoresizingMask = [.flexibleTopMargin, .flexibleLeftMargin, .flexibleRightMargin, .flexibleWidth]
        theScrollView.addSubview(textField!)
    }
    
    @objc func restart() {
        if catLabel.count != 0 {
            sendLabel()
        }
        else {
            navigationController?.popToRootViewController(animated: false)
        }
    }
    
    @objc func showWikiView() {
        let wvc: WebViewController? = Utilities.createWikiView((newClassifiedImage?.lemma)!)
        wvc?.modalTransitionStyle = .coverVertical
        present(wvc!, animated: true)
    }
    
    @objc func showTreeView(_ sender: Any) {
        let tvc = TreeViewController(id: (newClassifiedImage?.classid)!, withLemma: (newClassifiedImage?.lemma)!)
        tvc.modalTransitionStyle = .coverVertical
        tvc.modalPresentationStyle = .formSheet
        present(tvc, animated: true)
    }
    
    @objc func showHelp(_ sender: Any?) {
        AlertControllerSingleButton.showAlert("Help", withMessage: kMessageHelpLabel, withButtonTitle: "OK", in: self)
    }
    
    func sendLabel() {
        // Filter label characters
        var labelString: String = catLabel.replacingOccurrences(of: "\"", with: "\\\"")
        labelString = labelString.replacingOccurrences(of: "\'", with: "\\\'")
        labelString = labelString.replacingOccurrences(of: "<", with: " ")
        // < and > are directly removed
        labelString = labelString.replacingOccurrences(of: ">", with: " ")
        labelString = labelString.replacingOccurrences(of: "&", with: " and ")
        // Start connection
        let userId = UserDefaults.standard.object(forKey: "userid") as! String
        let urlString: String = Test.getURL()
        let PHPparams: String = "user/\(userId)/images/\(ident)/label"
        theConnection = Connection()
        theConnection?.delegate = self
        let params: Parameters = ["label":"\(labelString)"]
        theConnection?.startV1(urlString, withPHPParams: PHPparams, method: "PUT", params: params, headers: [:])
        // Show spinner
        let topView: UIView? = navigationController?.topViewController?.view
        spinnerView = ActivityViewController.showActivityView(topView!)
    }
    
    // MARK: textFieldDelegate methods
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Cut nsstring to have at maximum kMaxLabel length
        var catLabelRange: NSRange = NSMakeRange(0,min((textField.text?.count)!, kMaxLabel))
        // adjust the range to include dependent chars
        catLabelRange = (textField.text! as NSString).rangeOfComposedCharacterSequences(for: catLabelRange)
        catLabel = (textField.text! as NSString).substring(with: catLabelRange)
        navigationItem.rightBarButtonItem?.isEnabled = true
        textField.resignFirstResponder()
        return true
    }
    
    @objc func keyboardWillShown(_ notification: Notification) {
        let keyboardSize: CGSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)!.cgRectValue.size
        var shift: Float
        shift = Float(keyboardSize.width - toolBar.frame.size.height/2)
        theScrollView.setContentOffset(CGPoint(x: 0, y: CGFloat(shift)), animated: true)
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        theScrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
        navigationItem.rightBarButtonItem?.isEnabled = true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        navigationItem.rightBarButtonItem?.isEnabled = false
    }
    
    // MARK: -
    // MARK: Connection delegate
    func didFinishConnection() {
        if self.theConnection?.receivedData != nil{
            // Hide spinner
            ActivityViewController.hideActivityView(spinnerView!)
            // Connection for sending the label
            navigationController?.popToRootViewController(animated: false)
        }
    }
    
    func didFailedConnection() {
        // Hide spinner
        ActivityViewController.hideActivityView(spinnerView!)
    }
    
    deinit {
        theConnection?.delegate = nil
        theConnection = nil
        NotificationCenter.default.removeObserver(self)
    }
    
    func didEndParsing() {
        let sim: Float = Float(similarity)!
        if (newClassifiedImage?.classid == oldClassifiedImage?.classid) {
            robotText = kSuccess
            robotImageName = "robot_ok.jpg"
        }
        else if (oldClassifiedImage?.classid == "-1") {
            robotText = kNoIdea
            robotImageName = "robot_down.jpg"
        }
        else {
            if sim == 0 {
                robotText = kCompletelyWrong
                robotImageName = "robot_lied.jpg"
            }
            else {
                if sim >= 0 && sim < 33 {
                    robotText = String(format: kSimilar1, (oldClassifiedImage?.lemma)!, (newClassifiedImage?.lemma)!, "\(responseDict["similarity_lemma"]!)")
                    robotImageName = "robot_head.jpg"
                }
                else if sim >= 33 && sim < 66 {
                    robotText = String(format: kSimilar2, (oldClassifiedImage?.lemma)!, (newClassifiedImage?.lemma)!, "\(responseDict["similarity_lemma"]!)")
                    robotImageName = "robot_down.jpg"
                }
                else if sim >= 66 {
                    robotText = String(format: kSimilar3, (oldClassifiedImage?.lemma)!, (newClassifiedImage?.lemma)!, "\(responseDict["similarity_lemma"]!)")
                    robotImageName = "robot_lookup.jpg"
                }
            }
        }
    }
}
