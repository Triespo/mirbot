//
//  ClassifiedImage.swift
//  mirbot
//
//  Created by Miguel Ángel Jareño Escudero on 08/09/2017.
//  Copyright © 2017 Master Móviles. All rights reserved.
//

class ClassifiedImage: NSObject {
    var classid: String = ""
    var score: NSNumber?
    var lemma: String = ""
    var definition: String = ""
    var label: String = ""
    
    override init(){
        super.init()
    }
    
    init(classid: String, score: NSNumber, lemma: String, definition: String, label: String) {
        super.init()
        
        self.classid = classid
        self.score = score
        self.lemma = lemma
        self.definition = definition
        self.label = label
    }
    
    override func mutableCopy() -> Any {
        let new: ClassifiedImage? = ClassifiedImage()
        new?.classid = classid.copy() as! String
        new?.score = score?.copy() as? NSNumber
        new?.lemma = lemma.copy() as! String
        new?.definition = definition.copy() as! String
        new?.label = label.copy() as! String
        return new!
    }
}
