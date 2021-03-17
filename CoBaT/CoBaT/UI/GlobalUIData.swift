//
//  GlobalUIData.swift
//  CoBaT
//
//  Created by Hartwig Hopfenzitz on 27.11.20.
//

import Foundation
import UIKit
import MapKit


// -------------------------------------------------------------------------------------------------
// MARK: -
// MARK: - Class
// -------------------------------------------------------------------------------------------------
final class GlobalUIData: NSObject {
    
    // ---------------------------------------------------------------------------------------------
    // MARK: - Singleton
    // ---------------------------------------------------------------------------------------------
    static let unique = GlobalUIData()
    
    // ---------------------------------------------------------------------------------------------
    // MARK: - Constants and variables (NOT permanent stored)
    // ---------------------------------------------------------------------------------------------
    private let permanentStore = UserDefaults.standard

    // The DetailsRKITableViewController uses this data to build local data out of the global Storage
    public var UIDetailsRKIAreaLevel: Int = GlobalStorage.unique.RKIDataCounty
    public var UIDetailsRKISelectedMyID: String = "7"
    
    // the details screen is called in two differnt scenarios: First form main screen and
    // in rki browser. to make sure that the right graph will be shown when user gets back
    // to the main screen, we have to save the selected arealevel and ID and restore it, when
    // the browsed detail screen disapeared
    // we do that by saving the two values in BrowseRKIDataTableViewController.detailsButtonTapped()
    // and restore it in DetailsRKIViewController.viewDidDisappear()
    public var UIDetailsRKIAreaLevelSaved: Int = GlobalStorage.unique.RKIDataCounty
    public var UIDetailsRKISelectedMyIDSaved: String = "7"



    // tabBar currently active, will be set by CountryTabViewController (0), StateTabViewController (1) or CountyTabViewController (2)
    public var UITabBarCurrentlyActive: Int = 0
    
    // this UICoros will be set in CommonTabViewController for the embedded CommonTabTableViewController
    public var UITabBarCurentTextColor: UIColor = UIColor.label
    public var UITabBarCurentBackgroundColor: UIColor = UIColor.systemBackground
    public var UITabBarCurentGrade: Int = 0

    // this colors have to be set for the DetailsRKITableViewController. it will use this to color the
    // cells which are not related to day details
    public var UIDetailsRKITextColor: UIColor = UIColor.label
    public var UIDetailsRKIBackgroundColor: UIColor = UIColor.systemBackground
    
    
    // there are three small graphs on top of the DetailsRKITableView
    // The size of that graphs will be depending on the screen width of the device
    // this are the constants which are used in differtent functions
    
    public let RKIGraphMaxWidth: CGFloat      = 650.0
    public var UIScreenWidth: CGFloat         = min(UIScreen.main.bounds.width, 650.0)
    
    public let RKIGraphSideMargins: CGFloat   = 10.0
    public let RKIGraphTopMargine: CGFloat    = 0.0
    public var RKIGraphBottomMargine: CGFloat = 5.0
    public var RKIGraphNeededWidth: CGFloat =
        round ((min(UIScreen.main.bounds.width, 650.0) - (10.0 * 2)) * 0.32)
    public var RKIGraphNeededHeight: CGFloat =
        round(((min(UIScreen.main.bounds.width, 650.0) - (10.0 * 2)) * 0.32) / 5 * 4)
//    public var RKIGraphNeededWidth: CGFloat =  round((min(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
//                                        - (10.0 * 2)) * 0.32)
//    public var RKIGraphNeededHeight: CGFloat = round(
//                                round((min(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
//                                        - (10.0 * 2)) * 0.32)
//                                    / 5 * 4)

    public var RKIGraphCurrentViewWidth: CGFloat = min(UIScreen.main.bounds.width, 650.0)
    public var RKIGraphCurrentViewHeight: CGFloat = min(UIScreen.main.bounds.height, 650.0)
    

    // ---------------------------------------------------------------------------------------------
    // MARK: - Variables (permanent stored)
    // ---------------------------------------------------------------------------------------------
    public var UIBrowserRKIAreaLevel: Int = GlobalStorage.unique.RKIDataCounty
    
