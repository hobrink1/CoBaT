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
    public let RKIDataCountry: Int = 0
    public let RKIDataState: Int = 1
    public let RKIDataCounty: Int = 2
    
    // size of storage
    private let maxNumberOfDaysStored: Int = 7
    private let maxNumberOfErrorsStored: Int = 20
    
    // Version of permanent storage
    private let VersionOfPermanentStorage: Int = 2

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
                    
                    
                    // got the data, try to decode it
                    do {
                        
                        let myRKIData = try JSONDecoder().decode([[[RKIDataStruct]]].self,
                                                                       from: (loadedRKIData as? Data)!)
                        
                        let myRKIDataTimeStamps = try JSONDecoder().decode([[TimeInterval]].self,
                                                                                 from: (loadedRKIDataTimeStamps as? Data)!)
                        
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
                            
                            // rebuild the delta values
                            self.rebuildRKIDeltas()

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
                                    
                                    
                                default:
                                    
                                    // unknown version, just report nd do not restore the date
                                    self.storeLastError(errorText: "CoBaT.GlobalStorage.restoreSavedRKIData: Error: version of permanent storage (\(currentVersionOfPermanentStorage)) is unknown, current version is: \(self.VersionOfPermanentStorage), do not restore data, as it might be not usefull")
                                    
                                    break
                                    
                                } // case
                                
                            } // loop
                            
                            // OK, we did the migration, so store the migrated values ...
                            self.RKIData = migratedRKIData
                            self.RKIDataTimeStamps = migratedRKIDataTimeStamps
                            self.RKIDataLastUpdated = loadedRKIDataLastUpdated
                            self.RKIDataLastRetreived = loadedRKIDataLastRetreived

                            // and force a save to secure what we have done
                            self.saveRKIData()
                            
                            // rebuild the delta values
                            self.rebuildRKIDeltas()
                            
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
            
            #if DEBUG_PRINT_FUNCCALLS
            print("restoreSavedRKIData done, call")
            #endif
            
            // get fresh data
            RKIDataDownload.unique.getRKIData()
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
    
    public var RKIData : [[[RKIDataStruct]]] = [[], [], []]   // initialise with three empty arrays, avoid empty level
    
    
    // We use this to precalculate the deltas (differneces to yesterday and to 7 days back).
    // So for the second index (days) we use 0 for today, 1 for deltas to yesterday and 2 for deltas to 7 days back.
    // This colums are only filled if suitable data are available
    // This array is recalculated each time the data in RKIData[] changed
    // this array will not stored permanently!
    
    public var RKIDataDeltas : [[[RKIDataStruct]]] = [[], [], []]   // initialise with three empty arrays, avoid empty level

    
    // TimeStamps per array item
    // we use a different array to make sure we can compare new and old [RKIDataStruct] by hash values
    // use the same logic as on RKIData, but only two index levels
    // first index level is the kind of data set (country, state or county) (index 0 = country, 1 = state, 2 = county)
    // second index level are the up to maxNumberOfDaysStored days (index 0 = today, index 7 = same day last week)
    //
    // example: "Country (0), yesterday (1), timestamp" looks like: RKIDataTimeStamps[0][1]
    
    public var RKIDataTimeStamps : [[TimeInterval]] = [[], [], []]       // initialise with two empty arrays, so first index level not empty
    
    
    // the timeStamp the data was last updated (updates only if data changed)
    public var RKIDataLastUpdated: TimeInterval = 0
    
    
    // the timeStamp data was last retrieved
    public var RKIDataLastRetreived: TimeInterval = 0

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
        
        GlobalStorageQueue.async(execute: {
            
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
                        // so just an update (replaceDataOfToday())
                        #if DEBUG_PRINT_FUNCCALLS
                        print("refresh_RKIData case 2: oldDate (\(oldDate) == newDate(\(newDate)) -> replaceData0()")
                        #endif

                        self.replaceDataOfToday(kindOf, newRKIData, oldestTimeStamp)

                    } else {
                    
                        // case 3: new item is from a different day (addNewData())
                        #if DEBUG_PRINT_FUNCCALLS
                        print("refresh_RKIData case 3: oldDate (\(oldDate) != newDate(\(newDate)) -> addNewData()")
                        #endif
                        
                        self.addNewData(kindOf, newRKIData, oldestTimeStamp)
                    }
                    
                } else {
                    
                    // case 4: data are the same, so ignore it
                    print ("refresh_RKIData case 4: data sets are equal, so do not update")
                }
            }
            
            // at least we have a new retrieving date
            self.RKIDataLastRetreived = CFAbsoluteTimeGetCurrent()

            // make it permamnent
            self.permanentStore.set(self.RKIDataLastRetreived, forKey: "CoBaT.RKIDataLastRetreived")

            // local notification to update UI
            NotificationCenter.default.post(Notification(name: .CoBaT_RKIDataRetrieved))
            
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

           } else {
                
            while self.RKIData[kindOfArea].count > self.maxNumberOfDaysStored {
                    
                    self.RKIData[kindOfArea].removeLast()
                    self.RKIDataTimeStamps[kindOfArea].removeLast()
                }
                
                self.RKIData[kindOfArea].insert(newRKIData, at: 0)
                self.RKIDataTimeStamps[kindOfArea].insert(timeStamp, at: 0)
            }
            
            // check if state data were chenged
            if kindOfArea == self.RKIDataState {
                // yes state data changed, so rebuild country data
                self.rebuildCountryData()
            }
            
            // remember the timeStamp
            self.RKIDataLastUpdated = CFAbsoluteTimeGetCurrent()
            
            // make it permanant
            self.saveRKIData()
            
            // rebuild the delta values
            self.rebuildRKIDeltas()

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
                
            } else {
                
                self.RKIData[kindOfArea][0] = newRKIData
                self.RKIDataTimeStamps[kindOfArea][0] = timeStamp
            }
            
            // check if state data were chenged
            if kindOfArea == self.RKIDataState {
                // yes state data changed, so rebuild country data
                self.rebuildCountryData()
            }
            
            // remember the timeStamp
            self.RKIDataLastUpdated = CFAbsoluteTimeGetCurrent()
            
            // make it permanant
            self.saveRKIData()

            // rebuild the delta values
            self.rebuildRKIDeltas()
            
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
    }
    
    /**
     -----------------------------------------------------------------------------------------------
     
     rebuilds the RKIDataDeltas[].
     
     Has to be called inside a "GlobalStorageQueue.async(flags: .barrier, ..." closure
     
     -----------------------------------------------------------------------------------------------
     */
    private func rebuildRKIDeltas() {
        
        #if DEBUG_PRINT_FUNCCALLS
        print("rebuildRKIDeltas just started")
        #endif

        // first step, remove the old data, and make sure we have an empty array per area level
        self.RKIDataDeltas = [ [], [], [] ]
        
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
                                
                                print ("CoBaT.GlobalStorage.rebuildRKIDeltas: Day \(dayIndex): areaMemberToday.name (\"\(areaMemberToday.name)\") != areaMemberYesterday.name (\"\(areaMemberOldDay.name)\"), set error, break loop")
                                break
                            }
                            
                        } // loop area members
                        
                        if noErrors == true {
                            
                            self.RKIDataDeltas[areaIndex].append(newDeltaData)
                            
                        } else {
                            
                            // encode did fail, log the message
                            self.storeLastError(errorText: "CoBaT.GlobalStorage.rebuildRKIDeltas: Error: we have an inconsitency in yesterday data of RKIData[\(areaIndex)], no deltas for yesterday and 7 days stored")
                            
                        } // noErrors
                        
                    } // loop over days
                    
                } // available days > 1
                
            } else {
                
                #if DEBUG_PRINT_FUNCCALLS
                print("rebuildRKIDeltas no data available, do nothing")
                #endif
            }
            
        } // loop over country, state, county
        
        // local notification to update UI
        NotificationCenter.default.post(Notification(name: .CoBaT_NewRKIDataReady))
        
        #if DEBUG_PRINT_FUNCCALLS
        print("rebuildRKIDeltas just posted .CoBaT_NewRKIDataReady")
        #endif

    }
    
    /**
     -----------------------------------------------------------------------------------------------
     
     stores the three variables RKIData, RKIDataTimeStamps and RKIDataLastUpdated into the permanant store
     
     -----------------------------------------------------------------------------------------------
     */
    private func saveRKIData() {
        
        // make sure we have consistent data
        GlobalStorageQueue.async(execute: {
            
            #if DEBUG_PRINT_FUNCCALLS
            print("saveRKIData just started")
            #endif

            // make it permamnent, by encode it to JSON and store it
            do {
                // try to encode the county data and the timeStamps
                let encodedRKIData = try JSONEncoder().encode(self.RKIData)
                let encodedRKIDataTimeStamps = try JSONEncoder().encode(self.RKIDataTimeStamps)
                
                // if we got to here, no errors encountered, so store it
                self.permanentStore.set(encodedRKIData, forKey: "CoBaT.RKIData")
                self.permanentStore.set(encodedRKIDataTimeStamps, forKey: "CoBaT.RKIDataTimeStamps")
                self.permanentStore.set(self.RKIDataLastUpdated, forKey: "CoBaT.RKIDataLastUpdated")
                
                self.permanentStore.set(self.VersionOfPermanentStorage, forKey: "CoBaT.VersionOfPermanentStorage")
                
                #if DEBUG_PRINT_FUNCCALLS
                print("saveRKIData done!")
                #endif
                
            } catch let error as NSError {
                
                // encode did fail, log the message
                self.storeLastError(errorText: "CoBaT.GlobalStorage.saveRKIData: Error: JSON encoder could not encode RKIData: error: \"\(error.description)\"")
            }
        })
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
            
            // local notification to update UI
            NotificationCenter.default.post(Notification(name: .CoBat_NewErrorStored))
            
            #if DEBUG_PRINT_FUNCCALLS
            print("storeLastError: just posted .CoBat_NewErrorStored")
            #endif
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
