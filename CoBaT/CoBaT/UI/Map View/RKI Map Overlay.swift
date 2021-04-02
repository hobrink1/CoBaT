//
//  RKI Map Overlay.swift
//  CoBaT
//
//  Created by Hartwig Hopfenzitz on 19.03.21.
//

import Foundation
import MapKit


// -------------------------------------------------------------------------------------------------
// MARK: -
// MARK: - RKI Map Overlaya
// -------------------------------------------------------------------------------------------------

enum RKIMapOverlayType {
    case countyArea, stateBorder
}

// -------------------------------------------------------------------------------------------------
// MARK: -
// MARK: - Class
// -------------------------------------------------------------------------------------------------
final class RKIMapOverlay : NSObject, MKOverlay {

    // ---------------------------------------------------------------------------------------------
    // MARK: - Class Properties
    // ---------------------------------------------------------------------------------------------
    
    // properties of MKOverlay protocol
    
    // the coordinate of the center
    public var coordinate: CLLocationCoordinate2D
    
    // the bounding rectangle
    public let boundingMapRect: MKMapRect
       
    
    // other properties
    
    // this is the map which will be served
    public var mapToServe: MKMapView?
    
    // type of overlay
    public let overlayType: RKIMapOverlayType
    
    // index associated with this overlayType
    public let typeIndex: Int
    
    // the ID string of the state / county
    public let myID: String
    
    // the index of that state / county in the RKIData array
    public var RKIDataIndex: Int = 0
    
    // the current day to display
    public var currentDayIndex: Int
    
    // the index of the corresponding area data in the RKIMapAreaAndBorderData[[]] array
    public var areaDataIndex: Int = 0
    
    // the current incidence (cases in 7 days per 100 k inhabitants)
    public var currentIncidence: Double = 0.0
    
    // color for the area of a county (.countyArera)
    // we use the predefined colors to avoid initialisation overhead of UIColor for each overlay
    public var areaColor: CGColor = GlobalUIData.unique.UIClearColor.cgColor
    public var textColorCG: CGColor = GlobalUIData.unique.UIClearColor.cgColor
    public var textColorUI: UIColor = GlobalUIData.unique.UIClearColor

    public let rectForLabel: MKMapRect
    public var labelImage: CGImage?
    
    
    
    
    // ---------------------------------------------------------------------------------------------
    // MARK: -
    // MARK: - Life Cycle
    // ---------------------------------------------------------------------------------------------
    
    /**
     -----------------------------------------------------------------------------------------------
     
     init()
     
     -----------------------------------------------------------------------------------------------
     
     - Parameters:
        - type: type of overlay (.countyArea or .stateBorder)
        - myID: the ID string of the state / county
        - dayIndex: the index of the day to display in the RKIData array
        - map: the map an which the overlay is displayed
        - centerCoordinate: the center of the overlay as a CLLocationCoordinate2D
        - rect: the boundingRectangle of the overlay
     
     */
    init(type overlayType: RKIMapOverlayType,
         myID: String,
         dayIndex: Int,
         areaDataIndex: Int,
         map mapToServe: MKMapView?,
         center centerCoordinate: CLLocationCoordinate2D,
         rect rectToDraw: MKMapRect
    ) {
        
        self.overlayType = overlayType
        
        // get typeIndex associated with the overlayType
        switch self.overlayType {
        
        case .countyArea:
            self.typeIndex = GlobalStorage.unique.RKIDataCounty
            
        case .stateBorder:
            self.typeIndex = GlobalStorage.unique.RKIDataState
        }

        // the current ID and dayIndex
        self.myID = myID
        self.currentDayIndex = dayIndex
        
        // the index of the corresponding area data
        self.areaDataIndex = areaDataIndex
        
        // the map with the geometry
        self.mapToServe = mapToServe
        self.coordinate = centerCoordinate
        self.boundingMapRect = rectToDraw
        
        // we found the size by try and error
        let size: Double = 100_000
        
        // this will be the rect in which we draw the labels
        let centerMapPoint = MKMapPoint(centerCoordinate)
        
        self.rectForLabel = MKMapRect(x: centerMapPoint.x - (size / 2),
                                      y: centerMapPoint.y - (size / 4),
                                      width: size,
                                      height: size / 2)
 
        
        // because of NSObject
        super.init()
        
        
        // set the depending values after super.init()
        self.RKIDataIndex = self.getIndexFromID(myID)
        self.getIncidenceAndSetColors()
        


        
     }
    
    // ---------------------------------------------------------------------------------------------
    // MARK: - API
    // ---------------------------------------------------------------------------------------------

