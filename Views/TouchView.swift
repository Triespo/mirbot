//
//  TouchView.swift
//  mirbot
//
//  Created by Master Móviles on 01/08/2017.
//  Copyright © 2017 Master Móviles. All rights reserved.
//

class TouchView: UIView {
    var locationInit = CGPoint.zero
    var locationEnd = CGPoint.zero
    var touched: UIBarButtonItem?

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        touched?.isEnabled = true
        let touch: UITouch? = event?.allTouches?.first
        if (touch.self != nil) {
            if touch?.tapCount == 2 {
                NSObject.cancelPreviousPerformRequests(withTarget: self)
            }
            else {
                locationInit = (touch?.location(in: self))!
                locationEnd = locationInit
                setNeedsDisplay()
            }
        }
    }
    
    override func draw(_ rect: CGRect) {
        //UIGraphicsBeginImageContextWithOptions((inputView?.bounds.size)!, false, 0)
        
        var rectAux = rect
        super.draw(rectAux)
        // Init context
        let context: CGContext? = UIGraphicsGetCurrentContext()
        context?.saveGState()
        context?.clear(rectAux)
        // Darken background
        context?.setFillColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        context?.fill(rectAux)
        // Now, create the rectangle
        rectAux = CGRect(x: locationInit.x, y: locationInit.y, width: locationEnd.x - locationInit.x, height: locationEnd.y - locationInit.y)
        // Set the rectangle transparent
        context!.setBlendMode(CGBlendMode.clear)
        context?.fill(rectAux)
        // Add border
        context!.setBlendMode(CGBlendMode.normal)
        context?.setStrokeColor(red: 255, green: 255, blue: 255, alpha: 255)
        context?.setLineWidth(2)
        context?.stroke(rectAux)
        // like Processing popMatrix
        context?.restoreGState()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch: UITouch? = event?.allTouches?.first
        if (touch.self != nil) {
            if touch?.tapCount == 2 {
                locationInit = CGPoint(x: 0, y: 0)
                locationEnd = CGPoint(x: bounds.size.width, y: bounds.size.height)
            }
            else {
                locationEnd = (touch?.location(in: self))!
            }
            setNeedsDisplay()
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch: UITouch? = event?.allTouches?.first
        if (touch.self != nil) {
            locationEnd = (touch?.location(in: self))!
            setNeedsDisplay()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        locationEnd = CGPoint(x: bounds.size.width, y: bounds.size.height)
        backgroundColor = UIColor.clear
        isUserInteractionEnabled = true
        isOpaque = false
        isHidden = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
