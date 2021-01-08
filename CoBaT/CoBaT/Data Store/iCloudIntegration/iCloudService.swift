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
// MARK: - Global queues
// --------------------------------------------------------------------

// serial queue for operations
let IS_QueueForOperations : DispatchQueue = DispatchQueue(label: "org.hobrink.WayAndSee.IS_QueueForOperations", qos: .utility)

// serial queue
let IS_QueueForPList : DispatchQueue = DispatchQueue(label: "org.hobrink.WayAndSee.IS_QueueForPList", qos: .userInitiated)



// --------------------------------------------------------------------
// MARK: - Global constants and variables
// --------------------------------------------------------------------

enum IS_iCloudSignEnum { case Off, OK, Busy, Warning, NotOK }
var IS_iCloudSignStatus : IS_iCloudSignEnum = .Off
var IS_iCloudStatus : CKAccountStatus = .couldNotDetermine

let IS_MinRemainingBackgroundTime = 10.0   // if there is less backround time remaining, we do not start timeconsuming processes (se .start as an example)


let UnknownString = NSLocalizedString("<unknown>", comment: "Just the phrase <unknown> as hint, that this value is unknown")


// --------------------------------------------------------------------
// MARK: - File Directory Constants
// --------------------------------------------------------------------
let IS_iCloudDirectory : String    = "IS_iCloud"
let IS_iCloudInDirectory : String  = "IN"
let IS_iCloudOutDirectory : String = "OUT"


// --------------------------------------------------------------------
// MARK: - Container
// --------------------------------------------------------------------
// MARK: Container Names
// --------------------------------------------------------------------
let IS_DataContainerName          = "iCloud.org.hobrink.CoBaT"

// --------------------------------------------------------------------
// MARK: Default Container
// --------------------------------------------------------------------
let IS_DefaultContainer : CKContainer      = CKContainer.default()
//var IS_DefaultPrivateDB : CKDatabase!
//var IS_GotDefaultContainer : Bool          = false

// --------------------------------------------------------------------
// MARK: Data Container
// --------------------------------------------------------------------
var IS_DataContainer : CKContainer!
var IS_DataPrivateDB : CKDatabase!
var IS_GotDataContainer : Bool              = false


let IS_PublicDatabase = IS_DefaultContainer.publicCloudDatabase

// --------------------------------------------------------------------
// MARK: User Info
// --------------------------------------------------------------------
var IS_UserRecordID : CKRecord.ID = CKRecord.ID()

// --------------------------------------------------------------------
// MARK: - OpIndex constants
// --------------------------------------------------------------------
let WIS_OPIndex_neutral : Int                    = -1
let WIS_OPIndex_LastInChain : Int                = -2
let WIS_OPIndex_DataMigrationStopsFinished : Int = -3
let WIS_OPIndex_EmptyFile : Int                  = -4

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
    
    // we will try to send these data
    var dataQueueArray: [dataQueueStruct] = []
    
    // --------------------------------------------------------------------
    // MARK: - Zones and RecordTypes
    // --------------------------------------------------------------------




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
            self.getReferences()
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
    private func getReferences() {
        
        GlobalStorageQueue.async(execute: {
            
            #if DEBUG_PRINT_FUNCCALLS
            print( "iCloudService.getReferences(): just started")
            #endif

            
        })
    }

}
