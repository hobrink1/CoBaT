//
//  RKI Map Overlay Renderer.swift
//  CoBaT
//
//  Created by Hartwig Hopfenzitz on 19.03.21.
//

import UIKit
import MapKit

// -------------------------------------------------------------------------------------------------
// MARK: -
// MARK: - RKI Map Overlay Renderer
// -------------------------------------------------------------------------------------------------

let RKIMapOverlayRendererBorderColor: CGColor = UIColor.white.cgColor


// -------------------------------------------------------------------------------------------------
// MARK: -
// MARK: - Class
// -------------------------------------------------------------------------------------------------
class RKIMapOverlayRenderer: MKOverlayRenderer {
    
    // ---------------------------------------------------------------------------------------------
    // MARK: - Class Properties
    // ---------------------------------------------------------------------------------------------
    
    // cross reference to the overlay with the right class
    var myOverlay : RKIMapOverlay
    
    // table of gaps
    // to speed up drawing we draw different detail levels depending on current zoom level
    // the lower the zoomlevel, the bigger the gaps
    // inside self.draw() we increase the index of the points of a ahape by this gaps
    let gapsPerZoomLevel: [Int] = [
    
        100, //  0
        100, //  1
        100, //  2
        100, //  3
        80, //  4
        40, //  5
        20, //  6
        12, //  7
        6, //  8
        3, //  9
        2, // 10
        1, // 11
        1, // 12
        1, // 13
        1, // 14
        1, // 15
        1, // 16
        1, // 17
        1, // 18
        1, // 19
        1, // 20
        1, // 21
        1, // 22
        1, // 23
        1, // 24
        1, // 25
        1, // 26
        1, // 27
        1, // 28
        1  // 29
    ]
    
    
    
    
    
    // ---------------------------------------------------------------------------------------------
    // MARK: -
    // MARK: - Life Cycle
    // ---------------------------------------------------------------------------------------------
    
    /**
     -----------------------------------------------------------------------------------------------
     
     init()
     
     -----------------------------------------------------------------------------------------------
     */
    override init(overlay: MKOverlay) {
        
        // store the overlay object as the right type
        myOverlay = overlay as! RKIMapOverlay
        
        // call the super class
        super.init(overlay: overlay)
    }
    
    
    // ---------------------------------------------------------------------------------------------
    // MARK: -
    // MARK: - API
    // ---------------------------------------------------------------------------------------------
    
    /**
     -----------------------------------------------------------------------------------------------
     
     draw()
     
     -----------------------------------------------------------------------------------------------
     */
    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
                
