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

// -------------------------------------------------------------------------------------------------
// MARK: -
// MARK: - Queues
// -------------------------------------------------------------------------------------------------

// we use a queue to manage the global storage. This provides us from data races. The queue is concurrent,
// so many can read at the same time, but only one can write
let GlobalStorageQueue : DispatchQueue = DispatchQueue(
    label: "org.hobrink.CoBaT.GlobalStorageQueue",
    qos: .userInitiated, attributes: .concurrent)


// -------------------------------------------------------------------------------------------------
// MARK: -
// MARK: - Class
// -------------------------------------------------------------------------------------------------
final class GlobalStorage: NSObject {
    
    // ---------------------------------------------------------------------------------------------
    // MARK: - Singleton
    // ---------------------------------------------------------------------------------------------
    static let unique = GlobalStorage()

    // ---------------------------------------------------------------------------------------------
    // MARK: - Constants and variables
    // ---------------------------------------------------------------------------------------------
    private let permanentStore = UserDefaults.standard

    // usefull constants to index the right Level
    public let RKIDataState: Int = 0
    public let RKIDataCounty: Int = 1
    
    // size of storage
    private let maxNumberOfDaysStored: Int = 7
    private let maxNumberOfErrorsStored: Int = 20

    // ---------------------------------------------------------------------------------------------
    // MARK: - RKI Data API
    // ---------------------------------------------------------------------------------------------
    
    /**
     -----------------------------------------------------------------------------------------------
     
     reads the permananently stored values into the global storage. Values are stored in user defaults
     
     -----------------------------------------------------------------------------------------------
     */
    public func restoreSavedRKIData() {
        
        GlobalStorageQueue.async(flags: .barrier, execute: {

            print("read the permanent store is not fully implemented yet")
            
            // try to read the stored county data
            if let loadedRKICountyData = self.permanentStore.object(
                forKey: "CoBaT.RKIData") {
                
                if let loadedRKICountyDataTimeStamps = self.permanentStore.object(
                    forKey: "CoBaT.RKIDataTimeStamps") {
                    
                    let loadedRKICountyDataLastUpdated = self.permanentStore.double(
                        forKey: "CoBaT.RKIDataLastUpdated")
                    
                    let loadedRKIDataLastRetreived = self.permanentStore.double(
                        forKey: "CoBaT.RKIDataLastRetreived")
                    
                    
                    // got the data, try to decode it
                    do {
                        
                        let myRKICountyData = try JSONDecoder().decode([[[RKIDataStruct]]].self,
                                                                       from: (loadedRKICountyData as? Data)!)
                        
                        let myRKICountyDataTimeStamps = try JSONDecoder().decode([[TimeInterval]].self,
                                                                                 from: (loadedRKICountyDataTimeStamps as? Data)!)
                        
                        // if we got to here, no errors encountered, so store it
                        self.RKIData = myRKICountyData
                        self.RKIDataTimeStamps = myRKICountyDataTimeStamps
                        self.RKIDataLastUpdated = loadedRKICountyDataLastUpdated
                        self.RKIDataLastRetreived = loadedRKIDataLastRetreived
                                                
                    } catch let error as NSError {
                        
                        // encode did fail, log the message
                        self.storeLastError(errorText: "CoBaT.GlobalStorage.restoreSavedRKIData: Error: JSON decoder could not dencode RKIData: error: \"\(error.description)\"")
                    }
                    
                } else {
 
                    // could not read the stored data, report it
                    self.storeLastError(errorText: "CoBaT.GlobalStorage.restoreSavedRKIData: Error: could not read RKIDataTimeStamps")
                }
                
            } else {
                
                // could not read the stored data, report it
                self.storeLastError(errorText: "CoBaT.GlobalStorage.restoreSavedRKIData: Error: could not read RKIData")
            }
            
            print("got them")
        })
    }
    
    
    
    /**
     -----------------------------------------------------------------------------------------------
     
     stores the new RKIData[], but only if the data has changed, it also initiates local notifications "Data updated" and "Data retrieved"
     
     -----------------------------------------------------------------------------------------------
     
     - Parameters:
        - newRKIStateData: array with the new data, data will replace old data if changed
     
     - Returns: nothing
     */
    public func refresh_RKIStateData(newRKIStateData: [RKIDataStruct]) {
        
        // call the local methode to handle all, just tell that this are county datas
        self.refresh_RKIData(self.RKIDataState, newRKIStateData)
    }
  
