//
//  SendViewController.swift
//  mirbot
//
//  Created by Master Móviles on 06/08/2017.
//  Copyright © 2017 Master Móviles. All rights reserved.
//
//  View where shows message with lemma find by robot and a segmentedControl for the user send if it agree

import Alamofire

class SendViewController: UIViewController, ConnectionDelegate {
    var previousResponse: String = ""
    weak var userimage: UIImage?
    @IBOutlet var infoView: CustomTextView!
    
    @IBOutlet var segmentedControl: UISegmentedControl!
    @IBOutlet var robotView: UIImageView!
    @IBOutlet var objectView: UIImageView!

    var currScore: String = ""
    var currLabel: String = ""
    // v1.1
    // Response dictionary with image identifier
    var responseDict = [String: Any]()
    // Array of classified images
    var classifiedImages = [ClassifiedImage]()
    // Image proposed by the system
    var oldClassifiedImage: ClassifiedImage?
    // Connection
    var theConnection: Connection?
    var finalVC: FinalViewController?
    var listContent = [ClassifiedImage]()
    var shouldspeak: Bool = false
    var labelOfFirstObject: String = ""
    var counter = Int()
    var myGroup = DispatchGroup()

    var spinnerView: UIView?
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        // Solved infoView resize problem with rotation
        infoView.setNeedsDisplay()
        infoView.setNeedsLayout()
    }
    
    init(){
        super.init(nibName: nil, bundle: nil)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    deinit {
        theConnection?.delegate = nil
        theConnection = nil
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UI_USER_INTERFACE_IDIOM() == .pad {
            return .all
        }
        else {
            return .portrait
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Speech
        myGroup.notify(queue: .main) {
            if self.shouldspeak {
                Utilities.startspeech(self.infoView.text)
                self.shouldspeak = false
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        segmentedControl?.selectedSegmentIndex = UISegmentedControlNoSegment
        view.isUserInteractionEnabled = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NSObject.cancelPreviousPerformRequests(withTarget: self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        Utilities.stopspeech()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // appDelegate is used to see if this is the first object which is being classified by the user
        let appDelegate: AppDelegate? = (UIApplication.shared.delegate as? AppDelegate)
        view.backgroundColor = UIColor.white
        // Add image for ipad
        if UI_USER_INTERFACE_IDIOM() == .pad {
            robotView?.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin]
            setupObjectView()
        }
        // Init metadata dictionary and classified images array
        responseDict = [String: Any]()
        classifiedImages = [ClassifiedImage]()
        // Parse results from server
        parseMetadata(previousResponse)
        // Get additional information from idclass

        for i in 0..<classifiedImages.count {
            if Int(classifiedImages[i].classid)! > -1{
                myGroup.enter()
                let urlString: String = Test.getURL()
                let PHPparams = "wordnet/class/\(classifiedImages[i].classid)"
                Alamofire.request(URL(string: urlString+PHPparams)!, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: nil).responseJSON(completionHandler: {response in
                    if response.result.isSuccess{
                        
                        do{
                            let jsonParser = try JSONSerialization.jsonObject(with: response.data!, options: []) as? [String : Any]
                            self.classifiedImages[self.counter].definition = jsonParser!["definition"] as! String
                        }catch{
                            print("Error Json getting definition in SendViewController")
                        }
                        
                        self.counter += 1
                        self.myGroup.leave()
                    } else {
                        self.theConnection?.presentAlertWithTitle(title: kErrorConnection, message: (response.result.error?.localizedDescription)!)
                    }
                })
                //Entered in this when all myGroup.stop() have been finished by myGroup.leave()
                myGroup.notify(queue: .main) {
                    // Only done when this option is selected (for efficiency)
                    // Get oldClassifiedImage (v1.1, it was before in the previous function without copy)
                    self.oldClassifiedImage = self.classifiedImages[0]
                    // Set value of resultclass (best classified image)
                    let im = self.classifiedImages[0]
                    self.responseDict["resultclass"] = im.classid
                    // Fill text content
                    var textContent: String
                    // Threshold indicates the acceptable value (otherwise, unknown class). Lower is best
                    let sure_thresholdAux = String(describing: self.responseDict["sure_threshold"]!)
                    let sure_threshold = NSNumber(value: Float(sure_thresholdAux)!)
                    let known_thresholdAux = String(describing: self.responseDict["known_threshold"]!)
                    let known_threshold = NSNumber(value: Float(known_thresholdAux)!)
                    
                    // Unknown class
                    if im.classid == "-1" || im.score?.compare(known_threshold) == .orderedDescending {
                        self.segmentedControl?.isHidden = true
                        if appDelegate?.firstClassifiedObject == true {
                            textContent = kMessageFirstClassifiedObject
                            appDelegate?.firstClassifiedObject = false as NSNumber
                        }
                        else {
                            textContent = kMessageNewClass
                        }
                        if im.classid != "-1" {
                            // If the score is greater than the threshold, then assign -1 to resultclass
                            self.responseDict["resultclass"] = "-1"
                        }
                        let nextButton = UIBarButtonItem(title: "Answer", style: .plain, target: self, action: #selector(self.launchDictionaryView))
                        self.navigationItem.rightBarButtonItem = nextButton
                        // v1.1
                        self.oldClassifiedImage?.classid = "-1"
                    }
                    else {
                        // Generate robot message
                        textContent = self.generateRobotMessage(im, withSureThreshold: sure_threshold, withKnownThreshold: known_threshold)
                        // Show segmented control
                        self.showSegmentedControl()
                    }
                    // Show infoView
                    self.showInfoView(textContent)
                    self.shouldspeak = true
                }
            }
        }
    }
    
    //That's only for iPad
    func setupObjectView() {
        objectView.image = userimage
        objectView.layer.shadowColor = UIColor.gray.cgColor
        objectView.layer.shadowOffset = CGSize(width: 0, height: 1)
        objectView.layer.shadowOpacity = 1
        objectView.layer.shadowRadius = 5.0
        objectView.clipsToBounds = false
        objectView.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin]
        objectView.setNeedsDisplay()
    }
    
    func parseMetadata(_ input: String) {
        var jsonObject = [String:Any]()
        
        if let data = input.data(using: String.Encoding.utf8) {
            do {
                jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as! [String:Any]
                let classification = jsonObject["classification"] as! [[String:Any]]
                
                responseDict["sure_threshold"] = jsonObject["sure_threshold"]
                responseDict["known_threshold"] = jsonObject["known_threshold"]
                responseDict["imageID"] = jsonObject["imageID"]
                responseDict["classification"] = classification
                
                for element in classification {
                    let im: ClassifiedImage? = ClassifiedImage(classid: element["class"] as! String,
                                                               score: NSNumber(value: Float("\(element["score"]!)")!),
                                                               lemma: element["lemma"] as? String ?? "", definition: "",
                                                               label: element["label"] as! String)
                    
                    self.classifiedImages.append(im!)
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    @objc func launchDictionaryView() {
        let theDictViewController = DictViewController()
        theDictViewController.responseDict = responseDict
        theDictViewController.oldClassifiedImage = oldClassifiedImage
        // v1.1, changed
        navigationController?.pushViewController(theDictViewController, animated: true)
    }
    
    func generateRobotMessage(_ im: ClassifiedImage, withSureThreshold sure: NSNumber, withKnownThreshold known: NSNumber) -> String {
        var textContent: String
        let lemma: String = im.lemma
        let definition: String = im.definition
        let label: String = im.label
        // v1.1
        // Update title
        navigationItem.title = Utilities.upperFirstLetter(lemma)
        // Generate message
        var scoretoindex = CDouble(truncating: im.score!) - CDouble(truncating: sure)
        if scoretoindex < 0 {
            scoretoindex = 0
        }
        let r = Int(10 * scoretoindex * (1.0 / (CDouble(truncating: known) - CDouble(truncating: sure))))
        let messages: [Any] = [kObjectMessage1, kObjectMessage2, kObjectMessage3, kObjectMessage4, kObjectMessage5, kObjectMessage6, kObjectMessage7, kObjectMessage8, kObjectMessage9, kObjectMessage10, kObjectMessage11]
        let theMessage: String = (messages[r] as? String)!
        let index = lemma.index(lemma.startIndex, offsetBy: 1)
        let firstletter = lemma[..<index]
        if label == "" {
            if firstletter == "a" || firstletter == "e" || firstletter == "i" || firstletter == "o" {
                textContent = "\(theMessage) \(lemma), \(definition)"
            }
            else {
                textContent = "\(theMessage) \(lemma), \(definition)"
            }
        }
        else {
            if firstletter == "a" || firstletter == "e" || firstletter == "i" || firstletter == "o" {
                textContent = "\(theMessage) \(lemma) (\(label)), \(definition)"
            }
            else {
                textContent = "\(theMessage) \(lemma) (\(label)), \(definition)"
            }
            labelOfFirstObject = label
            // v1.1
        }
        return textContent
    }
    
    func showSegmentedControl() {
        segmentedControl?.selectedSegmentIndex = UISegmentedControlNoSegment
        segmentedControl?.addTarget(self, action: #selector(self.pickValue), for: .valueChanged)
    }
    
    func showInfoView(_ textContent: String) {
        var frame: CGRect
        
        frame = CGRect(x: 5, y: 5, width: 310, height: 0)
        infoView = CustomTextView(frame: frame, withText: textContent, withParentView: view)
        infoView.center = CGPoint(x: view.center.x, y: infoView.center.y)
        infoView.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin, .flexibleWidth, .flexibleLeftMargin, .flexibleRightMargin, .flexibleHeight]
        infoView.setNeedsDisplay()
    }
    
    @objc func pickValue(_ sender: Any) {
        segmentedControl = (sender as? UISegmentedControl)
        view.isUserInteractionEnabled = false
        navigationController?.view?.isUserInteractionEnabled = false
        if segmentedControl?.selectedSegmentIndex == 0 {
            let ident: String = responseDict["imageID"] as? String ?? ""
            let userId = UserDefaults.standard.object(forKey: "userid") as! String
            let urlString: String = Test.getURL()
            let PHPparams = "user/\(userId)/images/\(ident)/confirm"
            theConnection = Connection()
            theConnection?.delegate = self
            let params: Parameters = ["class":"\(oldClassifiedImage!.classid)"]
            theConnection?.startV1(urlString, withPHPParams: PHPparams, method: "POST", params: params, headers: [:])
            // Show spinner
            let topView: UIView? = navigationController?.topViewController?.view
            spinnerView = ActivityViewController.showActivityView(topView!)
        }
        else if segmentedControl?.selectedSegmentIndex == 1 {
            navigationController?.view?.isUserInteractionEnabled = true
            launchAlternativesViewController()
        }
        
    }
    
    // MARK: ConnectionDelegate
    func didFinishConnection() {
        if self.theConnection?.receivedData != nil{

            finalVC = FinalViewController(oldClassifiedImage: oldClassifiedImage!, withNewClassifiedImage: oldClassifiedImage!,
                                          withIdent: responseDict["imageID"] as! String, withReceivedData: (theConnection?.receivedData!)!,
                                          withLabelOfFirstObject: labelOfFirstObject)
            navigationController?.pushViewController(finalVC!, animated: true)
            view.isUserInteractionEnabled = true
            navigationController?.view?.isUserInteractionEnabled = true
            ActivityViewController.hideActivityView(spinnerView!)
        }
    }
    
    func didFailedConnection() {
        segmentedControl?.selectedSegmentIndex = UISegmentedControlNoSegment
        view.isUserInteractionEnabled = true
        navigationController?.view?.isUserInteractionEnabled = true
        ActivityViewController.hideActivityView(spinnerView!)
    }
    
    func launchAlternativesViewController() {
        fillTable()
        if listContent.count != 1 {
            let av = AlternativesViewController(style: .grouped)
            av.oldClassifiedImage = oldClassifiedImage
            av.classifiedImages = classifiedImages
            av.responseDict = responseDict
            av.listContentReceived = listContent
            if UI_USER_INTERFACE_IDIOM() != .pad {
                navigationController?.pushViewController(av, animated: true)
            }
            /*else {
                let iPadAlternatives = iPadAlternativesViewController(nibName: "iPadAlternativesViewController", bundle: nil)
                iPadAlternatives.alternativesViewController = av
                navigationController?.pushViewController(iPadAlternatives as? UIViewController ?? UIViewController(), animated: true)
            }*/
        }
        else {
            launchDictionaryView()
        }
    }
    
    func fillTable() {
        listContent = [ClassifiedImage]()
        for i in 0..<classifiedImages.count {
            let im = classifiedImages[i]
            // Find repeated classid to avoid duplicates
            var ok: Bool = true
            var j = 0
            while j < listContent.count && ok {
                let tmp = listContent[j]
                if (tmp.classid == im.classid) {
                    ok = false
                }
                j += 1
            }
            if ok {
                listContent.append(im)
            }
        }
    }
}

