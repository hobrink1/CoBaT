//
//  CoBaTBackgroundService.swift
//  CoBaT
//
//  Created by Hartwig Hopfenzitz on 03.12.20.
//

import Foundation
import BackgroundTasks


// -------------------------------------------------------------------------------------------------
// MARK: -
// MARK: - RKI Data Download
// -------------------------------------------------------------------------------------------------
class CoBaTBackgroundService: NSObject {

    // ---------------------------------------------------------------------------------------------
    // MARK: - Singleton
    // ---------------------------------------------------------------------------------------------
    static let unique = CoBaTBackgroundService()
    
    // ---------------------------------------------------------------------------------------------
    // MARK: - Properties
    // ---------------------------------------------------------------------------------------------
    private var RKICountyDataOK: Bool = false
    private var RKIStateDataOK: Bool = false
    
    // ---------------------------------------------------------------------------------------------
    // MARK: - API
    // ---------------------------------------------------------------------------------------------
    
    // this is the task object of the currently running background task
    public var RKIBackgroundFetchTask: BGAppRefreshTask?
    
    // with this flag GlobalStorage knows it have to use this class
    public var RKIBackgroundFetchIsOngoingFlag: Bool = false

    /**
     -----------------------------------------------------------------------------------------------
     
     This func is called from the background scheduler.
     
     After some preparation work, it starts the process chain of getting new data by calling GlobalStorage.unique.restoreSavedRKIData()
     
     -----------------------------------------------------------------------------------------------
     
     - Parameters:
        - task: The task object of the recently started background task
     
     - Returns: nothing
     
     */
     public func startRKIBackgroundFetch(task: BGAppRefreshTask) {
        
        // set the variable to manage the fetch in globalStorage()
        // globalStorage() will call the completion handler for that task, when processing is done
        RKIBackgroundFetchTask = task
        
        // globalStorage() uses this flag to determine, if a background task is active
        // it will set it to false after all is done
        RKIBackgroundFetchIsOngoingFlag = true
        
        // set the flag to be able to determin if both data typs are done
        RKICountyDataOK = false
        RKIStateDataOK = false
        
        #if DEBUG_PRINT_FUNCCALLS
        print("startRKIBackgroundFetch: will call restoreSavedRKIData()")
        #endif

        // restore the current data store and call RKI
        GlobalStorage.unique.restoreSavedRKIData()

    }
    
    /**
     -----------------------------------------------------------------------------------------------
     
     This function is called by several GlobalStorage functions to signal that new data has been processed
     
     The func waits until the state and county data are reported. If both have been reported. The function closes the background task be calling self.RKIBackgroundFetchTask?.setTaskCompleted(success: true)
     
     -----------------------------------------------------------------------------------------------
     
     - Parameters:
        - kindOf:
     
     - Returns:
     
     */
    // the func to call when new data arrived
    public func newRKIDataArraived(kindOf: Int) {
        
        // handle what kind of data we got
        switch kindOf {
        
        case GlobalStorage.unique.RKIDataState:
            RKIStateDataOK = true
            
        case GlobalStorage.unique.RKIDataCounty:
            RKICountyDataOK = true

        default:
            break
        }
        
        // if we have both parts, call success
        if (RKIStateDataOK == true)
            && (RKICountyDataOK == true) {
            
            // yes both parts are done, so close the task
            #if DEBUG_PRINT_FUNCCALLS
            print("newRKIDataArraived: RKIStateDataOK == true) && (RKICountyDataOK == true), close background task")
            #endif
         
            // with this flag GlobalStorage knows it have to use this class
            RKIBackgroundFetchIsOngoingFlag = false

            // close the current task
            RKIBackgroundFetchTask?.setTaskCompleted(success: true)
        }
    }
}
