//
//  Global Storage.swift
//  CoBaT
//
//  Created by Hartwig Hopfenzitz on 24.11.20.
//

// This class holds and manages the global storage for the app
// It decouples data retrieve from UI
//
// this includes:
// - last fetched RKI data
// - last location data
// - several state variables to manage UI etc.
//
// all variables are stored permanently
//
// if data changes this class generates notifications
//


import Foundation

// -------------------------------------------------------------------------------------------------
// MARK: -
// MARK: - CoBaT Global Storage
// -------------------------------------------------------------------------------------------------
final class GlobalStorage: NSObject {
    
    // ---------------------------------------------------------------------------------------------
    // MARK: - Singleton
    // ---------------------------------------------------------------------------------------------
    static let unique = GlobalStorage()


    
    
    
    // ---------------------------------------------------------------------------------------------
    // MARK: - RKI Data API
    // ---------------------------------------------------------------------------------------------
    
    /**
     -----------------------------------------------------------------------------------------------
     
     
     
     -----------------------------------------------------------------------------------------------
     
     - Parameters:
     - :
     
     - Returns:
     
     */
    public func readPermanentStore() {
        
        // TODO: TODO: read permanent store
        print("read the permanent store is not implemented yet")
        
        // TODO: TODO: local notification, new data available
    }
    
    
    
    /**
     -----------------------------------------------------------------------------------------------
     
     stores the new RKICountyData[], but only if the data has changed, it also initiates local notifications "Data updated" and "Data retrieved"
     
     -----------------------------------------------------------------------------------------------
     
     - Parameters:
        - newRKICountyData: array with the new data, data will replace old data if changed
     
     - Returns: nothing
     
     */
    public func refresh_RKICountyData(newRKICountyData: [RKICountyDataStruct]) {
        
        // check if there are differences
        if RKICountyData.hashValue != newRKICountyData.hashValue {
            
            // yes, there are differences, so store the new data
            RKICountyData = newRKICountyData
            
            // remember the timeStamp
            RKICountyDataLastUpdated = CFAbsoluteTimeGetCurrent()
            
            // just for testing
            for item in RKICountyData {
                print("refresh_RKICountyData: \(item.countyName): \(item.Covid7DaysCasesPer100K)")
            }
            
            // TODO: TODO: local notification

            // TODO: TODO: make it permamnent

            print("refresh_RKICountyData: we have to implement the permananent storage")
            
            
        } else {
            print ("same data as before")
        }
        
        // TODO: TODO: local notification

        // TODO: TODO: make it permamnent
        RKIRKICountyDataLastRetreived = CFAbsoluteTimeGetCurrent()
        print("refresh_RKICountyData: we have to implement the permananent storage")
    }
    
    
    // ---------------------------------------------------------------------------------------------
    // MARK: - RKI County data storage (permanent)
    // ---------------------------------------------------------------------------------------------
    struct RKICountyDataStruct : Hashable {
        public let stateName : String
        public let countyName : String
        public let Covid7DaysCasesPer100K : Double
        
        init(stateName: String, countyName: String, Covid7DaysCasesPer100K: Double) {
            self.stateName = stateName
            self.countyName = countyName
            self.Covid7DaysCasesPer100K = Covid7DaysCasesPer100K
        }
    }
    
    var RKICountyData : [RKICountyDataStruct] = []
    
    // the timeStamp the data was last updated (updates only if data changed)
    var RKICountyDataLastUpdated: TimeInterval = 0
    
    // the timeStamp data was last retrieved
    var RKIRKICountyDataLastRetreived: TimeInterval = 0

    
    // ---------------------------------------------------------------------------------------------
    // MARK: - Last Errors API
    // ---------------------------------------------------------------------------------------------
    /**
     -----------------------------------------------------------------------------------------------
     
     Logs the error text as NSLog() and stores it in an internal ring buffer (self.lastErros[])
     
     -----------------------------------------------------------------------------------------------
     
     - Parameters:
     
        - errorText: Text of the error to log and store
     
     - Returns: nothing
     
     */
    public func storeLastError(errorText: String) {
        
        // log it on console
        NSLog(errorText)

        // check if the buffer is full
        while lastErrors.count >= 10 {
            
            // yes buffer is full, so remove the oldest
            lastErrors.removeFirst()
        }
        
        // append the new error
        lastErrors.append(lastErrorStruct(errorText: errorText))
        
        // TODO: TODO: local notification
        // local notification
        print("storeLastError: notifiucation is still missing")
    }
    
    
    // ---------------------------------------------------------------------------------------------
    // MARK: - Last Errors Storage (not permanent)
    // ---------------------------------------------------------------------------------------------

    struct lastErrorStruct {
        let errorText: String
        let errorTimeStamp: TimeInterval
        
        init(errorText: String) {
            self.errorText = errorText
            self.errorTimeStamp = CFAbsoluteTimeGetCurrent()
        }
    }
    
    var lastErrors: [lastErrorStruct] = []
}
