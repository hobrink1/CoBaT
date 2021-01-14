//
//  iCloudService.swift
//  CoBaT
//
//  Created by Hartwig Hopfenzitz on 06.01.21.
//

import Foundation
import CloudKit
import MapKit


// TODO: eventuell eine referenz auf das device für jeden Records? oder eher nicht .. nachdenken!


// --------------------------------------------------------------------
// MARK: Standard Record field names
// --------------------------------------------------------------------
/*
 
 Unfortunatly, the record fields in the dashboard are spelled differently as the standard name we
 have to use in sorts etc..
 
 So, this is the list for the field names we have to use. Further down the let constants we use at WayAndSee
 
 recordID: CKRecordID
 The unique ID of the record.
 
 recordType: String
 The app-defined string that identifies the type of the record.
 
 creationDate: Date?
 The time when the record was first saved to the server.
 
 creatorUserRecordID: CKRecordID?
 The ID of the user who created the record.
 
 modificationDate: Date?
 The time when the record was last saved to the server.
 
 lastModifiedUserRecordID: CKRecordID?
 The ID of the user who last modified the record.
 
 recordChangeTag: String?
 A string containing the server change token for the record.
 */

var IS_CK_modifiedAt_FieldName : String     = "modificationDate"
var IS_CK_recordID_FieldName : String       = "recordID"



// --------------------------------------------------------------------
// MARK: -
// MARK: - WIS iCloud Service
// --------------------------------------------------------------------
final class iCloudService: NSObject {
    
    // --------------------------------------------------------------------
    // MARK: - Singleton
    // --------------------------------------------------------------------
    static let unique = iCloudService()
    
    // --------------------------------------------------------------------
    // MARK: - Database
    // --------------------------------------------------------------------
    //static let database = CKContainer.default().publicCloudDatabase
    static let database = CKContainer(identifier: "iCloud.org.hobrink.CoBaT").publicCloudDatabase
    
    // --------------------------------------------------------------------
    // MARK: - Class Properties
    // --------------------------------------------------------------------
    
    // User Account status, we need that for the push..() methodes, the pull methodes will work, as
    // read operations to public databases are always possible
    var userIsLoggedIn: Bool = false
    
    
    // this table holds the reference which days are available in iCloud
    struct ReferenceTableStruct {
        let DayNumber: Int
        let DateString: String
        let DataHashValue : Int
        
        init(dayNumber: Int, dateString: String, dataHashValue: Int) {
            self.DayNumber = dayNumber
            self.DateString = dateString
            self.DataHashValue = dataHashValue
        }
    }
    
    // this are the reference tables itself
    var RKIReferenceTableState: [ReferenceTableStruct] = []
    var RKIReferenceTableCounty: [ReferenceTableStruct] = []

    var CoBaTReferenceTableState: [ReferenceTableStruct] = []
    var CoBaTReferenceTableCounty: [ReferenceTableStruct] = []

    
    // enum of status for that queue
    enum sendStatusEnum {
        case new, markedForSend, dataSend
    }

    // this dataStruct will be used to build a queue of data to send
    struct dataQueueStruct {
        
        let time: TimeInterval
        let data: Data
        let RKIDataType: GlobalStorage.RKI_DataTypeEnum
        var sendStatus: sendStatusEnum
        
        init(time: TimeInterval, data: Data, RKIDataType: GlobalStorage.RKI_DataTypeEnum) {
            self.time = time
            self.data = data
            self.RKIDataType = RKIDataType
            self.sendStatus = .new
        }
    }
    
    
    // we will try to send these data items
    var RKIDataToSendCounty: [Int : dataQueueStruct] = [:]
    var RKIDataToSendState:   [Int : dataQueueStruct] = [:]

    var CoBaTDataToSendCounty: [Int : dataQueueStruct] = [:]
    var CoBaTDataToSendState:   [Int : dataQueueStruct] = [:]

    // --------------------------------------------------------------------
    // MARK: - RecordTypes and RecordFields
    // --------------------------------------------------------------------
    /**
     -----------------------------------------------------------------------------------------------
     Recordtypes
     -----------------------------------------------------------------------------------------------
     */
    let RT_RKICountyData: String      = "RKI_County_Data"
    let RT_RKICountyReference: String = "RKI_County_Reference"
    
    let RT_RKIStateData: String       = "RKI_State_Data"
    let RT_RKIStateReference: String  = "RKI_State_Reference"
    
    let RT_CoBaTCountyData: String      = "CoBaT_County_Data"
    let RT_CoBaTCountyReference: String = "CoBaT_County_Reference"
    
    let RT_CoBaTStateData: String       = "CoBaT_State_Data"
    let RT_CoBaTStateReference: String  = "CoBaT_State_Reference"
    
    /**
     -----------------------------------------------------------------------------------------------
     RecordFields
     -----------------------------------------------------------------------------------------------
     */
    let RF_CoBaTData: String        = "CoBaTData"
    let RF_DataHashValue: String    = "DataHashValue"
    let RF_Date: String             = "Date"
    let RF_DayNumber: String        = "DayNumber"
    let RF_RKIData: String          = "RKIData"
    let RF_Time: String             = "Time"

      
    // --------------------------------------------------------------------
    // MARK: - API
    // --------------------------------------------------------------------
    /**
     -----------------------------------------------------------------------------------------------
     
     THis func stores the provided data in an array and calls the first step of the work queue (getReferences())
     
     -----------------------------------------------------------------------------------------------
     - Parameters:
     - RKI_DataType: The data type of the data object
     - time: TimeStamp of the data object
     - data: The data object
     
     - Returns:
     */
    public func saveRKIData(RKI_DataType:  GlobalStorage.RKI_DataTypeEnum, time: TimeInterval, data: Data) {
        
        GlobalStorageQueue.async(flags: .barrier ,execute: {
            
            #if DEBUG_PRINT_FUNCCALLS
            print( "iCloudService.saveRKIData(): type: \(RKI_DataType), time: \(Date(timeIntervalSinceReferenceDate: time)), size: \(data.count) just started")
            #endif
            
            // check the user acoount
            self.checkUserAccount()
            

            // get the number of day, we need it as the key for the dictonary
            let dayNumber = GlobalStorage.unique.getDayNumberFromTimeInterval(time: time)
            
            // store the data for future use
            switch RKI_DataType {
            
            case .county:
                
                // check if we already have a dictionary element
                if self.RKIDataToSendCounty[dayNumber] == nil {
                    
                    // no, so just add the data to the dictonary
                    self.RKIDataToSendCounty[dayNumber] = dataQueueStruct(time: time, data: data, RKIDataType: RKI_DataType)
                    
                    #if DEBUG_PRINT_FUNCCALLS
                    print( "iCloudService.saveRKIData(): just set RKIDataToSendCounty[\(dayNumber)] to type: \(RKI_DataType), time: \(Date(timeIntervalSinceReferenceDate: time))")
                    #endif

                } else {
                    
                    // yes, we have already data with that dayNumber, so check if this is an update, by hashValues
                    
                    let hashData = CoBaTHash(data: self.RKIDataToSendCounty[dayNumber]!.data)
                    let hashReference = CoBaTHash(data: data)
                   
                    if hashData != hashReference {
                        
                        // yes we have newer data, so check if we are early enough to replace the data
                        if self.RKIDataToSendCounty[dayNumber]!.sendStatus == .new {
                            
                            // yes, it is still new, so just replace it, as we nmight have updated values
                            self.RKIDataToSendCounty[dayNumber] = dataQueueStruct(time: time, data: data, RKIDataType: RKI_DataType)
                            
                            #if DEBUG_PRINT_FUNCCALLS
                            print( "iCloudService.saveRKIData(): just replaced RKIDataToSendCounty[\(dayNumber)] by type: \(RKI_DataType), time: \(Date(timeIntervalSinceReferenceDate: time))")
                            #endif
                            
                        } else {
                            
                            #if DEBUG_PRINT_FUNCCALLS
                            print( "iCloudService.saveRKIData(): RKIDataToSendCounty[\(dayNumber)]!.sendStatus != .new, do NOT replace by type: \(RKI_DataType), time: \(Date(timeIntervalSinceReferenceDate: time))")
                            #endif
                        }
                        
                    } else {
                        
                        // no, same data, so do nothing
                        #if DEBUG_PRINT_FUNCCALLS
                        print( "iCloudService.saveRKIData(): new data \(RKI_DataType), time: \(Date(timeIntervalSinceReferenceDate: time)) already in dataToSendSCounty[\(dayNumber)] and hash values are equal, do nothing")
                        #endif
                    }
                }
 
                // start the workflow by getting the reference data
                self.getRKIReferencesCounty()

                
                
            case .state:
                
                // store the data for future use
                
                // check if we already have a dictionary element
                if self.RKIDataToSendState[dayNumber] == nil {
                    
                    // no, so just add the data to the dictonary
                    self.RKIDataToSendState[dayNumber] = dataQueueStruct(time: time, data: data, RKIDataType: RKI_DataType)
                    
                    #if DEBUG_PRINT_FUNCCALLS
                    print( "iCloudService.saveRKIData(): just set RKIDataToSendState[\(dayNumber)] to type: \(RKI_DataType), time: \(Date(timeIntervalSinceReferenceDate: time))")
                    #endif

                } else {
                    
                    // yes, we have already data with that dayNumber, so check if this is an update, by hashValues
                    
                    let hashData = CoBaTHash(data: self.RKIDataToSendState[dayNumber]!.data)
                    let hashReference = CoBaTHash(data: data)
                   
                    if hashData != hashReference {
                        
                        // yes we have newer data, so check if we are early enough to replace the data
                        if self.RKIDataToSendState[dayNumber]!.sendStatus == .new {
                            
                            // yes, it is still new, so just replace it, as we nmight have updated values
                            self.RKIDataToSendState[dayNumber] = dataQueueStruct(time: time, data: data, RKIDataType: RKI_DataType)
                            
                            #if DEBUG_PRINT_FUNCCALLS
                            print( "iCloudService.saveRKIData(): just replaced RKIDataToSendState[\(dayNumber)] by type: \(RKI_DataType), time: \(Date(timeIntervalSinceReferenceDate: time))")
                            #endif
                            
                        } else {
                            
                            #if DEBUG_PRINT_FUNCCALLS
                            print( "iCloudService.saveRKIData(): RKIDataToSendState[\(dayNumber)]!.sendStatus != .new, do NOT replace by type: \(RKI_DataType), time: \(Date(timeIntervalSinceReferenceDate: time))")
                            #endif
                        }
                        
                    } else {
                        
                        // no, same data, so do nothing
                        #if DEBUG_PRINT_FUNCCALLS
                        print( "iCloudService.saveRKIData(): new data \(RKI_DataType), time: \(Date(timeIntervalSinceReferenceDate: time)) already in dataToSendState[\(dayNumber)] and hash values are equal, do nothing")
                        #endif
                    }
                }

                // start the workflow by getting the reference data
                self.getRKIReferencesState()
                
            default:
                break
            }
        })
    }
    
    /**
     -----------------------------------------------------------------------------------------------
     
     
     
     -----------------------------------------------------------------------------------------------
     
     - Parameters:
     - :
     
     - Returns:
     
     */
    
