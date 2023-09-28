//
//  CustomNavigationController.swift
//  mirbot
//
//  Created by Miguel Ángel Jareño Escudero on 11/10/2017.
//  Copyright © 2017 Master Móviles. All rights reserved.
//

import Foundation

class CustomNavigationController: UINavigationController {
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask{
        if (self.topViewController?.responds(to: #selector(getter: self.supportedInterfaceOrientations)))!{
            return (self.topViewController?.supportedInterfaceOrientations)!
        }
        else {
            return super.supportedInterfaceOrientations
        }
    }
}
