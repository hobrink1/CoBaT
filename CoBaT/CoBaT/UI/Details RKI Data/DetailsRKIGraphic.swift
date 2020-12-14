//
//  DetailsRKIGraphic.swift
//  CoBaT
//
//  Created by Hartwig Hopfenzitz on 14.12.20.
//

import Foundation
import UIKit


// -------------------------------------------------------------------------------------------------
// MARK: -
// MARK: - Details RKI Graphic
// -------------------------------------------------------------------------------------------------




// -------------------------------------------------------------------------------------------------
// MARK: -
// MARK: - Class
// -------------------------------------------------------------------------------------------------
class DetailsRKIGraphic: NSObject {
    
    // ---------------------------------------------------------------------------------------------
    // MARK: - Singleton
    // ---------------------------------------------------------------------------------------------
    static let unique = DetailsRKIGraphic()
    
    // ---------------------------------------------------------------------------------------------
    // MARK: - Class Properties
    // ---------------------------------------------------------------------------------------------
    private let ScreenScale = UIScreen.main.scale
    private let graphBackgroundUIColor = UIColor.white
    private let graphBackgroundCGColor = UIColor.white.cgColor
    
    
    // ---------------------------------------------------------------------------------------------
    // MARK: - API
    // ---------------------------------------------------------------------------------------------
    public var GraphLeft: UIImage = UIImage(named: "5To4TestImage")!
    public var GraphMiddle: UIImage = UIImage(named: "5To4TestImage")!
    public var GraphRight: UIImage = UIImage(named: "5To4TestImage")!

    public func startGraphicSystem() {
        
        #if DEBUG_PRINT_FUNCCALLS
        print("DetailsRKIGraphic.startGraphicSystem() just started, call createNewGraphs()")
        #endif
        createNewGraphs()

        
    }
    
    // ---------------------------------------------------------------------------------------------
    // MARK: - Drawing Helpers
    // ---------------------------------------------------------------------------------------------
    /**
     -----------------------------------------------------------------------------------------------
     
     
     
     -----------------------------------------------------------------------------------------------
     
     - Parameters:
     - :
     
     - Returns:
     
     */
    private func createNewGraphs() {
        
        // this is the y-offset for the label
        let labelY = GlobalUIData.unique.RKIGraphNeededHeight - 14
        
        // the new image for the left graph
        if let newImage = getNewBlankImage() {
            
            // add the label
            if let newImageLabled = textToImage(
                text: "Neue Fälle",
                color: UIColor.darkGray,
                image: newImage,
                atPoint: CGPoint(x: 0,
                                 y: labelY)) {
                
                GraphLeft = newImageLabled
                
            } else {
                
                GlobalStorage.unique.storeLastError(
                    errorText: "DetailsRKIGraphic.createNewGraphs().leftImage textToImage() returned nil")
            }
            
        } else {
            
            GlobalStorage.unique.storeLastError(
                errorText: "DetailsRKIGraphic.createNewGraphs().leftImage getNewBlankImage() returned nil")
        }
        
        // the new image for the middle graph
        if let newImage = getNewBlankImage() {
            
            // add the label
            if let newImageLabled = textToImage(
                text: "Neue Todesfälle",
                color: UIColor.darkGray,
                image: newImage,
                atPoint: CGPoint(x: 0,
                                 y: labelY)) {
                
                GraphMiddle = newImageLabled
                
            } else {
                
                GlobalStorage.unique.storeLastError(
                    errorText: "DetailsRKIGraphic.createNewGraphs().middleImage textToImage() returned nil")
            }
            
        } else {
            
            GlobalStorage.unique.storeLastError(
                errorText: "DetailsRKIGraphic.createNewGraphs().middleImage getNewBlankImage() returned nil")
        }
        
        // the new image for the right graph
        if let newImage = getNewBlankImage() {
            
            // add the label
            if let newImageLabled = textToImage(
                text: "Inzidenz",
                color: UIColor.darkGray,
                image: newImage,
                atPoint: CGPoint(x: 0,
                                 y: labelY)) {
                
                GraphRight = newImageLabled
                
            } else {
                
                GlobalStorage.unique.storeLastError(
                    errorText: "DetailsRKIGraphic.createNewGraphs().rightImage textToImage() returned nil")
            }
            
        } else {
            
            GlobalStorage.unique.storeLastError(
                errorText: "DetailsRKIGraphic.createNewGraphs().rightImage getNewBlankImage() returned nil")
        }

    }
    
    
    /**
     -----------------------------------------------------------------------------------------------
     
     
     
     -----------------------------------------------------------------------------------------------
     
     - Parameters:
     - :
     
     - Returns:
     
     */
    private func getNewBlankImage() -> UIImage? {
        
        let newImageHeight = GlobalUIData.unique.RKIGraphNeededHeight
        let newImageWidth = GlobalUIData.unique.RKIGraphNeededWidth
        
        // the initial canvas
        UIGraphicsBeginImageContextWithOptions(CGSize(width: newImageWidth, height: newImageHeight),
                                               false,
                                               ScreenScale)
        
        // get the current context (our canvas)
        let context = UIGraphicsGetCurrentContext()
        
        // start the drawing (we just set the background)
        context!.beginPath()
        
        // fill the whole canvas with background color
        context!.setFillColor(graphBackgroundCGColor)
        
        // use slightly bigger value to overcome rounding effects and ensure a whole black area
        context!.addRect(CGRect(x: 0, y: 0, width: newImageWidth + 1, height: newImageHeight + 1))
        
        // draw it
        context!.drawPath(using: .fill)
        
        // OK, that's it, we take this as the new image
        let returnImage = UIGraphicsGetImageFromCurrentImageContext()
        
        // OK, we now have a nice new image, store it
        UIGraphicsEndImageContext()
        
        // return the new image
        return returnImage

    }
    
    
    
    /**
     -----------------------------------------------------------------------------------------------
     
     textToImage()
     
     -----------------------------------------------------------------------------------------------
     
     - Parameters:
     - :
     
     - Returns:
     
     */
    private func textToImage(text: String,
                             color: UIColor,
                             image: UIImage,
                             atPoint: CGPoint) -> UIImage?
    {
        let textColor = color
        let textFont = UIFont.systemFont(ofSize: 12)
        
        let alignAsCenter = NSMutableParagraphStyle()
        alignAsCenter.alignment = NSTextAlignment.center
        
        UIGraphicsBeginImageContextWithOptions(image.size, false, self.ScreenScale)
        
        let textFontAttributes = [
            NSAttributedString.Key.font: textFont,
            NSAttributedString.Key.foregroundColor: textColor,
            NSAttributedString.Key.paragraphStyle: alignAsCenter
        ] as [NSAttributedString.Key : Any]
        image.draw(in: CGRect(origin: CGPoint.zero, size: image.size))
        
        let rect = CGRect(origin: atPoint, size: image.size)
        text.draw(in: rect, withAttributes: textFontAttributes)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
}