    public func saveCoBaTData(_ kindOfArea: Int,
                              _ newRKIData: [GlobalStorage.RKIDataStruct],
                              _ time: TimeInterval) {
        
        let data: Data
        do {
            // try to encode the county data and the timeStamps
            data = try JSONEncoder().encode(newRKIData)
            
        } catch let error as NSError {
            
            // encode did fail, log the message and return
            GlobalStorage.unique.storeLastError(errorText: "iCloudService.saveCoBaTData(): Error: JSON encoder could not encode newRKIData: error: \"\(error.description)\", do nothing and return")
            
            return
        }

        // if we reach here, we hava valid data object
        GlobalStorageQueue.async(flags: .barrier ,execute: {
            
            #if DEBUG_PRINT_FUNCCALLS
            print( "iCloudService.saveCoBaTData(): type: \(kindOfArea), time: \(Date(timeIntervalSinceReferenceDate: time)), size: \(data.count) just started")
            #endif
            
            // check the user acoount
            self.checkUserAccount()

            // get the number of day, we need it as the key for the dictonary
            let dayNumber = GlobalStorage.unique.getDayNumberFromTimeInterval(time: time)
            
            // store the data for future use
            switch kindOfArea {
            
            case GlobalStorage.unique.RKIDataCounty:
                
                 // check if we already have a dictionary element
                if self.RKIDataToSendCounty[dayNumber] == nil {
                    
                    // no, so just add the data to the dictonary
                    self.CoBaTDataToSendCounty[dayNumber] = dataQueueStruct(time: time, data: data, RKIDataType: .county)
                    
                    #if DEBUG_PRINT_FUNCCALLS
                    print( "iCloudService.saveCoBaTData(): just set CoBaTDataToSendCounty[\(dayNumber)] to type: \(GlobalStorage.RKI_DataTypeEnum.county), time: \(Date(timeIntervalSinceReferenceDate: time))")
                    #endif

                } else {
                    
                    // yes, we have already data with that dayNumber, so check if this is an update, by hashValues
                    
                    let hashData = CoBaTHash(data: self.RKIDataToSendCounty[dayNumber]!.data)
                    let hashReference = CoBaTHash(data: data)
                   
                    if hashData != hashReference {
                        
                        // yes we have newer data, so check if we are early enough to replace the data
                        if self.RKIDataToSendCounty[dayNumber]!.sendStatus == .new {
                            
                            // yes, it is still new, so just replace it, as we nmight have updated values
                            self.CoBaTDataToSendCounty[dayNumber] = dataQueueStruct(time: time, data: data, RKIDataType: .county)
                            
                            #if DEBUG_PRINT_FUNCCALLS
                            print( "iCloudService.saveCoBaTData(): just replaced CoBaTDataToSendCounty[\(dayNumber)] by type: \(GlobalStorage.RKI_DataTypeEnum.county), time: \(Date(timeIntervalSinceReferenceDate: time))")
                            #endif
                            
                        } else {
                            
                            #if DEBUG_PRINT_FUNCCALLS
                            print( "iCloudService.saveCoBaTData(): CoBaTDataToSendCounty[\(dayNumber)]!.sendStatus != .new, do NOT replace by type: \(GlobalStorage.RKI_DataTypeEnum.county), time: \(Date(timeIntervalSinceReferenceDate: time))")
                            #endif
                        }
                        
                    } else {
                        
                        // no, same data, so do nothing
                        #if DEBUG_PRINT_FUNCCALLS
                        print( "iCloudService.saveCoBaTData(): new data \(GlobalStorage.RKI_DataTypeEnum.county), time: \(Date(timeIntervalSinceReferenceDate: time)) already in CoBaTDataToSendSCounty[\(dayNumber)] and hash values are equal, do nothing")
                        #endif
                    }
                }
 
                // start the workflow by getting the reference data
                self.getCoBaTReferencesCounty()

                
                
            case GlobalStorage.unique.RKIDataState:
                
                // store the data for future use
                
                // check if we already have a dicinary element
                if self.CoBaTDataToSendState[dayNumber] == nil {
                    
                    // no, so just add the data to the dictonary
                    self.CoBaTDataToSendState[dayNumber] = dataQueueStruct(time: time, data: data, RKIDataType: GlobalStorage.RKI_DataTypeEnum.state)
                    
                    #if DEBUG_PRINT_FUNCCALLS
                    print( "iCloudService.saveCoBaTData(): just set CoBaTDataToSendState[\(dayNumber)] to type: \(GlobalStorage.RKI_DataTypeEnum.state)), time: \(Date(timeIntervalSinceReferenceDate: time))")
                    #endif

                } else {
                    
                    // yes, we have already data with that dayNumber, so check if this is an update, by hashValues
                    
                    let hashData = CoBaTHash(data: self.CoBaTDataToSendState[dayNumber]!.data)
                    let hashReference = CoBaTHash(data: data)
                   
                    if hashData != hashReference {
                        
                        // yes we have newer data, so check if we are early enough to replace the data
                        if self.CoBaTDataToSendState[dayNumber]!.sendStatus == .new {
                            
                            // yes, it is still new, so just replace it, as we nmight have updated values
                            self.CoBaTDataToSendState[dayNumber] = dataQueueStruct(time: time, data: data, RKIDataType: GlobalStorage.RKI_DataTypeEnum.state)
                            
                            #if DEBUG_PRINT_FUNCCALLS
                            print( "iCloudService.saveCoBaTData(): just replaced CoBaTDataToSendState[\(dayNumber)] by type: \(GlobalStorage.RKI_DataTypeEnum.state)), time: \(Date(timeIntervalSinceReferenceDate: time))")
                            #endif
                            
                        } else {
                            
                            #if DEBUG_PRINT_FUNCCALLS
                            print( "iCloudService.saveCoBaTData(): CoBaTDataToSendState[\(dayNumber)]!.sendStatus != .new, do NOT replace by type: \(GlobalStorage.RKI_DataTypeEnum.state)), time: \(Date(timeIntervalSinceReferenceDate: time))")
                            #endif
                        }
                        
                    } else {
                        
                        // no, same data, so do nothing
                        #if DEBUG_PRINT_FUNCCALLS
                        print( "iCloudService.saveCoBaTData(): new data \(GlobalStorage.RKI_DataTypeEnum.state)), time: \(Date(timeIntervalSinceReferenceDate: time)) already in dataToSendState[\(dayNumber)] and hash values are equal, do nothing")
                        #endif
                    }
                }

                // start the workflow by getting the reference data
                self.getCoBaTReferencesState()
                
            default:
                break
            }
        })
    }
    
    /**
     -----------------------------------------------------------------------------------------------
     
     Starts the Work Queue of CoBaT data. initiated when new Data arraived, but was the same as before.
     
     This can happen after a app restart or when the user initiated "refresh data" on the UI.
     
     -----------------------------------------------------------------------------------------------
     
     - Parameters:
        - kindOfArea: the area level we want to be checked
     
     - Returns:
     
     */
    public func startCoBaTWorkQueue(_ kindOfArea: Int) {
        
        // just call tghe right start point of the work queue
        switch kindOfArea {
        
        case GlobalStorage.unique.RKIDataCounty:
            
            #if DEBUG_PRINT_FUNCCALLS
            print( "iCloudService.startCoBaTWorkQueue(): just started, kindOfArea: \(kindOfArea), call getCoBaTReferencesCounty()")
            #endif
            self.getCoBaTReferencesCounty()
            
        case GlobalStorage.unique.RKIDataState:
            
            #if DEBUG_PRINT_FUNCCALLS
            print( "iCloudService.startCoBaTWorkQueue(): just started, kindOfArea: \(kindOfArea), call getCoBaTReferencesState()")
            #endif
            self.getCoBaTReferencesState()

        default:
        
            #if DEBUG_PRINT_FUNCCALLS
            print( "iCloudService.startCoBaTWorkQueue(): just started, but kindOfArea (\(kindOfArea)) is not valid, do nothing")
            #endif

        }
    }
    
    
// --------------------------------------------------------------------
// MARK: - CoBaT Work Queue
// --------------------------------------------------------------------
    /**
     -----------------------------------------------------------------------------------------------
     
     This func will read the refences and will fill the tables for further reference
     
     -----------------------------------------------------------------------------------------------
     */
    private func getCoBaTReferencesState() {
        
        GlobalStorageQueue.async(execute: {
            
            #if DEBUG_PRINT_FUNCCALLS
            print( "iCloudService.getCoBaTReferencesState(): just started")
            #endif
            
            // -------------------------------------------------------------------------------------
            // Preperation
            // -------------------------------------------------------------------------------------
            
            var newReferenceTableState: [ReferenceTableStruct] = []
            var recordCounterState: Int = 0
            
            
            // -------------------------------------------------------------------------------------
            // Build the query
            // -------------------------------------------------------------------------------------
            let queryState = CKQuery(recordType: self.RT_CoBaTStateReference,
                                     predicate: NSPredicate(value: true))
            queryState.sortDescriptors = [NSSortDescriptor(key: self.RF_DayNumber, ascending: false)]
            
            let operationState = CKQueryOperation(query: queryState)
            operationState.resultsLimit = GlobalStorage.unique.maxNumberOfDaysStored
            
            
            // -------------------------------------------------------------------------------------
            // Record Fetch Block
            // -------------------------------------------------------------------------------------
            operationState.recordFetchedBlock = {
                record in
                
                if let dateRead = record[self.RF_Date] as? String {
                    if let dayNumberRead = record[self.RF_DayNumber] as? Int {
                        if let dataHashValueRead = record[self.RF_DataHashValue] as? Int {
                            
                            // as we reach here, we got all we need
                            newReferenceTableState.append(ReferenceTableStruct(dayNumber: dayNumberRead,
                                                                               dateString: dateRead,
                                                                               dataHashValue: dataHashValueRead))
                            recordCounterState += 1
                            
                        } else {
                            
                            GlobalStorage.unique.storeLastError(
                                errorText: "iCloudService.getCoBaTReferencesState(): could not read dataHashValueRead on record from \(dateRead), ignore record, last good Record: \(recordCounterState)")
                        }
                        
                    } else {
                        
                        GlobalStorage.unique.storeLastError(
                            errorText: "iCloudService.getCoBaTReferencesState(): could not read dayNumber on record from \(dateRead), ignore record, last good Record: \(recordCounterState)")
                    }
                    
                } else {
                    
                    GlobalStorage.unique.storeLastError(
                        errorText: "iCloudService.getCoBaTReferencesState(): could not read dateString, ignore record, last good Record: \(recordCounterState)")
                }
            } // recordFetchBlock
            
            
            // -------------------------------------------------------------------------------------
            // Query Completion Block
            // -------------------------------------------------------------------------------------
            operationState.queryCompletionBlock = {
                (cursor, error) in
                
                if error == nil {
                    
                    // -----------------------------------------------------------------------------
                    //                                  Success!
                    // -----------------------------------------------------------------------------
                    #if DEBUG_PRINT_FUNCCALLS
                    print( "iCloudService.getCoBaTReferencesState(): success!, got \(recordCounterState) records, will update CoBaTReferenceTableState and call checkCoBaTStateData()")
                    #endif
                    GlobalStorageQueue.async(flags: .barrier, execute: {
                        self.CoBaTReferenceTableState = newReferenceTableState
                        self.checkCoBaTStateData()

                    })
                    
                    
                } else {
                    // -----------------------------------------------------------------------------
                    // -----------------------------------------------------------------------------
                    //                                  Error!
                    // -----------------------------------------------------------------------------
                    // -----------------------------------------------------------------------------
                    
                    // check for errors
                    if let currentError = error as? CKError {
                        
                        // call the common error routine to print out error and do the usual error handling
                        self.CommonErrorHandling( currentError, from: "iCloudService.getCoBaTReferencesState()")
                        
                        //                        // if neccessary use this
                        //                        switch currentError.code {
                        //
                        //                        default:
                        //                        break
                        //                        }
                        
                    } else {
                        
                        GlobalStorage.unique.storeLastError(
                            errorText: "iCloudService.getCoBaTReferencesState(): Error occured, but could not get the error code")
                    }
                }
            }
            
            
            // -------------------------------------------------------------------------------------
            // Start the query
            // -------------------------------------------------------------------------------------
            iCloudService.database.add(operationState)
            
        })
    }
    
