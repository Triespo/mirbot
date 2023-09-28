//
//  CustomTextView.swift
//  mirbot
//
//  Created by Master Móviles on 06/08/2017.
//  Copyright © 2017 Master Móviles. All rights reserved.
//

import Foundation
import QuartzCore
import UIKit

class CustomTextView:UITextView {
    let FontSizePhone = 17
    let FontSizePad = 20
    
    // Programmatically initialization
    init(frame: CGRect, withText text: String, withParentView parentView: UIView) {
        super.init(frame: frame, textContainer: nil)
        
        setStyle()
        self.text = text
        recalculateFrameSize()
        parentView.addSubview(self)
        setNeedsDisplay()
        parentView.setNeedsDisplay()
        
    }
    
    // Xib initialization
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setStyle()
        if UI_USER_INTERFACE_IDIOM() == .phone {
            autoresizingMask = [.flexibleHeight, .flexibleWidth, .flexibleBottomMargin]
        }
        else {
            autoresizingMask = [.flexibleHeight, .flexibleWidth, .flexibleBottomMargin, .flexibleRightMargin, .flexibleLeftMargin]
        }
        
    }
    
    func setStyle() {
        alpha = 0.9
        if UI_USER_INTERFACE_IDIOM() == .pad {
            font = UIFont.systemFont(ofSize: CGFloat(FontSizePad))
        }
        else {
            font = UIFont.systemFont(ofSize: CGFloat(FontSizePhone))
        }
        layer.borderColor = UIColor.gray.cgColor
        layer.borderWidth = 2.3
        layer.cornerRadius = 15
        isEditable = false
        isSelectable = false
        clipsToBounds = true
    }
    
    func recalculateFrameSize() {
        // To ensure proper calculation of self.contentSize
        layoutManager.ensureLayout(for: textContainer)
        layoutIfNeeded()
        // Adjust height
        var frame: CGRect = self.frame
        frame.size.height = contentSize.height
        self.frame = frame
        // Adjust width (for ipad only)
        if UI_USER_INTERFACE_IDIOM() == .pad {
            let width: CGFloat = CGFloat(text.size(withAttributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: CGFloat(FontSizePad))]).width + 50)
            if width != 50 && width < frame.size.width {
                frame.size.width = CGFloat(width)
                self.frame = frame
            }
        }
    }
    
    override func layoutSubviews() {
        // Very important to be here for iOS7!!
        super.layoutSubviews()
        recalculateFrameSize()
    }
}
