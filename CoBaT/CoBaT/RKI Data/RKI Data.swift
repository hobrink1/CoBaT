//
//  Get RKI Data.swift
//  CoBaT
//
//  Created by Hartwig Hopfenzitz on 24.11.20.
//

//
// calls the RKI data server, decode the JSON and stores the retrieved data into global storage
//

import Foundation

// -------------------------------------------------------------------------------------------------
// MARK: -
// MARK: - RKI Data
// -------------------------------------------------------------------------------------------------
class RKIData: NSObject {
    
    // ---------------------------------------------------------------------------------------------
    // MARK: - Singleton
    // ---------------------------------------------------------------------------------------------
    static let unique = RKIData()
    
    // ---------------------------------------------------------------------------------------------
    // MARK: - RKI Data Tab
    // ---------------------------------------------------------------------------------------------
    //
    // The methode getRKIData() will walk over this array and calls the URL For each item.
    //
    private enum RKI_DataTypeEnum {
        case county, state
    }
    
    private struct RKI_DataTabStruct {
        let RKI_DataType: RKI_DataTypeEnum
        let URL_String: String
        
        init(_ dataType: RKI_DataTypeEnum, _ URLString: String) {
            self.RKI_DataType = dataType
            self.URL_String = URLString
        }
    }
    
    private let RKI_DataTab: [RKI_DataTabStruct] = [
        
        RKI_DataTabStruct(.county,  "https://services7.arcgis.com/mOBPykOjAyBO2ZKk/arcgis/rest/services/RKI_Landkreisdaten/FeatureServer/0/query?where=1%3D1&outFields=*&returnGeometry=false&outSR=4326&f=json"),
        
        RKI_DataTabStruct(.state, "https://services7.arcgis.com/mOBPykOjAyBO2ZKk/arcgis/rest/services/Coronaf%C3%A4lle_in_den_Bundesl%C3%A4ndern/FeatureServer/0/query?where=1%3D1&outFields=*&returnGeometry=false&outSR=4326&f=json")
    ]
    
    // ---------------------------------------------------------------------------------------------
    // MARK: - RKI data API
    // ---------------------------------------------------------------------------------------------
    /**
     -----------------------------------------------------------------------------------------------
     
     Walks through the array "RKI_DataTab" of this class, calls the related URLs and calls handleRKIContent() if valid data recieved
     
     -----------------------------------------------------------------------------------------------
     - Parameters: none
     - Returns: nothing
     */
    public func getRKIData() {
        
        // walk over the array with the configurations
        for singleDataSet in RKI_DataTab {
            
            // build a valid URL
            if let url = URL(string: singleDataSet.URL_String) {
                
                // build the task and define the completion handler
                let task = URLSession.shared.dataTask(
                    with: url,
                    completionHandler: { data, response, error in
                        
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
                                        if mimeType == "text/plain" {
                                            
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
                                                    errorText: "CoBaT.RKIData.getRKIData: Error: URLSession.dataTask, no valid data, return")
                                                return
                                            }
                                            
                                        } else {
                                            
                                            // not the right mimeType, log message and return
                                            GlobalStorage.unique.storeLastError(
                                                errorText: "CoBaT.RKIData.getRKIData: Error: URLSession.dataTask, wrong mimeType (\"\(mimeType)\" instead of \"text/plain\"), return")
                                            return
                                        }
                                        
                                    } else {
                                        
                                        // no valid mimeType, log message and return
                                        GlobalStorage.unique.storeLastError(
                                            errorText: "CoBaT.RKIData.getRKIData: Error: URLSession.dataTask, no mimeType in response, return")
                                        return
                                    }
                                    
                                } else {
                                    
                                    // not a good status, log message and return
                                    GlobalStorage.unique.storeLastError(
                                        errorText: "CoBaT.RKIData.getRKIData: Server responded with error status: \(httpResponse.statusCode), return")
                                    return
                                }
                                
                            } else {
                                
                                // no valid response, log message and return
                                GlobalStorage.unique.storeLastError(
                                    errorText: "CoBaT.RKIData.getRKIData: Error: URLSession.dataTask has no valid HTTP response, return")
                                return
                            }
                            
                        } else {
                            
                            // error is not nil, check if error code is valid
                            if let myError = error  {
                                
                                // valid errorCode, call the handler and return
                                GlobalStorage.unique.storeLastError(
                                    errorText: "CoBaT.RKIData.getRKIData: handleServerError(), \(myError.localizedDescription)")
                                return
                                
                            } else {
                                
                                // no valid error code, log message and return
                                GlobalStorage.unique.storeLastError(
                                    errorText: "CoBaT.RKIData.getRKIData: Error: URLSession.dataTask came back with error which is not nil, but no valid errorCode, return")
                                return
                            }
                        }
                    })
                
                // start the task
                task.resume()
                
            } else {
                
                // no valid URL, log message and return
                GlobalStorage.unique.storeLastError(
                    errorText: "CoBaT.RKIData.getRKIData: Error: URLSession.dataTask came back with error which is not nil, but no valid errorCode, return")
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

    private func handleRKIContent( _ data: Data, _ RKI_DataType: RKI_DataTypeEnum) {
        
        print("handleRKIContent just started")
        do {
                    
            switch RKI_DataType {
            
            case .county:
                
                print("handleRKIContent County")
                
                let countyData = try newJSONDecoder().decode(RKI_County_JSON.self, from: data)
                
                print("handleRKIContent after decoding")
                
                // we will provide an array of converted values
                var newDataArray: [GlobalStorage.RKICountyDataStruct] = []
                
                // Walk over data and build array
                for singleItem in countyData.features {
                    
                    newDataArray.append(GlobalStorage.RKICountyDataStruct(
                                            stateName: singleItem.attributes.bl.rawValue,
                                            countyName: singleItem.attributes.gen,
                                            Covid7DaysCasesPer100K: singleItem.attributes.cases7Per100K))
                }

                GlobalStorage.unique.refresh_RKICountyData(newRKICountyData: newDataArray)
                print("handleRKIContent done")

                
            case .state:
                print("State")
                
                let welcomeResult = try newJSONDecoder().decode(RKI_State_JSON.self, from: data)
                
                //let welcomeResult = try RKI_County_JSON(json)
                
                print("receive 3:")
                
                // let test = welcomeResult.
                
                //            if welcomeResult.features != nil {
                for singleItem in welcomeResult.features {
                    //if let test1 = singleItem.attributes!.bl {
                    print("\(singleItem.attributes.cases7BlPer100K), \(singleItem.attributes.cases7BlPer100K))")
                    //}
                }
                
            //            for singleItem in welcomeResult.features! {
            //                print("\(String(describing: singleItem.attributes!.lanEwBEZ)), \(String(describing: singleItem.attributes!.objectid1)): \(String(describing: singleItem.attributes!.cases7BlPer100K))")
            //            }
            
            }
            
            
        } catch let error as NSError {
            
            GlobalStorage.unique.storeLastError(
                errorText: "CoBaT.RKIData.handleRKIContent: Error: JSON decoder failed: error: \"\(error.description)\", return")
            return
        }
    }
    


    
    
}
