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
    
    // this is the directory in .applicationSupportDirectory for the map data
    private let mapDataDirectory : String = "mapData"
    
    // this are the current filenames
    private let mapDataCurrentFilenameCountyShapes: String = "RKICountyShapesV4"
    private let mapDataCurrentFilenameStateBorders: String =  "RKIStateShapesV1"

    // in this array we store the old filenames. Used in self.checkMapFiles().
    // All files in that array have an outdated structure or outdated data. So they will be removed.
    // by this we can do some kind of version management, but there is no data migratiuon, we simply
    // reload the data from RKI website
    private let mapDataOldFilenamesToDelete: [String] = ["RKICountyShapesV1", "RKICountyShapesV2", "RKICountyShapesV3", "RKIStateShapes"]

    
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
    
    // this UIColors will be set in CommonTabViewController for the embedded CommonTabTableViewController
    public var UITabBarCurentTextColor: UIColor = UIColor.label
    public var UITabBarCurentBackgroundColor: UIColor = UIColor.systemBackground
    public var UITabBarCurentGrade: Int = 0

    // this colors have to be set for the DetailsRKITableViewController. it will use this to color the
    // cells which are not related to day details
    public var UIDetailsRKITextColor: UIColor = UIColor.label
    public var UIDetailsRKIBackgroundColor: UIColor = UIColor.systemBackground
    
    // this is a predefined neutral color
    public let UIClearColor: UIColor = UIColor.clear
    
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
    // MARK: - RKI Map Data (permanent)
    // ---------------------------------------------------------------------------------------------
    public struct RKIMapDataStruct : Encodable, Decodable {
        
        let myID: String                // each item has a unique ID, it's a number but we use a string
        let name: String                // the name of the item

        let ringsX: [[Double]]          // We split the MKMapPoint to its two part (x and Y)
        let ringsY: [[Double]]          // to keep the struct En/Decodable

        let centerLatitude: Double      // Latitude of center coordinate
        let centerLongitude: Double     // Longitude of center coordinate
        
        let boundingRectOriginX: Double // X value of origin of the bounding rectangle
        let boundingRectOriginY: Double // Y value of origin of the bounding rectangle
        
        let boundingRectSizeWidth: Double // width of size of the bounding rectangle
        let boundingRectSizeHeight: Double // hight of size of the bounding rectangle
        
        
        init(_ myID: String,
             _ name: String,
             _ ringsX: [[Double]],
             _ ringsY: [[Double]],
             centerLatitude: Double,
             longitude centerLongitude: Double,
             boundingRectOriginX: Double,
             y boundingRectOriginY: Double,
             boundingRectSizeWidth: Double,
             height boundingRectSizeHight: Double
             ) {
            
            self.myID                    = myID
            self.name                    = name
            self.ringsX                  = ringsX
            self.ringsY                  = ringsY
            self.centerLatitude          = centerLatitude
            self.centerLongitude         = centerLongitude
            self.boundingRectOriginX     = boundingRectOriginX
            self.boundingRectOriginY     = boundingRectOriginY
            self.boundingRectSizeWidth   = boundingRectSizeWidth
            self.boundingRectSizeHeight  = boundingRectSizeHight

        }
    }
    
    // in here we store the raw data of the counties and states for the map
    // both arrays will be restored from files at app start.
    // If the files does not exist, the data is read from RKI Website and stored in the files
    public var RKIMapCountyData: [RKIMapDataStruct] = []
    public var RKIMapStateData: [RKIMapDataStruct] = []
    
    // this is the array of all overlays. The overlays will be generated once. The map reloads them
    // in viewDidLoad()
    public var RKIMapOverlays: [RKIMapOverlay] = []
    
    // we store the area data in separate arrays to keep the overlay data small
    public var RKIMapAreaAndBorderData: [[[MKMapPoint]]] = []

    // this is the array of all annotations. Like the overlays the annotations will be generated onse.
    // The map reloads them in viewDidLoad()
    public var RKIMapAnnotations: [CountyAnnotation] = []
    
    // a flag used in MapViewController to show "data not ready"
    public var RKIMapOverlaysBuild: Bool = false
    
    /**
     -----------------------------------------------------------------------------------------------
     
     First step in the chain to enable the map
     
     This methode checks the file directory structure and checks if the map data are already stored in files. If so load them, if not, try to get them from the RKI JSON websites.
     
     Both data types (countyArea and state borders will be handled. But county borders first, as they are more important.
     
     -----------------------------------------------------------------------------------------------
     */
    private func handleRKIShapeData() {
        
        // we start the work on the map data deferred, as we do not want to disturb the start sequence
        GlobalStorageQueue.asyncAfter(deadline: .now() + .seconds(3), flags: .barrier, execute: {
            
            // Instance of a private filemanager
            let myFileManager = FileManager.default
            
            
            // ---------------------------------------------------------------------------------
            // handle .applicationSupportDirectory directory

            // get the application support directory
            if let applicationSupportDirectoryURL = myFileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                
                let applicationSupportDirectoryPath:String = applicationSupportDirectoryURL.path
                //myFileManager.changeCurrentDirectoryPath(homeDirectoryPath)
                
                // check if we have to create the directory
                if myFileManager.fileExists(atPath: applicationSupportDirectoryPath) == false {
                    
                    // does not exist, so create it
                    do {
                        try myFileManager.createDirectory(atPath: applicationSupportDirectoryPath,
                                                          withIntermediateDirectories: false,
                                                          attributes: nil)
                        
                        GlobalStorage.unique.storeLastError(errorText: "handleRKIShapeData(): just created .applicationSupportDirectory")
                        
                    } catch let error  {
                        
                        GlobalStorage.unique.storeLastError(errorText: "handleRKIShapeData(): creation of .applicationSupportDirectory directory failed, error: \"\(error)\", return")
                        
                        return
                    }
                    
                } else {
                    
                    #if DEBUG_PRINT_FUNCCALLS
                    print("handleRKIShapeData(): .applicationSupportDirectory exists")
                    #endif
                }
                
                
                // ---------------------------------------------------------------------------------
                // handle map directory

                // build the path of the map data directory
                let mapDataDirectoryPath = applicationSupportDirectoryPath + "/" + self.mapDataDirectory
                
                // check if we have to create the directory
                if myFileManager.fileExists(atPath: mapDataDirectoryPath) == false {
                    
                    // does not exist, so create it
                    do {
                        try myFileManager.createDirectory(atPath: mapDataDirectoryPath,
                                                          withIntermediateDirectories: false,
                                                          attributes: nil)
                        
                        #if DEBUG_PRINT_FUNCCALLS
                        print("handleRKIShapeData(): just created mapData directory")
                        #endif
                        
                    } catch let error  {
                        
                        GlobalStorage.unique.storeLastError(errorText: "handleRKIShapeData(): creation of mapData directory failed, do nothing, error: \"\(error)\"")
                        
                        return
                    }
                    
                } else {
                    
                    #if DEBUG_PRINT_FUNCCALLS
                    print("handleRKIShapeData(): mapData directory exists")
                    #endif
                }
                
                
                // ---------------------------------------------------------------------------------
                // handle obsolete files

                // if we got here, we have a valid map data directory
                
                // check if we have outdated files in that directory.
                // use the array of obsolete files
                for index in 0 ..< self.mapDataOldFilenamesToDelete.count {
                    
                    let oldMapFilePath = mapDataDirectoryPath + "/" + self.mapDataOldFilenamesToDelete[index]
                    
                    if myFileManager.fileExists(atPath: oldMapFilePath) == true {
                        
                        // delete the file
                        do {
                            try myFileManager.removeItem(atPath: oldMapFilePath)
                            
                        } catch let error as NSError {
                            
                            // something went wrong
                            GlobalStorage.unique.storeLastError(errorText: "handleRKIShapeData(): ERROR deleting old mapFile \"\(self.mapDataOldFilenamesToDelete[index])\": \(error.description)")
                        }
                    }
                }
                
                
                // ---------------------------------------------------------------------------------
                // handle county data
                
                // now look for the current file
                let mapDataCountyShapePath = mapDataDirectoryPath + "/" + self.mapDataCurrentFilenameCountyShapes
                
                if myFileManager.fileExists(atPath: mapDataCountyShapePath) == true {
                    
                    // read the file
                    do {
                        
                        #if DEBUG_PRINT_FUNCCALLS
                        let start = CFAbsoluteTimeGetCurrent()
                        #endif
                        
                        let fileURL = URL(fileURLWithPath: mapDataCountyShapePath)
                        let myData = try Data(contentsOf: fileURL)
                        self.RKIMapCountyData = try JSONDecoder().decode([RKIMapDataStruct].self,
                                                                 from: myData)
                        
                        #if DEBUG_PRINT_FUNCCALLS
                        let end = CFAbsoluteTimeGetCurrent()
                        let duration = (end - start)
                        print("handleRKIShapeData(): done in \(duration) sec! Will call self.buildCountyShapeOverlays()")
                        #endif
                        
                        self.buildCountyShapeOverlays()
                        
                    } catch let error as NSError {
                        
                        // encode did fail, log the message
                        GlobalStorage.unique.storeLastError(errorText: "handleRKIShapeData(): Error: JSON dencoder could not dencode RKIMapCountyData or read from file failed: error: \"\(error.description)\"")
                    }
                    
                } else {
                    
                    GlobalStorage.unique.storeLastError(errorText: "handleRKIShapeData(): no local county data file, try to get the data from RKI, call getRKIData(from: 2, until: 2)")
                    
                    // get fresh data
                    RKIDataDownload.unique.getRKIData(from: 2, until: 2)
                }
                
                
                // ---------------------------------------------------------------------------------
                // handle state data
                
                // now look for the current file
                let mapDataStateShapePath = mapDataDirectoryPath + "/" + self.mapDataCurrentFilenameStateBorders
                
                if myFileManager.fileExists(atPath: mapDataStateShapePath) == true {
                    
                    // read the file
                    do {
                        
                        #if DEBUG_PRINT_FUNCCALLS
                        let start = CFAbsoluteTimeGetCurrent()
                        #endif
                        
                        let fileURL = URL(fileURLWithPath: mapDataStateShapePath)
                        let myData = try Data(contentsOf: fileURL)
                        self.RKIMapStateData = try JSONDecoder().decode([RKIMapDataStruct].self,
                                                                 from: myData)
                        
                        #if DEBUG_PRINT_FUNCCALLS
                        let end = CFAbsoluteTimeGetCurrent()
                        let duration = (end - start)
                        print("handleRKIShapeData(): done in \(duration) sec! Will call self.buildCountyShapeOverlays()")
                        #endif
                        
                        self.buildStateBorderOverlays()
                        
                    } catch let error as NSError {
                        
                        // encode did fail, log the message
                        GlobalStorage.unique.storeLastError(errorText: "handleRKIShapeData(): Error: JSON dencoder could not dencode RKIMapCountyData or read from file failed: error: \"\(error.description)\"")
                    }
                    
                } else {
                    
                    GlobalStorage.unique.storeLastError(errorText: "handleRKIShapeData(): no local state data file, try to get the data from RKI, call getRKIData(from: 3, until: 3)")
                    
                    // get fresh data
                    RKIDataDownload.unique.getRKIData(from: 3, until: 3)
                }
                
                
 
                
                
                
            } else {
                
                // no app support directory
                GlobalStorage.unique.storeLastError(errorText: "handleRKIShapeData(): ERROR: did not get a valid diretory for \".applicationSupportDirectory\", do nothing")
            }
        })
    }
    
    /**
     -----------------------------------------------------------------------------------------------
     
     Builds the shape overlays for the counties
     
     -----------------------------------------------------------------------------------------------
     */
    private func buildCountyShapeOverlays() {
        
        GlobalStorageQueue.async(flags: .barrier, execute: {
            
            // check if we really have to do something
            if self.RKIMapCountyData.isEmpty == false {
                
                #if DEBUG_PRINT_FUNCCALLS
                print("buildCountyShapeOverlays(): just started, RKIMapCountyData has \(self.RKIMapCountyData.count) elements")
                #endif
                
//                // remove all old data
//                self.RKIMapOverlays.removeAll()
//                self.RKIMapAreaAndBorderData.removeAll()
                
                // shortcut for the index of the county data
                let typeIndex = GlobalStorage.unique.RKIDataCounty
                
                // loop over the shape array
                for index in 0 ..< self.RKIMapCountyData.count {
                    
                    // get a shortcut for the current element of RKIMapCountyData[]
                    let item = self.RKIMapCountyData[index]
                    let myID = item.myID
                    
                    // in any case append an empty array, to keep index areaDataIndex in sync
                    self.RKIMapAreaAndBorderData.append([])
                    let indexInAABData = self.RKIMapAreaAndBorderData.count - 1

                    // check if we have a corresponding county item
                    if let indexInRKIData = GlobalStorage.unique.RKIData[typeIndex][0].firstIndex(where: { $0.myID == myID } ) {
                        // we found a valid record, so we can build the overlay
                        
                        // build the needed values
                        let centerCoordinate = CLLocationCoordinate2D(latitude:  item.centerLatitude,
                                                                      longitude: item.centerLongitude)
                        
                        let boundingRectangle = MKMapRect(x:      item.boundingRectOriginX,
                                                          y:      item.boundingRectOriginY,
                                                          width:  item.boundingRectSizeWidth,
                                                          height: item.boundingRectSizeHeight)
                        
                        // build the overlay
                        let newOverlay = RKIMapOverlay(type: .countyArea,
                                                       myID: item.myID,
                                                       dayIndex: 0,
                                                       areaDataIndex: indexInAABData,
                                                       map: nil,
                                                       center: centerCoordinate,
                                                       rect: boundingRectangle)
                        
                        // convert the raw area data in ringsX / ringsY in MKMapPoints and store them in RKIMapAreaAndBorderData
                        
                        // now loop ofer ringsX/Y and build the mapPoints
                        if item.ringsX.isEmpty == false {
                            
                            // loop over each ring
                            for outerLoop in 0 ..< item.ringsX.count {
                                
                                // prepare an empty array
                                self.RKIMapAreaAndBorderData[indexInAABData].append([])

                                // check bounds
                                if item.ringsX[outerLoop].isEmpty == false {
                                    
                                    // loop over ring elements
                                    for innerLoop in 0 ..< item.ringsX[outerLoop].count {
                                        
                                        let newMKMapPoint = MKMapPoint(x: item.ringsX[outerLoop][innerLoop],
                                                                       y: item.ringsY[outerLoop][innerLoop])
                                        
                                        self.RKIMapAreaAndBorderData[indexInAABData][outerLoop].append(newMKMapPoint)
                                    }
                                }
                            }
                        }
                        
                        // append to the array of overlays
                        self.RKIMapOverlays.append(newOverlay)
                        
                        let newAnnotation = CountyAnnotation(
                            countyID: item.myID,
                            title: item.name,
                            subTitle: GlobalStorage.unique.RKIData[typeIndex][0][indexInRKIData].kindOf,
                            coordinate: centerCoordinate)
                        
                        self.RKIMapAnnotations.append(newAnnotation)
                        

                    } // found county
                } // loop
                
                // set the flag
                self.RKIMapOverlaysBuild = true
                
                // the map might have to be redrawn, so we send a notification
                DispatchQueue.main.async(execute: {
                    NotificationCenter.default.post(Notification(name: .CoBaT_Map_OverlaysBuild))
                })
                
                #if DEBUG_PRINT_FUNCCALLS
                print("buildCountyShapeOverlays just posted .CoBaT_Map_OverlaysBuild")
                #endif
                
            } else {
                
                #if DEBUG_PRINT_FUNCCALLS
                print("buildCountyShapeOverlays(): just started,RKIMapCountyData.isEmpty == false, do nothing")
                #endif
            }
        })
    }
    
    /**
     -----------------------------------------------------------------------------------------------
     
     Builds the shape overlays for the states
     
     -----------------------------------------------------------------------------------------------
     */
    private func buildStateBorderOverlays() {
        
        GlobalStorageQueue.async(flags: .barrier, execute: {
            
            // check if we really have to do something
            if self.RKIMapStateData.isEmpty == false {
                
                #if DEBUG_PRINT_FUNCCALLS
                print("buildStateBorderOverlays(): just started, RKIMapCountyData has \(self.RKIMapStateData.count) elements")
                #endif
                
//                // remove all old data
//                self.RKIMapOverlays.removeAll()
//                self.RKIMapAreaAndBorderData.removeAll()
                
                // shortcut for the index of the county data
                let typeIndex = GlobalStorage.unique.RKIDataState
                
                // loop over the shape array
                for index in 0 ..< self.RKIMapStateData.count {
                    
                    // get a shortcut for the current element of RKIMapCountyData[]
                    let item = self.RKIMapStateData[index]
                    let myID = item.myID
                    
                    // in any case append an empty array, to keep index areaDataIndex in sync
                    self.RKIMapAreaAndBorderData.append([])
                    let indexInAABData = self.RKIMapAreaAndBorderData.count - 1

                    // check if we have a corresponding county item
                    if let _ = GlobalStorage.unique.RKIData[typeIndex][0].firstIndex(where: { $0.myID == myID } ) {
                        // we found a valid record, so we can build the overlay
                        
                        // build the needed values
                        let centerCoordinate = CLLocationCoordinate2D(latitude:  item.centerLatitude,
                                                                      longitude: item.centerLongitude)
                        
                        let boundingRectangle = MKMapRect(x:      item.boundingRectOriginX,
                                                          y:      item.boundingRectOriginY,
                                                          width:  item.boundingRectSizeWidth,
                                                          height: item.boundingRectSizeHeight)
                        
                        // build the overlay
                        let newOverlay = RKIMapOverlay(type: .stateBorder,
                                                       myID: item.myID,
                                                       dayIndex: 0,
                                                       areaDataIndex: indexInAABData,
                                                       map: nil,
                                                       center: centerCoordinate,
                                                       rect: boundingRectangle)
                        
                        // convert the raw area data in ringsX / ringsY in MKMapPoints and store them in RKIMapAreaAndBorderData
                        
                        // now loop ofer ringsX/Y and build the mapPoints
                        if item.ringsX.isEmpty == false {
                            
                            // loop over each ring
                            for outerLoop in 0 ..< item.ringsX.count {
                                
                                // prepare an empty array
                                self.RKIMapAreaAndBorderData[indexInAABData].append([])

                                // check bounds
                                if item.ringsX[outerLoop].isEmpty == false {
                                    
                                    // loop over ring elements
                                    for innerLoop in 0 ..< item.ringsX[outerLoop].count {
                                        
                                        let newMKMapPoint = MKMapPoint(x: item.ringsX[outerLoop][innerLoop],
                                                                       y: item.ringsY[outerLoop][innerLoop])
                                        
                                        self.RKIMapAreaAndBorderData[indexInAABData][outerLoop].append(newMKMapPoint)
                                    }
                                }
                            }
                        }
                        
                        
                        // append to the array of overlays
                        self.RKIMapOverlays.append(newOverlay)
                        
                        
                    } // found county
                } // loop
                
                // set the flag
                self.RKIMapOverlaysBuild = true
                
                // the map might have to be redrawn, so we send a notification
                DispatchQueue.main.async(execute: {
                    NotificationCenter.default.post(Notification(name: .CoBaT_Map_OverlaysBuild))
                })
                
                #if DEBUG_PRINT_FUNCCALLS
                print("buildStateBorderOverlays just posted .CoBaT_Map_OverlaysBuild")
                #endif
                
            } else {
                
                #if DEBUG_PRINT_FUNCCALLS
                print("buildStateBorderOverlays(): just started,RKIMapCountyData.isEmpty == false, do nothing")
                #endif
            }
        })
    }
    
    
    
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
                        
            // prepare the map data
            self.handleRKIShapeData()

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
     
     save new data of county shapes for the map to the local file and call
     
     -----------------------------------------------------------------------------------------------
     */
    public func saveNewCountyShapeData() {
        
        GlobalStorageQueue.async(flags: .barrier, execute: {
            
            // Instance of a private filemanager
            let myFileManager = FileManager.default
            
            // get the application support directory
            if let applicationSupportDirectoryURL = myFileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                
                let applicationSupportDirectoryPath:String = applicationSupportDirectoryURL.path
                //myFileManager.changeCurrentDirectoryPath(homeDirectoryPath)
                
                // check if we have to create the directory
                if myFileManager.fileExists(atPath: applicationSupportDirectoryPath) == false {
                    
                    // does not exist, so create it
                    do {
                        try myFileManager.createDirectory(atPath: applicationSupportDirectoryPath,
                                                          withIntermediateDirectories: false,
                                                          attributes: nil)
                        
                        GlobalStorage.unique.storeLastError(errorText: "saveNewCountyShapeData(): just created .applicationSupportDirectory")
                        
                    } catch let error  {
                        
                        GlobalStorage.unique.storeLastError(errorText: "saveNewCountyShapeData(): creation of .applicationSupportDirectory directory failed, error: \"\(error)\", return")
                        
                        return
                    }
                    
                } else {
                    
                    #if DEBUG_PRINT_FUNCCALLS
                    print("saveNewCountyShapeData(): .applicationSupportDirectory exists")
                    #endif
                }
                
                // build the path of the placemark directory
                let mapDataDirectoryPath = applicationSupportDirectoryPath + "/" + self.mapDataDirectory
                
                // check if we have to create the directory
                if myFileManager.fileExists(atPath: mapDataDirectoryPath) == false {
                    
                    // does not exist, so create it
                    do {
                        try myFileManager.createDirectory(atPath: mapDataDirectoryPath,
                                                          withIntermediateDirectories: false,
                                                          attributes: nil)
                        
                        #if DEBUG_PRINT_FUNCCALLS
                        print("saveNewCountyShapeData(): just created mapData directory")
                        #endif
                        
                    } catch let error  {
                        
                        GlobalStorage.unique.storeLastError(errorText: "saveNewCountyShapeData(): creation of mapData directory failed, error: \"\(error)\"")
                    }
                    
                } else {
                    
                    #if DEBUG_PRINT_FUNCCALLS
                    print("saveNewCountyShapeData(): mapData directory exists")
                    #endif
                }
                
                // check if an old file exist, if so, remove it
                let mapDataCountyShapePath = mapDataDirectoryPath + "/" + self.mapDataCurrentFilenameCountyShapes
                
                if myFileManager.fileExists(atPath: mapDataCountyShapePath) == true {
                    
                    // delete the file
                    do {
                        try myFileManager.removeItem(atPath: mapDataCountyShapePath)
                        
                    } catch let error as NSError {
                        
                        // something went wrong
                        GlobalStorage.unique.storeLastError(errorText: "saveNewCountyShapeData(): ERROR deleting old mapFile: \(error.description)")
                    }
                }
                
                // try to save the data
                do {
                    // try to encode the county data and the timeStamps
                    let encodedMapData = try JSONEncoder().encode(self.RKIMapCountyData)
                    
                    let fileURL = URL(fileURLWithPath: mapDataCountyShapePath)
                    // if we got to here, no errors encountered, so store it
                    try encodedMapData.write(to: fileURL)
                    
                    #if DEBUG_PRINT_FUNCCALLS
                    print("saveNewCountyShapeData(): done! Will call self.buildCountyShapeOverlays()")
                    #endif
                    
                    self.buildCountyShapeOverlays()
                    
                } catch let error as NSError {
                    
                    // encode did fail, log the message
                    GlobalStorage.unique.storeLastError(errorText: "saveNewCountyShapeData(): Error: JSON encoder could not encode RKIMapCountyData or write to file failed: error: \"\(error.description)\"")
                }
                
                
            } else {
                
                // no app support directory
                GlobalStorage.unique.storeLastError(errorText: "saveNewCountyShapeData(): ERROR: did not get a valid diretory for \".applicationSupportDirectory\", do nothing")
            }
        })
        
    }
    

    
    /**
     -----------------------------------------------------------------------------------------------
     
     save new data of state border for the map to the local file and call
     
     -----------------------------------------------------------------------------------------------
     */
    public func saveNewStateBorderData() {
        
        GlobalStorageQueue.async(flags: .barrier, execute: {
            
            // Instance of a private filemanager
            let myFileManager = FileManager.default
            
            // get the application support directory
            if let applicationSupportDirectoryURL = myFileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                
                let applicationSupportDirectoryPath:String = applicationSupportDirectoryURL.path
                //myFileManager.changeCurrentDirectoryPath(homeDirectoryPath)
                
                // check if we have to create the directory
                if myFileManager.fileExists(atPath: applicationSupportDirectoryPath) == false {
                    
                    // does not exist, so create it
                    do {
                        try myFileManager.createDirectory(atPath: applicationSupportDirectoryPath,
                                                          withIntermediateDirectories: false,
                                                          attributes: nil)
                        
                        GlobalStorage.unique.storeLastError(errorText: "saveNewStateBorderData(): just created .applicationSupportDirectory")
                        
                    } catch let error  {
                        
                        GlobalStorage.unique.storeLastError(errorText: "saveNewStateBorderData(): creation of .applicationSupportDirectory directory failed, error: \"\(error)\", return")
                        
                        return
                    }
                    
                } else {
                    
                    #if DEBUG_PRINT_FUNCCALLS
                    print("saveNewStateBorderData(): .applicationSupportDirectory exists")
                    #endif
                }
                
                // build the path of the placemark directory
                let mapDataDirectoryPath = applicationSupportDirectoryPath + "/" + self.mapDataDirectory
                
                // check if we have to create the directory
                if myFileManager.fileExists(atPath: mapDataDirectoryPath) == false {
                    
                    // does not exist, so create it
                    do {
                        try myFileManager.createDirectory(atPath: mapDataDirectoryPath,
                                                          withIntermediateDirectories: false,
                                                          attributes: nil)
                        
                        #if DEBUG_PRINT_FUNCCALLS
                        print("saveNewStateBorderData(): just created mapData directory")
                        #endif
                        
                    } catch let error  {
                        
                        GlobalStorage.unique.storeLastError(errorText: "saveNewStateBorderData(): creation of mapData directory failed, error: \"\(error)\"")
                    }
                    
                } else {
                    
                    #if DEBUG_PRINT_FUNCCALLS
                    print("saveNewStateBorderData(): mapData directory exists")
                    #endif
                }
                
                // check if an old file exist, if so, remove it
                let mapDataStateBorderPath = mapDataDirectoryPath + "/" + self.mapDataCurrentFilenameStateBorders
                
                if myFileManager.fileExists(atPath: mapDataStateBorderPath) == true {
                    
                    // delete the file
                    do {
                        try myFileManager.removeItem(atPath: mapDataStateBorderPath)
                        
                    } catch let error as NSError {
                        
                        // something went wrong
                        GlobalStorage.unique.storeLastError(errorText: "saveNewStateBorderData(): ERROR deleting old mapFile: \(error.description)")
                    }
                }
                
                // try to save the data
                do {
                    // try to encode the county data and the timeStamps
                    let encodedMapData = try JSONEncoder().encode(self.RKIMapStateData)
                    
                    let fileURL = URL(fileURLWithPath: mapDataStateBorderPath)
                    
                    // if we got to here, no errors encountered, so store it
                    try encodedMapData.write(to: fileURL)
                    
                    #if DEBUG_PRINT_FUNCCALLS
                    print("saveNewStateBorderData(): done! Will call self.buildCountyShapeOverlays()")
                    #endif
                    
                    self.buildStateBorderOverlays()
                    
                } catch let error as NSError {
                    
                    // encode did fail, log the message
                    GlobalStorage.unique.storeLastError(errorText: "saveNewStateBorderData(): Error: JSON encoder could not encode RKIMapStateData or write to file failed: error: \"\(error.description)\"")
                }

                
            } else {
                
                // no app support directory
                GlobalStorage.unique.storeLastError(errorText: "saveNewStateBorderData(): ERROR: did not get a valid diretory for \".applicationSupportDirectory\", do nothing")
            }
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
