//
//  RKI Data Download.swift
//  CoBaT
//
//  Created by Hartwig Hopfenzitz on 24.11.20.
//

//
// calls the RKI data server, decode the JSON and stores the retrieved data into global storage
//

import Foundation
import MapKit

// -------------------------------------------------------------------------------------------------
// MARK: -
// MARK: - RKI Data Download
// -------------------------------------------------------------------------------------------------
final class RKIDataDownload: NSObject {
    
    // ---------------------------------------------------------------------------------------------
    // MARK: - Singleton
    // ---------------------------------------------------------------------------------------------
    static let unique = RKIDataDownload()
    
    // ---------------------------------------------------------------------------------------------
    // MARK: - RKI Data Tab
    // ---------------------------------------------------------------------------------------------
    //
    // The methode getRKIData() will walk over this array and calls the URL For each item.
    //
    private struct RKI_DataTabStruct {
        let RKI_DataType: GlobalStorage.RKI_DataTypeEnum
        let URL_String: String
        
        init(_ dataType:  GlobalStorage.RKI_DataTypeEnum, _ URLString: String) {
            self.RKI_DataType = dataType
            self.URL_String = URLString
        }
    }
    
    private let RKI_DataTab: [RKI_DataTabStruct] = [
        
        RKI_DataTabStruct(.county,  "https://services7.arcgis.com/mOBPykOjAyBO2ZKk/arcgis/rest/services/RKI_Landkreisdaten/FeatureServer/0/query?where=1%3D1&outFields=*&returnGeometry=false&outSR=4326&f=json"),
        
        RKI_DataTabStruct(.state, "https://services7.arcgis.com/mOBPykOjAyBO2ZKk/arcgis/rest/services/Coronaf%C3%A4lle_in_den_Bundesl%C3%A4ndern/FeatureServer/0/query?where=1%3D1&outFields=*&returnGeometry=false&outSR=4326&f=json"),
        
        RKI_DataTabStruct(.countyShape, "https://services7.arcgis.com/mOBPykOjAyBO2ZKk/arcgis/rest/services/RKI_Landkreisdaten/FeatureServer/0/query?where=1%3D1&outFields=OBJECTID,Shape__Area,Shape__Length,GEN&outSR=4326&f=json"),
        
        RKI_DataTabStruct(.stateBorder, "https://services7.arcgis.com/mOBPykOjAyBO2ZKk/arcgis/rest/services/Coronaf%C3%A4lle_in_den_Bundesl%C3%A4ndern/FeatureServer/0/query?where=1%3D1&outFields=OBJECTID_1,Shape__Area,Shape__Length,LAN_ew_GEN&outSR=4326&f=json")

       //,
        
//        RKI_DataTabStruct(.age, "https://services7.arcgis.com/mOBPykOjAyBO2ZKk/arcgis/rest/services/RKI_COVID19/FeatureServer/0/query?where=IdLandkreis%20%3D%20'01001'&outFields=*&outSR=4326&f=json")
    ]
    