    /**
     -----------------------------------------------------------------------------------------------
     
     stores the new RKIData[], but only if the data has changed, it also initiates local notifications "Data updated" and "Data retrieved"
     
     -----------------------------------------------------------------------------------------------
     
     - Parameters:
        - newRKICountyData: array with the new data, data will replace old data if changed
     
     - Returns: nothing
     */
    public func refresh_RKICountyData(newRKICountyData: [RKIDataStruct]) {
        
        // call the local methode to handle all, just tell that this are county datas
        self.refresh_RKIData(self.RKIDataCounty, newRKICountyData)
    }
    

    
    
    // ---------------------------------------------------------------------------------------------
    // MARK: - RKI data storage (permanent)
    // ---------------------------------------------------------------------------------------------
    public struct RKIDataStruct : Hashable, Encodable, Decodable {
        public let stateID : String             // each state has a unique ID, it's a number but we use a string
        public let name : String                // the name of the state or the county
        public let kindOf: String               // what kind of state (Land, Freistaat, ...) or county (Kreis, kreisfreie Stadt)
        public let inhabitants: Int             // number of inhabitants
        public let cases: Int                   // number of cases in total
        public let deaths: Int                  // number of deaths in total
        public let casesPer100k: Double         // number of cases per 100,000 inhabitants
        public let cases7DaysPer100K : Double   // number of cases last 7 days per 100,000 inhabitants
        public let timeStamp : TimeInterval     // last updated at

        init(stateID : String,
             name: String,
             kindOf: String,
             inhabitants: Int,
             cases: Int,
             deaths: Int,
             casesPer100k: Double,
             cases7DaysPer100K: Double,
             timeStamp: TimeInterval)
        {
            self.stateID = stateID
            self.name = name
            self.kindOf = kindOf
            self.inhabitants = inhabitants
            self.cases = cases
            self.deaths = deaths
            self.casesPer100k = casesPer100k
            self.cases7DaysPer100K = cases7DaysPer100K
            self.timeStamp = timeStamp
        }
    }
    
    // RKI data array
    // - we use state data and county data
    // - we also try to build up a data set of the last 7 days (to show on UI the differences to yesterday and to last week)
    // - the state data has about 16 datasets per day, the county data has about 412 data sets per day
    //
    // to store all data in a single array we use a three level structure
    // first index level is the kind of data set (state or county) (index 0 = state, index 1 = county)
    // second index level are the up to maxNumberOfDaysStored days (index 0 = today, index 7 = same day last week)
    // third index level are the data sets per state or county
    //
    // example: "State (0), yesterday (1), Bavaria (9), cases" looks like: RKIData[0][1][9].cases
    
    public var RKIData : [[[RKIDataStruct]]] = [[], []]        // initialise with two empty arrays, so first index level not empty
    
    // TimeStamps per array item
    // we use a different array to make sure we can compare new and old [RKIDataStruct] by hash values
    // use the same logic as on RKIData, but only two index levels
    // first index level is the kind of data set (state or county) (index 0 = state, index 1 = county)
    // second index level are the up to maxNumberOfDaysStored days (index 0 = today, index 7 = same day last week)
    //
    // example: "State (0), yesterday (1), timestamp" looks like: RKIDataTimeStamps[0][1]
    
    public var RKIDataTimeStamps : [[TimeInterval]] = [[], []]       // initialise with two empty arrays, so first index level not empty
    
    // the timeStamp the data was last updated (updates only if data changed)
    public var RKIDataLastUpdated: TimeInterval = 0
    
    // the timeStamp data was last retrieved
    public var RKIDataLastRetreived: TimeInterval = 0

