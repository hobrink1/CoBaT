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
    var ReferenceTableState: [ReferenceTableStruct] = []
    var ReferenceTableCounty: [ReferenceTableStruct] = []
    
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
    var dataToSendSCounty: [Int : dataQueueStruct] = [:]
    var dataToSendState:   [Int : dataQueueStruct] = [:]

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
    
    /**
     -----------------------------------------------------------------------------------------------
     RecordFields
     -----------------------------------------------------------------------------------------------
     */
    let RF_DataHashValue: String    = "DataHashValue"
    let RF_Date: String             = "Date"
    let RF_DayNumber: String        = "DayNumber"
    let RF_RKIData: String          = "RKIData"
    
    
    
    
    
    
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
    public func syncNewRKIData(RKI_DataType:  GlobalStorage.RKI_DataTypeEnum, time: TimeInterval, data: Data) {
        
        GlobalStorageQueue.async(flags: .barrier ,execute: {
            
            #if DEBUG_PRINT_FUNCCALLS
            print( "iCloudService.syncData(): type: \(RKI_DataType), time: \(Date(timeIntervalSinceReferenceDate: time)), size: \(data.count) just started")
            #endif
            
            // check the user acoount
            self.checkUserAccount()
            

            // get the number of day, we need it as the key for the dictonary
            let dayNumber = GlobalStorage.unique.getDayNumberFromTimeInterval(time: time)
            
            // start the work queue by calling getReferences()
            switch RKI_DataType {
            
            case .county:
                
                // store the data for future use
                
                // check if we already have a dictionary element
                if self.dataToSendSCounty[dayNumber] == nil {
                    
                    // no, so just add the data to the dictonary
                    self.dataToSendSCounty[dayNumber] = dataQueueStruct(time: time, data: data, RKIDataType: RKI_DataType)
                    
                    #if DEBUG_PRINT_FUNCCALLS
                    print( "iCloudService.syncData(): just set dataToSendSCounty[\(dayNumber)] to type: \(RKI_DataType), time: \(Date(timeIntervalSinceReferenceDate: time))")
                    #endif

                } else {
                    
                    // yes, we have already data with that dayNumber, so check if this is an update, by hashValues
                    
                    let hashData = self.dataToSendSCounty[dayNumber]!.data.hashValue
                    let hashReference = data.hashValue
                   
                    if hashData != hashReference {
                        
                        // yes we have newer data, so check if we are early enough to replace the data
                        if self.dataToSendSCounty[dayNumber]!.sendStatus == .new {
                            
                            // yes, it is still new, so just replace it, as we nmight have updated values
                            self.dataToSendSCounty[dayNumber] = dataQueueStruct(time: time, data: data, RKIDataType: RKI_DataType)
                            
                            #if DEBUG_PRINT_FUNCCALLS
                            print( "iCloudService.syncData(): just replaced dataToSendSCounty[\(dayNumber)] by type: \(RKI_DataType), time: \(Date(timeIntervalSinceReferenceDate: time))")
                            #endif
                            
                        } else {
                            
                            #if DEBUG_PRINT_FUNCCALLS
                            print( "iCloudService.syncData(): dataToSendSCounty[\(dayNumber)]!.sendStatus != .new, do NOT replace by type: \(RKI_DataType), time: \(Date(timeIntervalSinceReferenceDate: time))")
                            #endif
                        }
                        
                    } else {
                        
                        // no, same data, so do nothing
                        #if DEBUG_PRINT_FUNCCALLS
                        print( "iCloudService.syncData(): new data \(RKI_DataType), time: \(Date(timeIntervalSinceReferenceDate: time)) already in dataToSendSCounty[\(dayNumber)] and hash values are equal, do nothing")
                        #endif
                    }
                }
 
                // start the workflow by getting the reference data
                self.getReferencesCounty()

                
                
            case .state:
                
                // store the data for future use
                
                // check if we already have a dicinary element
                if self.dataToSendState[dayNumber] == nil {
                    
                    // no, so just add the data to the dictonary
                    self.dataToSendState[dayNumber] = dataQueueStruct(time: time, data: data, RKIDataType: RKI_DataType)
                    
                    #if DEBUG_PRINT_FUNCCALLS
                    print( "iCloudService.syncData(): just set dataToSendState[\(dayNumber)] to type: \(RKI_DataType), time: \(Date(timeIntervalSinceReferenceDate: time))")
                    #endif

                } else {
                    
                    // yes, we have already data with that dayNumber, so check if this is an update, by hashValues
                    
                    let hashData = self.dataToSendState[dayNumber]!.data.hashValue
                    let hashReference = data.hashValue
                   
                    if hashData != hashReference {
                        
                        // yes we have newer data, so check if we are early enough to replace the data
                        if self.dataToSendState[dayNumber]!.sendStatus == .new {
                            
                            // yes, it is still new, so just replace it, as we nmight have updated values
                            self.dataToSendState[dayNumber] = dataQueueStruct(time: time, data: data, RKIDataType: RKI_DataType)
                            
                            #if DEBUG_PRINT_FUNCCALLS
                            print( "iCloudService.syncData(): just replaced dataToSendState[\(dayNumber)] by type: \(RKI_DataType), time: \(Date(timeIntervalSinceReferenceDate: time))")
                            #endif
                            
                        } else {
                            
                            #if DEBUG_PRINT_FUNCCALLS
                            print( "iCloudService.syncData(): dataToSendState[\(dayNumber)]!.sendStatus != .new, do NOT replace by type: \(RKI_DataType), time: \(Date(timeIntervalSinceReferenceDate: time))")
                            #endif
                        }
                        
                    } else {
                        
                        // no, same data, so do nothing
                        #if DEBUG_PRINT_FUNCCALLS
                        print( "iCloudService.syncData(): new data \(RKI_DataType), time: \(Date(timeIntervalSinceReferenceDate: time)) already in dataToSendState[\(dayNumber)] and hash values are equal, do nothing")
                        #endif
                    }
                }

                // start the workflow by getting the reference data
                self.getReferencesState()
                
            default:
                break
            }
        })
    }
    
    
    // --------------------------------------------------------------------
    // MARK: - Main Work Queue
    // --------------------------------------------------------------------
    /**
     -----------------------------------------------------------------------------------------------
     
     This func will read the refences and will fill the tables for further reference
     
     -----------------------------------------------------------------------------------------------
     */
    private func getReferencesState() {
        
        GlobalStorageQueue.async(execute: {
            
            #if DEBUG_PRINT_FUNCCALLS
            print( "iCloudService.getReferencesState(): just started")
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
            operationState.resultsLimit = 16
            
            
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
                                errorText: "iCloudService.getReferencesState(): could not read dataHashValueRead on record from \(dateRead), ignore record, last good Record: \(recordCounterState)")
                        }
                        
                    } else {
                        
                        GlobalStorage.unique.storeLastError(
                            errorText: "iCloudService.getReferencesState(): could not read dayNumber on record from \(dateRead), ignore record, last good Record: \(recordCounterState)")
                    }
                    
                } else {
                    
                    GlobalStorage.unique.storeLastError(
                        errorText: "iCloudService.getReferencesState(): could not read dateString, ignore record, last good Record: \(recordCounterState)")
                }
            } // recordFetchBlock
            
            // -------------------------------------------------------------------------------------
            // Query Completion Block
            // -------------------------------------------------------------------------------------
            
            operationState.queryCompletionBlock = { (cursor, error) in
                
                if error == nil {
                    
                    // -----------------------------------------------------------------------------
                    //                                  Success!
                    // -----------------------------------------------------------------------------
                    #if DEBUG_PRINT_FUNCCALLS
                    print( "iCloudService.getReferencesState(): success!, got \(recordCounterState) records, will update ReferenceTableState and call pullRKIDataState()")
                    #endif
                    GlobalStorageQueue.async(flags: .barrier, execute: {
                        self.ReferenceTableState = newReferenceTableState
                    })
                    
                    self.pullRKIDataState()
                    
                } else {
                    // -----------------------------------------------------------------------------
                    // -----------------------------------------------------------------------------
                    //                                  Error!
                    // -----------------------------------------------------------------------------
                    // -----------------------------------------------------------------------------
                    
                    // check for errors
                    if let currentError = error as? CKError {
                        
                        // call the common error routine to print out error and do the usual error handling
                        self.CommonErrorHandling( currentError, from: "iCloudService.getReferencesState()")
                        
                        //                        // if neccessary use this
                        //                        switch currentError.code {
                        //
                        //                        default:
                        //                        break
                        //                        }
                        
                    } else {
                        
                        GlobalStorage.unique.storeLastError(
                            errorText: "iCloudService.getReferencesState(): Error occured, but could not get the error code")
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
    
    private func getReferencesCounty() {
        
        GlobalStorageQueue.async(execute: {
            
            #if DEBUG_PRINT_FUNCCALLS
            print( "iCloudService.getReferencesCounty(): just started")
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
            operationCounty.resultsLimit = 16
            
            
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
                                errorText: "iCloudService.getReferencesCounty(): could not read dataHashValueRead on record from \(dateRead), ignore record, last good Record: \(recordCounterCounty)")
                        }
                        
                    } else {
                        
                        GlobalStorage.unique.storeLastError(
                            errorText: "iCloudService.getReferencesCounty(): could not read dayNumber on record from \(dateRead), ignore record, last good Record: \(recordCounterCounty)")
                    }
                    
                } else {
                    
                    GlobalStorage.unique.storeLastError(
                        errorText: "iCloudService.getReferencesCounty(): could not read dateString, ignore record, last good Record: \(recordCounterCounty)")
                }
            } // recordFetchBlock
            
            // -------------------------------------------------------------------------------------
            // Query Completion Block
            // -------------------------------------------------------------------------------------
            
            operationCounty.queryCompletionBlock = { (cursor, error) in
                
                if error == nil {
                    
                    // -----------------------------------------------------------------------------
                    //                                  Success!
                    // -----------------------------------------------------------------------------
                    #if DEBUG_PRINT_FUNCCALLS
                    print( "iCloudService.getReferencesCounty(): success!, got \(recordCounterCounty) records, will update ReferenceTableState and call pullRKIDataState()")
                    #endif
                    GlobalStorageQueue.async(flags: .barrier, execute: {
                        self.ReferenceTableCounty = newReferenceTableCounty
                    })
                    
                    self.pullRKIDataCounty()
                    
                } else {
                    
                    
                    // -----------------------------------------------------------------------------
                    // -----------------------------------------------------------------------------
                    //                                  Error!
                    // -----------------------------------------------------------------------------
                    // -----------------------------------------------------------------------------
                    
                    // check for errors
                    if let currentError = error as? CKError {
                        
                        // call the common error routine to print out error and do the usual error handling
                        self.CommonErrorHandling( currentError, from: "iCloudService.getReferencesCounty()")
                        
                        //                        // if neccessary use this
                        //                        switch currentError.code {
                        //
                        //                        default:
                        //                        break
                        //                        }
                        
                    } else {
                        
                        GlobalStorage.unique.storeLastError(
                            errorText: "iCloudService.getReferencesCounty(): Error occured, but could not get the error code")
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
     
     checks if there is data in iCloud which are not yet available on local and if so, pull that data from icloud.
     
     -----------------------------------------------------------------------------------------------
     */
    private func pullRKIDataState() {
        
        #if DEBUG_PRINT_FUNCCALLS
        print("iCloudService.pullRKIDataState(): just started")
        #endif

        
        
        
        
        #if DEBUG_PRINT_FUNCCALLS
        print("iCloudService.pullRKIDataState(): now call pushRKIDataState()")
        #endif

        self.pushRKIDataState()
    }
    
    /**
     -----------------------------------------------------------------------------------------------
     
     checks if there is data in iCloud which are not yet available on local and if so, pull that data from icloud.
     
     -----------------------------------------------------------------------------------------------
     */    private func pullRKIDataCounty() {
        
        #if DEBUG_PRINT_FUNCCALLS
        print("iCloudService.pullRKIDataCounty(): just started")
        #endif
        
        
        
        

        #if DEBUG_PRINT_FUNCCALLS
        print("iCloudService.pullRKIDataCounty(): now call pushRKIDataCounty()")
        #endif

        self.pushRKIDataCounty()
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
                
                for item in self.dataToSendState {
                    
                    if item.value.sendStatus == .new {
                        
                        if let indexFound = self.ReferenceTableState.firstIndex(where: { $0.DayNumber == item.key } ) {
                            
//                            // dayNumber is already in reference table, so check if we have the same data
//                            let hashData = item.value.data.hashValue
//                            let hashReference = self.ReferenceTableState[indexFound].DataHashValue
//
//                            if hashData != hashReference {
//
//                                // local data differ from iCloud data, replace the data in iCloud
//
//                                #if DEBUG_PRINT_FUNCCALLS
//                                print("iCloudService.pushRKIDataState(): dayNumber \(item.key) already in Reference table, but hashData (\(hashData)) != hashReference (\(hashReference)), will call sendStateToICloud(\(item.key))")
//                                #endif
//
//                                self.dataToSendState[item.key]!.sendStatus = .markedForSend
//                                self.sendStateToICloud(dayNumber: item.key)
//
//                            } else {
//
//                                #if DEBUG_PRINT_FUNCCALLS
//                                print("iCloudService.pushRKIDataState(): dayNumber \(item.key) already in Reference table, and hashData (\(hashData)) == hashReference (\(hashReference)), will NOT call sendStateToICloud()")
//                                #endif
//                            }
                            
                            #if DEBUG_PRINT_FUNCCALLS
                            print("iCloudService.pushRKIDataState(): dayNumber \(item.key) already in Reference table, will NOT call sendStateToICloud()")
                            #endif

                        } else {
                            
                            // local data not in reference table, so send it to iCloud
                            #if DEBUG_PRINT_FUNCCALLS
                            print("iCloudService.pushRKIDataState(): dayNumber \(item.key) is not in reference table, will call sendStateToICloud(\(item.key))")
                            #endif
                            self.dataToSendState[item.key]!.sendStatus = .markedForSend
                            self.sendStateToICloud(dayNumber: item.key)
                        }
                    }
                }
                
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
                
                for item in self.dataToSendSCounty {
                    
                    if item.value.sendStatus == .new {
                        
                        if let indexFound = self.ReferenceTableCounty.firstIndex(where: { $0.DayNumber == item.key } ) {
                            
//                            // dayNumber is already in reference table, so check if we have the same data
//                            let hashData = item.value.data.hashValue
//                            let hashReference = self.ReferenceTableCounty[indexFound].DataHashValue
//
//                            if hashData != hashReference {
//
//                                // local data differ from iCloud data, replace the data in iCloud
//
//                                #if DEBUG_PRINT_FUNCCALLS
//                                print("iCloudService.pushRKIDataCounty(): dayNumber \(item.key) already in Reference table, but hashData (\(hashData)) != hashReference (\(hashReference)), will call sendCountyToICloud(\(item.key))")
//                                #endif
//
//                                self.dataToSendSCounty[item.key]!.sendStatus = .markedForSend
//                                self.sendCountyToICloud(dayNumber: item.key)
//
//                            } else {
//
//                                #if DEBUG_PRINT_FUNCCALLS
//                                print("iCloudService.pushRKIDataCounty(): dayNumber \(item.key) already in Reference table, and hashData (\(hashData)) == hashReference (\(hashReference)), will NOT call sendCountyToICloud()")
//                                #endif
//                            }
   
                            #if DEBUG_PRINT_FUNCCALLS
                            print("iCloudService.pushRKIDataCounty(): dayNumber \(item.key) already in Reference table, will NOT call sendCountyToICloud()")
                            #endif

                        } else {
                            
                            // local data not in reference table, so send it to iCloud
                            #if DEBUG_PRINT_FUNCCALLS
                            print("iCloudService.pushRKIDataCounty(): dayNumber \(item.key) is not in reference table, will call sendCountyToICloud(\(item.key))")
                            #endif
                            
                            self.dataToSendSCounty[item.key]!.sendStatus = .markedForSend
                            self.sendCountyToICloud(dayNumber: item.key)
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
    private var sendStateToICloudCounter: Int = 0
    private func sendStateToICloud(dayNumber: Int) {
        
        GlobalStorageQueue.async(execute: {
            
            #if DEBUG_PRINT_FUNCCALLS
            print("iCloudService.sendStateToICloud(\(dayNumber)): just started, counter: \(self.sendStateToICloudCounter)")
            #endif
            
            // build the RKI record
            let newRKIRecordID = CKRecord.ID(recordName: "RKIStateData\(dayNumber)")
            let newRKIRecord = CKRecord(recordType: self.RT_RKIStateData, recordID: newRKIRecordID)
            
            newRKIRecord[self.RF_DayNumber]  = dayNumber
            newRKIRecord[self.RF_RKIData]    = self.dataToSendSCounty[dayNumber]!.data
            
            
            // build the RKIReference Record
            let newRKIReferenceRecordID = CKRecord.ID(recordName: "RKIStateReference\(dayNumber)")
            let newRKIReferenceRecord = CKRecord(recordType: self.RT_RKIStateReference, recordID: newRKIReferenceRecordID)
            
            newRKIReferenceRecord[self.RF_DayNumber]  = dayNumber
            newRKIReferenceRecord[self.RF_Date]  = GlobalStorage.unique.getDateStringFromDayNumber(dayNumber: dayNumber)
            newRKIReferenceRecord[self.RF_DataHashValue] = self.dataToSendState[dayNumber]!.data.hashValue
                        
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
                        GlobalStorageQueue.async(flags: .barrier, execute: {
                            
                            #if DEBUG_PRINT_FUNCCALLS
                            print( "iCloudService.sendStateToICloud(\(dayNumber)): success!, got \(savedRecords!.count) records,")
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
                                self.dataToSendState.removeValue(forKey: dayNumber)
                                
                                // reset the counter
                                self.sendStateToICloudCounter = 0
                                
                                GlobalStorage.unique.storeLastError(
                                    errorText: "iCloudService.sendStateToICloud(\(dayNumber)): success!, found both records, removed data from queue, will call getReferencesState()")

                                // restart the work chain
                                self.getReferencesState()
     
                            } else {
                                
                                // reset the status of the data record in dictionary
                                self.dataToSendState[dayNumber]?.sendStatus = .new
                                
                                
                                // if we have less than 3 tries in a row, rgry again
                                self.sendStateToICloudCounter += 1
                                if self.sendStateToICloudCounter < 3 {
                                    
                                    #if DEBUG_PRINT_FUNCCALLS
                                    print( "iCloudService.sendStateToICloud(\(dayNumber)): success!, but dataSend == \(dataSend), referenceSend == \(referenceSend), sendStateToICloudCounter (\(self.sendStateToICloudCounter)) < 3, will call getReferencesState()")
                                    #endif
                                    // restart the work chain
                                    self.getReferencesState()
                                    
                                } else {
                                  
                                    GlobalStorage.unique.storeLastError(
                                        errorText: "iCloudService.sendStateToICloud(\(dayNumber)): success!, but dataSend == \(dataSend), referenceSend == \(referenceSend), sendStateToICloudCounter (\(self.sendStateToICloudCounter)) >= 3, will NOT call getReferencesState(), reset counter")
                                    
                                    
                                    self.sendStateToICloudCounter = 0
                                }
                            }
                         })
                        
                    } else {
                        
                        // safed records nil
                        GlobalStorage.unique.storeLastError(
                            errorText: "iCloudService.sendStateToICloud(\(dayNumber)): success!, but savedRecords == nil, do nothing")
                     
                        
                        // reset the counter
                        self.sendStateToICloudCounter = 0
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
                        self.CommonErrorHandling( currentError, from: "iCloudService.sendStateToICloud(\(dayNumber))")
                        
                        //                        // if neccessary use this
                        //                        switch currentError.code {
                        //
                        //                        default:
                        //                        break
                        //                        }
                        
                    } else {
                        
                        GlobalStorage.unique.storeLastError(
                            errorText: "iCloudService.sendStateToICloud(\(dayNumber)): Error occured, but could not get the error code")
                    }
                    
                    // reset the counter
                    self.sendStateToICloudCounter = 0
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
    private var sendCountyToICloudCounter: Int = 0

    private func sendCountyToICloud(dayNumber: Int) {
        
        GlobalStorageQueue.async(execute: {
            
            #if DEBUG_PRINT_FUNCCALLS
            print("iCloudService.sendCountyToICloud(\(dayNumber)): just started, counter: \(self.sendCountyToICloudCounter)")
            #endif
            
            // build the RKI record
            let newRKIRecordID = CKRecord.ID(recordName: "RKICountyData\(dayNumber)")
            let newRKIRecord = CKRecord(recordType: self.RT_RKICountyData, recordID: newRKIRecordID)
            
            newRKIRecord[self.RF_DayNumber]  = dayNumber
            newRKIRecord[self.RF_RKIData]    = self.dataToSendSCounty[dayNumber]!.data
            
            
            // build the RKIReference Record
            let newRKIReferenceRecordID = CKRecord.ID(recordName: "RKICountyReference\(dayNumber)")
            let newRKIReferenceRecord = CKRecord(recordType: self.RT_RKICountyReference, recordID: newRKIReferenceRecordID)
            
            newRKIReferenceRecord[self.RF_DayNumber]  = dayNumber
            newRKIReferenceRecord[self.RF_Date]  = GlobalStorage.unique.getDateStringFromDayNumber(dayNumber: dayNumber)
            newRKIReferenceRecord[self.RF_DataHashValue] = self.dataToSendSCounty[dayNumber]!.data.hashValue
                        
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
                        GlobalStorageQueue.async(flags: .barrier, execute: {
                            
                            #if DEBUG_PRINT_FUNCCALLS
                            print( "iCloudService.sendCountyToICloud(\(dayNumber)): success!, got \(savedRecords!.count) records,")
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
                                self.dataToSendSCounty.removeValue(forKey: dayNumber)
                                
                                // reset the counter
                                self.sendCountyToICloudCounter = 0
                                
                                GlobalStorage.unique.storeLastError(
                                    errorText: "iCloudService.sendCountyToICloud(\(dayNumber)): success!, found both records, removed data from queue, will call getReferencesState()")

                                // restart the work chain
                                self.getReferencesCounty()
     
                            } else {
                                
                                // reset the status of the data record in dictionary
                                self.dataToSendSCounty[dayNumber]?.sendStatus = .new
                                
                                
                                // if we have less than 3 tries in a row, rgry again
                                self.sendCountyToICloudCounter += 1
                                if self.sendCountyToICloudCounter < 3 {
                                    
                                    #if DEBUG_PRINT_FUNCCALLS
                                    print( "iCloudService.sendCountyToICloud(\(dayNumber)): success!, but dataSend == \(dataSend), referenceSend == \(referenceSend), sendCountyToICloudCounter (\(self.sendCountyToICloudCounter)) < 3, will call getReferencesState()")
                                    #endif
                                    // restart the work chain
                                    self.getReferencesCounty()
                                    
                                } else {
                                  
                                    GlobalStorage.unique.storeLastError(
                                        errorText: "iCloudService.sendCountyToICloud(\(dayNumber)): success!, but dataSend == \(dataSend), referenceSend == \(referenceSend), sendCountyToICloudCounter (\(self.sendCountyToICloudCounter)) >= 3, will NOT call getReferencesState(), reset counter")
                                    
                                    
                                    self.sendCountyToICloudCounter = 0
                                }
                            }
                         })
                        
                    } else {
                        
                        // safed records nil
                        GlobalStorage.unique.storeLastError(
                            errorText: "iCloudService.sendCountyToICloud(\(dayNumber)): success!, but savedRecords == nil, do nothing")
                     
                        
                        // reset the counter
                        self.sendCountyToICloudCounter = 0
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
                        self.CommonErrorHandling( currentError, from: "iCloudService.sendCountyToICloud(\(dayNumber))")
                        
                        //                        // if neccessary use this
                        //                        switch currentError.code {
                        //
                        //                        default:
                        //                        break
                        //                        }
                        
                    } else {
                        
                        GlobalStorage.unique.storeLastError(
                            errorText: "iCloudService.sendCountyToICloud(\(dayNumber)): Error occured, but could not get the error code")
                    }
                    
                    // reset the counter
                    self.sendCountyToICloudCounter = 0
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
