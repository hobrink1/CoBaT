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

// -------------------------------------------------------------------------------------------------
// MARK: -
// MARK: - Class
// -------------------------------------------------------------------------------------------------
class RKI_Map_Overlay_Renderer: MKOverlayRenderer {
    
    // ---------------------------------------------------------------------------------------------
    // MARK: - Class Properties
    // ---------------------------------------------------------------------------------------------
    
    var myOverlay : RKIMapOverlay
    
    
    
    
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
        
        // start the path to draw
        context.beginPath()
        
        // set the color to use
        context.setFillColor(myOverlay.areaColor)
        
        // set the alpha to full
        context.setAlpha(0.7)
        
        // add the rect to the path
        let cgRectToUse = rect(for: myOverlay.boundingMapRect)
        context.addEllipse(in: cgRectToUse)
        
        // draw it
        context.drawPath(using:.fill)
    }
}
