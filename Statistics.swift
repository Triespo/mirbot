//
//  Statistics.swift
//  mirbot
//
//  Created by Miguel Ángel Jareño Escudero on 26/08/2017.
//  Copyright © 2017 Master Móviles. All rights reserved.
//

@objcMembers
class Statistics: NSObject {
    var identifier: NSNumber?
    var message: String = ""
    var user: String = ""
    var value: String = ""
    
    func order(byIdentifier otherObject: Statistics) -> ComparisonResult {
        return (identifier!.compare(otherObject.identifier!))
    }
}
