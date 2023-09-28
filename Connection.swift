//
//  Connection.swift
//  mirbot
//
//  Created by Master Móviles on 24/07/2017.
//  Copyright © 2017 Master Móviles. All rights reserved.
//

import Alamofire

protocol ConnectionDelegate: class {
    func didFinishConnection()
    
    func didFailedConnection()
}

class Connection: NSObject{
    var receivedData: Data?
    var delegate: ConnectionDelegate?
    var session: URLSession?
    
    func startV1(_ theRequest: NSMutableURLRequest) {
        Alamofire.upload(theRequest.httpBody!, to: theRequest.url!, method: .post, headers: theRequest.allHTTPHeaderFields).responseJSON(completionHandler: {response in
            if response.result.isSuccess{
                self.receivedData = response.data
                self.callFinish(sync: true)
            } else {
                self.presentAlertWithTitle(title: kErrorConnection, message: (response.result.error?.localizedDescription)!)
            }
        })
    }
    
    func startV1(_ URLRequest: String, withPHPParams PHPparams: String, method: String){
        
        if(method == "GET"){
            Alamofire.request(URL(string: URLRequest+PHPparams)!, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: nil).responseJSON(completionHandler: {response in
                if response.result.isSuccess{
                    self.receivedData = response.data
                    self.callFinish(sync: true)
                } else {
                    self.presentAlertWithTitle(title: kErrorConnection, message: (response.result.error?.localizedDescription)!)
                }
            })
        }
        else if(method == "PUT"){
            var urlDivided = PHPparams.split(separator: "/")
            var urlPath = ""
            for (index,element) in urlDivided.enumerated(){
                if(index < urlDivided.count-1){
                    urlPath.append("\(element)/")
                }
            }
            if(urlDivided.count > 0){
                let keyValue = urlDivided[urlDivided.count-1].split(separator: "=")
                if(keyValue.count > 1){
                    //Alamofire.upload
                    let params: Parameters = ["\(keyValue[0])":"\(keyValue[1])"]
                    Alamofire.request(URL(string: URLRequest+urlPath)!, method: .put, parameters: params,
                                      encoding: JSONEncoding.default, headers: nil).responseJSON(completionHandler: {response in
                        if response.result.isSuccess{
                            self.receivedData = response.data
                            self.callFinish(sync: true)
                        } else {
                            self.presentAlertWithTitle(title: kErrorConnection, message: (response.result.error?.localizedDescription)!)
                        }
                    })
                }
            }
        }
    }
    
    func startV1(_ URLRequest: String, withPHPParams PHPparams: String, image: UIImage, params: [String:Any], headers: HTTPHeaders){
        
        Alamofire.upload(multipartFormData: {
            multipartFormData in
            
            if let imageData = UIImageJPEGRepresentation(image, CGFloat(kCOMPRESSION)) {
                multipartFormData.append(imageData, withName: "image", fileName: "imagen.jpg", mimeType: "image/jpeg")
                //multipartFormData.append(fileName, withName: "image")
            }
            
            for (key, value) in params {
                if key=="metadata"{
                    multipartFormData.append(value as! Data, withName: key)
                }else{
                    multipartFormData.append((value as! String).data(using: String.Encoding.utf8)!, withName: key)
                }
            }
        },
         usingThreshold: 100,
         to: URL(string: URLRequest+PHPparams)!,
         method: .post,
         headers: ["Content-type":kContentType],
         encodingCompletion: {
            encodingResult in
            
            switch encodingResult{
            case .success(let request, _, _):
                request.responseJSON{
                    response in
                    self.receivedData = response.data
                    self.callFinish(sync: true)
                }
            case .failure(let error):
                self.presentAlertWithTitle(title: kErrorConnection, message: error.localizedDescription)
            }
        })
    }
    
    func startV1(_ URLRequest: String, withPHPParams PHPparams: String, method: String, params: Parameters, headers: HTTPHeaders){
        var met: HTTPMethod?
        
        if(method == "PUT"){
            met = HTTPMethod.put
        }else if(method == "POST"){
            met = HTTPMethod.post
        }else if(method == "DELETE"){
            met = HTTPMethod.delete
        }else{
            met = HTTPMethod.get
        }
        Alamofire.request(URL(string: URLRequest+PHPparams)!, method: met!, parameters: params,
         encoding: JSONEncoding.default, headers: headers).responseJSON(completionHandler: {response in
            if response.result.isSuccess{
                self.receivedData = response.data
                self.callFinish(sync: true)
            } else {
                self.presentAlertWithTitle(title: kErrorConnection, message: (response.result.error?.localizedDescription)!)
            }
         })
    }
    
    func callFinish(sync: Bool){
        //print("RESPONSE CALL: \(String(data: receivedData!, encoding: String.Encoding.utf8)!)")
        DispatchQueue.main.async(execute: {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            if self.delegate != nil{
                self.delegate?.didFinishConnection()
            }
        })
    }
}

extension Connection{
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
