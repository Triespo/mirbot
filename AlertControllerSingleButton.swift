//
//  AlertControllerSingleButton.swift
//  mirbot
//
//  Created by Miguel Ángel Jareño Escudero on 26/08/2017.
//  Copyright © 2017 Master Móviles. All rights reserved.
//
// It shows alert with info for user in case it is needed when user clicks for example in one organization

class AlertControllerSingleButton: NSObject {
    class func showAlert(_ title: String, withMessage message: String, withButtonTitle buttonTitle: String, in vc: UIViewController) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancel = UIAlertAction(title: buttonTitle, style: .default, handler: {(_ action: UIAlertAction) -> Void in
            alert.dismiss(animated: true)
        })
        alert.addAction(cancel)
        vc.present(alert, animated: true)
    }
    class func showAlertWithImage(_ title: String, withPhoto photo: String, withMessage message: String, withButtonTitle buttonTitle: String, in vc: UIViewController){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let imageView = UIImageView(frame: CGRect(x:220,y:10,width:40,height:40))
        
        if photo != ""{
            let image_OK = try? UIImage(data: Data(contentsOf: URL(string: photo)!))
             imageView.image = image_OK!
            alert.view.addSubview(imageView)
        }
        let cancel = UIAlertAction(title: buttonTitle, style: .default, handler: {(_ action: UIAlertAction) -> Void in
            alert.dismiss(animated: true)
        })
        alert.addAction(cancel)
        vc.present(alert, animated: true)
    }
}