    /**
     -----------------------------------------------------------------------------------------------
     
     stores the new RKIData[], but only if the data has changed, it also initiates local notifications "Data updated" and "Data retrieved"
     
     -----------------------------------------------------------------------------------------------
     
     - Parameters:
        - newRKICountyData: array with the new data, data will replace old data if changed
     
     - Returns: nothing
     */
    private func refresh_RKIData(_ kindOf: Int, _ newRKIData: [RKIDataStruct]) {
        
        // we have to consider four different cases:
        
        // case 1: RKIData is empty, so just add the new item (addNewData())
        // case 2: There is a difference to the existing data, but from the same day, so an update (replaceData0())
        // case 3: new item is from a different day (addNewData())
        // case 4: data are the same, so ignore it
        
        GlobalStorageQueue.async(execute: {
            
            // check if this is the very first entry
            if self.RKIData[kindOf].isEmpty == true {
                
                // case 1: RKIData is empty, so just add the new item (addNewData())
                print("case 1: RKIData is empty, so just add the new item (addNewData())")
                
                // take the best timeStamp
                let oldestTimeStamp = self.RKIDataGetBestTimeStamp(newRKIData)
                
                // and add the new values
                self.addNewData(kindOf, newRKIData, oldestTimeStamp)
                
            } else {
                
                // check if there are differences
                if self.RKIData[kindOf][0].hashValue != newRKIData.hashValue {

                    // yes, there are differences, so check if the day changed
                    // take the best timeStamp of new data
                    let oldestTimeStamp = self.RKIDataGetBestTimeStamp(newRKIData)
                    
                    // check if the days are different
                    let newDate = shortSingleDateFormatterRKI.string(
                        from: Date(timeIntervalSinceReferenceDate: oldestTimeStamp))
                    
                    let oldDate = shortSingleDateFormatterRKI.string(
                        from: Date(timeIntervalSinceReferenceDate: self.RKIDataTimeStamps[kindOf][0]))
                    
                    if oldDate == newDate {
                    
                        // case 2: There is a difference to the existing data, but from the same day,
                        // so just an update (replaceData0())
                        print("case 2: oldDate (\(oldDate) == newDate(\(newDate)) -> replaceData0()")

                        self.replaceData0(kindOf, newRKIData, oldestTimeStamp)

                    } else {
                    
                        // case 3: new item is from a different day (addNewData())
                        print("case 3: oldDate (\(oldDate) != newDate(\(newDate)) -> addNewData()")
                        
                        self.addNewData(kindOf, newRKIData, oldestTimeStamp)
                    }
                    
                } else {
                    
                    // case 4: data are the same, so ignore it
                    print ("case 4: data are the same, so ignore it")
                }
            }
            
            // at least we have a new retrieving data
            self.RKIDataLastRetreived = CFAbsoluteTimeGetCurrent()

            // make it permamnent
            self.permanentStore.set(self.RKIDataLastRetreived,
                                    forKey: "CoBaT.RKIDataLastRetreived")

            // TODO: TODO: local notification
            
        })
    }
    
    /**
     -----------------------------------------------------------------------------------------------
     
     adds a new array item of [RKIDataStruct] at index 0, make sure there are not more than maxNumberOfDaysStored items in [[RKIDataStruct]]
     
     -----------------------------------------------------------------------------------------------
     
     - Parameters:
        - newRKICountyData: new data to add
     
     - Returns: nothing
     
     */
    private func addNewData(_ kindOf: Int,
                            _ newRKIData: [RKIDataStruct],
                            _ timeStamp: TimeInterval) {
        
        GlobalStorageQueue.async(flags: .barrier, execute: {
            
            if self.RKIData[kindOf].isEmpty == true {
                
                self.RKIData[kindOf].append(newRKIData)
                self.RKIDataTimeStamps[kindOf].append(timeStamp)

           } else {
                
            while self.RKIData[kindOf].count > self.maxNumberOfDaysStored {
                    
                    self.RKIData[kindOf].removeLast()
                    self.RKIDataTimeStamps[kindOf].removeLast()
                }
                
                self.RKIData[kindOf].insert(newRKIData, at: 0)
                self.RKIDataTimeStamps[kindOf].insert(timeStamp, at: 0)
            }
            
            // remember the timeStamp
            self.RKIDataLastUpdated = CFAbsoluteTimeGetCurrent()
            
            // just for testing
            for item in self.RKIData[kindOf][0] {
                print("addNewData, RKIData[\(kindOf)][0]: \(item.kindOf) \(item.name): \(item.cases7DaysPer100K), \(Date(timeIntervalSinceReferenceDate: item.timeStamp))")
            }
            print("addNewData, RKIDataTimeStamps[\(kindOf)][0]: \(Date(timeIntervalSinceReferenceDate: self.RKIDataTimeStamps[kindOf][0]))")

            // make it permanant
            self.storeRKIData()
            
            
           // TODO: TODO: local notification
            

            print("all good")
        })
    }
    
    
    /**
     -----------------------------------------------------------------------------------------------
     
     replace the existing item at index 0 of [[RKIDataStruct]] by new item of [RKIDataStruct]
     
     -----------------------------------------------------------------------------------------------
     
     - Parameters:
        - newRKIData: new data to replace item 0
     
     - Returns: nothing
     
     */
    private func replaceData0(_ kindOf: Int,
                              _ newRKIData: [RKIDataStruct],
                              _ timeStamp: TimeInterval) {
        
        GlobalStorageQueue.async(flags: .barrier, execute: {
            
            if self.RKIData[kindOf].isEmpty == true {
                
                self.RKIData[kindOf].append(newRKIData)
                self.RKIDataTimeStamps[kindOf].append(timeStamp)
                
            } else {
                
                self.RKIData[kindOf][0] = newRKIData
                self.RKIDataTimeStamps[kindOf][0] = timeStamp
            }
            
            // remember the timeStamp
            self.RKIDataLastUpdated = CFAbsoluteTimeGetCurrent()
            
            // just for testing
            for item in self.RKIData[kindOf][0] {
                print("replaceData0, RKIData[\(kindOf)][0]: \(item.kindOf) \(item.name): \(item.cases7DaysPer100K), \(Date(timeIntervalSinceReferenceDate: item.timeStamp))")
            }
            print("replaceData0, RKIDataTimeStamps[\(kindOf)][0]: \(Date(timeIntervalSinceReferenceDate: self.RKIDataTimeStamps[kindOf][0]))")

            // make it permanant
            self.storeRKIData()
            
            
            // TODO: TODO: local notification

            print("all good")

        })
    }
    
