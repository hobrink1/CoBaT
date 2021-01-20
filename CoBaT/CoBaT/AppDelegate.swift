//
//  AppDelegate.swift
//  CoBaT
//
//  Created by Hartwig Hopfenzitz on 20.11.20.
//

import UIKit
import Foundation
import BackgroundTasks

let VersionLabel: String = "CoBaT V2.1.0.6"


// simple variable to detect if we are in background or not
// this avoids to call UIApplication.shared.applicationState, as this always have to be called on main thread
var weAreInBackground: Bool = true

var backgroundTaskID: UIBackgroundTaskIdentifier = UIBackgroundTaskIdentifier.invalid
var myCoBaTAppDelegate: AppDelegate!

// -------------------------------------------------------------------------------------------------
// MARK: -
// MARK: - AppDelegate
// -------------------------------------------------------------------------------------------------
@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    // ---------------------------------------------------------------------------------------------
    // MARK: - IOS App Management
    // ---------------------------------------------------------------------------------------------

    /**
     -----------------------------------------------------------------------------------------------
     
     didFinishLaunchingWithOptions:
     
     -----------------------------------------------------------------------------------------------
     */
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Override point for customization after application launch.
        myCoBaTAppDelegate = self

        
        // build the formatters
        buildAllFormatters()

//        // get the iCloud reference table
//        iCloudService.unique.getReferences()
//
        // restore the permanent stored data
        GlobalUIData.unique.restoreSavedUIData()
        GlobalStorage.unique.restoreSavedRKIData()
        
        // we will try to fetch new RKI data every 10 minutes so configure the background fetch
        
        //org.hobrink.CoBat.refreshRKIBackground
        // Fetch data once an hour.
        // backgroundfetch is deprecated, so use the new framework BGTaskScheduler
     
        // UIApplication.shared.setMinimumBackgroundFetchInterval(3600)
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "org.hobrink.CoBat.refreshRKIBackground",
            using: nil)
        { task in
             self.handleRKIBackgroundFetch(task: task as! BGAppRefreshTask)
        }
        
        // Schedule a new refresh task
        scheduleAppRefresh()

        return true
    }

    // -------------------------------------------------------------------------------------------------------------------------
    // MARK: - Application life cycle
    // -------------------------------------------------------------------------------------------------------------------------
    /**
     -----------------------------------------------------------------------------------------------
     
     applicationDidBecomeActive()
     
     -----------------------------------------------------------------------------------------------
     */
    func applicationDidBecomeActive(_ application: UIApplication) {
        
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        weAreInBackground = false
    }
    
    
    /**
     -----------------------------------------------------------------------------------------------
     
     applicationWillEnterForeground()
     
     -----------------------------------------------------------------------------------------------
     */
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        // this code awakes the app
        
        weAreInBackground = false
    }
    
    
    /**
     -----------------------------------------------------------------------------------------------
     
     applicationWillResignActive()
     
     -----------------------------------------------------------------------------------------------
     */
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        
         
    }
    
    
    /**
     -----------------------------------------------------------------------------------------------
     
     applicationDidEnterBackground()
     
     -----------------------------------------------------------------------------------------------
     */
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        // Set the flag
        weAreInBackground = true

    }
    
    
    /**
     -----------------------------------------------------------------------------------------------
     
     applicationWillTerminate()
     
     -----------------------------------------------------------------------------------------------
     */
    func applicationWillTerminate(_ application: UIApplication) {
        
        
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        
        
    }

    
    // ---------------------------------------------------------------------------------------------
    // MARK: - CoBaT Background tasks
    // ---------------------------------------------------------------------------------------------

    /**
     -----------------------------------------------------------------------------------------------
     
     handleRKIBackgroundFetch()
     
     is called by a submitted background task. It schedules the next periode by calling self.scheduleAppRefresh() and calls CoBaTBackgroundService.unique.startRKIBackgroundFetch(task: task) to start the background work
     
     -----------------------------------------------------------------------------------------------
      */
    func handleRKIBackgroundFetch(task: BGAppRefreshTask) {

        //#if DEBUG_PRINT_FUNCCALLS
        GlobalStorage.unique.storeLastError(
            errorText: "handleRKIBackgroundFetch(): just started")
        //#endif

        // Schedule a new refresh task
        scheduleAppRefresh()
        
        // ask for more background time
        // but make sure that a possible old one has been canceled
        self.stopCurrentBackgroundTask()
        backgroundTaskID = UIApplication.shared.beginBackgroundTask (withName: "CoBaT.BackgroundFetchBackgroundTask") {
            
            // End the task if time expires.
            self.stopCurrentBackgroundTask()
        }

        // call the background handler. The handler will also call task.setTaskCompleted(success: )
        CoBaTBackgroundService.unique.startRKIBackgroundFetch(task: task)
        
        // Provide an expiration handler for the background task that cancels the operation
        task.expirationHandler = {
            
            //#if DEBUG_PRINT_FUNCCALLS
            GlobalStorage.unique.storeLastError(
                errorText: "handleRKIBackgroundFetch().expirationHandler: will call setTaskCompleted(success: false)")
            //#endif

            self.stopCurrentBackgroundTask()

            task.setTaskCompleted(success: false)
        }
    }
    
    /**
     -----------------------------------------------------------------------------------------------
     
     scheduleAppRefresh()
     
     -----------------------------------------------------------------------------------------------
     */
    func scheduleAppRefresh() {
        
        let request = BGAppRefreshTaskRequest(identifier: "org.hobrink.CoBat.refreshRKIBackground")
        
        // Fetch no earlier than 60 minutes from now
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 60)
        
        do {
            try BGTaskScheduler.shared.submit(request)
            
            //#if DEBUG_PRINT_FUNCCALLS
            GlobalStorage.unique.storeLastError(
                errorText: "scheduleAppRefresh(): did submit task")
            //#endif
            
        } catch let error as NSError {
            
            GlobalStorage.unique.storeLastError(
                errorText: "scheduleAppRefresh(): Could not schedule app refresh: \(error.localizedDescription)")
        }
    }
    
    
    /**
     -----------------------------------------------------------------------------------------------
     
     We need that function to give the CoBaTBackgroundService a chance to call it
     
     -----------------------------------------------------------------------------------------------
     */
    public func stopCurrentBackgroundTask() {
        
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = UIBackgroundTaskIdentifier.invalid
        }
    }
    
    // ---------------------------------------------------------------------------------------------
    // MARK: - UISceneSession Lifecycle
    // ---------------------------------------------------------------------------------------------
    /**
     -----------------------------------------------------------------------------------------------
     
     configurationForConnecting:
     
     -----------------------------------------------------------------------------------------------
     */
    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    /**
     -----------------------------------------------------------------------------------------------
     
     didDiscardSceneSessions:
     
     -----------------------------------------------------------------------------------------------
     */
    func application(_ application: UIApplication,
                     didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

