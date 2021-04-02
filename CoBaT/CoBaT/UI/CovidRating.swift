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
    -> (background: UIColor, forground: UIColor, forgroundLower: UIColor, grade: Int) {
        
        let backgroundColor: UIColor
        let foregroundColor: UIColor
        let forgroundLowerColor: UIColor
        let grade: Int
        
        if value <= 0 {
            
            backgroundColor = UIColor.systemBackground
            foregroundColor = UIColor.label
            forgroundLowerColor = UIColor.secondaryLabel
            grade = 0

        } else if value < 10.0 {
            
            backgroundColor = UIColor.systemGreen
            foregroundColor = UIColor.black
            forgroundLowerColor = UIColor(red: 62/255, green: 62/255, blue: 62/255, alpha: 1.0)
             grade = 1
            
        } else if value < 35.0 {
            
            backgroundColor = UIColor(red: 203/255, green: 255/255, blue: 168/255, alpha: 1.0)
            foregroundColor = UIColor.black
            forgroundLowerColor = UIColor(red: 62/255, green: 62/255, blue: 62/255, alpha: 1.0)
           grade = 2

        } else if value < 50.0 {
            
            backgroundColor = UIColor.systemYellow
            foregroundColor = UIColor.black
            forgroundLowerColor = UIColor(red: 62/255, green: 62/255, blue: 62/255, alpha: 1.0)
            grade = 3

        } else if value < 100.0 {
            
            backgroundColor = UIColor.systemOrange
            foregroundColor = UIColor.black
            forgroundLowerColor = UIColor(red: 62/255, green: 62/255, blue: 62/255, alpha: 1.0)
            grade = 4

        } else if value < 200.0 {
            
            backgroundColor = UIColor(red: 255/255, green: 0/255, blue: 0/255, alpha: 1.0)
            foregroundColor = UIColor.white
            forgroundLowerColor = UIColor(red: 223/255, green: 222/255, blue: 229/255, alpha: 1.0)
            grade = 5

        } else if value < 400.0 {
            
            backgroundColor = UIColor(red: 153/255, green: 0/255, blue: 0/255, alpha: 1.0)
            foregroundColor = UIColor.white
            forgroundLowerColor = UIColor(red: 223/255, green: 222/255, blue: 229/255, alpha: 1.0)
            grade = 6

       } else {
            
            backgroundColor = UIColor.systemPurple
            foregroundColor = UIColor.white
            forgroundLowerColor = UIColor(red: 223/255, green: 222/255, blue: 229/255, alpha: 1.0)
            grade = 7
        }
        
        return (backgroundColor, foregroundColor, forgroundLowerColor, grade)
        
    }
    
}
