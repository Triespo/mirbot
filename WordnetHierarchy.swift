//
//  WordnetHierarchy.swift
//  mirbot
//
//  Created by Miguel Ángel Jareño Escudero on 26/08/2017.
//  Copyright © 2017 Master Móviles. All rights reserved.
//

import Alamofire

class WordnetHierarchy: NSObject {
    var hierarchyArray = [CategoryInfo]()
    var lemma = String()
    var definition: String?
    var category = String()
    var parent = [NSDictionary]()
    var delegate: TreeViewController?
    
    init(id classid: String, delegate: TreeViewController) {
        super.init()
        
        self.delegate = delegate
        self.delegate?.generalGroup.enter()
        performQuery(classid: classid)
    }
    
    func performQuery(classid: String) {
        if Int(classid)! > -1{
            let urlString: String = Test.getURL()
            let PHPparams = "wordnet/class/\(classid)"
            Alamofire.request(URL(string: urlString+PHPparams)!, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: nil).responseJSON(completionHandler: {response in
                
                if response.result.isSuccess{
                    do{
                        let jsonParser = try JSONSerialization.jsonObject(with: response.data!, options: []) as? [String : Any]
                        let definition = jsonParser!["definition"] as! String
                        self.definition = Utilities.upperFirstLetter(definition)
                        self.lemma = jsonParser!["lemma"] as! String
                        self.category = jsonParser!["category_id"] as! String
                        self.parent = jsonParser!["hierarchy"] as! [NSDictionary]
                        self.fillHierarchy()
                    }catch{
                        print("Error Json getting definition in WordnetHierarchy")
                    }
                } else {
                    self.presentAlertWithTitle(title: kErrorConnection, message: (response.result.error?.localizedDescription)!)
                }
            })
        }
    }
    
    func fillHierarchy(){
        for member in self.parent {
            let catInfo = CategoryInfo()
            catInfo.classid = member.value(forKey: "class_id") as! String
            catInfo.lemma = member.value(forKey: "lemma") as! String
            catInfo.definition = member.value(forKey: "definition") as! String
            hierarchyArray.append(catInfo)
        }
        self.delegate?.generalGroup.leave()
    }
}

extension WordnetHierarchy{
    func presentAlertWithTitle(title: String, message : String){
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let closeAction = UIAlertAction(title: "Close", style: .default)
        alertController.addAction(closeAction)
        var topController = UIApplication.shared.keyWindow!.rootViewController
        
        while ((topController?.presentedViewController) != nil) {
            topController = topController?.presentedViewController;
        }
        topController?.present(alertController, animated:true, completion:nil)
    }
}
