//
//  CovidRating.swift
//  CoBaT
//
//  Created by Hartwig Hopfenzitz on 25.11.20.
//

import Foundation
import UIKit

// -------------------------------------------------------------------------------------------------
// MARK: -
// MARK: - CovidRating
// -------------------------------------------------------------------------------------------------

// -------------------------------------------------------------------------------------------------
// MARK: -
// MARK: - Class
// -------------------------------------------------------------------------------------------------
final class CovidRating: NSObject {
    
    // ---------------------------------------------------------------------------------------------
    // MARK: - Singleton
    // ---------------------------------------------------------------------------------------------
    static let unique = CovidRating()
    
    
    // ---------------------------------------------------------------------------------------------
    // MARK: - API
    // ---------------------------------------------------------------------------------------------
    /**
     -----------------------------------------------------------------------------------------------
     
     provides the standard background and forground colors for a given value (asuming Covid cases)
     
     -----------------------------------------------------------------------------------------------
     
     - Parameters:
        - value: the value which should be a value related to 7 day average for 100 k people
     
     - Returns:
        - backgroundColor
        - forgroundColor
     
     */
    public func getColorsForValue(_ value: Double)
    -> (background: UIColor, forground: UIColor) {
        
        let backgroundColor: UIColor
        let foregroundColor: UIColor
        
        if value <= 0 {
            
            backgroundColor = UIColor.systemBackground
            foregroundColor = UIColor.label

        } else if value < 35.0 {
            
            backgroundColor = UIColor.systemGreen
            foregroundColor = UIColor.black
            
        } else if value < 50.0 {
            
            backgroundColor = UIColor.systemYellow
            foregroundColor = UIColor.black
            
        } else if value < 100.0 {
            
            backgroundColor = UIColor.systemOrange
            foregroundColor = UIColor.black
            
            
        } else if value < 600.0 {
            
            backgroundColor = UIColor.systemRed
            foregroundColor = UIColor.white
            
        } else {
            
            backgroundColor = UIColor.systemPurple
            foregroundColor = UIColor.white
        }
        
        return (backgroundColor, foregroundColor)
        
    }
    
}