    /**
     -----------------------------------------------------------------------------------------------
     
     This func will read the refences and will fill the tables for further reference
     
     -----------------------------------------------------------------------------------------------
     */
    private func getCoBaTReferencesCounty() {
        
        GlobalStorageQueue.async(execute: {
            
            #if DEBUG_PRINT_FUNCCALLS
            print( "iCloudService.getCoBaTReferencesCounty(): just started")
            #endif
            
            // -------------------------------------------------------------------------------------
            // Preperation
            // -------------------------------------------------------------------------------------
            
            var newReferenceTableCounty: [ReferenceTableStruct] = []
            var recordCounterCounty: Int = 0
            
            
            // -------------------------------------------------------------------------------------
            // Build the query
            // -------------------------------------------------------------------------------------
            let queryCounty = CKQuery(recordType: self.RT_CoBaTCountyReference,
                                     predicate: NSPredicate(value: true))
            queryCounty.sortDescriptors = [NSSortDescriptor(key: self.RF_DayNumber, ascending: false)]
            
            let operationCounty = CKQueryOperation(query: queryCounty)
            operationCounty.resultsLimit = GlobalStorage.unique.maxNumberOfDaysStored
            
            
            // -------------------------------------------------------------------------------------
            // Record Fetch Block
            // -------------------------------------------------------------------------------------
            operationCounty.recordFetchedBlock = {
                record in
                
                if let dateRead = record[self.RF_Date] as? String {
                    if let dayNumberRead = record[self.RF_DayNumber] as? Int {
                        if let dataHashValueRead = record[self.RF_DataHashValue] as? Int {
                            
                            // as we reach here, we got all we need
                            newReferenceTableCounty.append(ReferenceTableStruct(dayNumber: dayNumberRead,
                                                                               dateString: dateRead,
                                                                               dataHashValue: dataHashValueRead))
                            recordCounterCounty += 1
                            
                        } else {
                            
                            GlobalStorage.unique.storeLastError(
                                errorText: "iCloudService.getCoBaTReferencesCounty(): could not read dataHashValueRead on record from \(dateRead), ignore record, last good Record: \(recordCounterCounty)")
                        }
                        
                    } else {
                        
                        GlobalStorage.unique.storeLastError(
                            errorText: "iCloudService.getCoBaTReferencesCounty(): could not read dayNumber on record from \(dateRead), ignore record, last good Record: \(recordCounterCounty)")
                    }
                    
                } else {
                    
                    GlobalStorage.unique.storeLastError(
                        errorText: "iCloudService.getCoBaTReferencesCounty(): could not read dateString, ignore record, last good Record: \(recordCounterCounty)")
                }
            } // recordFetchBlock
            
            
            // -------------------------------------------------------------------------------------
            // Query Completion Block
            // -------------------------------------------------------------------------------------
            operationCounty.queryCompletionBlock = {
                (cursor, error) in
                
                if error == nil {
                    
                    
                    // -----------------------------------------------------------------------------
                    //                                  Success!
                    // -----------------------------------------------------------------------------
                    #if DEBUG_PRINT_FUNCCALLS
                    print( "iCloudService.getCoBaTReferencesCounty(): success!, got \(recordCounterCounty) records, will update CoBaTReferenceTableCounty and call checkCoBaTCountyData()")
                    #endif
                    GlobalStorageQueue.async(flags: .barrier, execute: {
                        self.CoBaTReferenceTableCounty = newReferenceTableCounty
                    })
                    
                    self.checkCoBaTCountyData()
 
                    
                } else {
                    // -----------------------------------------------------------------------------
                    // -----------------------------------------------------------------------------
                    //                                  Error!
                    // -----------------------------------------------------------------------------
                    // -----------------------------------------------------------------------------
                    
                    // check for errors
                    if let currentError = error as? CKError {
                        
                        // call the common error routine to print out error and do the usual error handling
                        self.CommonErrorHandling( currentError, from: "iCloudService.getCoBaTReferencesCounty()")
                        
                        //                        // if neccessary use this
                        //                        switch currentError.code {
                        //
                        //                        default:
                        //                        break
                        //                        }
                        
                    } else {
                        
                        GlobalStorage.unique.storeLastError(
                            errorText: "iCloudService.getCoBaTReferencesCounty(): Error occured, but could not get the error code")
                    }
                }
            }
            
            
            // -------------------------------------------------------------------------------------
            // Start the query
            // -------------------------------------------------------------------------------------
            iCloudService.database.add(operationCounty)
            
        })
    }

    
    /**
     -----------------------------------------------------------------------------------------------
     
     
     
     -----------------------------------------------------------------------------------------------
     
     - Parameters:
     - :
     
     - Returns:
     
     */
    private func checkCoBaTStateData() {
        
        // as we will change some data, make it a barrier call
        GlobalStorageQueue.async(flags: .barrier, execute: {
            
            // first: for all local day codes
            //    if daycode     in reference AND dayCode NOT in sendQueue AND hashes local != reference -> replace local data
            //    if daycode     in reference AND dayCode NOT in sendQueue AND hashes local == reference -> do nothing
            //    if daycode     in reference AND dayCode     in sendQueue AND hashes sendQueue != reference -> send local data
            //    if daycode     in reference AND dayCode     in sendQueue AND hashes sendQueue == reference -> remove item from sendQueue
            //    if daycode NOT in reference AND dayCode NOT in sendQueue -> send local data
            //    if daycode NOT in reference AND dayCode     in sendQueue -> do nothing

            // second:
            // for all reference daycodes
            //    if daycode not in local data -> pull data from iCloud
            
            // first, check if we have items in the local array which are not already in the sendQueue
            
            // build shortcuts
            let areaLevel = GlobalStorage.unique.RKIDataState
            let areaData = GlobalStorage.unique.RKIData[areaLevel]
            
            // walk over the dayNumbers and compare with the reference table
            for dayCodeIndex in 0 ..< GlobalStorage.unique.RKINumbersOfDays[areaLevel].count {
                
                let currentDayCode = GlobalStorage.unique.RKINumbersOfDays[areaLevel][dayCodeIndex]
                if let indexFound = self.CoBaTReferenceTableState.firstIndex(where: { $0.DayNumber == currentDayCode } ) {
                    
                    // dayNumber is already in reference table, so check if we have the same data
                    // we need the hashValue later on
                    //let data: Data
                    do {
                        
                        // try to encode the local data and the timeStamps
                        let data = try JSONEncoder().encode(areaData[dayCodeIndex])
                        
                        let hashLocal = CoBaTHash(data: data)
                        let hashReference = self.CoBaTReferenceTableState[indexFound].DataHashValue
                        
                        // check if we have that data in the send queue
                        // we always asume, tha the iCloud data is "better" than the local ones
                        // but if we have something to send from the same day, we asume, our data is the better one
                        if self.CoBaTDataToSendState[currentDayCode] == nil {
                            
                            // no nothing to send, so just check if we should overwrite our own data
                            // dayNumber is already in reference table, so check if we have the same data
                            if hashLocal != hashReference {
                                
                                // local data differ from iCloud data, replace the data by iCloud
                                // we always asume, tha the iCloud data is "better" than the local ones
                                #if DEBUG_PRINT_FUNCCALLS
                                print("iCloudService.checkCoBaTStateData(): dayNumber \(currentDayCode) already in Reference table, but hashLocal (\(hashLocal)) != hashReference (\(hashReference)), will pull data from iCloud and replace the local data")
                                #endif
                                
                                self.replaceCoBaTStateData(dayNumber: currentDayCode)
                                
                                // one step after the other, so return if we did something here
                                return
                                
                            } else {
                                
                                // we already have that data, so skip the record
                                #if DEBUG_PRINT_FUNCCALLS
                                print("iCloudService.checkCoBaTStateData(): dayNumber \(currentDayCode) already in Reference table, and hashLocal (\(hashLocal)) == hashReference (\(hashReference)), will skip item")
                                #endif
                            }
                            
                        } else {
                            
                            // we have something to send for the same day, so further checks needed
                            
                            // first: Check if the data to send still ".new"
                            if self.CoBaTDataToSendState[currentDayCode]!.sendStatus == .new {
                                
                                // shortcut for the hash value
                                let hashSendQueue = CoBaTHash(data: self.CoBaTDataToSendState[currentDayCode]!.data)
                                
                                // check data
                                if hashSendQueue != hashReference {
                                    
                                    // data in send queue differ from iCloud data, so we asume our data are better and send them to iCloud
                                    
                                    // we only can send data, if user is logged in, so check if he is
                                    if self.userIsLoggedIn == true {
                                        
                                        // yes, user is logged in and can send data to iCloud
                                        
                                        #if DEBUG_PRINT_FUNCCALLS
                                        print("iCloudService.checkCoBaTStateData(): dayNumber \(currentDayCode) already in Reference table but also in SendQueue, but hashSendQueue (\(hashSendQueue)) != hashReference (\(hashReference)), will send data to iCloud")
                                        #endif
                                        self.CoBaTDataToSendState[currentDayCode] = dataQueueStruct(
                                            time: GlobalStorage.unique.RKIDataTimeStamps[areaLevel][dayCodeIndex],
                                            data: data, RKIDataType: .state)
                                        
                                        self.CoBaTDataToSendState[currentDayCode]!.sendStatus = .markedForSend
                                        self.sendCoBaTStateToICloud(dayNumber: currentDayCode)
                                        
                                        // one step after the other, so return, if we did something here
                                        return
                                        
                                    } else {
                                        
                                        // not logged in
                                        #if DEBUG_PRINT_FUNCCALLS
                                        print("iCloudService.checkCoBaTStateData(): dayNumber \(currentDayCode) already in Reference table and also in SendQueue, but hashSendQueue (\(hashSendQueue)) != hashReference (\(hashReference)), would send data to iCloud, but user is not logged in, so skip that")
                                        #endif
                                    }
                                    
                                } else {
                                    
                                    #if DEBUG_PRINT_FUNCCALLS
                                    print("iCloudService.checkCoBaTStateData(): dayNumber \(currentDayCode) already in Reference table, and hashSendQueue (\(hashSendQueue)) == hashReference (\(hashReference)), remove sendqueue and skip that record")
                                    #endif
                                    
                                    self.CoBaTDataToSendState.removeValue(forKey: currentDayCode)
                                }
                                
                            } else {
                                
                                #if DEBUG_PRINT_FUNCCALLS
                                print("iCloudService.checkCoBaTStateData(): dayNumber \(currentDayCode) already in Reference table and also in send queue, sendStatus: \(self.CoBaTDataToSendState[currentDayCode]!.sendStatus), will skip that record")
                                #endif
                            }
                        }
                        
                    } catch let error as NSError {
                        
                        // encode did fail, log the message and return
                        GlobalStorage.unique.storeLastError(errorText: "iCloudService.checkCoBaTStateData(): Error: JSON encoder could not encode newRKIData: error: \"\(error.description)\", do nothing and skip the record")
                        
                        break
                    }
                    
                } else {
                    
                    // local data not in reference table, so send it to iCloud
                    // we only can send data, if user is logged in, so check if he is
                    if self.userIsLoggedIn == true {
                        
                        if self.CoBaTDataToSendState[currentDayCode] == nil {
                            
                            // yes, user is logged in and can send data to iCloud
                            
                            //let data: Data
                            do {
                                
                                // found .new data in send queue, but also already in reference table,check hash value
                                
                                // try to encode the county data and the timeStamps
                                let data = try JSONEncoder().encode(areaData[dayCodeIndex])
                                
                                #if DEBUG_PRINT_FUNCCALLS
                                print("iCloudService.checkCoBaTStateData(): dayNumber \(currentDayCode) is not in reference table, will call sendStateToICloud(\(currentDayCode))")
                                #endif

                                self.CoBaTDataToSendState[currentDayCode] = dataQueueStruct(
                                    time: GlobalStorage.unique.RKIDataTimeStamps[areaLevel][dayCodeIndex],
                                    data: data, RKIDataType: .state)
                                
                                self.CoBaTDataToSendState[currentDayCode]!.sendStatus = .markedForSend
                                self.sendCoBaTStateToICloud(dayNumber: currentDayCode)
                                
                                // one step after the other, so return, if we did something here
                                return
                                
                                
                            } catch let error as NSError {
                                
                                // encode did fail, log the message and return
                                GlobalStorage.unique.storeLastError(errorText: "iCloudService.checkCoBaTStateData(): Error: JSON encoder could not encode newRKIData: error: \"\(error.description)\", do nothing")
                            }
                            
                        } else {
                            
                            #if DEBUG_PRINT_FUNCCALLS
                            print("iCloudService.checkCoBaTStateData(): dayNumber \(currentDayCode) is not in reference table, but already in send queue, do nothing")
                            #endif
                        }
                        
                    } else {
                        
                        // no, user is NOT logged in so skip that
                        #if DEBUG_PRINT_FUNCCALLS
                        print("iCloudService.checkCoBaTStateData(): dayNumber \(currentDayCode) is not in reference table, but will NOT call sendStateToICloud(\(currentDayCode)), as user is not logged in")
                        #endif
                    }
                    
                } // in reference table
            } // for dayNumber
            
            // if we reach here, all local data are available in iCloud, with the right hash value
            
            // second step, check if there is data in iCloud we do not have
            
            for index in 0 ..< self.CoBaTReferenceTableState.count {
                
                let currentDayNumber = self.CoBaTReferenceTableState[index].DayNumber
                
                if GlobalStorage.unique.RKINumbersOfDays[areaLevel].contains(currentDayNumber) == false {
                    
                    // we do not have that in our local database, so get it
                    
                    #if DEBUG_PRINT_FUNCCALLS
                    print("iCloudService.checkCoBaTStateData(): dayNumber \(currentDayNumber) in Reference table but not in local data, will pull data from iCloud")
                    #endif
                    
                    self.pullCoBaTStateData(dayNumber: currentDayNumber)
                }
            }
        })
    }
    
