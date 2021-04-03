//
//  CountyAnnotation.swift
//  CoBaT
//
//  Created by Hartwig Hopfenzitz on 02.04.21.
//

import Foundation
import MapKit

// -------------------------------------------------------------------------------------------------
// MARK: -
// MARK: - County Annotation
// -------------------------------------------------------------------------------------------------


// -------------------------------------------------------------------------------------------------
// MARK: -
// MARK: - Class
// -------------------------------------------------------------------------------------------------
final class CountyAnnotation: NSObject, MKAnnotation {
    
    // ---------------------------------------------------------------------------------------------
    // MARK: - Class Properties
    // ---------------------------------------------------------------------------------------------
    
    let countyID: String                     // searchString of the ID of the related State
    
    // prperties for the MKAnnotationProtocol
    let title: String?                      // name of the state
    let subtitle: String?                   // additional infos to that state
    let coordinate: CLLocationCoordinate2D  // center of the state as the touchpoint

    
    // ---------------------------------------------------------------------------------------------
    // MARK: - Life Cycle
    // ---------------------------------------------------------------------------------------------
    
    /**
     -----------------------------------------------------------------------------------------------
     
     init()
     
     -----------------------------------------------------------------------------------------------
     
     - Parameters:
        - countyID: the String to find the state in the RKI Data
        - title: the title string to show on a call out
        - subTitle: the subtitle string to show on a call out
        - coordinate: the GPS coordinate of the annotation
     
     */
    init(countyID: String, title: String, subTitle: String, coordinate: CLLocationCoordinate2D) {
        
        self.countyID = countyID
        self.title = title
        self.subtitle = subTitle
        self.coordinate = coordinate
        
        
        super.init()
    }
}