    // ---------------------------------------------------------------------------------------------
    // MARK: - RKI data API
    // ---------------------------------------------------------------------------------------------
    /**
     -----------------------------------------------------------------------------------------------
     
     Walks through the array "RKI_DataTab" of this class, calls the related URLs and calls handleRKIContent() if valid data recieved
     
     -----------------------------------------------------------------------------------------------
     - Parameters:
        - from:  startIndex in RKI_DataTab[]
        - until: endIndex in RKI_DataTab[]
     - Returns: nothing
     */
    public func getRKIData(from: Int, until: Int) {
        
        #if DEBUG_PRINT_FUNCCALLS
        print("getRKIData just started with from: \(from), until: \(until)")
        #endif
        
        // walk over the array with the configurations
        for loopIndex in from ... until {
            
            let singleDataSet = RKI_DataTab[loopIndex]
            
            // build a valid URL
            if let url = URL(string: singleDataSet.URL_String) {
                
                // build the task and define the completion handler
                let task = URLSession.shared.dataTask(
                    with: url,
                    completionHandler: { data, response, error in
                        
                        #if DEBUG_PRINT_FUNCCALLS
                        print("getRKIData.completionHandler just started")
                        #endif
                        
                        // check if there are errors
                        if error == nil {
                            
                            // no errors, go ahead
                            
                            // check if we have a valid HTTP response
                            if let httpResponse = response as? HTTPURLResponse {
                                
                                // check if we have a a good status (codes from 200 to 299 are always good
                                if (200...299).contains(httpResponse.statusCode) == true {
                                    
                                    // good status, go ahead
                                    
                                    // check if we have a mimeType
                                    if let mimeType = httpResponse.mimeType {
                                        
                                        // check the mime type
                                        if mimeType == "application/json" {
                                            
                                            // right mime type, go ahead
                                            
                                            // check the data
                                            if data != nil {
                                                
                                                // we have data, go ahead
                                                
                                                // convert it to string and print it (used for testing AND
                                                // for quickType webside to generate the "JSON RKI ....swift" files
                                                // print("\(String(data: data!, encoding: .utf8) ?? "Convertion data to string failed")")
                                                
                                                // handle the content
                                                self.handleRKIContent(data!, singleDataSet.RKI_DataType)
                                                
                                            } else {
                                                
                                                // no valid data, log message and return
                                                GlobalStorage.unique.storeLastError(
                                                    errorText: "CoBaT.RKIDataDownload.getRKIData: Error: URLSession.dataTask, no valid data, return")
                                                return
                                            }
                                            
                                        } else {
                                            
                                            // not the right mimeType, log message and return
                                            GlobalStorage.unique.storeLastError(
                                                errorText: "CoBaT.RKIDataDownload.getRKIData: Error: URLSession.dataTask, wrong mimeType (\"\(mimeType)\" instead of \"application/json\"), return")
                                            return
                                        }
                                        
                                    } else {
                                        
                                        // no valid mimeType, log message and return
                                        GlobalStorage.unique.storeLastError(
                                            errorText: "CoBaT.RKIDataDownload.getRKIData: Error: URLSession.dataTask, no mimeType in response, return")
                                        return
                                    }
                                    
                                } else {
                                    
                                    // not a good status, log message and return
                                    GlobalStorage.unique.storeLastError(
                                        errorText: "CoBaT.RKIDataDownload.getRKIData: Server responded with error status: \(httpResponse.statusCode), return")
                                    return
                                }
                                
                            } else {
                                
                                // no valid response, log message and return
                                GlobalStorage.unique.storeLastError(
                                    errorText: "CoBaT.RKIDataDownload.getRKIData: Error: URLSession.dataTask has no valid HTTP response, return")
                                return
                            }
                            
                        } else {
                            
                            // error is not nil, check if error code is valid
                            if let myError = error  {
                                
                                // valid errorCode, call the handler and return
                                GlobalStorage.unique.storeLastError(
                                    errorText: "CoBaT.RKIDataDownload.getRKIData: handleServerError(), \(myError.localizedDescription)")
                                return
                                
                            } else {
                                
                                // no valid error code, log message and return
                                GlobalStorage.unique.storeLastError(
                                    errorText: "CoBaT.RKIDataDownload.getRKIData: Error: URLSession.dataTask came back with error which is not nil, but no valid errorCode, return")
                                return
                            }
                        }
                    })
                
                // start the task
                task.resume()
                
            } else {
                
                // no valid URL, log message and return
                GlobalStorage.unique.storeLastError(
                    errorText: "CoBaT.RKIDataDownload.getRKIData: Error: URLSession.dataTask came back with error which is not nil, but no valid errorCode, return")
                return
            }
        }
    }
    
    
    // ---------------------------------------------------------------------------------------------
    // MARK: - internal helper methodes
    // ---------------------------------------------------------------------------------------------
    /**
     -----------------------------------------------------------------------------------------------
     
     Decodes the JSON data and stores it into global storage
     
     -----------------------------------------------------------------------------------------------
     
     - Parameters:
        - data: prepared JSON data
        - RKI_DataType: enum what kind of data is provided
     
     - Returns: nothing
     */

