//
//  CoBaT User Notification.swift
//  CoBaT
//
//  Created by Hartwig Hopfenzitz on 03.12.20.
//

import UIKit
import Foundation
import UserNotifications


// -------------------------------------------------------------------------------------------------
// MARK: -
// MARK: - CoBaT User Notification
// -------------------------------------------------------------------------------------------------
final class CoBaTUserNotification: NSObject {
    
    // ---------------------------------------------------------------------------------------------
    // MARK: - Singleton
    // ---------------------------------------------------------------------------------------------
    static let unique = CoBaTUserNotification()
    
    // ---------------------------------------------------------------------------------------------
    // MARK: - Properties
    // ---------------------------------------------------------------------------------------------
    enum CoBaTUserNotificationMessageType {
        case newRKIData
    }
    var queueOfMessagesToSend : [String] = []

    var alreadyInSendMode: Bool = false

    // ---------------------------------------------------------------------------------------------
    // MARK: - API
    // ---------------------------------------------------------------------------------------------
    //
    /**
     -----------------------------------------------------------------------------------------------
     
     if not in background, the function returns without anything done.
     
     Depending on the type of message, the text string is created based on the current RKI Data and queued into the internal message queue
     
     -----------------------------------------------------------------------------------------------
     
     - Parameters:
        - CoBaTUserNotificationMessageType: determins which message will be created
     
     - Returns:
     
     */
    public func sendUserNotification(type: CoBaTUserNotificationMessageType) {
        
        // first check if we are in background
        if weAreInBackground == false {

            // no , not in background, so the user sees the news right in front of him, no need to message
            //#if DEBUG_PRINT_FUNCCALLS
            GlobalStorage.unique.storeLastError(
                errorText:"sendUserNotification: called, but weAreInBackground == false, do nothing and return")
            //#endif

            return
        }
            
//        // check if we have stae AND county data
//        if (GlobalStorage.unique.didRecieveCountyData == false)
//            || (GlobalStorage.unique.didRecieveStateData == false) {
//
//            // no, one of them is missing, so report and return
//            #if DEBUG_PRINT_FUNCCALLS
//            GlobalStorage.unique.storeLastError(
//                errorText:"sendUserNotification: called, but but didRecieveCountyData (\(GlobalStorage.unique.didRecieveCountyData)) or didRecieveStateData (\(GlobalStorage.unique.didRecieveStateData)) still false, so return")
//            #endif
//        }
//        
//        // reset the flags
//        GlobalStorage.unique.didRecieveCountyData = false
//        GlobalStorage.unique.didRecieveStateData = false

        // prepare to build the text
        var textToSend: String = ""

        var numberOfDays: Int = 0
        
        var casesGermany: Int = 0
        var casesGermanyOtherDay: Int = 0
        
        var countyName: String = ""
        var incidencesCounty: Double = 0.0
        
        // to sync data access get the date we need in the global data queue
        GlobalStorageQueue.async(execute: {
            
            numberOfDays = GlobalStorage.unique.RKIData[GlobalStorage.unique.RKIDataCountry].count
            
            if numberOfDays > 0 {
                casesGermany = GlobalStorage.unique.RKIData[GlobalStorage.unique.RKIDataCountry][0][0].cases
                
                // check if we have also data from other days
                if numberOfDays > 1 {
                    casesGermanyOtherDay = GlobalStorage.unique.RKIData[GlobalStorage.unique.RKIDataCountry][1][0].cases
                }
                
                // try to find the county and get its data
                if let county = GlobalStorage.unique.RKIData[GlobalStorage.unique.RKIDataCounty][0].first(
                    where: { $0.myID == GlobalUIData.unique.UIBrowserRKISelectedCountyID } ) {
                    
                    countyName = county.name
                    incidencesCounty = county.cases7DaysPer100K
                }
            } else {
                
                GlobalStorage.unique.storeLastError(errorText: "sendUserNotification: did not find any RKI data, will not notify user")
            }
            
            // check if we have any data
            if numberOfDays > 0 {
                
                // we have data so check if we have data from several days
                if numberOfDays > 1 {
                    
                    // we are able to show differences:
                    // Germany: xxx new cases since yesterday
                    
                    
                    let casesDiff = casesGermany - casesGermanyOtherDay
                    
                    let localizedString = NSLocalizedString("Germany-new-cases",
                                                            comment: "RKI data difference cases for Germany")
                    
                    textToSend += String(format: localizedString,
                                         numberNoFractionFormatter.string(from: NSNumber(value: casesDiff)) ?? "???")
                    textToSend += "\n" // add new line
                    
                } else {
                    
                    // we just have the data of a single day
                    // Germany: xxx cases in total
                    
                    let localizedString = NSLocalizedString("Germany-total-cases",
                                                            comment: "RKI data cases in total for Germany")
                    
                    textToSend += String(format: localizedString,
                                         numberNoFractionFormatter.string(from: NSNumber(value: casesGermany)) ?? "???")
                                         
                    textToSend += "\n" // add new line
                }
                
                
                // in the second line we show the incidences for the selceted county
                // county: xxx cases in 7 days per 100,000
                let localizedString = NSLocalizedString("County-cases7day100k",
                                                        comment: "RKI data incidences for county")
                
                textToSend += String(format: localizedString, countyName,
                                     number1FractionFormatter.string(from: NSNumber(value: incidencesCounty)) ?? "???")
                
                // that's it, go for it
                
                
                // we use main thread as
                DispatchQueue.main.async(execute: {
                    
                    if let _ = self.queueOfMessagesToSend.firstIndex(where: {$0 == textToSend } ) {
                        
                        // we got an index, so we do have the same text still to send
                        // just report and return
                        //#if DEBUG_PRINT_FUNCCALLS
                        GlobalStorage.unique.storeLastError(
                            errorText: "sendUserNotification: text \"\(textToSend)\" already in message queue, do not send")
                        //#endif
                        
                    } else {
                        
                        // it's a new text, so append it and send a notification
                        // append the text to the message queue
                        self.queueOfMessagesToSend.append(textToSend)
                        
                        // check if we already waiting for messages to send ou
                        if self.alreadyInSendMode == false {
                            
                            // no, so we initiate the send process
                            
                            // flag it
                            self.alreadyInSendMode = true
                            
                            // do the call
                            self.doNextSendCycle()
                        }
                    }
                })
            }
        })
    }
    
    
    // ---------------------------------------------------------------------------------------------
    // MARK: - Main functions
    // ---------------------------------------------------------------------------------------------
    /**
     -----------------------------------------------------------------------------------------------
     
     Starts the new send cycle by requesting authorization.
     
     If the usr authorized it, call self.grantedHandler(), otherwise call self.notGrantedHandler()
     
     -----------------------------------------------------------------------------------------------
     */
    private func doNextSendCycle() {
        
        DispatchQueue.main.async(execute: {
            
            // check the authorization statsu
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) { granted, error in
                if error == nil {
                    if granted == true {
                        
                        #if DEBUG_PRINT_FUNCCALLS
                        print("doNextSendCycle: granted")
                        #endif
                        
                        self.grantedHandler()
                        
                    } else {
                        
                        #if DEBUG_PRINT_FUNCCALLS
                        print("doNextSendCycle: not granted")
                        #endif
                        
                        self.notGrantedHandler()
                    }
                    
                } else if let error = error {
                    
                    GlobalStorage.unique.storeLastError(errorText: "doNextSendCycle: error: \(error.localizedDescription)")
                    self.notGrantedHandler()
                    
                }
            }
        })
    }
    
    /**
     -----------------------------------------------------------------------------------------------
     
     Finally this function actually sends the message
     
     -----------------------------------------------------------------------------------------------
     */
    private func grantedHandler() {
        
        DispatchQueue.main.async(execute: {
            
            // loop over all messages
            for item in self.queueOfMessagesToSend {
   
                let content = UNMutableNotificationContent()
                
                content.title = NSLocalizedString("new-Rki-tilte", comment: "new RKI Data titl")
                content.body = item
                //content.sound = UNNotificationSound.default
                
                #if DEBUG_PRINT_FUNCCALLS
                GlobalStorage.unique.storeLastError(
                    errorText:"grantedHandler: Will send message \"\(content.title)\", \"\(content.body)\"")
                #endif
                
                // show this notification 5 seconds from now to have chance of bundle some messages
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
                
                // choose a random identifier
                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
                
                // add our notification request
                UNUserNotificationCenter.current().add(request) {
                    (error : Error?) in
                    
                    if let error = error {
                        
                        GlobalStorage.unique.storeLastError(errorText: "grantedHandler: error at addRequest: \(error.localizedDescription)")
                     }
                }
            }
            
            // after we send them all, we can remove them all
            self.queueOfMessagesToSend.removeAll()
            
            // close the session
            self.alreadyInSendMode = false
        })
    }
    
    /**
     -----------------------------------------------------------------------------------------------
     
     just a clean up
     
     -----------------------------------------------------------------------------------------------
     */
    private func notGrantedHandler() {
        
        DispatchQueue.main.async(execute: {
            
            self.queueOfMessagesToSend.removeAll()
            self.alreadyInSendMode = false
        })
    }
    
}
