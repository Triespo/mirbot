//
//  RemoteImage.swift
//  mirbot
//
//  Created by Miguel Ángel Jareño Escudero on 26/08/2017.
//  Copyright © 2017 Master Móviles. All rights reserved.
//

class RemoteImage: NSObject {
    var url: NSString = ""
    var label: String = ""
    var classid: String = ""
    var imageid: String = ""
    
    override init(){
        super.init()
    }
    
    init(url theURL: NSString, withLabel theLabel: String, withClassId theClassid: String) {
        super.init()
        
        url = theURL
        label = theLabel
        imageid = url.lastPathComponent.replacingOccurrences(of: "image", with: "")
        classid = theClassid
    }
    
    override func mutableCopy() -> Any {
        let new: RemoteImage? = RemoteImage()
        new?.url = url.copy() as! NSString
        new?.label = (label.copy() as? String)!
        new?.classid = classid.copy() as! String
        new?.imageid = imageid.copy() as! String
        return new!
    }
}
