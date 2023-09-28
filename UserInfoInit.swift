//
//  UserInfoInit.swift
//  mirbot
//
//  Created by Master Móviles on 16/08/2017.
//  Copyright © 2017 Master Móviles. All rights reserved.
//

import Foundation
import UIKit
import Alamofire

protocol UserInfoInitDelegate: class {
    func didFinishUserInfoInitDelegate()
    
    func didFailedUserInfoInitDelegate()
}

@objcMembers
class CategoryInfo: NSObject {
    var classid: String = ""
    var lemma: String = ""
    var definition: String = ""
    var n: NSNumber?
}

class UserInfoInit: NSObject, ConnectionDelegate{
    
    var userImages: NSMutableDictionary?
    var catInfo: NSMutableArray?
    var theConnection: Connection?
    var userStatistics: NSMutableDictionary?
    var globalStatistics: NSMutableDictionary?
    var delegate: UserInfoInitDelegate?
    var PHPparams: String?
    var identifier: Int = 0
    // Counter for ordering elements in a NSArray of statistics
    
    override init() {
        super.init()
        userImages = NSMutableDictionary()
        userStatistics = NSMutableDictionary()
        globalStatistics = NSMutableDictionary()
        identifier = 0
        sendUserInfo("images")
    }
    
    func sendUserInfo(_ parameter: String) {
        let userid = UserDefaults.standard.object(forKey: "userid") as? String
        theConnection = Connection()
        theConnection?.delegate = self
        let urlString: String = Test.getURL()
        PHPparams = "user/\(userid!)/\(parameter)"
        theConnection?.startV1(urlString, withPHPParams: PHPparams!,method: "GET")
    }
    
    // MARK: -
    // MARK: Connection delegate
    func didFinishConnection() {
        if self.theConnection?.receivedData != nil{
            let response = String(data: (theConnection?.receivedData)!, encoding: String.Encoding.utf8)
            
            if(self.PHPparams?.suffix(6)=="images"){
                setImagesFromUser(response!)
                sendUserInfo("stats")
            }else if(self.PHPparams?.suffix(5)=="stats"){
                setStatistics(response!)
                catInfo = NSMutableArray()
                let myGroup = DispatchGroup()
                allCategoriesInfo(myGroup)
                myGroup.notify(queue: .main) {
                    self.delegate?.didFinishUserInfoInitDelegate()
                }
            }
        }
    }
    
    func didFailedConnection() {
        delegate?.didFailedUserInfoInitDelegate()
    }
    
    func setImagesFromUser(_ response: String){
        
        do{
            let jsonParser = try JSONSerialization.jsonObject(with: response.data(using: String.Encoding.utf8)!, options: []) as? [String:Any]
            let array = jsonParser!["images"] as! [[String:Any]]
            for obj in array{
                let rem = RemoteImage()
                rem.imageid = obj["id"] as! String
                rem.classid = obj["class_id"] as! String
                rem.label = obj["label"] as? String ?? ""
                rem.url = obj["url"] as! NSString
                if userImages![rem.classid] == nil {
                    let tmparray = NSMutableArray()
                    tmparray.add(rem)
                    userImages![rem.classid] = tmparray
                }
                else {
                    let tmparray: NSMutableArray = (userImages![rem.classid] as? NSMutableArray)!
                    tmparray.add(rem)
                }
            }
        }catch {
            print("Error setting user images JSON")
        }
    }
    
    func setStatistics(_ response: String) {
        do{
            let jsonParser = try JSONSerialization.jsonObject(with: response.data(using: String.Encoding.utf8)!, options: []) as? [String:Any]
            let user_stats = jsonParser!["user_stats"] as? NSDictionary
            let global_stats = jsonParser!["global_stats"] as? NSDictionary
            
            setImageStatistics(user_stats!,global_stats!)
            setAnimalStats(user_stats!,global_stats!)
            setObjectStats(user_stats!,global_stats!)
            setFoodieStats(user_stats!,global_stats!)
            setPlantStats(user_stats!,global_stats!)
        }catch {
            print("Error setting user stats JSON")
        }
    }
    
    func setImageStatistics(_ user_stats: NSDictionary, _ global_stats: NSDictionary){
        let statsRate = Statistics()
        
        statsRate.identifier = 0
        statsRate.user = "YES"
        statsRate.message = "Success rate"
        statsRate.value = String(describing: user_stats["success_rate"]!).prefix(5)+"%"
        
        userStatistics!["stats_user_success_rate"] = statsRate
        
        let statsSuggestions = Statistics()
        
        statsSuggestions.identifier = 1
        statsSuggestions.user = "YES"
        statsSuggestions.message = "Within suggestions"
        statsSuggestions.value = String(describing: user_stats["between_suggestions_rate"]!).prefix(5)+"%"
        
        userStatistics!["stats_user_between_suggestions"] = statsSuggestions
        
        let statsTotal = Statistics()
        
        statsTotal.identifier = 2
        statsTotal.user = "YES"
        statsTotal.message = "Total images"
        statsTotal.value = "\(user_stats["total_num_images"]!)"
        
        userStatistics!["stats_user_num_images"] = statsTotal
        
        let statsGlobalRate = Statistics()
        
        statsGlobalRate.identifier = 7
        statsGlobalRate.user = "YES"
        statsGlobalRate.message = statsRate.message
        statsGlobalRate.value = String(describing: global_stats["success_rate"]!).prefix(5)+"%"
        
        globalStatistics!["stats_total_success_rate"] = statsGlobalRate
        
        let statsGlobalSuggestions = Statistics()
        
        statsGlobalSuggestions.identifier = 8
        statsGlobalSuggestions.user = "YES"
        statsGlobalSuggestions.message = statsSuggestions.message
        statsGlobalSuggestions.value = String(describing: global_stats["between_suggestions_rate"]!).prefix(5)+"%"
        globalStatistics!["stats_total_between_suggestions"] = statsGlobalSuggestions
        
        let statsGlobalTotal = Statistics()
        
        statsGlobalTotal.identifier = 9
        statsGlobalTotal.user = "YES"
        statsGlobalTotal.message = statsTotal.message
        statsGlobalTotal.value = "\(global_stats["total_num_images"]!)"
        globalStatistics!["stats_total_num_images"] = statsGlobalTotal
    }
    
