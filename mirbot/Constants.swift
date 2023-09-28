//
//  Constants.swift
//  mirbot
//
//  Created by Master Móviles on 18/07/2017.
//  Copyright © 2017 Master Móviles. All rights reserved.
//

let isTest = false
let isPhone4s = (UIScreen.main.bounds.size.height == 480)
let kMaxLabel = 64
// DB constants
let kDBName = "wordnet.db"
//#define kDBName @"wordnet30SQLite.db"
let kQueryLemma = "SELECT DISTINCT wordnet_lemmas.lemma FROM wordnet_lemmas, wordnet WHERE wordnet.id = wordnet_lemmas.class_id AND parent_class_id IS NOT NULL ORDER BY wordnet_lemmas.lemma"
//#define kQueryLemma @"SELECT lemma FROM word_nouns"
let kQueryDefinition = "SELECT definition, id FROM wordnet, wordnet_lemmas WHERE wordnet_lemmas.lemma=\"%@\" AND wordnet_lemmas.class_id = wordnet.id"
//#define kQueryDefinition @"SELECT synset.definition, synset.synsetid FROM word,sense,synset WHERE word.lemma=\"%@\" AND word.wordid=sense.wordid AND synset.synsetid=sense.synsetid AND synset.pos=\"n\" AND (synset.categoryid=05 OR synset.categoryid=06 OR synset.categoryid=13 OR synset.categoryid=17 OR synset.categoryid=20)"
let kQueryDefinitionFromClass = "SELECT definition FROM wordnet WHERE id=%@"
//#define kQueryDefinitionFromClass @"SELECT definition FROM synset WHERE synsetid=%@"
let kQueryLemmaFromSynset = "SELECT lemma FROM wordnet WHERE id=%@"
//#define kQueryLemmaFromSynset @"SELECT lemma FROM word,sense where synsetid=%@ and sense.wordid=word.wordid"
let kCategoryID = "SELECT category_id FROM wordnet WHERE id=%@"
// #define kCategoryID @"select categoryid from synset where synsetid=%@"
// TO DO!
let kParentClass = "SELECT parent_class_id FROM wordnet WHERE id=%@"
//#define kParentClass @"select synset2id from semlinkref where synset1id=%@ and linkid=1"
let kParentClass2 = "SELECT path FROM wordnet WHERE id=%@"
let kSynonyms = "SELECT lemma FROM wordnet_lemmas WHERE class_id=%@ AND lemma!=\"%@\""
//#define kSynonyms @"select lemma from sense,word where synsetid=%@ and sense.wordid=word.wordid and lemma!=\"%@\""
let kNoSynonyms = "No synonyms found"
let kObjectMessage1 = "I'm pretty sure that this is a"
let kObjectMessage2 = "I'm almost sure that this is a"
let kObjectMessage3 = "I bet that this is a"
let kObjectMessage4 = "This is probably a"
let kObjectMessage5 = "I think this is a"
let kObjectMessage6 = "I think this could be a"
let kObjectMessage7 = "I'm not sure, but this seems to be a"
let kObjectMessage8 = "Maybe a"
let kObjectMessage9 = "I have many doubts, but this could be a"
let kObjectMessage10 = "Buf, this one is difficult to me, but could be a"
let kObjectMessage11 = "This is tricky, it could be a"
let kUnknownAlternative = "It's not in this list"
let kUnknownAlertView = "Do you know what is this?"
let kUnknown = "Don't worry, let's try again!"
let kSuccess = "Great, I did it, try me again!"
let kCompletelyWrong = "Ups, I was not even close!"
let kSimilar1 = "Terrible, %@ and %@ are very different, but at least both of them are a kind of %@"
let kSimilar2 = "Not bad, at least %@ and %@ are a kind of %@"
let kSimilar3 = "This time I was close, %@ and %@ are a kind of %@"
let kNoIdea = "Thanks, I didn't know what it was, try me again!"
let kNoInfo = "Hey, there is basically nothing in the selected area!"
let kMessageNumClasses1 = "Thanks!, I've seen a"
let kMessageNumClasses2 = "times."
let kMessageNewClass = "I think I've never seen this before, please tell me what is it!"
let kMessageFirstClassifiedObject = "This is the first thing you show me, please tell me what is it!"
let kMessageNewClass2 = "Thanks, it's the first time I see a"
let kAlternativesMessage = "Give me another chance, is it some of these things?"
let kMessageHelpLabel = "You can optionally insert a label to identify this particular object in the class. For example, if the class was an animal this field can contain his name, if it was a computer, its brand."
let kWebpage = "http://gbrain.dlsi.ua.es/webpage/rest/rest.php?id="
let kWebpageTest = "http://gbrain.dlsi.ua.es/webpage-test/rest/rest.php?id="
let kWebpageTestv1 = "http://staging.mirbot.com/api/v1/"
let kWebpagev1 = "http://mirbot.com/api/v1/"
let kSentClassURI = "confirmimage"
let kUpdateLabel = "updatelabel"
let kProcessImage = "processimage"
let kGetUserInfoURI = "userinfo"
let kDeleteImageURI = "deleteimage"
let kToolbarHeight = 44
let kToolbarHeightModal = 64
// Image constants
let kMAXRESOLUTION : CGFloat = 640.0
let kERROR = -1000.0
let kCOMPRESSION = 0.7
let kMINREGION = 0.025
let kApacheLicense = "This software uses BPXLUUIDHandler, licensed under the Apache License, Version 2.0 (the \"License\"); you may not use this file except in compliance with the License. You may obtain a copy of the License at\n http://www.apache.org/licenses/LICENSE-2.0. \n Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an \"AS IS\" BASIS,WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License."
let kWordnetLicense = "This software uses WordNet 3.0 dictionary with the following license. Copyright 2006 by Princeton University. All rights reserved. THIS SOFTWARE AND DATABASE IS PROVIDED \"AS IS\" AND PRINCETON UNIVERSITY MAKES NO REPRESENTATIONS OR WARRANTIES, EXPRESS OR IMPLIED. BY WAY OF EXAMPLE, BUT NOT LIMITATION, PRINCETON UNIVERSITY MAKES NO REPRESENTATIONS OR WARRANTIES OF MERCHANT- ABILITY OR FITNESS FOR ANY PARTICULAR PURPOSE OR THAT THE USE OF THE LICENSED SOFTWARE, DATABASE OR DOCUMENTATION WILL NOT INFRINGE ANY THIRD PARTY PATENTS, COPYRIGHTS, TRADEMARKS OR OTHER RIGHTS."
let kFGalleryLicense = "This software uses FGallery component, Copyright © 2010 Grant Davis Interactive, LLC under the following MIT license: THE SOFTWARE IS PROVIDED ‘AS IS’, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE."
//#define kApacheLicense @"This software uses BPXLUUIDHandler, licensed under the Apache License, Version 2.0 (the \"License\"); you may not use this file except in compliance with the License. You may obtain a copy of the License at\n http:
private var kServiceName: String = "es.ua.mirbot"

let kUnknownLenght = -1
let kWikipedia = "http://en.m.wikipedia.org/wiki/"
let kVideoType = "m4v"
let kWebType = "html"
let kButtonAcceptTerms = "I have read and accept the terms"
let kAnimalCategory = "5"
let kObjectCategory = "6"
let kFoodieCategory = "13"
let kNaturalObjectCategory = "17"
let kPlantsCategory = "20"
let kAllCategoryes = "\(kAnimalCategory),\(kObjectCategory),\(kFoodieCategory),\(kNaturalObjectCategory),\(kPlantsCategory)"
let kBoundary = "------randomidrandom"
let kContentType = "multipart/form-data, boundary=\(kBoundary)"
let kErrorConnection = "Error connection"
/* TO DO:
 - Compute day/night/dawn/dusk? (search twilight|sunrise equation at wikipedia, daylight at mathforum.org/library/drmath/view/56478.html)
 */
