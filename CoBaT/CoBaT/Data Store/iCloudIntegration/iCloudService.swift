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
    
    // this dataStruct will be used to build a queue of data to send
    struct dataQueueStruct {
        
        let time: TimeInterval
        let data: Data
        let RKIDataType: GlobalStorage.RKI_DataTypeEnum
        
        init(time: TimeInterval, data: Data, RKIDataType: GlobalStorage.RKI_DataTypeEnum) {
            self.time = time
            self.data = data
            self.RKIDataType = RKIDataType
        }
    }
    
    // we will try to send these data items
    var dataQueueArray: [dataQueueStruct] = []
    
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
            
            // store the data for duture use
            self.dataQueueArray.append(dataQueueStruct(time: time, data: data, RKIDataType: RKI_DataType))
            
            // start the work queue by calling getReferences()
            switch RKI_DataType {
            
            case .county:
                self.getReferencesCounty()

            case .state:
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
                    print( "iCloudService.getReferencesState(): success!, got \(recordCounterState) records, will update ReferenceTableState and call getReferencesCounty")
                    #endif
                    GlobalStorageQueue.async(flags: .barrier, execute: {
                        self.ReferenceTableState = newReferenceTableState
                    })
                    
                    //self.getReferencesCounty()
                    
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
                    print( "iCloudService.getReferencesCounty(): success!, got \(recordCounterCounty) records, will update ReferenceTableState and call checkStateData")
                    #endif
                    GlobalStorageQueue.async(flags: .barrier, execute: {
                        self.ReferenceTableCounty = newReferenceTableCounty
                    })
                    
                    //self.getReferencesCounty()
                    
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
                errorText: "iCloudService.CommonErrorHandling(\(from): Error.Code = .notAuthenticated, \(currentError.localizedDescription)")
            
            
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