    /**
     -----------------------------------------------------------------------------------------------
     
     
     
     -----------------------------------------------------------------------------------------------
     
     - Parameters:
     - :
     
     - Returns:
     
     */
    private func checkCoBaTCountyData() {
        
        // as we will change some data, make it a barrier call
        GlobalStorageQueue.async(flags: .barrier, execute: {
            
            // first: for all local day codes
            //    if daycode     in reference AND dayCode NOT in sendQueue AND hashes local != reference -> replace local data
            //    if daycode     in reference AND dayCode NOT in sendQueue AND hashes local == reference -> do nothing
            //    if daycode     in reference AND dayCode     in sendQueue AND hashes sendQueue != reference -> send local data
            //    if daycode     in reference AND dayCode     in sendQueue AND hashes sendQueue == reference -> remove item from sendQueue
            //    if daycode NOT in reference AND dayCode NOT in sendQueue -> send local data
            //    if daycode NOT in reference AND dayCode     in sendQueue -> do nothing

            // second:
            // for all reference daycodes
            //    if daycode not in local data -> pull data from iCloud
            
            // first, check if we have items in the local array which are not already in the sendQueue
            
            // build shortcuts
            let areaLevel = GlobalStorage.unique.RKIDataCounty
            let areaData = GlobalStorage.unique.RKIData[areaLevel]
            
            // walk over the dayNumbers and compare with the reference table
            for dayCodeIndex in 0 ..< GlobalStorage.unique.RKINumbersOfDays[areaLevel].count {
                
                let currentDayCode = GlobalStorage.unique.RKINumbersOfDays[areaLevel][dayCodeIndex]
                if let indexFound = self.CoBaTReferenceTableCounty.firstIndex(where: { $0.DayNumber == currentDayCode } ) {
                    
                    // dayNumber is already in reference table, so check if we have the same data
                    // we need the hashValue later on
                    
                    do {
                        
                        // try to encode the local data and the timeStamps
                        let data = try JSONEncoder().encode(areaData[dayCodeIndex])
                        
                        let hashLocal = CoBaTHash(data: data)
                        let hashReference = self.CoBaTReferenceTableCounty[indexFound].DataHashValue
                        
                        // check if we have that data in the send queue
                        // we always asume, tha the iCloud data is "better" than the local ones
                        // but if we have something to send from the same day, we asume, our data is the better one
                        if self.CoBaTDataToSendCounty[currentDayCode] == nil {
                            
                            // no nothing to send, so just check if we should overwrite our own data
                            // dayNumber is already in reference table, so check if we have the same data
                            if hashLocal != hashReference {
                                
                                // local data differ from iCloud data, replace the data by iCloud
                                // we always asume, tha the iCloud data is "better" than the local ones
                                #if DEBUG_PRINT_FUNCCALLS
                                print("iCloudService.checkCoBaTCountyData(): dayNumber \(currentDayCode) already in Reference table, but hashLocal (\(hashLocal)) != hashReference (\(hashReference)), will pull data from iCloud and replace the local data")
                                #endif
                                
                                self.replaceCoBaTCountyData(dayNumber: currentDayCode)
                                
                                // one step after the other, so return if we did something here
                                return
                                
                            } else {
                                
                                // we already have that data, so skip the record
                                #if DEBUG_PRINT_FUNCCALLS
                                print("iCloudService.checkCoBaTCountyData(): dayNumber \(currentDayCode) already in Reference table, and hashLocal (\(hashLocal)) == hashReference (\(hashReference)), will skip item")
                                #endif
                            }
                            
                        } else {
                            
                            // we have something to send for the same day, so further checks needed
                            
                            // first: Check if the data to send still ".new"
                            if self.CoBaTDataToSendCounty[currentDayCode]!.sendStatus == .new {
                                
                                //let data: Data
                                
                                // found .new data in send queue, but also already in reference table,check hash value
                                
                                // try to encode the county data and the timeStamps
                                // shortcut for the hash value
                                let hashSendQueue = CoBaTHash(data: self.CoBaTDataToSendCounty[currentDayCode]!.data)
                                
                                // check data
                                if hashSendQueue != hashReference {
                                    
                                    // data in send queue differ from iCloud data, so we asume our data are better and send them to iCloud
                                    
                                    // we only can send data, if user is logged in, so check if he is
                                    if self.userIsLoggedIn == true {
                                        
                                        // yes, user is logged in and can send data to iCloud
                                        
                                        #if DEBUG_PRINT_FUNCCALLS
                                        print("iCloudService.checkCoBaTCountyData(): dayNumber \(currentDayCode) already in Reference table but also in SendQueue, but hashLocal (\(hashLocal)) != hashReference (\(hashReference)), will send data to iCloud")
                                        #endif
                                        self.CoBaTDataToSendCounty[currentDayCode] = dataQueueStruct(
                                            time: GlobalStorage.unique.RKIDataTimeStamps[areaLevel][dayCodeIndex],
                                            data: data, RKIDataType: .county)
                                        
                                        self.CoBaTDataToSendCounty[currentDayCode]!.sendStatus = .markedForSend
                                        self.sendCoBaTCountyToICloud(dayNumber: currentDayCode)
                                        
                                        // one step after the other, so return, if we did something here
                                        return
                                        
                                    } else {
                                        
                                        // not logged in
                                        #if DEBUG_PRINT_FUNCCALLS
                                        print("iCloudService.checkCoBaTCountyData(): dayNumber \(currentDayCode) already in Reference table and also in SendQueue, but hashLocal (\(hashLocal)) != hashReference (\(hashReference)), would send data to iCloud, but user is not logged in, so skip that")
                                        #endif
                                    }
                                    
                                } else {
                                    
                                    #if DEBUG_PRINT_FUNCCALLS
                                    print("iCloudService.checkCoBaTCountyData(): dayNumber \(currentDayCode) already in Reference table, and hashSendQueue (\(hashSendQueue)) == hashReference (\(hashReference)), remove sendqueue and skip that record")
                                    #endif
                                    
                                    self.CoBaTDataToSendCounty.removeValue(forKey: currentDayCode)
                                }
                                
                            } else {
                                
                                #if DEBUG_PRINT_FUNCCALLS
                                print("iCloudService.checkCoBaTCountyData(): dayNumber \(currentDayCode) already in Reference table and also in send queue, sendStatus: \(self.CoBaTDataToSendCounty[currentDayCode]!.sendStatus), will skip that record")
                                #endif
                            }
                        }
                        
                    } catch let error as NSError {
                        
                        // encode did fail, log the message and return
                        GlobalStorage.unique.storeLastError(errorText: "iCloudService.checkCoBaTCountyData(): Error: JSON encoder could not encode newRKIData: error: \"\(error.description)\", do nothing and break the loop")
                        
                        break
                    }
                    
                } else {
                    
                    // local data not in reference table, so send it to iCloud
                    // we only can send data, if user is logged in, so check if he is
                    if self.userIsLoggedIn == true {
                        
                        if self.CoBaTDataToSendCounty[currentDayCode] == nil {
                            
                            // yes, user is logged in and can send data to iCloud
                            
                            //let data: Data
                            do {
                                
                                // found .new data in send queue, but also already in reference table,check hash value
                                
                                // try to encode the county data and the timeStamps
                                let data = try JSONEncoder().encode(areaData[dayCodeIndex])
                                
                                #if DEBUG_PRINT_FUNCCALLS
                                print("iCloudService.checkCoBaTCountyData(): dayNumber \(currentDayCode) is not in reference table, will call sendCountyToICloud(\(currentDayCode))")
                                #endif

                                self.CoBaTDataToSendCounty[currentDayCode] = dataQueueStruct(
                                    time: GlobalStorage.unique.RKIDataTimeStamps[areaLevel][dayCodeIndex],
                                    data: data, RKIDataType: .county)
                                
                                self.CoBaTDataToSendCounty[currentDayCode]!.sendStatus = .markedForSend
                                self.sendCoBaTCountyToICloud(dayNumber: currentDayCode)
                                
                                // one step after the other, so return, if we did something here
                                return
                                
                                
                            } catch let error as NSError {
                                
                                // encode did fail, log the message and return
                                GlobalStorage.unique.storeLastError(errorText: "iCloudService.checkCoBaTCountyData(): Error: JSON encoder could not encode newRKIData: error: \"\(error.description)\", do nothing")
                            }
                            
                        } else {
                            
                            #if DEBUG_PRINT_FUNCCALLS
                            print("iCloudService.checkCoBaTCountyData(): dayNumber \(currentDayCode) is not in reference table, but already in send queue, do nothing")
                            #endif
                        }
                        
                    } else {
                        
                        // no, user is NOT logged in so skip that
                        #if DEBUG_PRINT_FUNCCALLS
                        print("iCloudService.checkCoBaTCountyData(): dayNumber \(currentDayCode) is not in reference table, but will NOT call sendCountyToICloud(\(currentDayCode)), as user is not logged in")
                        #endif
                    }
                    
                } // in reference table
            } // for dayNumber
            
            // if we reach here, all local data are available in iCloud, with the right hash value
            
            // second step, check if there is data in iCloud we do not have
            
            for index in 0 ..< self.CoBaTReferenceTableCounty.count {
                
                let currentDayNumber = self.CoBaTReferenceTableCounty[index].DayNumber
                
                if GlobalStorage.unique.RKINumbersOfDays[areaLevel].contains(currentDayNumber) == false {
                    
                    // we do not have that in our local database, so get it
                    
                    #if DEBUG_PRINT_FUNCCALLS
                    print("iCloudService.checkCoBaTCountyData(): dayNumber \(currentDayNumber) in Reference table but not in local data, will pull data from iCloud")
                    #endif
                    
                    self.pullCoBaTCountyData(dayNumber: currentDayNumber)
                }
            }
        })
    }
    
    /**
     -----------------------------------------------------------------------------------------------
     
     
     
     -----------------------------------------------------------------------------------------------
     
     - Parameters:
     - :
     
     - Returns:
     
     */
    private func pullCoBaTStateData(dayNumber: Int) {
        
        
        GlobalStorageQueue.async(execute: {
            
            #if DEBUG_PRINT_FUNCCALLS
            print( "iCloudService.pullCoBaTStateData(\(dayNumber)): just started")
            #endif
            
            // -------------------------------------------------------------------------------------
            // Preperation
            // -------------------------------------------------------------------------------------
            
            var newCoBaTDataState: [GlobalStorage.RKIDataStruct] = []
            var recordCounterState: Int = 0
            
            
            // -------------------------------------------------------------------------------------
            // Build the query
            // -------------------------------------------------------------------------------------
            let queryPredicate = NSPredicate(format: "DayNumber = \(dayNumber)")
            
            let queryState = CKQuery(recordType: self.RT_CoBaTStateData,
                                     predicate: queryPredicate)
            //queryState.sortDescriptors = [NSSortDescriptor(key: IS_CK_modifiedAt_FieldName, ascending: false)]
            
            let operationState = CKQueryOperation(query: queryState)
            operationState.resultsLimit = 1
            
            
//            // -----------------------------------------------------------------------------
//            //                                  Prepare operation
//            // -----------------------------------------------------------------------------
//            // Initialize Query
//            let myDeviceID_Predicate = NSPredicate(format: "Locations_ZoneTimeStamp_Device_ID = \(WIS.unique.WIS_DeviceID)")
//            let query = CKQuery(recordType: WIS_RT_Locations_ZoneTimeStamp, predicate: myDeviceID_Predicate)
//
//            // We want the result sorted by modified date
//            query.sortDescriptors = [NSSortDescriptor(key: WIS_CK_modifiedAt_FieldName, ascending: true)]
            
            
            
            // -------------------------------------------------------------------------------------
            // Record Fetch Block
            // -------------------------------------------------------------------------------------
            operationState.recordFetchedBlock = {
                record in
                
                // read the data
                if let dataRead = record[self.RF_CoBaTData] as? Data {
                    if let dayNumberRead = record[self.RF_DayNumber] as? Int {
                          
                        // check if we have the right dayCode
                        if dayNumberRead == dayNumber {
                            
                            // try to decode the data
                            do {
                                
                                let RKIDataRead = try JSONDecoder().decode([GlobalStorage.RKIDataStruct].self,
                                                                           from: (dataRead))
                                
                                // as we reach here, we got all we need, so call refresh_RKIStateData
                                
                                #if DEBUG_PRINT_FUNCCALLS
                                print( "iCloudService.pullCoBaTStateData(\(dayNumber)): success!, got record \"\(record.recordID.recordName)\", will call GlobalStorage.unique.refresh_RKIStateData()")
                                #endif

                                GlobalStorage.unique.refresh_RKIStateData(newRKIStateData: RKIDataRead)
                                
                                // count the good record
                                recordCounterState += 1
                                
                            } catch let error as NSError {
                                
                                // encode did fail, log the message
                                GlobalStorage.unique.storeLastError(errorText: "iCloudService.pullCoBaTStateData(\(dayNumber)): got record \"\(record.recordID.recordName)\", Error: JSON decoder could not decode RKIData: error: \"\(error.description)\"")
                            }
                            
                        } else {
                            
                            // did not get the requested day Number
                            // encode did fail, log the message
                            GlobalStorage.unique.storeLastError(errorText: "iCloudService.pullCoBaTStateData(\(dayNumber)): got record \"\(record.recordID.recordName)\", dayNumber in record (\(dayNumberRead) != requested dayNumber (\(dayNumber)), ignore record")
                        }
                       
                    } else {
                        
                        GlobalStorage.unique.storeLastError(
                            errorText: "iCloudService.pullCoBaTStateData(\(dayNumber)): could not read dayNumber from record \(record.recordID.recordName), ignore record")
                    }
                    
                } else {
                    
                    GlobalStorage.unique.storeLastError(
                        errorText: "iCloudService.pullCoBaTStateData(\(dayNumber)): could not read data from record \(record.recordID.recordName), ignore record")
                }
            } // recordFetchBlock
            
            
            // -------------------------------------------------------------------------------------
            // Query Completion Block
            // -------------------------------------------------------------------------------------
            operationState.queryCompletionBlock = {
                (cursor, error) in
                
                if error == nil {
                    
                    // -----------------------------------------------------------------------------
                    //                                  Success!
                    // -----------------------------------------------------------------------------
                    #if DEBUG_PRINT_FUNCCALLS
                    print( "iCloudService.pullCoBaTStateData(\(dayNumber)): success!, got \(recordCounterState) good records, will call checkCoBaTStateData()")
                    #endif
                        self.checkCoBaTStateData()
                    
                    
                } else {
                    // -----------------------------------------------------------------------------
                    // -----------------------------------------------------------------------------
                    //                                  Error!
                    // -----------------------------------------------------------------------------
                    // -----------------------------------------------------------------------------
                    
                    // check for errors
                    if let currentError = error as? CKError {
                        
                        // call the common error routine to print out error and do the usual error handling
                        self.CommonErrorHandling( currentError, from: "iCloudService.pullCoBaTStateData(\(dayNumber))")
                        
                        //                        // if neccessary use this
                        //                        switch currentError.code {
                        //
                        //                        default:
                        //                        break
                        //                        }
                        
                    } else {
                        
                        GlobalStorage.unique.storeLastError(
                            errorText: "iCloudService.pullCoBaTStateData(\(dayNumber)): Error occured, but could not get the error code")
                    }
                }
            }
            
            
            // -------------------------------------------------------------------------------------
            // Start the query
            // -------------------------------------------------------------------------------------
            iCloudService.database.add(operationState)
            
        })

    }

    /**
     -----------------------------------------------------------------------------------------------
     
     
     
     -----------------------------------------------------------------------------------------------
     
     - Parameters:
     - :
     
     - Returns:
     
     */
    private func pullCoBaTCountyData(dayNumber: Int) {
        
        #if DEBUG_PRINT_FUNCCALLS
        print("iCloudService.pullCoBaTCountyData(\(dayNumber)): just started")
        #endif
    }

    /**
     -----------------------------------------------------------------------------------------------
     
     
     
     -----------------------------------------------------------------------------------------------
     
     - Parameters:
     - :
     
     - Returns:
     
     */
    private func replaceCoBaTStateData(dayNumber: Int) {
        
        #if DEBUG_PRINT_FUNCCALLS
        print("iCloudService.replaceCoBaTStateData(\(dayNumber)): just started")
        #endif

        
        
    }
    