        // we need the zoomLevel for speed optimization, as we reduce details on high altitudes
        let zoomLevel : Int
        if #available(iOS 13, *) {
            zoomLevel  = Int( 20 - log2( 1 / zoomScale )) - 1
        } else {
            zoomLevel  = Int( 20 - log2( 1 / zoomScale ))
        }

        // we use the gap value to optimize drawing. the higher the altitude, the feweer points will be drawn
        // the gap value increases the index which is used to walk through the array with the area data
        let gap: Int = self.gapsPerZoomLevel[zoomLevel]

        // draw according to the overlay type
        switch myOverlay.overlayType {
        
        case .countyArea:
            
            // we set the borderWidth according tpo the zoomLevel (found by testing)
            let borderWidth: CGFloat
            if zoomLevel <= 6 {
                borderWidth = MKRoadWidthAtZoomScale(zoomScale) / 2.0
            } else {
                borderWidth = MKRoadWidthAtZoomScale(zoomScale)
            }
            
            // setup the canvas
            context.setFillColor(myOverlay.areaColor)
            context.setStrokeColor(RKIMapOverlayRendererBorderColor)
            context.setLineWidth(borderWidth)
            context.setAlpha(0.6)
            
            // shortcut for the current area data
            let myAreaData = GlobalUIData.unique.RKIMapAreaAndBorderData[myOverlay.areaDataIndex]
            
            // the area data are a two dimensional array. The inner array consist the drawing data of an area.
            // the outerarray holds these inner arrays.
            
            // start a new drawing
            context.beginPath()
            
            for outerIndex in 0 ..< myAreaData.count {
                
                // check if empty
                if myAreaData[outerIndex].isEmpty == false {
                    
                    // the first point of the inner array is the atrt point and will be used for the end point later on
                    let firstPoint = self.point(for: myAreaData[outerIndex][0])
                    context.move(to: firstPoint)
                    
                    // this is the index we ise to walk through the inner array
                    var innerIndex: Int = 0 + gap
                    
                    // loop over the inner array
                    while innerIndex < myAreaData[outerIndex].count {
                        
                        // get the next point
                        let nextPoint = self.point(for: myAreaData[outerIndex][innerIndex])
                        
                        // add it to the path
                        context.addLine(to: nextPoint)
                        
                        // advance the index
                        innerIndex += gap
                    }
                    
                    // close the area
                    context.addLine(to: firstPoint)
                }
            }
            
            // on altitudes higher than ZoomLevel 6 we do not draw borders (looks better)
            if zoomLevel <= 5 {
                context.drawPath(using: .eoFill)
            } else {
                context.drawPath(using: .eoFillStroke)
            }
            
            
            
            // ----------------------------------------------------------------------------------------
            // draw the label text image
            
            // shortcut for the corresdonding MKMapRect of the overlay
            let labelMapRect = myOverlay.rectForLabel
            
            // check if the current tile intersects with this label rect
            if (mapRect.intersects(labelMapRect) == true)
                && (zoomLevel > 6) {
                
                // Yes, so we have to draw it
                
                // try to get a valid image
                if let cgImage = myOverlay.labelImage {
                    
                    // we have a valid image, so prepare the context for drawing
                    context.saveGState()
                    
                    // for better reading we use an alpha of 1.0
                    context.setAlpha(1.0)
                    
                    //draw the image
                    context.draw(cgImage, in: self.rect(for: labelMapRect))
                    
                    // restore the context
                    context.restoreGState()
                }
            }
            
        // done with .countyArea
        
        
        /*
         // ----------------------------------------------------------------------------------------
         // JUST FOR DEVELOPMENT: Draw zoomLevel instead of labelImage
         // (you have to comment out the lines for labelImage)
         
         let LabelString: String = "\(ZoomLevel)"
         
         let paragraphStyle = NSMutableParagraphStyle()
         paragraphStyle.alignment = .center
         
         //let foregroundColor = color
         
         let attributes = [NSAttributedString.Key.paragraphStyle  : paragraphStyle,
         NSAttributedString.Key.font            : UIFont.systemFont(ofSize: 100.0),
         NSAttributedString.Key.foregroundColor : UIColor.black]
         
         //func image(withAttributes attributes: [NSAttributedString.Key: Any]? = nil, size: CGSize? = nil) -> UIImage? {
         let size = (LabelString as NSString).size(withAttributes: attributes)
         
         let renderer = UIGraphicsImageRenderer(size: size)
         
         let newZoomLevelImage = renderer.image {
         (context) in
         
         let canvasContext = context.cgContext
         
         canvasContext.translateBy(x: 0, y: CGFloat(size.height))
         canvasContext.scaleBy(x: 1.0, y: -1.0)
         
         
         (LabelString as NSString).draw(in: CGRect(origin: .zero, size: size),
         withAttributes: attributes)
         
         canvasContext.scaleBy(x: 1.0, y: -1.0)
         canvasContext.translateBy(x: 0, y: (CGFloat(size.height) * -1.0))
         
         }
         
         // shortcut for the corresdonding MKMapRect of the overlay
         let labelMapRect = myOverlay.rectForLabel
         
         // check if the current tile intersects with this label rect
         if mapRect.intersects(labelMapRect) == true {
         
         // Yes, so we have to draw it
         
         // try to get a valid image
         if let cgImage = newZoomLevelImage.cgImage {
         
         // we have a valid image, so prepare the context for drawing
         context.saveGState()
         
         // for better reading we use an alpha of 1.0
         context.setAlpha(1.0)
         
         //draw the image
         context.draw(cgImage, in: self.rect(for: labelMapRect))
         
         // restore the context
         context.restoreGState()
         }
         }
         */
        
        
        
        case .stateBorder:
            
            // we only draw borders if it is worth doing it (on high altitude is not usefull anymore)
            if zoomLevel > 4 {
                
                // we set the borderWidth according tpo the zoomLevel (found by testing)
                let borderWidth: CGFloat
                if zoomLevel <= 6 {
                    borderWidth = MKRoadWidthAtZoomScale(zoomScale)
                } else {
                    borderWidth = MKRoadWidthAtZoomScale(zoomScale) * 2
                }
                
                // setup the canvas
                //context.setFillColor(myOverlay.areaColor)
                context.setStrokeColor(RKIMapOverlayRendererBorderColor)
                context.setLineWidth(borderWidth)
                context.setAlpha(0.8)
                
                // shortcut for the current area data
                let myAreaData = GlobalUIData.unique.RKIMapAreaAndBorderData[myOverlay.areaDataIndex]
                
                // the area data are a two dimensional array. The inner array consist the drawing data of an area.
                // the outerarray holds these inner arrays.
                
                // start a new drawing
                context.beginPath()
                
                for outerIndex in 0 ..< myAreaData.count {
                    
                    // check if empty
                    if myAreaData[outerIndex].isEmpty == false {
                        
                        // the first point of the inner array is the atrt point and will be used for the end point later on
                        let firstPoint = self.point(for: myAreaData[outerIndex][0])
                        context.move(to: firstPoint)
                        
                        // this is the index we ise to walk through the inner array
                        var innerIndex: Int = 0 + gap
                        
                        // loop over the inner array
                        while innerIndex < myAreaData[outerIndex].count {
                            
                            // get the next point
                            let nextPoint = self.point(for: myAreaData[outerIndex][innerIndex])
                            
                            // add it to the path
                            context.addLine(to: nextPoint)
                            
                            // advance the index
                            innerIndex += gap
                        }
                        
                        // close the area
                        context.addLine(to: firstPoint)
                    }
                }
                
                // on altitudes higher than ZoomLevel 6 we do not draw borders (looks better)
                //if zoomLevel <= 5 {
                context.drawPath(using: .stroke)
                //            } else {
                //                context.drawPath(using: .eoFillStroke)
                //            }
                
            }
        } // switch

    }
    
}