    /**
     -----------------------------------------------------------------------------------------------
     
     Change the depending parameters (color, etc.) of the overlay according ti the given dayIndex, and redraw the overlay
     
     -----------------------------------------------------------------------------------------------

     - Parameters:
        - newIndex: new index of the day
     
     */
    public func changeDayIndex(newIndex: Int) {
        
        // first check if we really have to todo something
        if (self.overlayType == .countyArea)
            && (self.currentDayIndex != newIndex) {
            
            // set the property
            self.currentDayIndex = newIndex
            
            // get and set the new color schema
            self.getIncidenceAndSetColors()
            
            // and force a redraw of the overlay
            self.redrawOverlay()
        }
        
    }
    
    
    
    /**
     -----------------------------------------------------------------------------------------------
     
     redrawOverlay()
     
     -----------------------------------------------------------------------------------------------
     */
    public func redrawOverlay() {
        
        // get the my renderer and force a redraw
        DispatchQueue.main.async(execute: {
            
            // get the corresponding renderer
            if let myRenderer = self.mapToServe?.renderer(for: self) {
                
                // force the renderer to redraw the map
                myRenderer.setNeedsDisplay()
            }
        })
    }
    
    
    // ---------------------------------------------------------------------------------------------
    // MARK: - Helper
    // ---------------------------------------------------------------------------------------------

    /**
     -----------------------------------------------------------------------------------------------
     
     translates the given ID string (e.g. "27") into the right index of the state / county in RKIData
     
     -----------------------------------------------------------------------------------------------
     
     - Parameters:
        - myID: the ID string of the state / county
     
     - Returns: Int index of the state / county in RKIData array or 0 if not found
     
     */
    private func getIndexFromID(_ myID: String) -> Int {
        
        if let foundIndex =
            //GlobalStorageQueue.sync(execute: {
            GlobalStorage.unique.RKIData[self.typeIndex][0].firstIndex(where: { $0.myID == myID } )
        //})
        {
            // we found a valid record, so return the index
            return foundIndex
        }
        
        // default is 0 as a safe value
        return 0
    }
    
    
    /**
     -----------------------------------------------------------------------------------------------
     
     get the incidences according to GlobalStorage.unique.RKIData[typeIndex][self.currentDayIndex][self.RKIDataIndex].cases7DaysPer100K and gets the background and text colors associated with it
     
     example: "State (1), today (0), Bavaria (9), cases" looks like: RKIData[1][0][9].cases

     -----------------------------------------------------------------------------------------------
     */
    private func getIncidenceAndSetColors() {
        
        // we do this only for counties
        if self.overlayType == .countyArea {
            
            // get the new incidence value
            let newIncidence =
                //GlobalStorageQueue.sync(execute: {
                GlobalStorage.unique.RKIData[self.typeIndex][self.currentDayIndex][self.RKIDataIndex].cases7DaysPer100K
            //})
            
            self.currentIncidence = newIncidence
            
            // use it, to get the right colors
            let (backgroundColor, textColor, _, _) = CovidRating.unique.getColorsForValue(newIncidence)
            
            // set the colors
            self.areaColor = backgroundColor.cgColor
            self.textColorCG = textColor.cgColor
            self.textColorUI = textColor
            
            // build the new labelImage
            self.buildLabelImage()
        }
    }
    
    
    /**
     -----------------------------------------------------------------------------------------------
     
     
     
     -----------------------------------------------------------------------------------------------
     
     - Parameters:
     - :
     
     - Returns:
     
     */
    private func buildLabelImage() {
        
        // the labelString shows the current incidence of that county
        let LabelString = number1FractionFormatter.string(
            from: NSNumber(value: self.currentIncidence)) ?? ""
        
        
        // prepare the attributes for the label image
        // center the label in the image
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        // also set font and color
        let labelStringAttributes = [
            NSAttributedString.Key.paragraphStyle  : paragraphStyle,
            NSAttributedString.Key.font            : UIFont.systemFont(ofSize: 90.0),
            // NSAttributedString.Key.foregroundColor : self.textColorUI
            NSAttributedString.Key.foregroundColor : UIColor.black
        ]

        
        // set the size according to the labelString and attach the textattributes (Font, color, alignment)
        let size1 = (LabelString as NSString).size(withAttributes: labelStringAttributes)
        
        let size = CGSize(width: size1.width + 10.0, height: size1.height)

        // get the renderer for the text
        let renderer = UIGraphicsImageRenderer(size: size)
        
        // build the image
        let newLabelImage = renderer.image {
            (context) in
     
            // get the canvas
            let canvasContext = context.cgContext
            
            // we have to flip the cnvas to get the image in right oriantation
            canvasContext.translateBy(x: 0, y: CGFloat(size.height))
            canvasContext.scaleBy(x: 1.0, y: -1.0)
            
            // draw the string image
            (LabelString as NSString).draw(in: CGRect(origin: .zero, size: size),
                                           withAttributes: labelStringAttributes)
            
            // flip the canvas back
            canvasContext.scaleBy(x: 1.0, y: -1.0)
            canvasContext.translateBy(x: 0, y: (CGFloat(size.height) * -1.0))
        }
        
        // safe the image for further purpose
        self.labelImage = newLabelImage.cgImage
    }
}