    /**
     -----------------------------------------------------------------------------------------------
     
     
     
     -----------------------------------------------------------------------------------------------
     
     - Parameters:
     - :
     
     - Returns:
     
     */
    private func replaceCoBaTCountyData(dayNumber: Int) {
        
        #if DEBUG_PRINT_FUNCCALLS
        print("iCloudService.replaceCoBaTCountyData(\(dayNumber)): just started")
        #endif

        
        
    }
 
    
    /**
     -----------------------------------------------------------------------------------------------
     
     
     
     -----------------------------------------------------------------------------------------------
     
     - Parameters:
     - :
     
     - Returns:
     
     */
    private var sendCoBaTStateToICloudCounter: Int = 0
    private func sendCoBaTStateToICloud(dayNumber: Int) {
        
          GlobalStorageQueue.async(execute: {
            
            #if DEBUG_PRINT_FUNCCALLS
            print("iCloudService.sendCoBaTStateToICloud(\(dayNumber)): just started, counter: \(self.sendRKIStateToICloudCounter)")
            #endif
            
            // build the CoBaT record
            let newCoBaTRecordID = CKRecord.ID(recordName: "CoBaTStateData\(dayNumber)")
            let newCoBaTRecord = CKRecord(recordType: self.RT_CoBaTStateData, recordID: newCoBaTRecordID)
            
            newCoBaTRecord[self.RF_DayNumber]  = dayNumber
            newCoBaTRecord[self.RF_Time]       = self.CoBaTDataToSendState[dayNumber]!.time
            newCoBaTRecord[self.RF_CoBaTData]  = self.CoBaTDataToSendState[dayNumber]!.data
            
            
            // build the CoBaTReference Record
            let newCoBaTReferenceRecordID = CKRecord.ID(recordName: "CoBaTStateReference\(dayNumber)")
            let newCoBaTReferenceRecord = CKRecord(recordType: self.RT_CoBaTStateReference, recordID: newCoBaTReferenceRecordID)
            
            newCoBaTReferenceRecord[self.RF_DayNumber]  = dayNumber
            newCoBaTReferenceRecord[self.RF_Date]  = GlobalStorage.unique.getDateStringFromDayNumber(dayNumber: dayNumber)
            newCoBaTReferenceRecord[self.RF_DataHashValue] = CoBaTHash(data: self.CoBaTDataToSendState[dayNumber]!.data)
            
            // create and prepare the new cloudKit operation
            let modifyRecordOperation = CKModifyRecordsOperation()
            modifyRecordOperation.savePolicy = .allKeys // save all keys (replace the record completly)
            modifyRecordOperation.isAtomic = true // the records are individual, so no need for .atomic
            modifyRecordOperation.recordsToSave = [newCoBaTRecord, newCoBaTReferenceRecord]
            modifyRecordOperation.recordIDsToDelete = nil
            modifyRecordOperation.qualityOfService = .background
            
            
            // -----------------------------------------------------------------------------
            //                                  modifyRecordsCompletionBlock
            // -----------------------------------------------------------------------------
            modifyRecordOperation.modifyRecordsCompletionBlock = {
                
                (savedRecords, deletedRecordIDs, error) in
                
                if error == nil {
                    
                    // -----------------------------------------------------------------------------
                    //                                  Success!
                    // -----------------------------------------------------------------------------
                    
                    if savedRecords != nil {
                        
                        // as we have success, we wait some seconds to give iCloud time to process
                        GlobalStorageQueue.asyncAfter(deadline: .now() + .seconds(3),
                                                      flags: .barrier, execute: {
                            
                            #if DEBUG_PRINT_FUNCCALLS
                            print( "iCloudService.sendCoBaTStateToICloud(\(dayNumber)): success!, got \(savedRecords!.count) records,")
                            #endif
                            
                            // check by looping over saved records if both records are saved and set flags
                            
                            // this are the flags
                            var dataSend: Bool = false
                            var referenceSend: Bool = false
                            
                            // this is the loop
                            for item in savedRecords! {
                                
                                // if current record has same recordID, set flag to true
                                if item.recordID == newCoBaTReferenceRecordID {
                                    dataSend = true
                                    
                                } else if item.recordID == newCoBaTRecordID {
                                    referenceSend = true
                                }
                            }
                            
                            // now check if we found bpth record IDs
                            if (dataSend == true) && (referenceSend == true) {
                                
                                // yes, we found both record IDs, so remove the data from the dictonary
                                self.CoBaTDataToSendState.removeValue(forKey: dayNumber)
                                
                                // reset the counter
                                self.sendCoBaTStateToICloudCounter = 0
                                
                                GlobalStorage.unique.storeLastError(
                                    errorText: "iCloudService.sendCoBaTStateToICloud(\(dayNumber)): success!, found both records, removed data from queue, will call getCoBaTReferencesState()")
                                
                                // restart the work chain
                                self.getCoBaTReferencesState()
                                
                            } else {
                                
                                // reset the status of the data record in dictionary
                                self.RKIDataToSendState[dayNumber]?.sendStatus = .new
                                
                                // if we have less than 3 tries in a row, retry again
                                self.sendCoBaTStateToICloudCounter += 1
                                if self.sendRKIStateToICloudCounter < 3 {
                                    
                                    #if DEBUG_PRINT_FUNCCALLS
                                    print( "iCloudService.sendCoBaTStateToICloud(\(dayNumber)): success!, but dataSend == \(dataSend), referenceSend == \(referenceSend), sendRKIStateToICloudCounter (\(self.sendRKIStateToICloudCounter)) < 3, will call getCoBaTReferencesState()")
                                    #endif
                                    // restart the work chain
                                    self.getCoBaTReferencesState()
                                    
                                } else {
                                    
                                    GlobalStorage.unique.storeLastError(
                                        errorText: "iCloudService.sendCoBaTStateToICloud(\(dayNumber)): success!, but dataSend == \(dataSend), referenceSend == \(referenceSend), sendRKIStateToICloudCounter (\(self.sendRKIStateToICloudCounter)) >= 3, will NOT call getReferencesState(), reset counter")
                                    
                                    self.sendCoBaTStateToICloudCounter = 0
                                }
                            }
                        })
                        
                    } else {
                        
                        // safed records nil
                        GlobalStorage.unique.storeLastError(
                            errorText: "iCloudService.sendCoBaTStateToICloud(\(dayNumber)): success!, but savedRecords == nil, do nothing")
                        
                        
                        // reset the counter
                        self.sendCoBaTStateToICloudCounter = 0
                    }
                    
                } else {
                    // -----------------------------------------------------------------------------
                    // -----------------------------------------------------------------------------
                    //                                  Error!
                    // -----------------------------------------------------------------------------
                    // -----------------------------------------------------------------------------
                    
                    // check for errors
                    if let currentError = error as? CKError {
                        
                        // call the common error routine to print out error and do the usual error handling
                        self.CommonErrorHandling( currentError, from: "iCloudService.sendCoBaTStateToICloud(\(dayNumber))")
                        
                        //                        // if neccessary use this
                        //                        switch currentError.code {
                        //
                        //                        default:
                        //                        break
                        //                        }
                        
                    } else {
                        
                        GlobalStorage.unique.storeLastError(
                            errorText: "iCloudService.sendCoBaTStateToICloud(\(dayNumber)): Error occured, but could not get the error code")
                    }
                    
                    // reset the counter
                    self.sendRKIStateToICloudCounter = 0
                }
            }
            
            // -----------------------------------------------------------------------------
            //                                  Fire operation
            // -----------------------------------------------------------------------------
            
            iCloudService.database.add(modifyRecordOperation)
            return
        })
 
    }

        
        
    
    
    /**
     -----------------------------------------------------------------------------------------------
     
     
     
     -----------------------------------------------------------------------------------------------
     
     - Parameters:
     - :
     
     - Returns:
     
     */
    private var sendCoBaTCountyToICloudCounter: Int = 0
    private func sendCoBaTCountyToICloud(dayNumber: Int) {
        
        GlobalStorageQueue.async(execute: {
            
            #if DEBUG_PRINT_FUNCCALLS
            print("iCloudService.sendCoBaTCountyToICloud(\(dayNumber)): just started, counter: \(self.sendRKICountyToICloudCounter)")
            #endif
            
            // build the CoBaT record
            let newCoBaTRecordID = CKRecord.ID(recordName: "CoBaTCountyData\(dayNumber)")
            let newCoBaTRecord = CKRecord(recordType: self.RT_CoBaTCountyData, recordID: newCoBaTRecordID)
            
            newCoBaTRecord[self.RF_DayNumber]  = dayNumber
            newCoBaTRecord[self.RF_Time]       = self.CoBaTDataToSendCounty[dayNumber]!.time
            newCoBaTRecord[self.RF_CoBaTData]  = self.CoBaTDataToSendCounty[dayNumber]!.data
            
            
            // build the CoBaTReference Record
            let newCoBaTReferenceRecordID = CKRecord.ID(recordName: "CoBaTCountyReference\(dayNumber)")
            let newCoBaTReferenceRecord = CKRecord(recordType: self.RT_CoBaTCountyReference, recordID: newCoBaTReferenceRecordID)
            
            newCoBaTReferenceRecord[self.RF_DayNumber]  = dayNumber
            newCoBaTReferenceRecord[self.RF_Date]  = GlobalStorage.unique.getDateStringFromDayNumber(dayNumber: dayNumber)
            newCoBaTReferenceRecord[self.RF_DataHashValue] = CoBaTHash(data: self.CoBaTDataToSendCounty[dayNumber]!.data)
            
            // create and prepare the new cloudKit operation
            let modifyRecordOperation = CKModifyRecordsOperation()
            modifyRecordOperation.savePolicy = .allKeys // save all keys (replace the record completly)
            modifyRecordOperation.isAtomic = true // the records are individual, so no need for .atomic
            modifyRecordOperation.recordsToSave = [newCoBaTRecord, newCoBaTReferenceRecord]
            modifyRecordOperation.recordIDsToDelete = nil
            modifyRecordOperation.qualityOfService = .background
            
            
            // -----------------------------------------------------------------------------
            //                                  modifyRecordsCompletionBlock
            // -----------------------------------------------------------------------------
            modifyRecordOperation.modifyRecordsCompletionBlock = {
                
                (savedRecords, deletedRecordIDs, error) in
                
                if error == nil {
                    
                    // -----------------------------------------------------------------------------
                    //                                  Success!
                    // -----------------------------------------------------------------------------
                    
                    if savedRecords != nil {
                        
                        // as we have success, we wait some seconds to give iCloud time to process
                        GlobalStorageQueue.asyncAfter(deadline: .now() + .seconds(3),
                                                      flags: .barrier, execute: {
                                                        
                                                        #if DEBUG_PRINT_FUNCCALLS
                                                        print( "iCloudService.sendCoBaTCountyToICloud(\(dayNumber)): success!, got \(savedRecords!.count) records,")
                                                        #endif
                                                        
                                                        // check by looping over saved records if both records are saved and set flags
                                                        
                                                        // this are the flags
                                                        var dataSend: Bool = false
                                                        var referenceSend: Bool = false
                                                        
                                                        // this is the loop
                                                        for item in savedRecords! {
                                                            
                                                            // if current record has same recordID, set flag to true
                                                            if item.recordID == newCoBaTReferenceRecordID {
                                                                dataSend = true
                                                                
                                                            } else if item.recordID == newCoBaTRecordID {
                                                                referenceSend = true
                                                            }
                                                        }
                                                        
                                                        // now check if we found bpth record IDs
                                                        if (dataSend == true) && (referenceSend == true) {
                                                            
                                                            // yes, we found both record IDs, so remove the data from the dictonary
                                                            self.CoBaTDataToSendCounty.removeValue(forKey: dayNumber)
                                                            
                                                            // reset the counter
                                                            self.sendCoBaTCountyToICloudCounter = 0
                                                            
                                                            GlobalStorage.unique.storeLastError(
                                                                errorText: "iCloudService.sendCoBaTCountyToICloud(\(dayNumber)): success!, found both records, removed data from queue, will call getCoBaTReferencesCounty()")
                                                            
                                                            // restart the work chain
                                                            self.getCoBaTReferencesCounty()
                                                            
                                                        } else {
                                                            
                                                            // reset the status of the data record in dictionary
                                                            self.RKIDataToSendCounty[dayNumber]?.sendStatus = .new
                                                            
                                                            // if we have less than 3 tries in a row, retry again
                                                            self.sendCoBaTCountyToICloudCounter += 1
                                                            if self.sendRKICountyToICloudCounter < 3 {
                                                                
                                                                #if DEBUG_PRINT_FUNCCALLS
                                                                print( "iCloudService.sendCoBaTCountyToICloud(\(dayNumber)): success!, but dataSend == \(dataSend), referenceSend == \(referenceSend), sendCoBaTCountyToICloudCounter (\(self.sendCoBaTCountyToICloudCounter)) < 3, will call getCoBaTReferencesCounty()")
                                                                #endif
                                                                // restart the work chain
                                                                self.getCoBaTReferencesCounty()
                                                                
                                                            } else {
                                                                
                                                                GlobalStorage.unique.storeLastError(
                                                                    errorText: "iCloudService.sendCoBaTCountyToICloud(\(dayNumber)): success!, but dataSend == \(dataSend), referenceSend == \(referenceSend), sendCoBaTCountyToICloudCounter (\(self.sendCoBaTCountyToICloudCounter)) >= 3, will NOT call getReferencesState(), reset counter")
                                                                
                                                                self.sendCoBaTCountyToICloudCounter = 0
                                                            }
                                                        }
                                                      })
                        
                    } else {
                        
                        // safed records nil
                        GlobalStorage.unique.storeLastError(
                            errorText: "iCloudService.sendCoBaTCountyToICloud(\(dayNumber)): success!, but savedRecords == nil, do nothing")
                        
                        
                        // reset the counter
                        self.sendCoBaTCountyToICloudCounter = 0
                    }
                    
                } else {
                    // -----------------------------------------------------------------------------
                    // -----------------------------------------------------------------------------
                    //                                  Error!
                    // -----------------------------------------------------------------------------
                    // -----------------------------------------------------------------------------
                    
                    // check for errors
                    if let currentError = error as? CKError {
                        
                        // call the common error routine to print out error and do the usual error handling
                        self.CommonErrorHandling( currentError, from: "iCloudService.sendCoBaTCountyToICloud(\(dayNumber))")
                        
                        //                        // if neccessary use this
                        //                        switch currentError.code {
                        //
                        //                        default:
                        //                        break
                        //                        }
                        
                    } else {
                        
                        GlobalStorage.unique.storeLastError(
                            errorText: "iCloudService.sendCoBaTCountyToICloud(\(dayNumber)): Error occured, but could not get the error code")
                    }
                    
                    // reset the counter
                    self.sendRKICountyToICloudCounter = 0
                }
            }
            
            // -----------------------------------------------------------------------------
            //                                  Fire operation
            // -----------------------------------------------------------------------------
            
            iCloudService.database.add(modifyRecordOperation)
            return
        })
        
    }
    
    
    
