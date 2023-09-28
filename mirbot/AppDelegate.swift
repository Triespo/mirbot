//
//  AppDelegate.swift
//  mirbot
//
//  Created by Master Móviles on 13/07/2017.
//  Copyright © 2017 Master Móviles. All rights reserved.
//
// Main class of the application. It loads dictionary and persistency variables from user.

import CoreData
import AVFoundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UINavigationControllerDelegate,ConnectionDelegate {

    var window: UIWindow?
    var navController: CustomNavigationController?
    // Database variables
    var databaseName: String = ""
    var databasePath: String = ""
    var listContent = [String]()
    var rootController: FirstViewController?
    @objc var firstTime: NSNumber?
    @objc var firstClassifiedObject: NSNumber?
    var speechSynthesizer: AVSpeechSynthesizer?
    // checks if it is the first time that the app is being executed by the user (for showing license and help videos)
    var progressView: UIView?
    var mDocumentsPath: String = ""
    var theConnection: Connection?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        application.isStatusBarHidden = true
        window = UIWindow(frame: UIScreen.main.bounds)
        initialize()
        initSynthesizer()
        setupByPreferences()
        rootController = FirstViewController()
        navController = CustomNavigationController(rootViewController: rootController!)
        navController?.delegate = self
        navController?.toolbar.isTranslucent = false
        window?.rootViewController = navController
        window?.makeKeyAndVisible()
        
        return true
    }
    
    var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UI_USER_INTERFACE_IDIOM() == .pad {
            return .all
        }
        else {
            return .portrait
        }
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "mirbot")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    func initialize() {
        // Setup some globals
        databaseName = kDBName
        // Get the path to the documents directory and append the databaseName
        fillData()
    }

    func fillData(){
        theConnection = Connection()
        theConnection?.delegate = self
        let urlString: String = Test.getURL()
        let PHPparams = "wordnet"
        theConnection?.startV1(urlString, withPHPParams: PHPparams,method: "GET")
    }
    
    func initSynthesizer() {
        speechSynthesizer = AVSpeechSynthesizer()
    }
    
    func setupByPreferences() {
        // Set firstTime to NO, it will change to true if a new userid is created
        firstTime = false
        firstClassifiedObject = false
        // Check userid
        let testValue: String? = UserDefaults.standard.string(forKey: "userid")
        // If no userid is found in NSUserDefaults, check keychain and iCloud
        if testValue == nil {
            // Get userid from keychain (if it was not found in keychain, from iCloud)
            let userId: String = BPXLUUIDHandler.uuid()
            // Propagate userId to NSUserDefaults
            UserDefaults.standard.set(userId, forKey: "userid")
            // Not really important variables, reset if NSStandardUserDefaults didn't have any value
            UserDefaults.standard.set("NO", forKey: "onlyuser")
            UserDefaults.standard.set("YES", forKey: "speech")
            if isTest{
                UserDefaults.standard.set("YES", forKey: "test")
            }
            UserDefaults.standard.synchronize()
        }
        let isUpdate: String? = UserDefaults.standard.string(forKey: "updated2.5")
        if isUpdate == nil {
            UserDefaults.standard.set("NO", forKey: "onlyuser")
            UserDefaults.standard.set("YES", forKey: "updated2.5")
        }
    }
    
    func didFinishConnection() {
        if self.theConnection?.receivedData != nil{
            let response = String(data: (theConnection?.receivedData)!, encoding: String.Encoding.utf8)
            let data = response?.data(using: String.Encoding.utf8)
            do {
                if(String(response!.prefix(1))=="{" && String(response!.suffix(1))=="}"){
                    let jsonParser = try JSONSerialization.jsonObject(with: data!, options: []) as? [String : Any]
                    if(jsonParser!["lemmas"] != nil){
                        let lemmas = jsonParser!["lemmas"] as! [String]
                        self.listContent = lemmas
                    }
                }
            } catch {
                print("Error JSON")
            }
        }
    }
    
    func didFailedConnection() {
    }
}

