//
//  Test.swift
//  mirbot
//
//  Created by Master Móviles on 06/08/2017.
//  Copyright © 2017 Master Móviles. All rights reserved.
//

class Test: NSObject{
    
    class func getURL() -> String {
        var output: String = kWebpagev1
        if (isTest){
            if (UserDefaults.standard.bool(forKey: "test")) {
                output = kWebpageTestv1
            }
        }
        return output
    }
}