    private func handleRKIContent( _ data: Data, _ RKI_DataType:  GlobalStorage.RKI_DataTypeEnum) {
        
        #if DEBUG_PRINT_FUNCCALLS
        print("handleRKIContent just started")
        #endif
        
        do {
                    
            switch RKI_DataType {
            
            // -------------------------------------------------------------------------------------
            case .county:
                
                #if DEBUG_PRINT_FUNCCALLS
                print("handleRKIContent County")
                #endif
                
                let countyData = try newJSONDecoder().decode(RKI_County_JSON.self, from: data)
                
                #if DEBUG_PRINT_FUNCCALLS
                print("handleRKIContent after decoding")
                #endif
                
                if countyData.features.isEmpty == false {
                    
                    // this will store the final timestamp
                    let updateDate : Date
                    
                    // get the first item as a refernce for the
                    let firstItem = countyData.features.first!
                    
                    // try to convert the string into a Date() object
                    if let myDate = RKIDateFormatter.date(from:firstItem.attributes.lastUpdate) {
                        
                        // success: so we can use that
                        updateDate = myDate
                        
                    } else {
                        
                        // failed: take the current timestamp as the timestamp and report it
                        updateDate = Date()
                        
                        GlobalStorage.unique.storeLastError(
                            errorText: "CoBaT.RKIDataDownload.handleRKIContent.County: Error: could not get updateDate from \"\(firstItem.attributes.lastUpdate)\", use current date \"\(updateDate)\" instead"
                        )
                    }
                    
                    
                    // we will provide an array of converted values
                    var newDataArray: [GlobalStorage.RKIDataStruct] = []
                    
                    // Walk over data and build array
                    for singleItem in countyData.features {
                        
                        //print("RKI County Date: \"\(singleItem.attributes.lastUpdate)\"")
                        
                        // RKI reports the timestamp as a formatted string, so we have to convert that
                        // by means of a formatter (see Formatters.swift"
                        
                        //                        // this will store the final timestamp
                        //                        let updateDate : Date
                        //
                        //                        // try to convert the string into a Date() object
                        //                        if let myDate = RKIDateFormatter.date(from:singleItem.attributes.lastUpdate) {
                        //
                        //                            // success: so we can use that
                        //                            updateDate = myDate
                        //
                        //                        } else {
                        //
                        //                            // failed: take the current timestamp as the timestamp and report it
                        //                            updateDate = Date()
                        //
                        //                            GlobalStorage.unique.storeLastError(
                        //                                errorText: "CoBaT.RKIDataDownload.handleRKIContent.County: Error: could not get updateDate from \"\(singleItem.attributes.lastUpdate)\", use current date \"\(updateDate)\" instead"
                        //                            )
                        //                        }
                        //
                        //print("State Update Date: \(shortSingleDateTimeFormatter.string(from: updateDate)), RKI:\(shortSingleDateFormatterRKI.string(from: updateDate))")
                        
                        let noonTime = GlobalStorage.unique.getMidnightTimeInterval(time: updateDate.timeIntervalSinceReferenceDate)
                        // append the new data
                        newDataArray.append(GlobalStorage.RKIDataStruct(
                                                stateID: singleItem.attributes.blid,
                                                myID: "\(singleItem.attributes.objectid)",
                                                name: singleItem.attributes.gen,
                                                kindOf: singleItem.attributes.bez.rawValue,
                                                inhabitants: singleItem.attributes.ewz,
                                                cases: singleItem.attributes.cases,
                                                deaths: singleItem.attributes.deaths,
                                                casesPer100k: singleItem.attributes.casesPer100K,
                                                cases7DaysPer100K: singleItem.attributes.cases7Per100K,
                                                timeStamp: noonTime))
                    }
                    
                    
                    // refresh our global storage
                    GlobalStorage.unique.refresh_RKICountyData(newRKICountyData: newDataArray)
                    
                    // save it to iCloud
                    iCloudService.unique.saveRKIData(RKI_DataType: RKI_DataType,
                                                     time: updateDate.timeIntervalSinceReferenceDate,
                                                     data: data)
                    
                } else {
                    
                    GlobalStorage.unique.storeLastError(
                        errorText: "CoBaT.RKIDataDownload.handleRKIContent: county data were empty, do nothingn")
                }
                
                #if DEBUG_PRINT_FUNCCALLS
                print("handleRKIContent County done")
                #endif
                
            // -------------------------------------------------------------------------------------
            case .state:
                
                #if DEBUG_PRINT_FUNCCALLS
                print("handleRKIContent State")
                #endif
                
                let stateData = try newJSONDecoder().decode(RKI_State_JSON.self, from: data)
                
                
                #if DEBUG_PRINT_FUNCCALLS
                print("handleRKIContent after decoding")
                #endif
                
                
                if stateData.features.isEmpty == false {
                    
                    
                    // get the first item as a refernce for the
                    let firstItem = stateData.features.first!
                    
                    // RKI reports the timestamp as milliseconds since 1970, so we have to convert
                    let secondsSince1970: TimeInterval = TimeInterval(Double(firstItem.attributes.aktualisierung) / 1_000)
                    let lastUpdateRKI: Date = Date(timeIntervalSince1970: secondsSince1970)
                    let lastUpdateTimeInterval: TimeInterval = lastUpdateRKI.timeIntervalSinceReferenceDate
                    let noonTime = GlobalStorage.unique.getMidnightTimeInterval(time: lastUpdateTimeInterval)
                    
                    // we will provide an array of converted values
                    var newDataArray: [GlobalStorage.RKIDataStruct] = []
                    
                    // walk over new data
                    for singleItem in stateData.features {
                        
                        // let lastUpdate: Date = Date(timeIntervalSinceReferenceDate: lastUpdateTimeInterval)
                        //print("State Update Date: \(shortSingleDateTimeFormatter.string(from: lastUpdate)), RKI:\(shortSingleDateFormatterRKI.string(from: lastUpdate))")
                        
                        // store the new data
                        newDataArray.append(GlobalStorage.RKIDataStruct(
                                                stateID: "\(singleItem.attributes.objectid1)",
                                                myID: "\(singleItem.attributes.objectid1)",
                                                name: singleItem.attributes.lanEwgen,
                                                kindOf: singleItem.attributes.lanEwbez,
                                                inhabitants: singleItem.attributes.lanEwewz,
                                                cases: singleItem.attributes.fallzahl,
                                                deaths: singleItem.attributes.death,
                                                casesPer100k: singleItem.attributes.faelle100000_ew,
                                                cases7DaysPer100K: singleItem.attributes.cases7BlPer100K,
                                                timeStamp: noonTime))
                        
                    }
                    
                    // store it in global storage
                    GlobalStorage.unique.refresh_RKIStateData(newRKIStateData: newDataArray)
                    
                    // save it to iCloud
                    iCloudService.unique.saveRKIData(RKI_DataType: RKI_DataType,
                                                     time: lastUpdateTimeInterval,
                                                     data: data)
                    
                } else {
                    
                    GlobalStorage.unique.storeLastError(
                        errorText: "CoBaT.RKIDataDownload.handleRKIContent: state data were empty, do nothingn")
                }
                
                #if DEBUG_PRINT_FUNCCALLS
                print("handleRKIContent State done")
                #endif
                
            // -------------------------------------------------------------------------------------
            case .age:
                
                #if DEBUG_PRINT_FUNCCALLS
                print("handleRKIContent Age Start")
                #endif
                
                
                let ageData = try newJSONDecoder().decode(RKI_Age_RKIAgeDeviation.self, from: data)
                
                let filtered = ageData.features.filter( { $0.attributes.idLandkreis == "01001" } )
                let sorted = filtered.sorted(by: {$0.attributes.altersgruppe.rawValue < $1.attributes.altersgruppe.rawValue})
                for item in sorted {
                    print ("\(item.attributes.altersgruppe.rawValue): Fall: \(item.attributes.anzahlFall), tot: \(item.attributes.anzahlTodesfall), genesen: \(item.attributes.anzahlGenesen)")
                }
                print(sorted)
                
                
                
                #if DEBUG_PRINT_FUNCCALLS
                print("handleRKIContent after decoding")
                #endif
                
                
                
                #if DEBUG_PRINT_FUNCCALLS
                print("handleRKIContent Age Done")
                #endif
                
                
            // -------------------------------------------------------------------------------------
            case .countyShape:
                
                #if DEBUG_PRINT_FUNCCALLS
                print("handleRKIContent CountyShape")
                #endif
                
                let countyShapeData = try newJSONDecoder().decode(RKI_CS_CountyShapeJSON.self, from: data)
                
                #if DEBUG_PRINT_FUNCCALLS
                print("handleRKIContent after decoding")
                #endif
                
                if countyShapeData.features.isEmpty == false {
                    
                    // clean the old data
                    GlobalUIData.unique.RKIMapCountyData.removeAll()
                    
                    // loop over data
                    for dataIndex in 0 ..< countyShapeData.features.count {
                        
                        // get the next item as a reference for the current item
                        let currentItem = countyShapeData.features[dataIndex]
                        
                        // get the main data
                        let myID = currentItem.attributes.objectid
                        let name = currentItem.attributes.gen
                        let rings = currentItem.geometry.rings
                        
                        // check if we have something todo
                        if rings.isEmpty == false {
                            
                             
                            // prepare the min / max variables to find the bounding rectangle
                            var minX: Double = Double.greatestFiniteMagnitude
                            var maxX: Double = 0.0
                            
                            var minY: Double = Double.greatestFiniteMagnitude
                            var maxY: Double = 0.0
                            
                            // prepare the data arrays
                            var ringsResultX: [[Double]] = []
                            var ringsResultY: [[Double]] = []
                            
                            // read and convert the shape data
                            // loop over the first index of rings[[]]
                            for outerIndex in 0 ..< rings.count {
                                
                                // append an empty array for the data
                                ringsResultX.append([])
                                ringsResultY.append([])
                                
                                // loop over the second index of rings[[]]
                                for innerIndex in 0 ..< rings[outerIndex].count {
                                    
                                    // first step convert the GPS coordinate into a MKMapPoint
                                    let currentMKPoint = MKMapPoint(CLLocationCoordinate2D(
                                                                        latitude:  rings[outerIndex][innerIndex][1],
                                                                        longitude: rings[outerIndex][innerIndex][0]))
                                    
                                    // store it into the array
                                    ringsResultX[outerIndex].append(currentMKPoint.x)
                                    ringsResultY[outerIndex].append(currentMKPoint.y)
                                    
                                    // calculate min and max values
                                    minX = min(minX, currentMKPoint.x)
                                    minY = min(minY, currentMKPoint.y)
                                    maxX = max(maxX, currentMKPoint.x)
                                    maxY = max(maxY, currentMKPoint.y)
                                    
                                } // inner
                            } // outer
                            
                            // build the bounding rectangle
                            let minPoint = MKMapPoint(x: minX, y: minY)
                            let maxPoint = MKMapPoint(x: maxX, y: maxY)
                            
                            let mapRect = MKMapRect(x: minPoint.x,
                                                    y: minPoint.y,
                                                    width: maxPoint.x - minPoint.x,
                                                    height: maxPoint.y - minPoint.y)
                            
                            // build the center coordinate
                            let centerPoint = MKMapPoint(x: mapRect.midX, y: mapRect.midY)
                            let centerCoordinate = centerPoint.coordinate
                            
                            GlobalUIData.unique.RKIMapCountyData.append(
                                GlobalUIData.RKIMapDataStruct(
                                    "\(myID)",
                                    name,
                                    ringsResultX,
                                    ringsResultY,
                                    centerLatitude: centerCoordinate.latitude, longitude: centerCoordinate.longitude,
                                    boundingRectOriginX: mapRect.origin.x, y: mapRect.origin.y,
                                    boundingRectSizeWidth: mapRect.size.width, height: mapRect.size.height))
                             
                        } else {
                            
                            GlobalStorage.unique.storeLastError(
                                errorText: "CoBaT.RKIDataDownload.handleRKIContent: county shape data: rings data of item [\(dataIndex)] (\"\(name)\") is empty, skip")
                        }
                    }
                    
                    GlobalStorage.unique.storeLastError(
                        errorText: "CoBaT.RKIDataDownload.handleRKIContent: county shape data: finished data conversion, will call GlobalStorage.unique.saveNewCountyShapeData()")
                    
                    GlobalUIData.unique.saveNewCountyShapeData()
                    
                } else {
                    
                    GlobalStorage.unique.storeLastError(
                        errorText: "CoBaT.RKIDataDownload.handleRKIContent: county shape data were empty, do nothing")
                }
                
                #if DEBUG_PRINT_FUNCCALLS
                print("handleRKIContent County Shape done")
                #endif

                
                
            // -------------------------------------------------------------------------------------
            case .stateBorder:
                
                #if DEBUG_PRINT_FUNCCALLS
                print("handleRKIContent StateBorder")
                #endif
                
                let stateBorderData = try newJSONDecoder().decode(RKI_SS_StateShapeJSON.self, from: data)
                
                #if DEBUG_PRINT_FUNCCALLS
                print("handleRKIContent after decoding")
                #endif
                
                if stateBorderData.features.isEmpty == false {
                    
                    // clean the old data
                    GlobalUIData.unique.RKIMapCountyData.removeAll()
                    
                    // loop over data
                    for dataIndex in 0 ..< stateBorderData.features.count {
                        
                        // get the next item as a reference for the current item
                        let currentItem = stateBorderData.features[dataIndex]
                        
                        // get the main data
                        let myID = currentItem.attributes.objectid1
                        let name = currentItem.attributes.lanEwGEN
                        let rings = currentItem.geometry.rings
                        
                        // check if we have something todo
                        if rings.isEmpty == false {
                            
                            // prepare the min / max variables to find the bounding rectangle
                            var minX: Double = Double.greatestFiniteMagnitude
                            var maxX: Double = 0.0
                            
                            var minY: Double = Double.greatestFiniteMagnitude
                            var maxY: Double = 0.0
                            
                            // prepare the data arrays
                            var ringsResultX: [[Double]] = []
                            var ringsResultY: [[Double]] = []
                            
                            // read and convert the shape data
                            // loop over the first index of rings[[]]
                            for outerIndex in 0 ..< rings.count {
                                
                                // append an empty array for the data
                                ringsResultX.append([])
                                ringsResultY.append([])
                                
                                // loop over the second index of rings[[]]
                                for innerIndex in 0 ..< rings[outerIndex].count {
                                    
                                    // first step convert the GPS coordinate into a MKMapPoint
                                    let currentMKPoint = MKMapPoint(CLLocationCoordinate2D(
                                                                        latitude:  rings[outerIndex][innerIndex][1],
                                                                        longitude: rings[outerIndex][innerIndex][0]))
                                    
                                    // store it into the array
                                    ringsResultX[outerIndex].append(currentMKPoint.x)
                                    ringsResultY[outerIndex].append(currentMKPoint.y)
                                    
                                    // calculate min and max values
                                    minX = min(minX, currentMKPoint.x)
                                    minY = min(minY, currentMKPoint.y)
                                    maxX = max(maxX, currentMKPoint.x)
                                    maxY = max(maxY, currentMKPoint.y)
                                    
                                } // inner
                            } // outer
                            
                            // build the bounding rectangle
                            let minPoint = MKMapPoint(x: minX, y: minY)
                            let maxPoint = MKMapPoint(x: maxX, y: maxY)
                            
                            let mapRect = MKMapRect(x: minPoint.x,
                                                    y: minPoint.y,
                                                    width: maxPoint.x - minPoint.x,
                                                    height: maxPoint.y - minPoint.y)
                            
                            // build the center coordinate
                            let centerPoint = MKMapPoint(x: mapRect.midX, y: mapRect.midY)
                            let centerCoordinate = centerPoint.coordinate
                            
                            GlobalUIData.unique.RKIMapStateData.append(
                                GlobalUIData.RKIMapDataStruct(
                                    "\(myID)",
                                    name,
                                    ringsResultX,
                                    ringsResultY,
                                    centerLatitude: centerCoordinate.latitude, longitude: centerCoordinate.longitude,
                                    boundingRectOriginX: mapRect.origin.x, y: mapRect.origin.y,
                                    boundingRectSizeWidth: mapRect.size.width, height: mapRect.size.height))
                             
                        } else {
                            
                            GlobalStorage.unique.storeLastError(
                                errorText: "CoBaT.RKIDataDownload.handleRKIContent: state border data: rings data of item [\(dataIndex)] (\"\(name)\") is empty, skip")
                        }
                    }
                    
                    GlobalStorage.unique.storeLastError(
                        errorText: "CoBaT.RKIDataDownload.handleRKIContent: state border data: finished data conversion, will call GlobalStorage.unique.saveNewCountyShapeData()")
                    
                    GlobalUIData.unique.saveNewStateBorderData()
                    
                } else {
                    
                    GlobalStorage.unique.storeLastError(
                        errorText: "CoBaT.RKIDataDownload.handleRKIContent: state border data were empty, do nothing")
                }
                
                #if DEBUG_PRINT_FUNCCALLS
                print("handleRKIContent state border done")
                #endif
                
            } // switch
            
        } catch let error as NSError {
            
            GlobalStorage.unique.storeLastError(
                errorText: "CoBaT.RKIDataDownload.handleRKIContent: Error: JSON decoder failed: error: \"\(error.description)\", return")
            return
        }
    }
        
}
