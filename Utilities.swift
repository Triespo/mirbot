//
//  Utilities.swift
//  mirbot
//
//  Created by Master Móviles on 04/08/2017.
//  Copyright © 2017 Master Móviles. All rights reserved.
//

import AVFoundation

class Utilities: NSObject{
    
    class func upperFirstLetter(_ theString: String) -> String {
        if(theString == ""){
            return ""
        }
        let index = theString.index(theString.startIndex, offsetBy: 1)
        return (theString as NSString).replacingCharacters(in: NSRange(location: 0, length: 1), with: (theString[..<index].uppercased()))
    }
    
    class func lowerFirstLetter(_ theString: String) -> String {
        if(theString == ""){
            return ""
        }
        let index = theString.index(theString.startIndex, offsetBy: 1)
        return (theString as NSString).replacingCharacters(in: NSRange(location: 0, length: 1), with: (theString[..<index].lowercased()))
    }
    
    @objc class func createWikiView(_ lemma: String) -> WebViewController {
        let wikilemma: String = lemma.replacingOccurrences(of: " ", with: "_")
        let URL: String = "\(kWikipedia)\(wikilemma)"
        let wvc = WebViewController(url: URL)
        return wvc
    }
    
    class func startspeech(_ text: String?) {

        if String(describing: UserDefaults.standard.object(forKey: "speech")!) == "true" && text != nil {
            let voice = AVSpeechSynthesisVoice(language: "en-US")
            //let voice = AVSpeechSynthesisVoice(language: "es-ES")
            let utterance = AVSpeechUtterance(string: text!)
            utterance.voice = voice
            utterance.pitchMultiplier = 1.1
            if(floor(NSFoundationVersionNumber) >= floor(NSFoundationVersionNumber_iOS_9_0) &&
                floor(NSFoundationVersionNumber) < floor(NSFoundationVersionNumber10_0)){
                utterance.rate *= 1.1
            }else if (floor(NSFoundationVersionNumber) >= floor(NSFoundationVersionNumber10_0)){
                utterance.rate *= 1.06
            }else{
                utterance.rate *= 0.45
            }
            let appDelegate: AppDelegate? = (UIApplication.shared.delegate as? AppDelegate)
            appDelegate?.speechSynthesizer?.speak(utterance)
        }
    }
    
    class func stopspeech() {
        if String(describing: UserDefaults.standard.object(forKey: "speech")) == "true" {
            let appDelegate: AppDelegate? = (UIApplication.shared.delegate as? AppDelegate)
            appDelegate?.speechSynthesizer?.stopSpeaking(at: .word)
        }
    }
}
