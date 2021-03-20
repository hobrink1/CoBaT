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
final class CoBaTBackgroundService: NSObject {

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
        
        // check if we already restored the saved data. We need them to determin if the recieved data are new ones
        if GlobalStorage.unique.savedRKIDataRestored == true {
            
            #if DEBUG_PRINT_FUNCCALLS
            GlobalStorage.unique.storeLastError(
                errorText:"startRKIBackgroundFetch: will call getRKIData()")
            #endif

            // get fresh data
            RKIDataDownload.unique.getRKIData(from: 0, until: 1)

        } else {
            
            #if DEBUG_PRINT_FUNCCALLS
            GlobalStorage.unique.storeLastError(
                errorText:"startRKIBackgroundFetch: will call restoreSavedRKIData()")
            #endif
            
            // restore the saved data store and call RKI
            GlobalStorage.unique.restoreSavedRKIData()
        }
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
    public func newRKIDataArrived(kindOf: Int) {
        
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
            //#if DEBUG_PRINT_FUNCCALLS
            GlobalStorage.unique.storeLastError(
                errorText:"newRKIDataArrived: kindOf: \(kindOf), (RKIStateDataOK == \(RKIStateDataOK)) && (RKICountyDataOK == \(RKICountyDataOK)), call closeBackgroundTask()")
            //#endif
         
            self.closeBackgroundTask()
            
        } else {
            
            //#if DEBUG_PRINT_FUNCCALLS
            GlobalStorage.unique.storeLastError(
                errorText:"newRKIDataArrived: kindOf: \(kindOf), RKIStateDataOK == \(RKIStateDataOK), RKICountyDataOK == \(RKICountyDataOK), DO NOT close background task")
            //#endif
        }
    }
    
    
    /**
     -----------------------------------------------------------------------------------------------
     
     Closes the backgroundtask by calling RKIBackgroundFetchTask?.setTaskCompleted(success: true)
     
     -----------------------------------------------------------------------------------------------
     */
    
    public func closeBackgroundTask() {
        
        //#if DEBUG_PRINT_FUNCCALLS
        GlobalStorage.unique.storeLastError(
            errorText:"closeBackgroundTask: will call setTaskCompleted(success: true) in 1 second")
        //#endif
        
        // to make sure we did everything we wanted to do, before the background task will be killed,
        // we do an async .barrier call with a 1 second delay to make sure all other tasks are done
        GlobalStorageQueue.asyncAfter(deadline: .now() + .seconds(1), flags: .barrier, execute: {
            
            // with this flag GlobalStorage knows it have to use this class
            self.RKIBackgroundFetchIsOngoingFlag = false
            
            myCoBaTAppDelegate.stopCurrentBackgroundTask()

            // close the current task
            self.RKIBackgroundFetchTask?.setTaskCompleted(success: true)
        })
    }
}