    // --------------------------------------------------------------------
    // MARK: - RKI Work Queue
    // --------------------------------------------------------------------
    /**
     -----------------------------------------------------------------------------------------------
     
     This func will read the refences and will fill the tables for further reference
     
     -----------------------------------------------------------------------------------------------
     */
    private func getRKIReferencesState() {
        
        GlobalStorageQueue.async(execute: {
            
            #if DEBUG_PRINT_FUNCCALLS
            print( "iCloudService.getRKIReferencesState(): just started")
            #endif
            
            // -------------------------------------------------------------------------------------
            // Preperation
            // -------------------------------------------------------------------------------------
            
            var newReferenceTableState: [ReferenceTableStruct] = []
            var recordCounterState: Int = 0
            
            
            // -------------------------------------------------------------------------------------
            // Build the query
            // -------------------------------------------------------------------------------------
            let queryState = CKQuery(recordType: self.RT_RKIStateReference,
                                     predicate: NSPredicate(value: true))
            queryState.sortDescriptors = [NSSortDescriptor(key: self.RF_DayNumber, ascending: false)]
            
            let operationState = CKQueryOperation(query: queryState)
            operationState.resultsLimit = GlobalStorage.unique.maxNumberOfDaysStored
            
            
            // -------------------------------------------------------------------------------------
            // Record Fetch Block
            // -------------------------------------------------------------------------------------
            operationState.recordFetchedBlock = {
                record in
                
                if let dateRead = record[self.RF_Date] as? String {
                    if let dayNumberRead = record[self.RF_DayNumber] as? Int {
                        if let dataHashValueRead = record[self.RF_DataHashValue] as? Int {
                            
                            // as we reach here, we got all we need
                            newReferenceTableState.append(ReferenceTableStruct(dayNumber: dayNumberRead,
                                                                               dateString: dateRead,
                                                                               dataHashValue: dataHashValueRead))
                            recordCounterState += 1
                            
                        } else {
                            
                            GlobalStorage.unique.storeLastError(
                                errorText: "iCloudService.getRKIReferencesState(): could not read dataHashValueRead on record from \(dateRead), ignore record, last good Record: \(recordCounterState)")
                        }
                        
                    } else {
                        
                        GlobalStorage.unique.storeLastError(
                            errorText: "iCloudService.getRKIReferencesState(): could not read dayNumber on record from \(dateRead), ignore record, last good Record: \(recordCounterState)")
                    }
                    
                } else {
                    
                    GlobalStorage.unique.storeLastError(
                        errorText: "iCloudService.getRKIReferencesState(): could not read dateString, ignore record, last good Record: \(recordCounterState)")
                }
            } // recordFetchBlock
            
            
            // -------------------------------------------------------------------------------------
            // Query Completion Block
            // -------------------------------------------------------------------------------------
            operationState.queryCompletionBlock = {
                (cursor, error) in
                
                if error == nil {
                    
                    
                    // -----------------------------------------------------------------------------
                    //                                  Success!
                    // -----------------------------------------------------------------------------
                    #if DEBUG_PRINT_FUNCCALLS
                    print( "iCloudService.getRKIReferencesState(): success!, got \(recordCounterState) records, will update ReferenceTableState and call pushRKIDataState()")
                    #endif
                    GlobalStorageQueue.async(flags: .barrier, execute: {
                        self.RKIReferenceTableState = newReferenceTableState
                    })
                    
                    self.pushRKIDataState()
                    
                    
                } else {
                    // -----------------------------------------------------------------------------
                    // -----------------------------------------------------------------------------
                    //                                  Error!
                    // -----------------------------------------------------------------------------
                    // -----------------------------------------------------------------------------
                    
                    // check for errors
                    if let currentError = error as? CKError {
                        
                        // call the common error routine to print out error and do the usual error handling
                        self.CommonErrorHandling( currentError, from: "iCloudService.getRKIReferencesState()")
                        
                        //                        // if neccessary use this
                        //                        switch currentError.code {
                        //
                        //                        default:
                        //                        break
                        //                        }
                        
                    } else {
                        
                        GlobalStorage.unique.storeLastError(
                            errorText: "iCloudService.getRKIReferencesState(): Error occured, but could not get the error code")
                    }
                }
            }
            
            
            // -------------------------------------------------------------------------------------
            // Start the query
            // -------------------------------------------------------------------------------------
            iCloudService.database.add(operationState)
            
        })
    }
    
    /**
     -----------------------------------------------------------------------------------------------
     
     This func will read the refences and will fill the tables for further reference
     
     -----------------------------------------------------------------------------------------------
     */
    
    private func getRKIReferencesCounty() {
        
        GlobalStorageQueue.async(execute: {
            
            #if DEBUG_PRINT_FUNCCALLS
            print( "iCloudService.getRKIReferencesCounty(): just started")
            #endif
            
            // -------------------------------------------------------------------------------------
            // Preperation
            // -------------------------------------------------------------------------------------
            
            var newReferenceTableCounty: [ReferenceTableStruct] = []
            var recordCounterCounty: Int = 0
            
            
            // -------------------------------------------------------------------------------------
            // Build the query
            // -------------------------------------------------------------------------------------
            let queryCounty = CKQuery(recordType: self.RT_RKICountyReference,
                                     predicate: NSPredicate(value: true))
            queryCounty.sortDescriptors = [NSSortDescriptor(key: self.RF_DayNumber, ascending: false)]
            
            let operationCounty = CKQueryOperation(query: queryCounty)
            operationCounty.resultsLimit = GlobalStorage.unique.maxNumberOfDaysStored
            
            
            // -------------------------------------------------------------------------------------
            // Record Fetch Block
            // -------------------------------------------------------------------------------------
            operationCounty.recordFetchedBlock = {
                record in
                
                if let dateRead = record[self.RF_Date] as? String {
                    if let dayNumberRead = record[self.RF_DayNumber] as? Int {
                        if let dataHashValueRead = record[self.RF_DataHashValue] as? Int {
                            
                            // as we reach here, we got all we need
                            newReferenceTableCounty.append(ReferenceTableStruct(dayNumber: dayNumberRead,
                                                                               dateString: dateRead,
                                                                               dataHashValue: dataHashValueRead))
                            recordCounterCounty += 1
                            
                        } else {
                            
                            GlobalStorage.unique.storeLastError(
                                errorText: "iCloudService.getRKIReferencesCounty(): could not read dataHashValueRead on record from \(dateRead), ignore record, last good Record: \(recordCounterCounty)")
                        }
                        
                    } else {
                        
                        GlobalStorage.unique.storeLastError(
                            errorText: "iCloudService.getRKIReferencesCounty(): could not read dayNumber on record from \(dateRead), ignore record, last good Record: \(recordCounterCounty)")
                    }
                    
                } else {
                    
                    GlobalStorage.unique.storeLastError(
                        errorText: "iCloudService.getRKIReferencesCounty(): could not read dateString, ignore record, last good Record: \(recordCounterCounty)")
                }
            } // recordFetchBlock
            
            
            // -------------------------------------------------------------------------------------
            // Query Completion Block
            // -------------------------------------------------------------------------------------
            operationCounty.queryCompletionBlock = {
                (cursor, error) in
                
                if error == nil {
                    
                    
                    // -----------------------------------------------------------------------------
                    //                                  Success!
                    // -----------------------------------------------------------------------------
                    #if DEBUG_PRINT_FUNCCALLS
                    print( "iCloudService.getRKIReferencesCounty(): success!, got \(recordCounterCounty) records, will update ReferenceTableState and call pushRKIDataCounty()")
                    #endif
                    GlobalStorageQueue.async(flags: .barrier, execute: {
                        self.RKIReferenceTableCounty = newReferenceTableCounty
                    })
                    
                    self.pushRKIDataCounty()
                    
                } else {
                    // -----------------------------------------------------------------------------
                    // -----------------------------------------------------------------------------
                    //                                  Error!
                    // -----------------------------------------------------------------------------
                    // -----------------------------------------------------------------------------
                    
                    // check for errors
                    if let currentError = error as? CKError {
                        
                        // call the common error routine to print out error and do the usual error handling
                        self.CommonErrorHandling( currentError, from: "iCloudService.getRKIReferencesCounty()")
                        
                        //                        // if neccessary use this
                        //                        switch currentError.code {
                        //
                        //                        default:
                        //                        break
                        //                        }
                        
                    } else {
                        
                        GlobalStorage.unique.storeLastError(
                            errorText: "iCloudService.getRKIReferencesCounty(): Error occured, but could not get the error code")
                    }
                }
            }
            
            // -------------------------------------------------------------------------------------
            // Start the query
            // -------------------------------------------------------------------------------------
            iCloudService.database.add(operationCounty)
            
        })
    }
    
    
    
    /**
     -----------------------------------------------------------------------------------------------
     
     checks if there is data local is not yet available on iCloud and if so, push that data to icloud.
     
     -----------------------------------------------------------------------------------------------
     */
    private func pushRKIDataState() {
        
        GlobalStorageQueue.async(flags: .barrier, execute: {
            
            if self.userIsLoggedIn == true {
                
                #if DEBUG_PRINT_FUNCCALLS
                print("iCloudService.pushRKIDataState(): User is logged in, go ahead")
                #endif
                
                for item in self.RKIDataToSendState {
                    
                    if item.value.sendStatus == .new {
                        
                        //if let _ = self.RKIReferenceTableState.firstIndex(where: { $0.DayNumber == item.key } ) {
                        
                        if let indexFound = self.RKIReferenceTableState.firstIndex(where: { $0.DayNumber == item.key } ) {
                            
                            // dayNumber is already in reference table, so check if we have the same data
                            let hashData =  CoBaTHash(data: item.value.data)
                            let hashReference = self.RKIReferenceTableState[indexFound].DataHashValue
                            
                            if hashData != hashReference {
                                
                                // local data differ from iCloud data, replace the data in iCloud
                                
                                #if DEBUG_PRINT_FUNCCALLS
                                print("iCloudService.pushRKIDataState(): dayNumber \(item.key) already in Reference table, but hashData (\(hashData)) != hashReference (\(hashReference)), will call sendRKIStateToICloud(\(item.key))")
                                #endif
                                
                                self.RKIDataToSendState[item.key]!.sendStatus = .markedForSend
                                self.sendRKIStateToICloud(dayNumber: item.key)
                                
                            } else {
                                
                                #if DEBUG_PRINT_FUNCCALLS
                                print("iCloudService.pushRKIDataState(): dayNumber \(item.key) already in Reference table, and hashData (\(hashData)) == hashReference (\(hashReference)), will NOT call sendRKIStateToICloud()")
                                #endif
                            }
                            
                            #if DEBUG_PRINT_FUNCCALLS
                            print("iCloudService.pushRKIDataState(): dayNumber \(item.key) already in Reference table, will NOT call sendStateToICloud()")
                            #endif
                            
                        } else {
                            
                            // local data not in reference table, so send it to iCloud
                            #if DEBUG_PRINT_FUNCCALLS
                            print("iCloudService.pushRKIDataState(): dayNumber \(item.key) is not in reference table, will call sendStateToICloud(\(item.key))")
                            #endif
                            self.RKIDataToSendState[item.key]!.sendStatus = .markedForSend
                            self.sendRKIStateToICloud(dayNumber: item.key)
                            
                            
                            // one step after the other, so return if we did something here
                            return
                        }
                        //}
                    } // if .new
                } // for item
            } else {
                
                #if DEBUG_PRINT_FUNCCALLS
                print("iCloudService.pushRKIDataState(): User is NOT logged in, do nothing")
                #endif
            }
        })
    }
    
    
    /**
     -----------------------------------------------------------------------------------------------
     
     checks if there is data local is not yet available on iCloud and if so, push that data to icloud.
     
     -----------------------------------------------------------------------------------------------
     */
    private func pushRKIDataCounty() {
        
        GlobalStorageQueue.async(flags: .barrier, execute: {
            
            if self.userIsLoggedIn == true {
                
                #if DEBUG_PRINT_FUNCCALLS
                print("iCloudService.pushRKIDataCounty(): User is logged in, go ahead")
                #endif
                
                for item in self.RKIDataToSendCounty {
                    
                    if item.value.sendStatus == .new {
                        
                        //if let _ = self.RKIReferenceTableCounty.firstIndex(where: { $0.DayNumber == item.key } ) {
                        if let indexFound = self.RKIReferenceTableCounty.firstIndex(where: { $0.DayNumber == item.key } ) {
                            
                            // dayNumber is already in reference table, so check if we have the same data
                            let hashData = CoBaTHash(data: item.value.data)
                            let hashReference = self.RKIReferenceTableCounty[indexFound].DataHashValue
                            
                            if hashData != hashReference {
                                
                                // local data differ from iCloud data, replace the data in iCloud
                                
                                #if DEBUG_PRINT_FUNCCALLS
                                print("iCloudService.pushRKIDataCounty(): dayNumber \(item.key) already in Reference table, but hashData (\(hashData)) != hashReference (\(hashReference)), will call sendRKICountyToICloud(\(item.key))")
                                #endif
                                
                                self.RKIDataToSendCounty[item.key]!.sendStatus = .markedForSend
                                self.sendRKICountyToICloud(dayNumber: item.key)
                                
                            } else {
                                
                                #if DEBUG_PRINT_FUNCCALLS
                                print("iCloudService.pushRKIDataCounty(): dayNumber \(item.key) already in Reference table, and hashData (\(hashData)) == hashReference (\(hashReference)), will NOT call sendRKICountyToICloud()")
                                #endif
                            }
                            
                            #if DEBUG_PRINT_FUNCCALLS
                            print("iCloudService.pushRKIDataCounty(): dayNumber \(item.key) already in Reference table, will NOT call sendCountyToICloud()")
                            #endif
                            
                        } else {
                            
                            // local data not in reference table, so send it to iCloud
                            #if DEBUG_PRINT_FUNCCALLS
                            print("iCloudService.pushRKIDataCounty(): dayNumber \(item.key) is not in reference table, will call sendCountyToICloud(\(item.key))")
                            #endif
                            
                            self.RKIDataToSendCounty[item.key]!.sendStatus = .markedForSend
                            self.sendRKICountyToICloud(dayNumber: item.key)
                        }
                    }
                }
                
            } else {
                
                #if DEBUG_PRINT_FUNCCALLS
                print("iCloudService.pushRKIDataCounty(): User is NOT logged in, do nothing")
                #endif
            }
        })
    }
    