    public var UIBrowserRKITitelString: String = "Rheinland-Pfalz"
    
    public var UIBrowserRKISelectedStateName: String = "Rheinland-Pfalz"
    public var UIBrowserRKISelectedStateID: String = "7"
    
    public var UIBrowserRKISelectedCountyName: String = "Mayen-Koblenz"
    public var UIBrowserRKISelectedCountyID: String = "149"

    // in this dictionary we store the selected County ID per State
    public var UIBrowserCountyIDPerStateID: [String : String] = ["7" : "149"]
    
    public enum UIBrowserRKISortEnum: Int {
        case alphabetically = 0, incidencesAscending = 1, incidencesDescending = 2
    }
    
    public var UIBrowserRKISorting: UIBrowserRKISortEnum = .alphabetically
    
    public var UIMainTabBarSelectedTab: Int = 0 
    
    // we restore the last map region. Initially we show whole Germany. The values are taken from a real device
    public var UIMapLastCenterCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 51.117027000000036,
                                                                                          longitude: 10.333652)
    
    public var UIMapLastSpan: MKCoordinateSpan = MKCoordinateSpan(latitudeDelta: 9.589147244505277,
                                                                  longitudeDelta: 10.026110459526336)

    
    
    
    
    
    // ---------------------------------------------------------------------------------------------
    // MARK: - RKI Data API
    // ---------------------------------------------------------------------------------------------
    
    /**
     -----------------------------------------------------------------------------------------------
     
     Finds the county data of a stateID. Usually that's the preselected county, but we do our best, to find anything useful
     
     -----------------------------------------------------------------------------------------------
     
     - Parameters:
        - stateID: The ID of the state
     
     - Returns:
        - the index of the county in the data of today, the ID of the county and the name of it
     */
    public func getCountyFromStateID(stateID: String) -> (countyIndex: Int, countyID: String, countyName: String) {
        
        // we sync the data access
        return GlobalStorageQueue.sync(execute: { () -> (Int, String, String) in
            
            // try to find the countyID in the dictionary
            if let countyID = GlobalUIData.unique.UIBrowserCountyIDPerStateID[stateID] {
                
                // yes we found it, now try to find that countyID in the data of today
                if let countyIndex = GlobalStorage.unique.RKIData[GlobalStorage.unique.RKIDataCounty][0].firstIndex(
                    where: { $0.myID == countyID } ) {
                    
                    // we found the record of the county, make a shortcut
                    let countyRecord = GlobalStorage.unique.RKIData[GlobalStorage.unique.RKIDataCounty][0][countyIndex]
                    
                    // return the result
                    return (countyIndex, countyRecord.myID!, countyRecord.name)
                    
                } else {
                    
                    // we DID NOT find the countyID in the data of today,
                    // so try to find the first county of that state in the data of today
                    if let countyIndex = GlobalStorage.unique.RKIData[GlobalStorage.unique.RKIDataCounty][0].firstIndex(
                        where: { $0.stateID == stateID } ) {
                        
                        // we found the record of the county, make a shortcut
                        let countyRecord = GlobalStorage.unique.RKIData[GlobalStorage.unique.RKIDataCounty][0][countyIndex]
                        
                        // set it in the dictonary
                        GlobalUIData.unique.UIBrowserCountyIDPerStateID[stateID] = countyRecord.myID
                        
                        #if DEBUG_PRINT_FUNCCALLS
                        print("getCountyFromStateID just set UIBrowserCountyIDPerStateID[\(stateID)] = \(countyRecord.myID!)")
                        #endif
                        
                        // return the result
                        return (countyIndex, countyRecord.myID!, countyRecord.name)
                        
                        
                    } else {
                        
                        // we did not found anything, so report that and return "-1"
                        
                        // encode did fail, log the message
                        GlobalStorage.unique.storeLastError(errorText: "GlobalUIData.getCountyFromStateID: Error: didn't find neither countyID (\(countyID)) or stateID (\(stateID)) in data of today, give up and return (-1, \"\", \"\")")
                        
                        return (-1, "", "")
                    }
                }
                
            } else {
                
                // we DID NOT find the countyID in the dictonary,
                // so try to find the first county of that state in the data of today
                if let countyIndex = GlobalStorage.unique.RKIData[GlobalStorage.unique.RKIDataCounty][0].firstIndex(
                    where: { $0.stateID == stateID } ) {
                    
                    // we found the record of the county, make a shortcut
                    let countyRecord = GlobalStorage.unique.RKIData[GlobalStorage.unique.RKIDataCounty][0][countyIndex]
                    
                    // set it in the dictonary
                    GlobalUIData.unique.UIBrowserCountyIDPerStateID[stateID] = countyRecord.myID
                    
                    #if DEBUG_PRINT_FUNCCALLS
                    print("getCountyFromStateID just set UIBrowserCountyIDPerStateID[\(stateID)] = \(countyRecord.myID!)")
                    #endif

                    // return the result
                    return (countyIndex, countyRecord.myID!, countyRecord.name)
                    
                } else {
                    
                    // we did not found anything, so report that and return "-1"
                    
                    // encode did fail, log the message
                    GlobalStorage.unique.storeLastError(errorText: "GlobalUIData.getCountyFromStateID: Error: didn't find stateID (\(stateID)) neither in dictionary or data of today, give up and return (-1, \"\", \"\")")
                    
                    return (-1, "", "")
                }
            }
        })
        
    }
    
    
    
    
    
    /**
     -----------------------------------------------------------------------------------------------
     
     reads the permananently stored values into the global storage. Values are stored in user defaults
     
     -----------------------------------------------------------------------------------------------
     */
    public func restoreSavedUIData() {
        
        GlobalStorageQueue.async(flags: .barrier, execute: {
            
            #if DEBUG_PRINT_FUNCCALLS
            print("restoreSavedUIData just started")
            #endif

            self.UIBrowserRKIAreaLevel = self.permanentStore.integer(
                forKey: "CoBaT.UIBrowserRKIAreaLevel")
            
            
            if let loadedUIBrowserRKITitelString = self.permanentStore.string(
                forKey: "CoBaT.UIBrowserRKITitelString") {
                self.UIBrowserRKITitelString = loadedUIBrowserRKITitelString
            }

            if let loadedUIBrowserRKISelectedStateName = self.permanentStore.string(
                forKey: "CoBaT.UIBrowserRKISelectedStateName") {
                self.UIBrowserRKISelectedStateName = loadedUIBrowserRKISelectedStateName
            }

            if let loadedUIBrowserRKISelectedID = self.permanentStore.string(
                forKey: "CoBaT.UIBrowserRKISelectedStateID") {
                self.UIBrowserRKISelectedStateID = loadedUIBrowserRKISelectedID
            }

            if let loadedUIBrowserRKISelectedCountyName = self.permanentStore.string(
                forKey: "CoBaT.UIBrowserRKISelectedCountyName") {
                self.UIBrowserRKISelectedCountyName = loadedUIBrowserRKISelectedCountyName
            }

            if let loadedUIBrowserRKISelectedCountyID = self.permanentStore.string(
                forKey: "CoBaT.UIBrowserRKISelectedCountyID") {
                self.UIBrowserRKISelectedCountyID = loadedUIBrowserRKISelectedCountyID
            }
            
            if let loadedUIBrowserCountyIDPerStateID = self.permanentStore.object(
                forKey: "CoBaT.UIBrowserCountyIDPerStateID") as? [String:String] {
                self.UIBrowserCountyIDPerStateID = loadedUIBrowserCountyIDPerStateID
            }

            
            if let loadedUIBrowserRKISorting = UIBrowserRKISortEnum(
                rawValue: self.permanentStore.integer(forKey: "CoBaT.UIBrowserRKISorting")) {
                self.UIBrowserRKISorting = loadedUIBrowserRKISorting
            }
            
            self.UIMainTabBarSelectedTab = self.permanentStore.integer(
                forKey: "CoBaT.UIMainTabBarSelectedTab")
            
            
            // restore the map region
            let mapCenterLatitude = self.permanentStore.double(
                forKey: "CoBaT.UIMapLastCenterCoordinateLatitude")
            
            if mapCenterLatitude != 0.0 {
                
                let mapCenterLongitude = self.permanentStore.double(
                    forKey: "CoBaT.UIMapLastCenterCoordinateLongitude")
                
                if mapCenterLongitude != 0.0 {
                    
                    let mapSpanLatitude = self.permanentStore.double(
                        forKey: "CoBaT.UIMapLastSpanLatitudeDelta")
                    
                    if mapSpanLatitude != 0 {
                        
                        let mapSpanLongitude = self.permanentStore.double(
                            forKey: "CoBaT.UIMapLastSpanLongitudeDelta")
                        
                        if mapSpanLongitude != 0 {
                            
                            self.UIMapLastCenterCoordinate = CLLocationCoordinate2D(
                                latitude: mapCenterLatitude,
                                longitude: mapCenterLongitude)
                            
                            self.UIMapLastSpan = MKCoordinateSpan(
                                latitudeDelta: mapSpanLatitude,
                                longitudeDelta: mapSpanLongitude)
                        }
                    }
                }
            }
                        
            
            // the load of some UI elements is faster than this restore, so we send a post to sync it
            DispatchQueue.main.async(execute: {
                NotificationCenter.default.post(Notification(name: .CoBaT_UIDataRestored))
            })
            
            #if DEBUG_PRINT_FUNCCALLS
            print("restoreSavedUIData just posted .CoBaT_UIDataRestored")
            #endif

         })
    }
    
    /**
     -----------------------------------------------------------------------------------------------
     
     stores the thre variables RKIData, RKIDataTimeStamps and RKIDataLastUpdated into the permanant store
     
     -----------------------------------------------------------------------------------------------
     */
    public func saveUIData() {
        
        // make sure we have consistent data
        GlobalStorageQueue.async(flags: .barrier, execute: {
            
            #if DEBUG_PRINT_FUNCCALLS
            print("saveUIData just started")
            #endif

            self.permanentStore.set(self.UIBrowserRKIAreaLevel,
                                    forKey: "CoBaT.UIBrowserRKIAreaLevel")
            
            self.permanentStore.set(self.UIBrowserRKITitelString,
                                    forKey: "CoBaT.UIBrowserRKITitelString")
            
            self.permanentStore.set(self.UIBrowserRKISelectedStateName,
                                    forKey: "CoBaT.UIBrowserRKISelectedStateName")
            self.permanentStore.set(self.UIBrowserRKISelectedStateID,
                                    forKey: "CoBaT.UIBrowserRKISelectedStateID")
            
            self.permanentStore.set(self.UIBrowserRKISelectedCountyName,
                                    forKey: "CoBaT.UIBrowserRKISelectedCountyName")
            self.permanentStore.set(self.UIBrowserRKISelectedCountyID,
                                    forKey: "CoBaT.UIBrowserRKISelectedCountyID")

            self.permanentStore.set(self.UIBrowserCountyIDPerStateID,
                                    forKey: "CoBaT.UIBrowserCountyIDPerStateID")

            self.permanentStore.set(self.UIBrowserRKISorting.rawValue,
                                    forKey: "CoBaT.UIBrowserRKISorting")
            
            self.permanentStore.set(self.UIMainTabBarSelectedTab,
                                    forKey: "CoBaT.UIMainTabBarSelectedTab")
            
            // map Data
            self.saveMapRegion()
         })
    }
    
    /**
     -----------------------------------------------------------------------------------------------
     
     stores the current map region
     
     -----------------------------------------------------------------------------------------------
     */
    public func saveMapRegion() {
        
        self.permanentStore.set(self.UIMapLastCenterCoordinate.latitude,
                                forKey: "CoBaT.UIMapLastCenterCoordinateLatitude")
        
        self.permanentStore.set(self.UIMapLastCenterCoordinate.longitude,
                                forKey: "CoBaT.UIMapLastCenterCoordinateLongitude")

        self.permanentStore.set(self.UIMapLastSpan.latitudeDelta,
                                forKey: "CoBaT.UIMapLastSpanLatitudeDelta")

        self.permanentStore.set(self.UIMapLastSpan.longitudeDelta,
                                forKey: "CoBaT.UIMapLastSpanLongitudeDelta")


    }

}