    /**
     -----------------------------------------------------------------------------------------------
     
     stores the thre variables RKIData, RKIDataTimeStamps and RKIDataLastUpdated into the permanant store
     
     -----------------------------------------------------------------------------------------------
     */
    private func storeRKIData() {
        
        // make it permamnent, by encode it to JSON and store it
        do {
            // try to encode the county data and the timeStamps
            let encodedRKICountyData = try JSONEncoder().encode(self.RKIData)
            let encodedRKICountyDataTimeStamps = try JSONEncoder().encode(self.RKIDataTimeStamps)
            
            // if we got to here, no errors encountered, so store it
            self.permanentStore.set(encodedRKICountyData, forKey: "CoBaT.RKIData")
            self.permanentStore.set(encodedRKICountyDataTimeStamps, forKey: "CoBaT.RKIDataTimeStamps")
            self.permanentStore.set(RKIDataLastUpdated, forKey: "CoBaT.RKIDataLastUpdated")
            
            print("storeRKIData done!")

        } catch let error as NSError {
            
            // encode did fail, log the message
            self.storeLastError(errorText: "CoBaT.GlobalStorage.storeRKIData: Error: JSON encoder could not encode RKIData: error: \"\(error.description)\"")
        }
    }

    /**
     -----------------------------------------------------------------------------------------------
     
     gets the highest timeStamp of an [RKIDataStruct].
     
     We take the highest value, to be sure it is a valid timeStamp. If we would have had used "min", we probably would get an entry from a missing timeStamp (which would be 0)
     
     -----------------------------------------------------------------------------------------------
     
     - Parameters:
        - RKIData: the array to check
     
     - Returns:
        - TimeInterval: highest timeStamp we found
     
     */
    private func RKIDataGetBestTimeStamp(_ RKIDataSet: [RKIDataStruct]) -> TimeInterval {
        
        // try to get the highest timeStamp
        if let oldestTimeStamp = RKIDataSet.max(by: { $0.timeStamp > $1.timeStamp } )?.timeStamp {
            
            // all good, return it
            return oldestTimeStamp
            
        } else {
            
            // something went wrong, return 0
            return 0
        }
    }
    

    
    
    // ---------------------------------------------------------------------------------------------
    // MARK: - Last Errors API
    // ---------------------------------------------------------------------------------------------
    /**
     -----------------------------------------------------------------------------------------------
     
     Logs the error text as NSLog() and stores it in an internal ring buffer (self.lastErros[]), size: maxNumberOfErrorsStored
     
     -----------------------------------------------------------------------------------------------
     
     - Parameters:
     
        - errorText: Text of the error to log and store
     
     - Returns: nothing
     
     */
    public func storeLastError(errorText: String) {
        
        // log it on console
        NSLog(errorText)

        GlobalStorageQueue.async(flags: .barrier, execute: {
            
            // check if the buffer is full
            while self.lastErrors.count >= self.maxNumberOfErrorsStored {
                
                // yes buffer is full, so remove the oldest
                self.lastErrors.removeFirst()
            }
            
            // append the new error
            self.lastErrors.append(lastErrorStruct(errorText: errorText))
            
            // TODO: TODO: local notification
            // local notification
            print("storeLastError: notifiucation is still missing")
        })
    }
    
    
    // ---------------------------------------------------------------------------------------------
    // MARK: - Last Errors Storage (not permanent)
    // ---------------------------------------------------------------------------------------------

    public struct lastErrorStruct {
        let errorText: String
        let errorTimeStamp: TimeInterval
        
        init(errorText: String) {
            self.errorText = errorText
            self.errorTimeStamp = CFAbsoluteTimeGetCurrent()
        }
    }
    
    public var lastErrors: [lastErrorStruct] = []
}