    /**
     -----------------------------------------------------------------------------------------------
     
     
     
     -----------------------------------------------------------------------------------------------
     
     - Parameters:
     - :
     
     - Returns:
     
     */
    
    
    private var sendRKIStateToICloudCounter: Int = 0
    private func sendRKIStateToICloud(dayNumber: Int) {
        
        GlobalStorageQueue.async(execute: {
            
            #if DEBUG_PRINT_FUNCCALLS
            print("iCloudService.sendRKIStateToICloud(\(dayNumber)): just started, counter: \(self.sendRKIStateToICloudCounter)")
            #endif
            
            // build the RKI record
            let newRKIRecordID = CKRecord.ID(recordName: "RKIStateData\(dayNumber)")
            let newRKIRecord = CKRecord(recordType: self.RT_RKIStateData, recordID: newRKIRecordID)
            
            newRKIRecord[self.RF_DayNumber]  = dayNumber
            newRKIRecord[self.RF_RKIData]    = self.RKIDataToSendState[dayNumber]!.data
            
            
            // build the RKIReference Record
            let newRKIReferenceRecordID = CKRecord.ID(recordName: "RKIStateReference\(dayNumber)")
            let newRKIReferenceRecord = CKRecord(recordType: self.RT_RKIStateReference, recordID: newRKIReferenceRecordID)
            
            newRKIReferenceRecord[self.RF_DayNumber]  = dayNumber
            newRKIReferenceRecord[self.RF_Date]  = GlobalStorage.unique.getDateStringFromDayNumber(dayNumber: dayNumber)
            newRKIReferenceRecord[self.RF_DataHashValue] = CoBaTHash(data: self.RKIDataToSendState[dayNumber]!.data)
                        
            // create and prepare the new cloudKit operation
            let modifyRecordOperation = CKModifyRecordsOperation()
            modifyRecordOperation.savePolicy = .allKeys // save all keys (replace the record completly)
            modifyRecordOperation.isAtomic = true // the records are individual, so no need for .atomic
            modifyRecordOperation.recordsToSave = [newRKIRecord, newRKIReferenceRecord]
            modifyRecordOperation.recordIDsToDelete = nil
            modifyRecordOperation.qualityOfService = .background
            
            
            // -----------------------------------------------------------------------------
            //                                  modifyRecordsCompletionBlock
            // -----------------------------------------------------------------------------
            modifyRecordOperation.modifyRecordsCompletionBlock = {
                
                (savedRecords, deletedRecordIDs, error) in
                
                if error == nil {
                    
                    // -----------------------------------------------------------------------------
                    //                                  Success!
                    // -----------------------------------------------------------------------------
                    
                    if savedRecords != nil {
                        GlobalStorageQueue.asyncAfter(deadline: .now() + .seconds(3),
                                                      flags: .barrier, execute: {
                                                        
                            #if DEBUG_PRINT_FUNCCALLS
                            print( "iCloudService.sendRKIStateToICloud(\(dayNumber)): success!, got \(savedRecords!.count) records,")
                            #endif
                            
                            // check if both records are saved by loop over saved records and set flags
                            
                            // this are the flags
                            var dataSend: Bool = false
                            var referenceSend: Bool = false
                            
                            // this is the loop
                            for item in savedRecords! {
                                
                                // if current record has same recordID, set flag to true
                                if item.recordID == newRKIReferenceRecordID {
                                    dataSend = true
                                    
                                } else if item.recordID == newRKIRecordID {
                                    referenceSend = true
                                }
                            }
                            
                            // now check if we found bpth record IDs
                            if (dataSend == true) && (referenceSend == true) {
                                
                                // yes, we found both record IDs, so remove the data from the dictonary
                                self.RKIDataToSendState.removeValue(forKey: dayNumber)
                                
                                // reset the counter
                                self.sendRKIStateToICloudCounter = 0
                                
                                GlobalStorage.unique.storeLastError(
                                    errorText: "iCloudService.sendRKIStateToICloud(\(dayNumber)): success!, found both records, removed data from queue, will call getReferencesState()")

                                // restart the work chain
                                self.getRKIReferencesState()
     
                            } else {
                                
                                // reset the status of the data record in dictionary
                                self.RKIDataToSendState[dayNumber]?.sendStatus = .new
                                
                                
                                // if we have less than 3 tries in a row, rgry again
                                self.sendRKIStateToICloudCounter += 1
                                if self.sendRKIStateToICloudCounter < 3 {
                                    
                                    #if DEBUG_PRINT_FUNCCALLS
                                    print( "iCloudService.sendRKIStateToICloud(\(dayNumber)): success!, but dataSend == \(dataSend), referenceSend == \(referenceSend), sendRKIStateToICloudCounter (\(self.sendRKIStateToICloudCounter)) < 3, will call getReferencesState()")
                                    #endif
                                    // restart the work chain
                                    self.getRKIReferencesState()
                                    
                                } else {
                                  
                                    GlobalStorage.unique.storeLastError(
                                        errorText: "iCloudService.sendRKIStateToICloud(\(dayNumber)): success!, but dataSend == \(dataSend), referenceSend == \(referenceSend), sendRKIStateToICloudCounter (\(self.sendRKIStateToICloudCounter)) >= 3, will NOT call getReferencesState(), reset counter")
                                    
                                    
                                    self.sendRKIStateToICloudCounter = 0
                                }
                            }
                         })
                        
                    } else {
                        
                        // safed records nil
                        GlobalStorage.unique.storeLastError(
                            errorText: "iCloudService.sendRKIStateToICloud(\(dayNumber)): success!, but savedRecords == nil, do nothing")
                     
                        
                        // reset the counter
                        self.sendRKIStateToICloudCounter = 0
                    }
                    
                } else {
                    // -----------------------------------------------------------------------------
                    // -----------------------------------------------------------------------------
                    //                                  Error!
                    // -----------------------------------------------------------------------------
                    // -----------------------------------------------------------------------------
                    
                    // check for errors
                    if let currentError = error as? CKError {
                        
                        // call the common error routine to print out error and do the usual error handling
                        self.CommonErrorHandling( currentError, from: "iCloudService.sendRKIStateToICloud(\(dayNumber))")
                        
                        //                        // if neccessary use this
                        //                        switch currentError.code {
                        //
                        //                        default:
                        //                        break
                        //                        }
                        
                    } else {
                        
                        GlobalStorage.unique.storeLastError(
                            errorText: "iCloudService.sendRKIStateToICloud(\(dayNumber)): Error occured, but could not get the error code")
                    }
                    
                    // reset the counter
                    self.sendRKIStateToICloudCounter = 0
                }
            }
            
            // -----------------------------------------------------------------------------
            //                                  Fire operation
            // -----------------------------------------------------------------------------
                        
            iCloudService.database.add(modifyRecordOperation)
            return
        })
    }
    
    
    /**
     -----------------------------------------------------------------------------------------------
     
     
     
     -----------------------------------------------------------------------------------------------
     
     - Parameters:
     - :
     
     - Returns:
     
     */
    private var sendRKICountyToICloudCounter: Int = 0
    private func sendRKICountyToICloud(dayNumber: Int) {
        
        GlobalStorageQueue.async(execute: {
            
            #if DEBUG_PRINT_FUNCCALLS
            print("iCloudService.sendRKICountyToICloud(\(dayNumber)): just started, counter: \(self.sendRKICountyToICloudCounter)")
            #endif
            
            // build the RKI record
            let newRKIRecordID = CKRecord.ID(recordName: "RKICountyData\(dayNumber)")
            let newRKIRecord = CKRecord(recordType: self.RT_RKICountyData, recordID: newRKIRecordID)
            
            newRKIRecord[self.RF_DayNumber]  = dayNumber
            newRKIRecord[self.RF_RKIData]    = self.RKIDataToSendCounty[dayNumber]!.data
            
            
            // build the RKIReference Record
            let newRKIReferenceRecordID = CKRecord.ID(recordName: "RKICountyReference\(dayNumber)")
            let newRKIReferenceRecord = CKRecord(recordType: self.RT_RKICountyReference, recordID: newRKIReferenceRecordID)
            
            newRKIReferenceRecord[self.RF_DayNumber]  = dayNumber
            newRKIReferenceRecord[self.RF_Date]  = GlobalStorage.unique.getDateStringFromDayNumber(dayNumber: dayNumber)
            newRKIReferenceRecord[self.RF_DataHashValue] = CoBaTHash(data: self.RKIDataToSendCounty[dayNumber]!.data)
                        
            // create and prepare the new cloudKit operation
            let modifyRecordOperation = CKModifyRecordsOperation()
            modifyRecordOperation.savePolicy = .allKeys // save all keys (replace the record completly)
            modifyRecordOperation.isAtomic = true // the records are individual, so no need for .atomic
            modifyRecordOperation.recordsToSave = [newRKIRecord, newRKIReferenceRecord]
            modifyRecordOperation.recordIDsToDelete = nil
            modifyRecordOperation.qualityOfService = .background
            
            
            // -----------------------------------------------------------------------------
            //                                  modifyRecordsCompletionBlock
            // -----------------------------------------------------------------------------
            modifyRecordOperation.modifyRecordsCompletionBlock = {
                
                (savedRecords, deletedRecordIDs, error) in
                
                if error == nil {
                    
                    // -----------------------------------------------------------------------------
                    //                                  Success!
                    // -----------------------------------------------------------------------------
                    
                    if savedRecords != nil {
                        GlobalStorageQueue.asyncAfter(deadline: .now() + .seconds(3),
                                                      flags: .barrier, execute: {
                            
                            #if DEBUG_PRINT_FUNCCALLS
                            print( "iCloudService.sendRKICountyToICloud(\(dayNumber)): success!, got \(savedRecords!.count) records,")
                            #endif
                            
                            // check if both records are saved by loop over saved records and set flags
                            
                            // this are the flags
                            var dataSend: Bool = false
                            var referenceSend: Bool = false
                            
                            // this is the loop
                            for item in savedRecords! {
                                
                                // if current record has same recordID, set flag to true
                                if item.recordID == newRKIReferenceRecordID {
                                    dataSend = true
                                    
                                } else if item.recordID == newRKIRecordID {
                                    referenceSend = true
                                }
                            }
                            
                            // now check if we found bpth record IDs
                            if (dataSend == true) && (referenceSend == true) {
                                
                                // yes, we found both record IDs, so remove the data from the dictonary
                                self.RKIDataToSendCounty.removeValue(forKey: dayNumber)
                                
                                // reset the counter
                                self.sendRKICountyToICloudCounter = 0
                                
                                GlobalStorage.unique.storeLastError(
                                    errorText: "iCloudService.sendRKICountyToICloud(\(dayNumber)): success!, found both records, removed data from queue, will call getReferencesState()")

                                // restart the work chain
                                self.getRKIReferencesCounty()
     
                            } else {
                                
                                // reset the status of the data record in dictionary
                                self.RKIDataToSendCounty[dayNumber]?.sendStatus = .new
                                
                                
                                // if we have less than 3 tries in a row, rgry again
                                self.sendRKICountyToICloudCounter += 1
                                if self.sendRKICountyToICloudCounter < 3 {
                                    
                                    #if DEBUG_PRINT_FUNCCALLS
                                    print( "iCloudService.sendRKICountyToICloud(\(dayNumber)): success!, but dataSend == \(dataSend), referenceSend == \(referenceSend), sendRKICountyToICloudCounter (\(self.sendRKICountyToICloudCounter)) < 3, will call getReferencesState()")
                                    #endif
                                    // restart the work chain
                                    self.getRKIReferencesCounty()
                                    
                                } else {
                                  
                                    GlobalStorage.unique.storeLastError(
                                        errorText: "iCloudService.sendRKICountyToICloud(\(dayNumber)): success!, but dataSend == \(dataSend), referenceSend == \(referenceSend), sendRKICountyToICloudCounter (\(self.sendRKICountyToICloudCounter)) >= 3, will NOT call getReferencesState(), reset counter")
                                    
                                    
                                    self.sendRKICountyToICloudCounter = 0
                                }
                            }
                         })
                        
                    } else {
                        
                        // safed records nil
                        GlobalStorage.unique.storeLastError(
                            errorText: "iCloudService.sendRKICountyToICloud(\(dayNumber)): success!, but savedRecords == nil, do nothing")
                     
                        
                        // reset the counter
                        self.sendRKICountyToICloudCounter = 0
                    }
                    
                } else {
                    // -----------------------------------------------------------------------------
                    // -----------------------------------------------------------------------------
                    //                                  Error!
                    // -----------------------------------------------------------------------------
                    // -----------------------------------------------------------------------------
                    
                    // check for errors
                    if let currentError = error as? CKError {
                        
                        // call the common error routine to print out error and do the usual error handling
                        self.CommonErrorHandling( currentError, from: "iCloudService.sendRKICountyToICloud(\(dayNumber))")
                        
                        //                        // if neccessary use this
                        //                        switch currentError.code {
                        //
                        //                        default:
                        //                        break
                        //                        }
                        
                    } else {
                        
                        GlobalStorage.unique.storeLastError(
                            errorText: "iCloudService.sendRKICountyToICloud(\(dayNumber)): Error occured, but could not get the error code")
                    }
                    
                    // reset the counter
                    self.sendRKICountyToICloudCounter = 0
                }
            }
            
            // -----------------------------------------------------------------------------
            //                                  Fire operation
            // -----------------------------------------------------------------------------
                        
            iCloudService.database.add(modifyRecordOperation)
            return
            
        })
        
    }
    