    func setAnimalStats(_ user_stats: NSDictionary, _ global_stats: NSDictionary){
        let stats = Statistics()
        
        stats.identifier = 3
        stats.user = "YES"
        stats.message = "🐮 Animals"
        stats.value = "\(user_stats["type_animal"]!)"+" ("+String(describing: user_stats["percentage_animal"]!).prefix(5)+"%)"
        userStatistics!["stats_user_animal"] = stats
        
        let statsGlobal = Statistics()
        
        statsGlobal.identifier = 10
        statsGlobal.user = "YES"
        statsGlobal.message = stats.message
        statsGlobal.value = "\(global_stats["type_animal"]!)"+" ("+String(describing: global_stats["percentage_animal"]!).prefix(5)+"%)"
        globalStatistics!["stats_total_animal"] = statsGlobal
    }
    
    func setObjectStats(_ user_stats: NSDictionary, _ global_stats: NSDictionary){
        let stats = Statistics()
        
        stats.identifier = 4
        stats.user = "YES"
        stats.message = "☎ Objects"
        stats.value = "\(user_stats["type_object"]!)"+" ("+String(describing: user_stats["percentage_object"]!).prefix(5)+"%)"
        
        userStatistics!["stats_user_object"] = stats
        
        let statsGlobal = Statistics()
        
        statsGlobal.identifier = 11
        statsGlobal.user = "YES"
        statsGlobal.message = stats.message
        statsGlobal.value = "\(global_stats["type_object"]!)"+" ("+String(describing: global_stats["percentage_object"]!).prefix(5)+"%)"
        
        globalStatistics!["stats_total_object"] = statsGlobal
    }
    
    func setFoodieStats(_ user_stats: NSDictionary, _ global_stats: NSDictionary){
        let stats = Statistics()
        
        stats.identifier = 5
        stats.user = "YES"
        stats.message = "🍔 Food/Drinks"
        stats.value = "\(user_stats["type_food_drink"]!)"+" ("+String(describing: user_stats["percentage_food_drink"]!).prefix(5)+"%)"
        
        userStatistics!["stats_user_food_drink"] = stats
        
        let statsGlobal = Statistics()
        
        statsGlobal.identifier = 12
        statsGlobal.user = "YES"
        statsGlobal.message = stats.message
        statsGlobal.value = "\(global_stats["type_food_drink"]!)"+" ("+String(describing: global_stats["percentage_food_drink"]!).prefix(5)+"%)"
        
        globalStatistics!["stats_total_food_drink"] = statsGlobal
    }
    
    func setPlantStats(_ user_stats: NSDictionary, _ global_stats: NSDictionary){
        let stats = Statistics()
        
        stats.identifier = 6
        stats.user = "YES"
        stats.message = "🌴 Plants"
        stats.value = "\(user_stats["type_plant"]!)"+" ("+String(describing: user_stats["percentage_plant"]!).prefix(5)+"%)"
        
        userStatistics!["stats_user_plant"] = stats
        
        let statsGlobal = Statistics()
        
        statsGlobal.identifier = 13
        statsGlobal.user = "YES"
        statsGlobal.message = stats.message
        statsGlobal.value = "\(global_stats["type_plant"]!)"+" ("+String(describing: global_stats["percentage_plant"]!).prefix(5)+"%)"
        
        globalStatistics!["stats_total_plant"] = statsGlobal
    }
    
    func allCategoriesInfo(_ myGroup: DispatchGroup) {
        
        
        findClasses(myGroup: myGroup)
        myGroup.notify(queue: .main) {
            // Sort results
            var sortDescriptor: NSSortDescriptor?
            sortDescriptor = NSSortDescriptor(key: "lemma", ascending: true)
            let sortDescriptors: [NSSortDescriptor] = [sortDescriptor!]
            self.catInfo?.sort(using: sortDescriptors)
        }
    }
    
    func findClasses(myGroup: DispatchGroup){

        myGroup.enter()
        let urlString: String = Test.getURL()
        let userId = UserDefaults.standard.object(forKey: "userid") as! String
        let PHPparams = "user/\(userId)/classes"
        Alamofire.request(URL(string: urlString+PHPparams)!, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: nil).responseJSON(completionHandler: {response in
            Alamofire.request(URL(string: urlString+PHPparams)!, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: nil).responseJSON(completionHandler: {response in
                if response.result.isSuccess{
                    do{
                        let jsonParser = try JSONSerialization.jsonObject(with: response.data!, options: []) as? NSArray
                        if let array = jsonParser{
                            for obj in array {
                                if let dict = obj as? NSDictionary {
                                    let cat = CategoryInfo()
                                    cat.classid = dict.value(forKey: "class_id") as! String
                                    cat.lemma = dict.value(forKey: "lemma") as! String
                                    cat.n = NSNumber(value: Int(dict.value(forKey: "num_items") as! String)!)
                                    self.catInfo?.add(cat)
                                }
                            }
                        }
                    }catch{
                        print("Error Json getting definition in SendViewController")
                    }
                    myGroup.leave()
                } else {
                    self.theConnection?.presentAlertWithTitle(title: kErrorConnection, message: (response.result.error?.localizedDescription)!)
                }
            })
        })
    }
}
