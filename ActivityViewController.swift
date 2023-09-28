//
//  ActivityViewController.swift
//  mirbot
//
//  Created by Master Móviles on 16/08/2017.
//  Copyright © 2017 Master Móviles. All rights reserved.
//
// Shows how to interpreting the presented controlled showing an spinner when app needs time for getting request from server
//

class ActivityViewController: NSObject {

    class func setupSpinnerBackground() -> UIView {
        let spinnerView = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        spinnerView.layer.cornerRadius = 10.0
        spinnerView.layer.backgroundColor = UIColor.black.cgColor
        spinnerView.alpha = 0.80
        spinnerView.layer.shadowOffset = CGSize.zero
        spinnerView.layer.shadowColor = UIColor.black.cgColor
        spinnerView.layer.shadowOpacity = 1
        spinnerView.layer.shadowRadius = 110
        if UI_USER_INTERFACE_IDIOM() == .phone {
            spinnerView.layer.shadowPath = UIBezierPath(rect: spinnerView.bounds.insetBy(dx: -50, dy: -50)).cgPath
        }
        else {
            spinnerView.layer.shadowPath = UIBezierPath(rect: spinnerView.bounds.insetBy(dx: -100, dy: -100)).cgPath
        }
        spinnerView.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin, .flexibleLeftMargin, .flexibleRightMargin]
        return spinnerView
    }
    
//  Show spinner at the top of the screen
    class func showActivityView(_ topView: UIView) -> UIView {
        // Create background spinner view (black rectangle)
        let spinnerView: UIView? = self.setupSpinnerBackground()
        spinnerView?.center = topView.convert(topView.center, from: topView.superview)
        // Create UIActivityIndicator
        let spinner = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        spinner.center = CGPoint(x: (spinnerView?.frame.size.width)! / 2, y: (spinnerView?.frame.size.height)! / 2)
        spinner.startAnimating()
        // Add subviews
        spinnerView?.addSubview(spinner)
        topView.addSubview(spinnerView!)
        return spinnerView!
    }

//    Show spinner at the center of the screen
    class func showActivityView(_ topView: UIView, atCenter center: CGPoint) -> UIView {
        let theFrame = CGRect(x: 0, y: 0, width: 50, height: 50)
        let activityView = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        activityView.backgroundColor = UIColor.clear
        activityView.alpha = 1
        let activityWheel = UIActivityIndicatorView(frame: CGRect(x: theFrame.size.width / 2 - 10, y: theFrame.size.height / 2 - 10, width: 24, height: 24))
        activityWheel.center = center
        activityWheel.startAnimating()
        activityWheel.activityIndicatorViewStyle = .whiteLarge
        activityView.addSubview(activityWheel)
        topView.addSubview(activityView)
        topView.bringSubview(toFront: activityView)
        return activityView
    }
    
    class func hideActivityView(_ spinnerView: UIView) {
        spinnerView.removeFromSuperview()
    }
}