    /**
     -----------------------------------------------------------------------------------------------
     
     Set the flag userIsLoggedIn according to the accountStatus of the default database.
     
     This flag is used to determin if this device is able to push data to the iCloud. If it is se to false, the two methodes pushRKIDataState() and pushRKIDataCounty() will do nothing.
     
     -----------------------------------------------------------------------------------------------
     */
    private func checkUserAccount() {
        
        CKContainer.default().accountStatus {
            (accountStatus, error) in
            
            switch accountStatus {
            
            case .available:
                GlobalStorageQueue.async(flags: .barrier, execute: {
                    print("iCloudService.checkUserAccount(): iCloud Available, set userIsLoggedIn = true")
                    self.userIsLoggedIn = true
                })
                
            case .noAccount:
                GlobalStorageQueue.async(flags: .barrier, execute: {
                    print("iCloudService.checkUserAccount(): No iCloud account, set userIsLoggedIn = false")
                    self.userIsLoggedIn = false
                })
                
            case .restricted:
                GlobalStorageQueue.async(flags: .barrier, execute: {
                    print("iCloudService.checkUserAccount(): iCloud restricted, set userIsLoggedIn = false")
                    self.userIsLoggedIn = false
                })
                
            case .couldNotDetermine:
                GlobalStorageQueue.async(flags: .barrier, execute: {
                    print("iCloudService.checkUserAccount(): Unable to determine iCloud status, set userIsLoggedIn = false")
                    self.userIsLoggedIn = false
                })
                
            @unknown default:
                GlobalStorageQueue.async(flags: .barrier, execute: {
                    print("iCloudService.checkUserAccount(): @unknown default, set userIsLoggedIn = false")
                    self.userIsLoggedIn = false
                })
            }
        }
    }
    
    // --------------------------------------------------------------------
    // MARK: - Error Handling
    // --------------------------------------------------------------------
    
    /**
     -----------------------------------------------------------------------------------------------
     
     WIS_CommonErrorHandling()
     
     -----------------------------------------------------------------------------------------------
     */
    // this string will be displayed at iCloudStatusViewController
    private func CommonErrorHandling(_ currentError: CKError, from: String) {
        
        
        switch currentError.code {
        
        case .alreadyShared:
            // An error that occurs when CloudKit attempts to share a record with an existing share.
            
            GlobalStorage.unique.storeLastError(
                errorText: "iCloudService.CommonErrorHandling(\(from): Error.Code = .alreadyShared, \(currentError.localizedDescription)")
            
            
        case .assetFileModified:
            // An error that occurs when the system modifies an asset while saving it.
            
            GlobalStorage.unique.storeLastError(
                errorText: "iCloudService.CommonErrorHandling(\(from): Error.Code = .assetFileModified, \(currentError.localizedDescription)")
            
            
        case .assetFileNotFound:
            // An error that occurs when the system can’t find the specified asset.
            
            GlobalStorage.unique.storeLastError(
                errorText: "iCloudService.CommonErrorHandling(\(from): Error.Code = .assetFileNotFound, \(currentError.localizedDescription)")
            
            
        case .assetNotAvailable:
            // An error that occurs when the system can’t access the specified asset.
            
            GlobalStorage.unique.storeLastError(
                errorText: "iCloudService.CommonErrorHandling(\(from): Error.Code = .assetNotAvailable, \(currentError.localizedDescription)")
            
            
        case .badContainer:
            // An error that occurs when you use an unknown or unauthorized container.
            
            GlobalStorage.unique.storeLastError(
                errorText: "iCloudService.CommonErrorHandling(\(from): Error.Code = .badContainer, \(currentError.localizedDescription)")
            
            
        case .badDatabase:
            // An error that occurs when the operation can’t complete for the specified database..
            
            GlobalStorage.unique.storeLastError(
                errorText: "iCloudService.CommonErrorHandling(\(from): Error.Code = .badDatabase, \(currentError.localizedDescription)")
            
            
        case .batchRequestFailed:
            // An error that occurs when the system rejects the entire batch of changes.
            
            GlobalStorage.unique.storeLastError(
                errorText: "iCloudService.CommonErrorHandling(\(from): Error.Code = .batchRequestFailed, \(currentError.localizedDescription)")
            
            
        case .changeTokenExpired:
            // An error that occurs when the change token expires.
            
            GlobalStorage.unique.storeLastError(
                errorText: "iCloudService.CommonErrorHandling(\(from): Error.Code = .changeTokenExpired, \(currentError.localizedDescription)")
            
            
        case .constraintViolation:
            // An error that occurs when the server rejects the request because of a unique constraint violation.
            
            GlobalStorage.unique.storeLastError(
                errorText: "iCloudService.CommonErrorHandling(\(from): Error.Code = .constraintViolation, \(currentError.localizedDescription)")
            
            
        case .incompatibleVersion:
            // An error that occurs when the current app version is older than the oldest allowed version.
            
            GlobalStorage.unique.storeLastError(
                errorText: "iCloudService.CommonErrorHandling(\(from): Error.Code = .incompatibleVersion, \(currentError.localizedDescription)")
            
            
        case .internalError:
            // A nonrecoverable error that CloudKit encounters.
            
            GlobalStorage.unique.storeLastError(
                errorText: "iCloudService.CommonErrorHandling(\(from): Error.Code = .internalError, \(currentError.localizedDescription)")
            
            
        case .invalidArguments:
            //An error that occurs when the request contains invalid information.
            
            GlobalStorage.unique.storeLastError(
                errorText: "iCloudService.CommonErrorHandling(\(from): Error.Code = .invalidArguments, \(currentError.localizedDescription)")
            
            
        case .limitExceeded:
            // An error that occurs when a request’s size exceeds the limit.
            
            GlobalStorage.unique.storeLastError(
                errorText: "iCloudService.CommonErrorHandling(\(from): Error.Code = .limitExceeded, \(currentError.localizedDescription)")
            
            
        case .managedAccountRestricted:
            // An error that occurs when CloudKit rejects a request due to a managed-account restriction.
            
            GlobalStorage.unique.storeLastError(
                errorText: "iCloudService.CommonErrorHandling(\(from): Error.Code = .managedAccountRestricted, \(currentError.localizedDescription)")
            
            
        case .missingEntitlement:
            // An error that occurs when the app is missing a required entitlement.
            
            GlobalStorage.unique.storeLastError(
                errorText: "iCloudService.CommonErrorHandling(\(from): Error.Code = .missingEntitlement, \(currentError.localizedDescription)")
            
            
        case .networkFailure:
            // An error that occurs when a network is available, but CloudKit is inaccessible.
            
            GlobalStorage.unique.storeLastError(
                errorText: "iCloudService.CommonErrorHandling(\(from): Error.Code = .networkFailure, \(currentError.localizedDescription)")
            
            
        case .networkUnavailable:
            // An error that occurs when the network is unavailable.
            
            GlobalStorage.unique.storeLastError(
                errorText: "iCloudService.CommonErrorHandling(\(from): Error.Code = .networkUnavailable, \(currentError.localizedDescription)")
            
            
        case .notAuthenticated:
            // An error that occurs when the user is unauthenticated.
            
            GlobalStorage.unique.storeLastError(
                errorText: "iCloudService.CommonErrorHandling(\(from): set userIsLoggedIn = false, Error.Code = .notAuthenticated, \(currentError.localizedDescription)")
            
            self.userIsLoggedIn = false
            
            
        case .operationCancelled:
            // An error that occurs when an operation cancels.
            
            GlobalStorage.unique.storeLastError(
                errorText: "iCloudService.CommonErrorHandling(\(from): Error.Code = .operationCancelled, \(currentError.localizedDescription)")
            
            
        case .partialFailure:
            // An error that occurs when an operation completes with partial failures.
            
            GlobalStorage.unique.storeLastError(
                errorText: "iCloudService.CommonErrorHandling(\(from): Error.Code = .partialFailure, \(currentError.localizedDescription)")
            
            
        case .participantMayNeedVerification:
            // An error that occurs when the user isn’t a participant of the share.
            
            GlobalStorage.unique.storeLastError(
                errorText: "iCloudService.CommonErrorHandling(\(from): Error.Code = .participantMayNeedVerification, \(currentError.localizedDescription)")
            
            
        case .permissionFailure:
            // An error that occurs when the user doesn’t have permission to save or fetch data.
            
            GlobalStorage.unique.storeLastError(
                errorText: "iCloudService.CommonErrorHandling(\(from): Error.Code = .permissionFailure, \(currentError.localizedDescription)")
            
            
        case .quotaExceeded:
            // An error that occurs when saving a record exceeds the user’s storage quota.
            
            GlobalStorage.unique.storeLastError(
                errorText: "iCloudService.CommonErrorHandling(\(from): Error.Code = .quotaExceeded, \(currentError.localizedDescription)")
            
            
        case .referenceViolation:
            // An error that occurs when CloudKit can’t find the target of a reference.
            
            GlobalStorage.unique.storeLastError(
                errorText: "iCloudService.CommonErrorHandling(\(from): Error.Code = .referenceViolation, \(currentError.localizedDescription)")
            
            
        case .requestRateLimited:
            // An error that occurs when CloudKit rate-limits requests.
            // Transfers to and from the server are being rate limited for the client at this time.
            
            GlobalStorage.unique.storeLastError(
                errorText: "iCloudService.CommonErrorHandling(\(from): Error.Code = .requestRateLimited, \(currentError.localizedDescription)")
            
            
        case .serverRecordChanged:
            // An error that occurs when CloudKit rejects a record because the server’s version is different.
            
            GlobalStorage.unique.storeLastError(
                errorText: "iCloudService.CommonErrorHandling(\(from): Error.Code = .serverRecordChanged, \(currentError.localizedDescription)")
            
            
        case .serverRejectedRequest:
            // An error that occurs when CloudKit rejects the request.
            
            GlobalStorage.unique.storeLastError(
                errorText: "iCloudService.CommonErrorHandling(\(from): Error.Code = .serverRejectedRequest, \(currentError.localizedDescription)")
            
            
        case .serverResponseLost:
            // An error that occurs when CloudKit is unable to maintain the network connection and provide a response.
            
            GlobalStorage.unique.storeLastError(
                errorText: "iCloudService.CommonErrorHandling(\(from): Error.Code = .serverResponseLost, \(currentError.localizedDescription)")
            
            
        case .serviceUnavailable:
            // An error that occurs when CloudKit is unavailable.
            
            GlobalStorage.unique.storeLastError(
                errorText: "iCloudService.CommonErrorHandling(\(from): Error.Code = .serviceUnavailable, \(currentError.localizedDescription)")
            
            
        case .tooManyParticipants:
            // An error that occurs when a share has too many participants.
            
            GlobalStorage.unique.storeLastError(
                errorText: "iCloudService.CommonErrorHandling(\(from): Error.Code = .tooManyParticipants, \(currentError.localizedDescription)")
            
            
        case .unknownItem:
            // An error that occurs when the specified record doesn’t exist.
            
            GlobalStorage.unique.storeLastError(
                errorText: "iCloudService.CommonErrorHandling(\(from): Error.Code = .unknownItem, \(currentError.localizedDescription)")
            
            
        case .userDeletedZone:
            // An error that occurs when the user deletes a record zone using the Settings app.
            
            GlobalStorage.unique.storeLastError(
                errorText: "iCloudService.CommonErrorHandling(\(from): Error.Code = .userDeletedZone, \(currentError.localizedDescription)")
            
            
        case .zoneBusy:
            // An error that occurs when the server is too busy to handle the record zone operation.
            
            GlobalStorage.unique.storeLastError(
                errorText: "iCloudService.CommonErrorHandling(\(from): Error.Code = .networkFailure, \(currentError.localizedDescription)")
            
            
        case .zoneNotFound:
            // An error that occurs when the specified record zone doesn’t exist
            
            GlobalStorage.unique.storeLastError(
                errorText: "iCloudService.CommonErrorHandling(\(from): Error.Code = .zoneNotFound or .userDeletedZone, \(currentError.localizedDescription)")
            
            
        default:
            // no special handling, just reporting
            GlobalStorage.unique.storeLastError(
                errorText: "iCloudService.CommonErrorHandling(\(from): default:, \(currentError.localizedDescription)")
        }
    }
}
