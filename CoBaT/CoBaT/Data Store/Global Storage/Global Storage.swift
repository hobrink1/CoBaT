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
import MapKit

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
    public let RKIDataCountry:   Int = 0
    public let RKIDataState:     Int = 1
    public let RKIDataCounty:    Int = 2
    public let RKIDataFavorites: Int = 3
    
    public let RKIIDForBavaria: String = "9"
    
    // just a flag if the RKI data has missing days (see checkForGaps()). This flag is used by iCloud Services.
    public var RKIDataHasGaps: Bool = true
    
    // size of storage
    // TODO: TODO: Value can be reduced, after iCloud sync is done
    public let maxNumberOfDaysStored: Int = 22
    private let maxNumberOfErrorsStored: Int = 50
    
    // Version of permanent storage
    private let VersionOfPermanentStorage: Int = 4

    
    // Calender
    /**
     -----------------------------------------------------------------------------------------------
     
     // flags to show what kind of data we recieved
     // this flags will be used from CoBaT to determin if it is worth to notify the user.
     // The flags will be manages by rebuildRKIDeltas
     
     -----------------------------------------------------------------------------------------------
     */
    public var didRecieveStateData: Bool = false
    public var didRecieveCountyData: Bool = false



    // ---------------------------------------------------------------------------------------------
    // MARK: - RKI Data API
    // ---------------------------------------------------------------------------------------------
    
    // flag if we already have restored the data, if so, no need to do it again. This is used in background fetch
    // see startRKIBackgroundFetch()
    public var savedRKIDataRestored: Bool = false
    
    // enum of the different data types
    public enum RKI_DataTypeEnum {
        case county, state, age, countyShape, stateBorder
    }

    /**
     -----------------------------------------------------------------------------------------------
     
     reads the permananently stored values into the global storage. Values are stored in user defaults
     
     -----------------------------------------------------------------------------------------------
     */
    public func restoreSavedRKIData() {
        
        GlobalStorageQueue.async(flags: .barrier, execute: {
            
            #if DEBUG_PRINT_FUNCCALLS
            print("restoreSavedRKIData just started")
            #endif
            
            // try to read the stored county data
            if let loadedRKIData = self.permanentStore.object(
                forKey: "CoBaT.RKIData") {
                
                if let loadedRKIDataTimeStamps = self.permanentStore.object(
                    forKey: "CoBaT.RKIDataTimeStamps") {
                    
                    let loadedRKIDataLastUpdated = self.permanentStore.double(
                        forKey: "CoBaT.RKIDataLastUpdated")
                    
                    let loadedRKIDataLastRetreived = self.permanentStore.double(
                        forKey: "CoBaT.RKIDataLastRetreived")
                    
                    let loadedLastErrors = self.permanentStore.object(
                        forKey: "CoBaT.lastErrors")
                    
                    let loadedRKIFavorites = self.permanentStore.object(
                        forKey: "CoBaT.RKIFavorites")

                    // got the data, try to decode it
                    do {
                        
                        let myRKIData = try JSONDecoder().decode([[[RKIDataStruct]]].self,
                                                                 from: (loadedRKIData as? Data)!)
                        
                        let myRKIDataTimeStamps = try JSONDecoder().decode([[TimeInterval]].self,
                                                                from: (loadedRKIDataTimeStamps as? Data)!)
                        
                        // there might be no last Errors, so make sure we have a clear start point
                        var myLastErrors: [lastErrorStruct] = []
                        if loadedLastErrors != nil {
                            
                            myLastErrors = try JSONDecoder().decode([lastErrorStruct].self,
                                                                        from: (loadedLastErrors as? Data)!)
                        }
                        
                        
                        // there might be no favorites, so make sure we have a clear start point
                        var myRKIFavorites: [[String]] = [[], [], [], []]
                        if loadedRKIFavorites != nil {
                            myRKIFavorites = try JSONDecoder().decode([[String]].self,
                                                                      from: (loadedRKIFavorites as? Data)!)
                        }
                        
                        // if we got to here, no errors encountered
                        
                        // now we have to check if we probably have to migrate data
                        // V1: Initial version
                        // V2: added country level
                        var currentVersionOfPermanentStorage = self.permanentStore.integer(
                            forKey: "CoBaT.VersionOfPermanentStorage")
                        
                        // check the version
                        if currentVersionOfPermanentStorage == self.VersionOfPermanentStorage {
                            
                            // we have the current version, so restore the date
                            self.RKIData = myRKIData
                            self.RKIDataTimeStamps = myRKIDataTimeStamps
                            self.RKIDataLastUpdated = loadedRKIDataLastUpdated
                            self.RKIDataLastRetreived = loadedRKIDataLastRetreived
                            
                            // and rebuild the diconary
                            self.rebuildStateDic()
                            
                            self.lastErrors = myLastErrors
                            
                            self.RKIFavorites = myRKIFavorites
                            
                            // build the days arrays
                            self.rebuildDayArrays()
                            
                            // rebuild the delta values
                            // but to not set the flags
                            self.rebuildRKIDeltas(kindOf: -1, newData: false)
                            
                        } else {
                            
                            // make a working copy of the loaded data
                            var migratedRKIData = myRKIData
                            var migratedRKIDataTimeStamps = myRKIDataTimeStamps
                            
                            // loop until all migrations are done
                            while currentVersionOfPermanentStorage != self.VersionOfPermanentStorage {
                                
                                // check the version and the possible migration strategy
                                switch currentVersionOfPermanentStorage {
                                
                                case 0, 1:
                                    // we have to add the country level
                                    
                                    // first step, copy the data one level up, to make room for the country level, which is level 0
                                    
                                    // copy county data to level 2 by appending
                                    migratedRKIData.append(migratedRKIData[1])
                                    
                                    // copy state data to former county level
                                    migratedRKIData[1] = migratedRKIData[0]
                                    
                                    // clean level 0
                                    migratedRKIData[0].removeAll()
                                    
                                    // build new country data from state data
                                    
                                    // loop over stored days in state data
                                    for dayIndex in 0 ..< migratedRKIData[1].count {
                                        
                                        // shortcut for current record
                                        let currentStateDayData = migratedRKIData[1][dayIndex]
                                        
                                        // preoare the calculation
                                        var inhabitants: Int = 0
                                        var cases: Int = 0
                                        var deaths: Int = 0
                                        var cases7Days: Double = 0
                                        
                                        // loop over the states
                                        for singleState in currentStateDayData {
                                            
                                            // do some sums
                                            inhabitants         += singleState.inhabitants
                                            cases               += singleState.cases
                                            deaths              += singleState.deaths
                                            
                                            // for the case in 7 days we have to calculate this number
                                            cases7Days          += Double(singleState.cases7DaysPer100K)
                                                * Double(singleState.inhabitants)
                                                / 100_000.0
                                        }
                                        
                                        // we calculate the casesPer100k and the cases7DaysPer100K
                                        let casesPer100k: Double   = Double(cases) * 100_000.0 / Double(inhabitants)
                                        let cases7DaysPer100K: Double = cases7Days * 100_000.0 / Double(inhabitants)
                                        
                                        // get the timeStamp
                                        let timeStamp = self.RKIDataGetBestTimeStamp(currentStateDayData)
                                        
                                        // build the struct
                                        let countryDataOfDay = RKIDataStruct(
                                            stateID: "0",
                                            myID: "",
                                            name: "Deutschland",
                                            kindOf: "Land",
                                            inhabitants: inhabitants,
                                            cases: cases,
                                            deaths: deaths,
                                            casesPer100k: casesPer100k,
                                            cases7DaysPer100K: cases7DaysPer100K,
                                            timeStamp: timeStamp)
                                        
                                        // store the struct as an array of a single struct
                                        migratedRKIData[0].append([countryDataOfDay])
                                    }
                                    
                                    // now we have to migrate the timeStamps
                                    // we just copy county and state data, we keep level 0,
                                    // as the timestamps for level 0 and 1 have the same values
                                    migratedRKIDataTimeStamps.append(migratedRKIDataTimeStamps[1])
                                    migratedRKIDataTimeStamps[1] = migratedRKIDataTimeStamps[0]
                                    
                                    // set the new version
                                    currentVersionOfPermanentStorage = 2
                                    self.storeLastError(errorText: "CoBaT.GlobalStorage.restoreSavedRKIData: just migrated the stored data from version 1 to version 2")
                                    break
                                    
   
                                    
                                case 2, 3: // migrate the timeStamps to noon. We need that to make sure we have a reliable hash value
                                    
                                    // we have to reset the timestamps to noon
                                    self.storeLastError(errorText: "CoBaT.GlobalStorage.restoreSavedRKIData: version of permanent storage (\(currentVersionOfPermanentStorage)) is below \(self.VersionOfPermanentStorage), migrate timeStamps")
                                    
                                    // loop over stored areas
                                    for areaIndex in 0 ..< migratedRKIData.count {
                                        
                                        // loop over stored days
                                        for dayIndex in 0 ..< migratedRKIData[areaIndex].count {
                                            
                                            // loop over stored items
                                            for itemIndex in 0 ..< migratedRKIData[areaIndex][dayIndex].count {
                                                
                                                // Exchange the old item by a new item.
                                                // The new item is just a copy of the old item, except the timeCode
                                                
                                                // get the old values
                                                let oldItem = migratedRKIData[areaIndex][dayIndex][itemIndex]
                                                
                                                // put all values (except the timeStamp) to new item
                                                let newItem = RKIDataStruct(
                                                    stateID: oldItem.stateID,
                                                    myID: oldItem.myID!,
                                                    name: oldItem.name,
                                                    kindOf: oldItem.kindOf,
                                                    inhabitants: oldItem.inhabitants,
                                                    cases: oldItem.cases,
                                                    deaths: oldItem.deaths,
                                                    casesPer100k: oldItem.casesPer100k,
                                                    cases7DaysPer100K: oldItem.cases7DaysPer100K,
                                                    
                                                    // migrate the timeStamp
                                                    timeStamp: self.getMidnightTimeInterval(time: oldItem.timeStamp))
                                                
                                                // replace the old item by the new item
                                                migratedRKIData[areaIndex][dayIndex][itemIndex] = newItem
                                            }
                                        }
                                    }

                                    // now the timeStamps
                                    
                                    // loop over areas
                                    for areaIndex in 0 ..< migratedRKIDataTimeStamps.count {
                                        
                                        // loop over days
                                        for dayIndex in 0 ..< migratedRKIDataTimeStamps[areaIndex].count {
                                            
                                            // migrate timeStamps
                                            migratedRKIDataTimeStamps[areaIndex][dayIndex] =
                                                self.getMidnightTimeInterval(time: migratedRKIDataTimeStamps[areaIndex][dayIndex])
                                        }
                                    }
                                    
                                    // set the new version
                                    currentVersionOfPermanentStorage += 1

                                    break

                                    
                                default:
                                    
                                    // unknown version, just report nd do not restore the date
                                    self.storeLastError(errorText: "CoBaT.GlobalStorage.restoreSavedRKIData: Error: version of permanent storage (\(currentVersionOfPermanentStorage)) is unknown, current version is: \(self.VersionOfPermanentStorage), do not restore data, as it might be not usefull")
                                    
                                    
                                } // case
                                
                            } // loop
                            
                            // OK, we did the migration, so store the migrated values ...
                            self.RKIData = migratedRKIData
                            self.RKIDataTimeStamps = migratedRKIDataTimeStamps
                            self.RKIDataLastUpdated = loadedRKIDataLastUpdated
                            self.RKIDataLastRetreived = loadedRKIDataLastRetreived
                            
                            // and rebuild the diconary
                            self.rebuildStateDic()
                            
                            // and also the not migrated values
                            self.lastErrors = myLastErrors
                            self.RKIFavorites = myRKIFavorites
                            
                            // build the day arrays
                            self.rebuildDayArrays()
                            
                            // and force a save to secure what we have done
                            self.saveRKIData(from: "restoreSavedRKIData")
                            
                            // rebuild the delta values
                            self.rebuildRKIDeltas(kindOf: -1, newData: false)
                            
                        } // Check version
                        
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
            
            // set the flag, that we have done, what to do
            self.savedRKIDataRestored = true
            
            #if DEBUG_PRINT_FUNCCALLS
            print("restoreSavedRKIData done, call getRKIData() and startGraphicSystem()")
            #endif
            
        })
        // start the production of the three graphs on the details table view
        DetailsRKIGraphic.unique.startGraphicSystem()
        
        // get fresh data
        RKIDataDownload.unique.getRKIData(from: 0, until: 1)
        
         
        //})
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
        
        // call the local methode to handle all, just tell that this are state datas
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
    
    
    
    /**
     -----------------------------------------------------------------------------------------------
     
     save a new favorite in the array and also permanent
     
     -----------------------------------------------------------------------------------------------
     
     - Parameters:
        - level: area level of the new favorite
        - id: ID of the new favorite
     
     - Returns: nothing
     */
    public func saveNewFavorite(level: Int, id: String) {
        
        GlobalStorageQueue.async(flags: .barrier, execute: {
            
            // check if this is really a new favorite
            if self.RKIFavorites[level].contains(id) == false {
                
                // yes, it's a new one, so save it
                self.RKIFavorites[level].append(id)
                
                // rebuild the favorites
                self.rebuildFavorites()
                
                // make it permanant
                self.saveRKIData(from: "saveNewFavorite")
                
                // rebuild the delta values
                self.rebuildRKIDeltas(kindOf: self.RKIDataFavorites, newData: false)
                

//                do {
//
//                    let encodedRKIFavorites = try JSONEncoder().encode(self.RKIFavorites)
//                    self.permanentStore.set(encodedRKIFavorites, forKey: "CoBaT.RKIFavorites")
//
//                } catch let error as NSError {
//
//                    // encode did fail, log the message
//                    self.storeLastError(errorText: "CoBaT.GlobalStorage.saveNewFavorite: Error: JSON encoder could not encode RKIFavorites: error: \"\(error.description)\"")
//                }
                
                
                
            } else {
                
                #if DEBUG_PRINT_FUNCCALLS
                print("saveNewFavorite level: \(level), id: \(id) already a favorite, do nothing")
                #endif
            }
        })
    }
    
    /**
     -----------------------------------------------------------------------------------------------
     
     remove an existing favorite in the array and also permanent
     
     -----------------------------------------------------------------------------------------------
     
     - Parameters:
        - level: area level of the new favorite
        - id: ID of the new favorite
     
     - Returns: nothing
     */
    public func removeFavorite(level: Int, id: String) {
        
        GlobalStorageQueue.async(flags: .barrier, execute: {
            
            // try to find the index of id
            if let index = self.RKIFavorites[level].firstIndex(of: id) {
                
                // we found it, so we can remove it
                self.RKIFavorites[level].remove(at: index)
                
                // rebuild the favorites
                self.rebuildFavorites()
                
                // make it permanant
                self.saveRKIData(from: "removeFavorite")
                
                // rebuild the delta values
                self.rebuildRKIDeltas(kindOf: self.RKIDataFavorites, newData: false)

            } else {
                
                #if DEBUG_PRINT_FUNCCALLS
                print("removeFavorite level: \(level), id: \(id) is not a favorite, do nothing")
                #endif
            }
        })
    }
    
    
    
    /**
    -----------------------------------------------------------------------------------------------
    
    get the number of the day of the given timeInterval for timezone "Europe/Berlin" (RKI reference timezone)
    
    -----------------------------------------------------------------------------------------------
    
    - Parameters:
       - time: given TimeInterval
    
    - Returns:
       - number of the day since Date() reference date
    
    */
    public func getDayNumberFromTimeInterval(time: TimeInterval) -> Int {
        
        // we use the gregorian calender
        var RKICalendar: Calendar = Calendar(identifier: .gregorian)
        
        // we have to use the timeZone of Berlin, if that does not work, use the durrent timezone
        let RKITimeZone: TimeZone = TimeZone(identifier: "Europe/Berlin") ?? TimeZone.current
        RKICalendar.timeZone = RKITimeZone

        // this is the reference date (noon)
        let refDate: Date = Date(timeIntervalSinceReferenceDate: 0)
        let refDateNoon : Date = RKICalendar.date(bySettingHour: 12, minute: 0, second: 0,
                                                    of: refDate) ?? refDate
        // get the noon of the endDate
        let ofDate: Date = Date(timeIntervalSinceReferenceDate: time)
        let ofDateNoon : Date = RKICalendar.date(bySettingHour: 12, minute: 0, second: 0,
                                                  of: ofDate) ?? ofDate
        
        
       return Calendar.current.dateComponents([.day],
                                              from: refDateNoon,
                                              to: ofDateNoon).day ?? -1
    }
 
    /**
    -----------------------------------------------------------------------------------------------
    
     This methode gives the timeInterval of noon for the given timeinterval
     
     We need this to normalize the timeIntervals and have reliable hash values
    
    -----------------------------------------------------------------------------------------------
    
    - Parameters:
       - time: given TimeInterval
    
    - Returns:
       - number of the day since Date() reference date
    
    */
    public func getMidnightTimeInterval(time: TimeInterval) -> TimeInterval {
        
        // we use the gregorian calender
        var RKICalendar: Calendar = Calendar(identifier: .gregorian)
        
        // we have to use the timeZone of Berlin, if that does not work, use the durrent timezone
        let RKITimeZone: TimeZone = TimeZone(identifier: "Europe/Berlin") ?? TimeZone.current
        RKICalendar.timeZone = RKITimeZone

        // get the noon of the endDate
        let ofDate: Date = Date(timeIntervalSinceReferenceDate: time)
        let ofDateNoon : Date = RKICalendar.date(bySettingHour: 0, minute: 0, second: 0,
                                                  of: ofDate) ?? ofDate
        
        // return the timeInterval
        return ofDateNoon.timeIntervalSinceReferenceDate
    }
 



    /**
    -----------------------------------------------------------------------------------------------
    
    get the formatted date string from the dayNumber for timezone "Europe/Berlin" (RKI reference timezone)
    
    -----------------------------------------------------------------------------------------------
    
    - Parameters:
       - dayNumber: given number of day
    
    - Returns:
       - nformatted sdate string
    
    */
    public func getDateStringFromDayNumber(dayNumber: Int) -> String! {
         
        // get the seconds. We add 12 hours to get noon
        let seconds: TimeInterval = (Double(dayNumber) * 24.0 * 60.0 * 60.0) + (12.0 * 60.0 * 60.0)
        
        // get the date
        let dateToUse: Date = Date(timeIntervalSinceReferenceDate: seconds)
        
        // get the string
        let stringToReturn: String = shortSingleDateFormatterRKI.string(from: dateToUse)
        
        //return what we have
        return stringToReturn
    }
    
    // ---------------------------------------------------------------------------------------------
    // MARK: - RKI data storage (permanent)
    // ---------------------------------------------------------------------------------------------
    public struct RKIDataStruct : Hashable, Encodable, Decodable {
        public let stateID: String              // each state has a unique ID, it's a number but we use a string
        public let myID: String?                // states and counties have a unique ID
        public let name: String                 // the name of the state or the county
        public let kindOf: String               // what kind of state (Land, Freistaat, ...) or county (Kreis, kreisfreie Stadt)
        public let inhabitants: Int             // number of inhabitants
        public let cases: Int                   // number of cases in total
        public let deaths: Int                  // number of deaths in total
        public let casesPer100k: Double         // number of cases per 100,000 inhabitants
        public let cases7DaysPer100K : Double   // number of cases last 7 days per 100,000 inhabitants
        public let timeStamp : TimeInterval     // last updated at

        init(stateID: String,
             myID: String,
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
            self.myID = myID
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
    // first index level is the kind of data set (state or county) (index 0 = Country, 1 = state, 2 = county)
    // second index level are the up to maxNumberOfDaysStored days (index 0 = today, index 7 = same day last week)
    // third index level are the data sets per state or county, for Ccountry there is only one record ("Deutschland")
    //
    // example: "State (1), today (0), Bavaria (9), cases" looks like: RKIData[1][0][9].cases
    
    public var RKIData : [[[RKIDataStruct]]] = [[], [], [], []]   // initialise with three empty arrays, avoid empty level
    
    
    // We use this to precalculate the deltas (differneces to yesterday and to 7 days back).
    // So for the second index (days) we use 0 for today, 1 for deltas to yesterday and 2 for deltas to 7 days back.
    // This colums are only filled if suitable data are available
    // This array is recalculated each time the data in RKIData[] changed
    // this array will not stored permanently!
    
    public var RKIDataDeltas : [[[RKIDataStruct]]] = [[], [], [], []]   // initialise with three empty arrays, avoid empty level

    
    // TimeStamps per array item
    // we use a different array to make sure we can compare new and old [RKIDataStruct] by hash values
    // use the same logic as on RKIData, but only two index levels
    // first index level is the kind of data set (country, state or county) (index 0 = country, 1 = state, 2 = county)
    // second index level are the up to maxNumberOfDaysStored days (index 0 = today, index 7 = same day last week)
    //
    // example: "Country (0), yesterday (1), timestamp" looks like: RKIDataTimeStamps[0][1]
    
    public var RKIDataTimeStamps : [[TimeInterval]] = [[], [], [], []]       // initialise with three empty arrays, so first index level not empty
    
    public var RKIDataWeekdays : [[Int]] = [[], [], [], []]       // initialise with three empty arrays, so first index level not empty
    public var RKINumbersOfDays: [[Int]] = [[], [], [], []]
    
    // the timeStamp the data was last updated (updates only if data changed)
    public var RKIDataLastUpdated: TimeInterval = 0
    
    
    // the timeStamp data was last retrieved
    public var RKIDataLastRetreived: TimeInterval = 0
    
    
    // the list of the favorite details
    public var RKIFavorites: [[String]] = [[], [], []]
    
    // the dictonary of stateIDs and state names
    public var RKIStateDic: [String : String] = [:]
    
    // ---------------------------------------------------------------------------------------------
    // MARK: - RKI Data Handling
    // ---------------------------------------------------------------------------------------------
    /**
     -----------------------------------------------------------------------------------------------
     
     stores the new RKIData[], but only if the data has changed, it also initiates local notifications "Data retrieved"
     
     -----------------------------------------------------------------------------------------------
     
     - Parameters:
        - newRKIData: array with the new data, data will replace old data if changed
     
     - Returns: nothing
     */
    private func refresh_RKIData(_ kindOf: Int, _ newRKIData: [RKIDataStruct]) {
        
        // we have to consider four different cases:
        
        // case 1: RKIData is empty, so just add the new item (addNewData())
        // case 2: There is a difference to the existing data, but from the same day, so an update (replaceDataOfToday())
        // case 3: new item is from a different day (addNewData())
        // case 4: data are the same, so ignore it
        // case 5: DayNumber not in list of dayNumbers, new day (addNewData())
        
        GlobalStorageQueue.async(flags: .barrier, execute: {
            
            // at least we have a new retrieving date
            self.RKIDataLastRetreived = CFAbsoluteTimeGetCurrent()

            // make it permamnent
            self.permanentStore.set(self.RKIDataLastRetreived, forKey: "CoBaT.RKIDataLastRetreived")

            
            // check if this is the very first entry
            if self.RKIData[kindOf].isEmpty == true {
                
                // case 1: RKIData is empty, so just add the new item (addNewData())
                #if DEBUG_PRINT_FUNCCALLS
                print("refresh_RKIData case 1: RKIData is empty, so just add the new item (addNewData())")
                #endif
                
                // take the best timeStamp
                let oldestTimeStamp = self.RKIDataGetBestTimeStamp(newRKIData)
                
                // and add the new values
                self.addNewData(kindOf, newRKIData, oldestTimeStamp)
                
            } else {
                
                // check if there are differences
                
                // take the best timeStamp of new data
                let oldestTimeStamp = self.RKIDataGetBestTimeStamp(newRKIData)

                // find the right index to insert by the number of the day
                let dayNumber = self.getDayNumberFromTimeInterval(time: oldestTimeStamp)
                
                if let foundIndex = self.RKINumbersOfDays[kindOf].firstIndex(where: { $0 <= dayNumber } ) {
                    
                    // we found that record, check it
                    if self.RKIData[kindOf][foundIndex].hashValue != newRKIData.hashValue {
                        
                        // yes, there are differences, so check if the day changed
                        
                        // check if the days are different
                        //                    let newDate = shortSingleDateFormatterRKI.string(
                        //                        from: Date(timeIntervalSinceReferenceDate: oldestTimeStamp))
                        
                        let dayNumberOld = self.getDayNumberFromTimeInterval(time: self.RKIDataTimeStamps[kindOf][foundIndex])
                        
                        //                    let oldDate = shortSingleDateFormatterRKI.string(
                        //                        from: Date(timeIntervalSinceReferenceDate: self.RKIDataTimeStamps[kindOf][indexToUse]))
                        //
                        if dayNumber == dayNumberOld {
                            
                            // case 2: There is a difference to the existing data, but from the same day,
                            // so just an update (replaceDataOfToday())
                            #if DEBUG_PRINT_FUNCCALLS
                            print("refresh_RKIData case 2: oldDate (\(dayNumberOld) == newDate(\(dayNumber)) -> replaceData0()")
                            #endif
                            
                            self.replaceDataOfToday(kindOf, newRKIData, oldestTimeStamp)
                            
                        } else {
                            
                            // case 3: new item is from a different day (addNewData())
                            #if DEBUG_PRINT_FUNCCALLS
                            print("refresh_RKIData case 3: oldDate (\(dayNumberOld) != newDate(\(dayNumber)) -> addNewData()")
                            #endif
                            
                            self.addNewData(kindOf, newRKIData, oldestTimeStamp)
                        }
                        
                    } else {
                        
                        // case 4: data are the same, so ignore it
                        #if DEBUG_PRINT_FUNCCALLS
                        print ("refresh_RKIData case 4: data sets are equal, so do not update, but call iCloudService.startCoBaTWorkQueue(\(kindOf))")
                        #endif
                        
                        iCloudService.unique.startCoBaTWorkQueue(kindOf)
                        
                        // check if we have to inform the background service
                        if CoBaTBackgroundService.unique.RKIBackgroundFetchIsOngoingFlag == true {
                            
                            // check what kind of data we got
                            if kindOf == self.RKIDataState {
                                self.didRecieveStateData = true
                            } else if kindOf == self.RKIDataCounty {
                                self.didRecieveCountyData = true
                            }
                            
                            // if we have both parts, close the background task
                            if (self.didRecieveStateData == true)
                                && (self.didRecieveCountyData == true) {
                                
                                // yes both parts are done, so close the task
                                //#if DEBUG_PRINT_FUNCCALLS
                                GlobalStorage.unique.storeLastError(
                                    errorText:"refresh_RKIData case 4: kindOf: \(kindOf), (didRecieveStateData == \(self.didRecieveStateData)) && (didRecieveCountyData == \(self.didRecieveCountyData)), call closeBackgroundTask()")
                                //#endif
                                
                                CoBaTBackgroundService.unique.closeBackgroundTask()
                                
                            } else {
                                
                                //#if DEBUG_PRINT_FUNCCALLS
                                GlobalStorage.unique.storeLastError(
                                    errorText:"refresh_RKIData case 4: kindOf: \(kindOf), didRecieveStateData == \(self.didRecieveStateData), didRecieveCountyData == \(self.didRecieveCountyData), DO NOT close background task")
                                //#endif
                            }
                        }
                    }
                    
                } else {
                    
                    // case 5: new item is from a different day (addNewData())
                    #if DEBUG_PRINT_FUNCCALLS
                    print("refresh_RKIData case 5: did not found dayNumber (\(dayNumber) in List of dayNumbers) -> addNewData()")
                    #endif
                    
                    self.addNewData(kindOf, newRKIData, oldestTimeStamp)

                }

            }
            

            // local notification to update UI
            DispatchQueue.main.async(execute: {
                NotificationCenter.default.post(Notification(name: .CoBaT_RKIDataRetrieved))
            })
            
            #if DEBUG_PRINT_FUNCCALLS
            print("refresh_RKIData just posted .CoBaT_RKIDataRetrieved")
            #endif
        })
    }
    
    /**
     -----------------------------------------------------------------------------------------------
     
     Adds a new array item of [RKIDataStruct] at index 0, make sure there are not more than maxNumberOfDaysStored items in [[RKIDataStruct]]

     Has to be called inside a "GlobalStorageQueue.async(flags: .barrier, ..." closure

     -----------------------------------------------------------------------------------------------
     
     - Parameters:
        - newRKICountyData: new data to add
     
     - Returns: nothing
     
     */
    private func addNewData(_ kindOfArea: Int,
                            _ newRKIData: [RKIDataStruct],
                            _ timeStamp: TimeInterval) {
        
        //GlobalStorageQueue.async(flags: .barrier, execute: {
        
        #if DEBUG_PRINT_FUNCCALLS
        print("addNewData just started")
        #endif
        
        if self.RKIData[kindOfArea].isEmpty == true {
            
            self.RKIData[kindOfArea].append(newRKIData)
            self.RKIDataTimeStamps[kindOfArea].append(timeStamp)
            self.RKIDataWeekdays[kindOfArea].append(getWeekdayFromTimeInterval(time: timeStamp))
            self.RKINumbersOfDays[kindOfArea].append(getDayNumberFromTimeInterval(time: timeStamp))

            
        } else {
            
             
            // find the right index to insert by the number of the day
            let dayNumber = getDayNumberFromTimeInterval(time: timeStamp)
            //let indexToUse: Int
            if let foundIndex = RKINumbersOfDays[kindOfArea].firstIndex(where: { $0 < dayNumber } ) {
                
                // we found a place somewere
                self.RKIData[kindOfArea].insert(newRKIData, at: foundIndex)
                self.RKIDataTimeStamps[kindOfArea].insert(timeStamp, at: foundIndex)
                self.RKIDataWeekdays[kindOfArea].insert(getWeekdayFromTimeInterval(time: timeStamp), at: foundIndex)
                self.RKINumbersOfDays[kindOfArea].insert(dayNumber, at: foundIndex)
                
            } else {
                
                // we do not found a smaller on, so we are the smallest, append it
                self.RKIData[kindOfArea].append(newRKIData)
                self.RKIDataTimeStamps[kindOfArea].append(timeStamp)
                self.RKIDataWeekdays[kindOfArea].append(getWeekdayFromTimeInterval(time: timeStamp))
                self.RKINumbersOfDays[kindOfArea].append(getDayNumberFromTimeInterval(time: timeStamp))
            }
            
            // we do this per array, as they might be differnt (happened during tests)
            while self.RKIData[kindOfArea].count > (self.maxNumberOfDaysStored + 1) {
                self.RKIData[kindOfArea].removeLast()
            }
            while self.RKIDataTimeStamps[kindOfArea].count > (self.maxNumberOfDaysStored + 1) {
                self.RKIDataTimeStamps[kindOfArea].removeLast()
            }
            while self.RKIDataWeekdays[kindOfArea].count > (self.maxNumberOfDaysStored + 1) {
                self.RKIDataWeekdays[kindOfArea].removeLast()
            }
            while self.RKINumbersOfDays[kindOfArea].count > (self.maxNumberOfDaysStored + 1) {
                self.RKINumbersOfDays[kindOfArea].removeLast()
            }
  
        }
        
        // check if state data were chenged
        if kindOfArea == self.RKIDataState {
            
            // yes state data changed, so rebuild country data
            self.rebuildCountryData()
            
            // and rebuild the diconary
            self.rebuildStateDic()
        }
        
        // remember the timeStamp
        self.RKIDataLastUpdated = CFAbsoluteTimeGetCurrent()
        
        // rebuild the favorites
        self.rebuildFavorites()
        
        // make it permanant
        self.saveRKIData(from: "addNewData")
        
        // rebuild the delta values
        self.rebuildRKIDeltas(kindOf: kindOfArea, newData: true)
        
        // just for testing
        //for item in self.RKIData[kindOfArea][0] {
        //    print("addNewData, RKIData[\(kindOfArea)][0]: \(item.kindOf) \(item.name): \(item.cases7DaysPer100K), \(Date(timeIntervalSinceReferenceDate: item.timeStamp))")
        //}
        //print("addNewData, RKIDataTimeStamps[\(kindOfArea)][0]: \(Date(timeIntervalSinceReferenceDate: self.RKIDataTimeStamps[kindOfArea][0]))")
        
        #if DEBUG_PRINT_FUNCCALLS
        print("addNewData all good")
        #endif
        
        // })
    }
    
    
    /**
     -----------------------------------------------------------------------------------------------
     
     replace the existing item at index 0 of [[RKIDataStruct]] by new item of [RKIDataStruct]

     Has to be called inside a "GlobalStorageQueue.async(flags: .barrier, ..." closure

     -----------------------------------------------------------------------------------------------
     
     - Parameters:
        - newRKIData: new data to replace item 0
     
     - Returns: nothing
     */
    private func replaceDataOfToday(_ kindOfArea: Int,
                                    _ newRKIData: [RKIDataStruct],
                                    _ timeStamp: TimeInterval) {
        
        // GlobalStorageQueue.async(flags: .barrier, execute: {
        
        #if DEBUG_PRINT_FUNCCALLS
        print("replaceDataOfToday just started")
        #endif
        
        if self.RKIData[kindOfArea].isEmpty == true {
            
            self.RKIData[kindOfArea].append(newRKIData)
            self.RKIDataTimeStamps[kindOfArea].append(timeStamp)
            self.RKIDataWeekdays[kindOfArea].append(getWeekdayFromTimeInterval(time: timeStamp))
            self.RKINumbersOfDays[kindOfArea].append(getDayNumberFromTimeInterval(time: timeStamp))
            
        } else {
            
            // find the right index to insert by the number of the day
            let dayNumber = getDayNumberFromTimeInterval(time: timeStamp)

            if let foundIndex = RKINumbersOfDays[kindOfArea].firstIndex(where: { $0 == dayNumber } ) {
               
                self.RKIData[kindOfArea][foundIndex] = newRKIData
                self.RKIDataTimeStamps[kindOfArea][foundIndex] = timeStamp
                self.RKIDataWeekdays[kindOfArea][foundIndex] = self.getWeekdayFromTimeInterval(time: timeStamp)
                self.RKINumbersOfDays[kindOfArea][foundIndex] = self.getDayNumberFromTimeInterval(time: timeStamp)

            } else {
                
                self.RKIData[kindOfArea].append(newRKIData)
                self.RKIDataTimeStamps[kindOfArea].append(timeStamp)
                self.RKIDataWeekdays[kindOfArea].append(getWeekdayFromTimeInterval(time: timeStamp))
                self.RKINumbersOfDays[kindOfArea].append(getDayNumberFromTimeInterval(time: timeStamp))

            }
        }
        
        // check if state data were chenged
        if kindOfArea == self.RKIDataState {
            
            // yes state data changed, so rebuild country data
            self.rebuildCountryData()
            
            // and rebuild the diconary
            self.rebuildStateDic()
        }
        
        // remember the timeStamp
        self.RKIDataLastUpdated = CFAbsoluteTimeGetCurrent()
        
        // rebuild the favorites
        self.rebuildFavorites()
        
        // make it permanant
        self.saveRKIData(from: "replaceDataOfToday")
        
        // rebuild the delta values
        self.rebuildRKIDeltas(kindOf: kindOfArea, newData: true)
        
        // just for testing
        //for item in self.RKIData[kindOfArea][0] {
        //    print("replaceDataOfToday, RKIData[\(kindOfArea)][0]: \(item.kindOf) \(item.name): inz: \(item.cases7DaysPer100K), cases: \(item.cases)")
        //}
        //print("replaceDataOfToday, RKIDataTimeStamps[\(kindOfArea)][0]: \(Date(timeIntervalSinceReferenceDate: self.RKIDataTimeStamps[kindOfArea][0]))")
        
        #if DEBUG_PRINT_FUNCCALLS
        print("replaceDataOfToday all good")
        #endif
        // })
    }
    

    
    
    
    
    // ---------------------------------------------------------------------------------------------
    // MARK: - Helper RKI Data Handling
    // ---------------------------------------------------------------------------------------------

    
    /**
     -----------------------------------------------------------------------------------------------
     
     Rebuilds the country data out of the state data. Country data are just an aggregation of the states.
     
     Has to be called inside a "GlobalStorageQueue.async(flags: .barrier, ..." closure
     
     -----------------------------------------------------------------------------------------------
     */
    private func rebuildCountryData() {
        
        // To make it more robust, ALL country data for ALL days will be rebuild.
        // There is only 16 states times (max) 7 days, so there is no real problem with performance etc.
        
        #if DEBUG_PRINT_FUNCCALLS
        print("rebuildCountryData just started")
        #endif

        // clean level for country data
        self.RKIData[RKIDataCountry].removeAll()
        
        // build new country data from state data
        
        // loop over stored days in state data
        for dayIndex in 0 ..< self.RKIData[RKIDataState].count {
            
            // shortcut for current record
            let currentStateDayData = self.RKIData[RKIDataState][dayIndex]
            
            // preoare the calculation
            var inhabitants: Int = 0
            var cases: Int = 0
            var deaths: Int = 0
            var cases7Days: Double = 0

            // loop over the states
            for singleState in currentStateDayData {
                
                // do some sums
                inhabitants         += singleState.inhabitants
                cases               += singleState.cases
                deaths              += singleState.deaths
                
                // for the case in 7 days we have to calculate this number
                cases7Days          += Double(singleState.cases7DaysPer100K)
                                        * Double(singleState.inhabitants)
                                        / 100_000.0
            }
            
            // we calculate the casesPer100k and the cases7DaysPer100K
            let casesPer100k: Double   = Double(cases) * 100_000.0 / Double(inhabitants)
            let cases7DaysPer100K: Double = cases7Days * 100_000.0 / Double(inhabitants)
            
            // get the timeStamp
            let timeStamp = self.RKIDataGetBestTimeStamp(currentStateDayData)
            
            // build the struct
            let countryDataOfDay = RKIDataStruct(
                stateID: "0",
                myID: "0",
                name: "Deutschland",
                kindOf: "Land",
                inhabitants: inhabitants,
                cases: cases,
                deaths: deaths,
                casesPer100k: casesPer100k,
                cases7DaysPer100K: cases7DaysPer100K,
                timeStamp: timeStamp)
            
            // store the struct as an array of a single struct
            self.RKIData[RKIDataCountry].append([countryDataOfDay])
        }
        
        // we just copy county and state data as the timestamps for countries and states have the same values
        self.RKIDataTimeStamps[RKIDataCountry] = self.RKIDataTimeStamps[RKIDataState]
        self.RKIDataWeekdays[RKIDataCountry] = self.RKIDataWeekdays[RKIDataState]
        self.RKINumbersOfDays[RKIDataCountry] = self.RKINumbersOfDays[RKIDataState]

    }
    
    
    
    
    /**
     -----------------------------------------------------------------------------------------------
     
     Rebuilds the dictonary which holds the name for each state id
     
     -----------------------------------------------------------------------------------------------
     */
    private func rebuildStateDic() {
        
        #if DEBUG_PRINT_FUNCCALLS
        print("rebuildStateDic just started")
        #endif
        
        // reset the dictonary
        self.RKIStateDic = [:]
        
        if self.RKIData[RKIDataState].isEmpty == false {
            
            // walk over the RKI state data of day 0
            for stateIndex in 0 ..< self.RKIData[RKIDataState][0].count {
                
                // we take day 0 as the reference
                let currentState = self.RKIData[RKIDataState][0][stateIndex]
                
                // set the dictonary item
                self.RKIStateDic[currentState.myID ?? " "] = currentState.name
            }
            
        } else {
            
            #if DEBUG_PRINT_FUNCCALLS
            print("rebuildStateDic RKIData[RKIDataState].isEmpty == false")
            #endif

        }
    }
    
    /**
     -----------------------------------------------------------------------------------------------
     
     rebuilds the RKIDataDeltas[].
     
     Has to be called inside a "GlobalStorageQueue.async(flags: .barrier, ..." closure
     
     -----------------------------------------------------------------------------------------------
     */
    private func rebuildRKIDeltas(kindOf: Int, newData: Bool) {
        
        //#if DEBUG_PRINT_FUNCCALLS
        GlobalStorage.unique.storeLastError(errorText: "rebuildRKIDeltas just started, newData: \(newData)")
        //#endif
        
        // first step, remove the old data, and make sure we have an empty array per area level
        self.RKIDataDeltas = [ [], [], [], [] ]
        
        // we only send user notification, if there is new data and no error occure in this function
        var worthToSendUserNotification: Bool = newData
        
        // loop over level 0 (country, state, county)
        for areaIndex in 0 ..< self.RKIData.count {
            
            // build a shortcut
            let currentArea = self.RKIData[areaIndex]
            
            // check how many days we have for that area
            let numberOfDaysAvailable = currentArea.count
            
            
            // check if we have at least data of today
            if numberOfDaysAvailable > 0 {
                
                // copy the data of today
                self.RKIDataDeltas[areaIndex].append(currentArea[0])
                
                // check if we have data from yesterday
                if numberOfDaysAvailable > 1 {
                    
                    // we have historical data
                    // we loop over the data of yesterday and
                    // if there is another day available over the data of the last day.
                    
                    // we use an array of indexes to loop over the relevant data
                    
                    // we start with the index of yesterday
                    var arrayOfDayIndexes: [Int] = [1]
                    
                    // check if we have another day
                    if numberOfDaysAvailable > 2 {
                        
                        // yes, ther is at least a third day (up to 7 days over the time)
                        // so remember the index of the last day
                        arrayOfDayIndexes.append(numberOfDaysAvailable - 1)
                    }
                    
                    // loop over the days
                    for dayIndex in arrayOfDayIndexes {
                        
                        // buffer to build up new data
                        var newDeltaData: [RKIDataStruct] = []
                        
                        // we use a flags to decide if the new data can be used
                        var noErrors: Bool = true
                        
                        // build deltas for yesterday
                        for areaMemberIndex in 0 ..< currentArea[0].count {
                            
                            // build shortcut
                            let areaMemberToday = currentArea[dayIndex - 1][areaMemberIndex]
                            let areaMemberOldDay = currentArea[dayIndex][areaMemberIndex]
                            
                            // check the consistency (same name)
                            if areaMemberToday.name == areaMemberOldDay.name {
                                
                                // both records have same name, so go ahead
                                let inhabitantsDelta        = areaMemberToday.inhabitants       - areaMemberOldDay.inhabitants
                                let casesDelta              = areaMemberToday.cases             - areaMemberOldDay.cases
                                let deathsDelta             = areaMemberToday.deaths            - areaMemberOldDay.deaths
                                let casesPer100kDelta       = areaMemberToday.casesPer100k      - areaMemberOldDay.casesPer100k
                                let cases7DaysPer100KDelta  = areaMemberToday.cases7DaysPer100K - areaMemberOldDay.cases7DaysPer100K
                                
                                newDeltaData.append(RKIDataStruct(
                                                        stateID:            areaMemberToday.stateID,
                                                        myID:               areaMemberToday.myID ?? "" ,
                                                        name:               areaMemberToday.name,
                                                        kindOf:             areaMemberToday.kindOf,
                                                        inhabitants:        inhabitantsDelta,
                                                        cases:              casesDelta,
                                                        deaths:             deathsDelta,
                                                        casesPer100k:       casesPer100kDelta,
                                                        cases7DaysPer100K:  cases7DaysPer100KDelta,
                                                        timeStamp:          areaMemberOldDay.timeStamp))
                                
                            } else {
                                
                                // names are different, so data structure might have been changed, break loop and discard data
                                noErrors = false
                                
                                //#if DEBUG_PRINT_FUNCCALLS
                                GlobalStorage.unique.storeLastError(errorText:"CoBaT.GlobalStorage.rebuildRKIDeltas: Day \(dayIndex): areaMemberToday.name (\"\(areaMemberToday.name)\") != areaMemberYesterday.name (\"\(areaMemberOldDay.name)\"), set error, break loop")
                                //#endif
                                break
                            }
                            
                        } // loop area members
                        
                        if noErrors == true {
                            
                            self.RKIDataDeltas[areaIndex].append(newDeltaData)
                            
                        } else {
                            
                            // encode did fail, log the message
                            self.storeLastError(errorText: "CoBaT.GlobalStorage.rebuildRKIDeltas: Error: we have an inconsitency in yesterday data of RKIData[\(areaIndex)], no deltas for yesterday and 7 days stored")
                            
                            worthToSendUserNotification = false
                            
                        } // noErrors
                        
                    } // loop over days
                    
                } // available days > 1
                
            } else {
                
                #if DEBUG_PRINT_FUNCCALLS
                print("rebuildRKIDeltas self.RKIData[\(areaIndex)].count == 0, no data available, do nothing")
                #endif
                
                worthToSendUserNotification = false
            }
            
        } // loop over country, state, county
        
        if kindOf != self.RKIDataFavorites {
            
            DispatchQueue.main.async(execute: {
                
                // local notification to update UI
                NotificationCenter.default.post(Notification(name: .CoBaT_NewRKIDataReady))
                
                // local notification to update graphs
                NotificationCenter.default.post(Notification(name: .CoBaT_Graph_NewDetailSelected))
            })
            
            // check if we really should inform the user (there must be both data parts delivered, and no errors at all)
            
            // check which kind of data we recieved and set the right flag
            if kindOf == self.RKIDataState {
                self.didRecieveStateData = true
            } else if kindOf == self.RKIDataCounty {
                self.didRecieveCountyData = true
            }
            
            // now make the decision ...
            if (self.didRecieveStateData == true)
                && (self.didRecieveCountyData == true) {
                
                
                // OK, we will send it...
                // reset the flags, and send the notification
                self.didRecieveStateData = false
                self.didRecieveCountyData = false
                
                if (worthToSendUserNotification == true) {
                    
                    //#if DEBUG_PRINT_FUNCCALLS
                    self.storeLastError(errorText:"rebuildRKIDeltas will call sendUserNotification(type: .newRKIData)")
                    //#endif
                    CoBaTUserNotification.unique.sendUserNotification(type: .newRKIData)
                    
                } else {
                    
                    // check if we have to inform the background service
                    if CoBaTBackgroundService.unique.RKIBackgroundFetchIsOngoingFlag == true {
                        
                        //#if DEBUG_PRINT_FUNCCALLS
                        self.storeLastError(errorText:"rebuildRKIDeltas will call closeBackgroundTask(), because of: worthToSendUserNotification: \(worthToSendUserNotification), RKIBackgroundFetchIsOngoingFlag: \(CoBaTBackgroundService.unique.RKIBackgroundFetchIsOngoingFlag)")
                        //#endif
                        
                        CoBaTBackgroundService.unique.closeBackgroundTask()
                        
                    } else {
                        
                        //#if DEBUG_PRINT_FUNCCALLS
                        self.storeLastError(errorText:"rebuildRKIDeltas did NOT called sendUserNotification() and not closeBackgroundTask(), because of: worthToSendUserNotification: \(worthToSendUserNotification), RKIBackgroundFetchIsOngoingFlag: \(CoBaTBackgroundService.unique.RKIBackgroundFetchIsOngoingFlag)")
                        //#endif
                    }
                }
                
            } else {
                
                //#if DEBUG_PRINT_FUNCCALLS
                self.storeLastError(errorText:"rebuildRKIDeltas did NOT called sendUserNotification(type: .newRKIData), because of: StateData: \(self.didRecieveStateData), CountyData: \(self.didRecieveCountyData )")
                //#endif
            }
            
            // if this was caused by new data, check iCloud
            if newData == true {
                iCloudService.unique.startCoBaTWorkQueue(kindOf)
            }

            #if DEBUG_PRINT_FUNCCALLS
            print("rebuildRKIDeltas just posted .CoBaT_NewRKIDataReady")
            #endif
            
            // As this is the last step of data gathering, we will check if there are gaps in the data (missing days)
            //self.checkForGaps()
            
            
        } else {
            
            #if DEBUG_PRINT_FUNCCALLS
            print("rebuildRKIDeltas was Favorites, no postings")
            #endif
        }
    }
    
    /**
     -----------------------------------------------------------------------------------------------
     
     Rebuilds the 4th level according to the current favorites of the user
     
     This func must be called within a GlobalStorageQueue.async(flags: .barrier, )  !!!
     
     -----------------------------------------------------------------------------------------------
     */
    private func rebuildFavorites() {
        
        // We rebuild the whole level. It's the most robust solution
        
        #if DEBUG_PRINT_FUNCCALLS
        print("rebuildFavorites just started")
        #endif
        
        // check if the level of favorites is already initalized
        if self.RKIData.count < (RKIDataFavorites + 1) {
            
            // initialize the favorites levels
            self.RKIData.append([])
        }
       
        if self.RKIDataTimeStamps.count < (RKIDataFavorites + 1) {
            // initialize the favorites levels
            self.RKIDataTimeStamps.append([])
        }

        if self.RKIDataWeekdays.count < (RKIDataFavorites + 1) {
            // clean level for favorites data
            self.RKIDataWeekdays.append([])
        }

        if self.RKINumbersOfDays.count < (RKIDataFavorites + 1) {
            // clean level for favorites data
            self.RKINumbersOfDays.append([])
        }

        // clean level for favorites data
        self.RKIData[RKIDataFavorites] = []
        self.RKIDataTimeStamps[RKIDataFavorites] = []
        self.RKIDataWeekdays[RKIDataFavorites] = []
        self.RKINumbersOfDays[RKIDataFavorites] = []
        
        var sortArray: [[String]] = []

        // loop over the two levels of favorites
        for levelIndex in 0 ..< self.RKIFavorites.count {
            for itemIndex in 0 ..< self.RKIFavorites[levelIndex].count {
                
                // shortcut for the current ID
                let currentMyID = self.RKIFavorites[levelIndex][itemIndex]
                
                // we collect the data of the current ID in that array
                var currentRKIDataSet: [RKIDataStruct] = []
                
                // go over the data
                for dayIndex in 0 ..< GlobalStorage.unique.RKIData[levelIndex].count {
                    
                    // shortcut
                    let RKIDataToUse = GlobalStorage.unique.RKIData[levelIndex][dayIndex]
                    
                    // try to find the index of the requested ID
                    if let RKIDataOfDay = RKIDataToUse.first(where: { $0.myID == currentMyID } ) {
                        
                        // we found a valid record, so store the data locally
                        currentRKIDataSet.append(RKIDataOfDay)
                        
                    } else {
                        
                        // we did not found a valid index, report it and ignore the record
                        GlobalStorage.unique.storeLastError(errorText: "GlobalStorage.rebuildFavorites: Error: RKIData: did not found valid record for day \(dayIndex) of ID \"\(currentMyID)\" of area level \"\(levelIndex)\", ignore record")
                    }
                }
                
                // check if we found something useful
                if currentRKIDataSet.isEmpty == false {
                    
                    // Yes, we have something, so insert it in the favorite level
                    
                    // first we build the sort key
                    let currentItem = currentRKIDataSet[0]
                    
                    // if the item is a state, the second String is " " to ensure that states are the first
                    // entry in the sequence of counties of the state
                    let secondString: String
                    if (currentItem.myID == currentItem.stateID) {
                        secondString = " "
                    } else {
                        secondString = currentItem.name
                    }
                    
                    // now build the key
                    let sortKey = "\(self.RKIStateDic[currentItem.stateID] ?? " ")|\(secondString)"
                    
                    // loop over the available days
                    for dayIndex in 0 ..< currentRKIDataSet.count {
                        
                        
                        // check if this is the first day
                        if self.RKIData[RKIDataFavorites].isEmpty == true {
                            
                            // create the first day
                            self.RKIData[RKIDataFavorites].append([])
                            sortArray.append([])
                        }
                        
                        while self.RKIData[RKIDataFavorites].count <= dayIndex {
                            
                            // create the first day
                            self.RKIData[RKIDataFavorites].append([])
                            sortArray.append([])
                        }

                        if self.RKIData[RKIDataFavorites][dayIndex].isEmpty == true {
                            // yes, it's the first data, so just append it
                            self.RKIData[RKIDataFavorites][dayIndex].append(currentRKIDataSet[dayIndex])
                            
                            // also append the sort key
                            sortArray[dayIndex].append(sortKey)
                            
                        } else {
                            
                            // look for the first dataSet which is bigger
                            if let indexToInsert = sortArray[dayIndex].firstIndex(
                                where: { $0 > sortKey }
                            ) {
                                
                                // insert the new data at this index to get sorted data
                                self.RKIData[RKIDataFavorites][dayIndex].insert(currentRKIDataSet[dayIndex], at: (indexToInsert))
                                sortArray[dayIndex].insert(sortKey, at: indexToInsert)
                                
                            } else {
                                
                                // did not found it, so just append the data
                                self.RKIData[RKIDataFavorites][dayIndex].append(currentRKIDataSet[dayIndex])
                                sortArray[dayIndex].append(sortKey)
                            }
                        }
                    }
                } // currentRKIDataSet.isEmpty
            } // itemIndex
        } // levelIndex
       
        
        // we just copy county data as the timestamps should be the same
        self.RKIDataTimeStamps[RKIDataFavorites] = self.RKIDataTimeStamps[RKIDataCounty]
        self.RKIDataWeekdays[RKIDataFavorites] = self.RKIDataWeekdays[RKIDataCounty]
        self.RKINumbersOfDays[RKIDataFavorites] = self.RKINumbersOfDays[RKIDataCounty]

        // Finally, report we are done
        DispatchQueue.main.async(execute: {
            NotificationCenter.default.post(Notification(name: .CoBaT_FavoriteTabBarChangedContent))
        })

        
    }
    
    /**
     -----------------------------------------------------------------------------------------------
     
     stores the three variables RKIData, RKIDataTimeStamps and RKIDataLastUpdated into the permanant store
     
     -----------------------------------------------------------------------------------------------
     */
    private func saveRKIData(from: String) {
        
        // make sure we have consistent data
        //GlobalStorageQueue.async(execute: {
            
            #if DEBUG_PRINT_FUNCCALLS
            print("saveRKIData(\(from)) just started")
            #endif
            
            // make it permamnent, by encode it to JSON and store it
            do {
                // try to encode the county data and the timeStamps
                let encodedRKIData = try JSONEncoder().encode(self.RKIData)
                let encodedRKIDataTimeStamps = try JSONEncoder().encode(self.RKIDataTimeStamps)
                let encodedRKIFavorites = try JSONEncoder().encode(self.RKIFavorites)
                
                // if we got to here, no errors encountered, so store it
                self.permanentStore.set(encodedRKIData, forKey: "CoBaT.RKIData")
                self.permanentStore.set(encodedRKIDataTimeStamps, forKey: "CoBaT.RKIDataTimeStamps")
                self.permanentStore.set(self.RKIDataLastUpdated, forKey: "CoBaT.RKIDataLastUpdated")
                self.permanentStore.set(encodedRKIFavorites, forKey: "CoBaT.RKIFavorites")
                
                let encodedLastErrors = try JSONEncoder().encode(self.lastErrors)
                self.permanentStore.set(encodedLastErrors, forKey: "CoBaT.lastErrors")
                
                
                
                self.permanentStore.set(self.VersionOfPermanentStorage, forKey: "CoBaT.VersionOfPermanentStorage")
                
                #if DEBUG_PRINT_FUNCCALLS
                print("saveRKIData done!")
                #endif
                
            } catch let error as NSError {
                
                // encode did fail, log the message
                self.storeLastError(errorText: "CoBaT.GlobalStorage.saveRKIData(\(from)): Error: JSON encoder could not encode RKIData: error: \"\(error.description)\"")
            }
            
   
            
       // })
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
    

    /**
     -----------------------------------------------------------------------------------------------
     
     get the weekday of the given timeInterval for timezone "Europe/Berlin" (RKI reference timezone)
     
     -----------------------------------------------------------------------------------------------
     
     - Parameters:
        - time: given TimeInterval
     
     - Returns:
        - day of week (sunday = 1 ... saturday = 7, error = 0
     
     */
    private func getWeekdayFromTimeInterval(time: TimeInterval) -> Int {
        
        // we use the gregorian calender
        let RKICalendar: Calendar = Calendar(identifier: .gregorian)
        
        // we have to use the timeZone of Berlin, if that does not work, use the durrent timezone
        let RKITimeZone: TimeZone = TimeZone(identifier: "Europe/Berlin") ?? TimeZone.current

        // get the date
        let currentDate = Date(timeIntervalSinceReferenceDate: time)
        
        // and finally the weekday (with default value "0")
        return RKICalendar.dateComponents(in: RKITimeZone, from: currentDate).weekday ?? 0
    }
    
   
    
    /**
     -----------------------------------------------------------------------------------------------
     
     rebuilds RKIDataWeekdays[] and RKINumbersOfDays[] out of RKIDataTimeStamps[]
     
     -----------------------------------------------------------------------------------------------
     */
    private func rebuildDayArrays() {
        
        // reset the array
        self.RKIDataWeekdays = []
        self.RKINumbersOfDays = []
        
        // loop over all area levels
        for areaIndex in 0 ..< self.RKIDataTimeStamps.count {
            
            // append an empty array per area level
            self.RKIDataWeekdays.append([])
            self.RKINumbersOfDays.append([])
            
            
            // loop over all days
            for dayIndex in 0 ..< self.RKIDataTimeStamps[areaIndex].count {
                
                // get the day of the week and store it
                let weekday = self.getWeekdayFromTimeInterval(
                    time: self.RKIDataTimeStamps[areaIndex][dayIndex])
                self.RKIDataWeekdays[areaIndex].append(weekday)
                
                let numberOfDay = self.getDayNumberFromTimeInterval(
                    time: self.RKIDataTimeStamps[areaIndex][dayIndex])
                self.RKINumbersOfDays[areaIndex].append(numberOfDay)
            }
        }
    }
    
    /**
     -----------------------------------------------------------------------------------------------
     
     This func simply set or reset the flag RKIDataHasGaps, if there are gaps (missing days).
     
     -----------------------------------------------------------------------------------------------
     */
    private func checkForGaps() {
        
        GlobalStorageQueue.async(execute: {
            
            #if DEBUG_PRINT_FUNCCALLS
            print("checkForGaps() just started")
            #endif
            
            // first check is simply a count. Do we have enough days?
            if self.RKIData[self.RKIDataState].count < self.maxNumberOfDaysStored {
                
                // we do not have enough days on state level
                
                #if DEBUG_PRINT_FUNCCALLS
                print("checkForGaps() number of days (state) (\(self.RKIData[self.RKIDataState].count)) < \(self.maxNumberOfDaysStored), will set flag RKIDataHasGaps = true")
                #endif
                
                GlobalStorageQueue.async(flags: .barrier, execute: {
                    self.RKIDataHasGaps = true
                })
                
            } else if self.RKIData[self.RKIDataCountry].count < self.maxNumberOfDaysStored {
                
                // we do not have enough days on county level
                
                #if DEBUG_PRINT_FUNCCALLS
                print("checkForGaps() number of days (County) (\(self.RKIData[self.RKIDataCountry].count)) < \(self.maxNumberOfDaysStored), will set flag RKIDataHasGaps = true")
                #endif
                
                GlobalStorageQueue.async(flags: .barrier, execute: {
                    self.RKIDataHasGaps = true
                })
                
            } else {
                
                // check if the newest data are from today
                let currentDay = self.getDayNumberFromTimeInterval(time: CFAbsoluteTimeGetCurrent())
                if self.RKINumbersOfDays[self.RKIDataState][0] != currentDay {
                    
                    #if DEBUG_PRINT_FUNCCALLS
                    print("checkForGaps() newest State day (\(self.RKINumbersOfDays[self.RKIDataState][0])) != currentDay (\(currentDay)), will set flag RKIDataHasGaps = true")
                    #endif
                    
                    GlobalStorageQueue.async(flags: .barrier, execute: {
                        self.RKIDataHasGaps = true
                    })
                    
                } else if self.RKINumbersOfDays[self.RKIDataCounty][0] != currentDay {
                    
                    #if DEBUG_PRINT_FUNCCALLS
                    print("checkForGaps() newest County day (\(self.RKINumbersOfDays[self.RKIDataCounty][0])) != currentDay (\(currentDay)), will set flag RKIDataHasGaps = true")
                    #endif
                    
                    GlobalStorageQueue.async(flags: .barrier, execute: {
                        self.RKIDataHasGaps = true
                    })
                    
                } else {
                    
                    // now we check the sequence of the day codes. They should be without gaps, starting with highest number on
                    var lastDayCode: Int = self.RKINumbersOfDays[self.RKIDataState][0]
                    var foundGap: Bool = false
                    
                    for index in 1 ..< self.RKINumbersOfDays[self.RKIDataState].count {
                        
                        // check if the next day is in sequence (decending order)
                        if self.RKINumbersOfDays[self.RKIDataState][index] == (lastDayCode - 1) {
                            
                            // yes, it's in sync, prepare next loop
                            lastDayCode = self.RKINumbersOfDays[self.RKIDataState][index]
                            
                        } else {
                            
                            // no, day is out of seqence, report, set flag and break loop
                            #if DEBUG_PRINT_FUNCCALLS
                            print("checkForGaps() found gap in state data at index \(index) (\(self.RKINumbersOfDays[self.RKIDataCounty][index])) != lastDayCode - 1 (\(lastDayCode - 1)), will set flag RKIDataHasGaps = true")
                            #endif
                            
                            GlobalStorageQueue.async(flags: .barrier, execute: {
                                self.RKIDataHasGaps = true
                            })

                            foundGap = true
                            break
                        }
                    }
                    
                    // check if we already found a gap
                    if foundGap == false {
                        
                        // no, so do the same for the county level
                        lastDayCode = self.RKINumbersOfDays[self.RKIDataCounty][0]
                        
                        for index in 1 ..< self.RKINumbersOfDays[self.RKIDataCounty].count {
                            
                            // check if the next day is in sequence (decending order)
                            if self.RKINumbersOfDays[self.RKIDataCounty][index] == (lastDayCode - 1) {
                                
                                // yes, it's in sync, prepare next loop
                                lastDayCode = self.RKINumbersOfDays[self.RKIDataCounty][index]
                                
                            } else {
                                
                                // no, day is out of seqence, report, set flag and break loop
                                #if DEBUG_PRINT_FUNCCALLS
                                print("checkForGaps() found gap in county data at index \(index) (\(self.RKINumbersOfDays[self.RKIDataCounty][index])) != lastDayCode - 1 (\(lastDayCode - 1)), will set flag RKIDataHasGaps = true")
                                #endif
                                
                                GlobalStorageQueue.async(flags: .barrier, execute: {
                                    self.RKIDataHasGaps = true
                                })
                                
                                foundGap = true
                                break
                            }
                        }
                        
                        // if we still did not find a gap, set the flag to false
                        if foundGap == false {
                            GlobalStorageQueue.async(flags: .barrier, execute: {
                                self.RKIDataHasGaps = false
                            })
                        }
                        
                    } // foundGap
                } // currentDay
            } // maxNumberOfDaysStored
        })
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
             
            self.saveRKIData(from: "storeLastError")
            
            #if DEBUG_PRINT_FUNCCALLS
            print("\(errorText)")
            #endif

            
//            // local notification to update UI
//            DispatchQueue.main.async(execute: {
//                NotificationCenter.default.post(Notification(name: .CoBat_NewErrorStored))
//            })
//
//            #if DEBUG_PRINT_FUNCCALLS
//            print("storeLastError: just posted .CoBat_NewErrorStored")
//            #endif
        })
    }
    
    
    // ---------------------------------------------------------------------------------------------
    // MARK: - Last Errors Storage (not permanent)
    // ---------------------------------------------------------------------------------------------

    public struct lastErrorStruct: Decodable, Encodable {
        let errorText: String
        let errorTimeStamp: TimeInterval
        
        init(errorText: String) {
            self.errorText = errorText
            self.errorTimeStamp = CFAbsoluteTimeGetCurrent()

        }
    }
    
    public var lastErrors: [lastErrorStruct] = []
}
