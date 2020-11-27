//
//  GlobalUIData.swift
//  CoBaT
//
//  Created by Hartwig Hopfenzitz on 27.11.20.
//

import Foundation


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
    // MARK: - Constants and variables
    // ---------------------------------------------------------------------------------------------
    private let permanentStore = UserDefaults.standard

    public var UIBrowserRKIAreaLevel: Int = GlobalStorage.unique.RKIDataCounty
    public var UIBrowserRKISelectedID: String = "7"
    public var UIBrowserRKITitelString: String = "Rheinland-Pfalz"
    
    public enum UIBrowserRKISortEnum : Int {
        case alphabetically = 0, incidencesAscending = 1, incidencesDescending = 2
    }
    
    public var UIBrowserRKISorting : UIBrowserRKISortEnum = .alphabetically
    
    
    // ---------------------------------------------------------------------------------------------
    // MARK: - RKI Data API
    // ---------------------------------------------------------------------------------------------
    
    /**
     -----------------------------------------------------------------------------------------------
     
     reads the permananently stored values into the global storage. Values are stored in user defaults
     
     -----------------------------------------------------------------------------------------------
     */
    public func restoreSavedUIData() {
        
        DispatchQueue.main.async(execute: {
            
            print("restoreSavedUIData just started")

            self.UIBrowserRKIAreaLevel = self.permanentStore.integer(
                forKey: "CoBaT.UIBrowserRKIAreaLevel")
            
            if let loadedUIBrowserRKISelectedID = self.permanentStore.string(
                forKey: "CoBaT.UIBrowserRKISelectedID") {
                
                self.UIBrowserRKISelectedID = loadedUIBrowserRKISelectedID
            }
            
            if let loadedUIBrowserRKITitelString = self.permanentStore.string(
                forKey: "CoBaT.UIBrowserRKITitelString") {
                
                self.UIBrowserRKITitelString = loadedUIBrowserRKITitelString
            }

            if let loadedUIBrowserRKISorting = UIBrowserRKISortEnum(
                rawValue: self.permanentStore.integer(forKey: "CoBaT.UIBrowserRKISorting")) {
                self.UIBrowserRKISorting = loadedUIBrowserRKISorting
            }

         })
        
    }
    
    /**
     -----------------------------------------------------------------------------------------------
     
     stores the thre variables RKIData, RKIDataTimeStamps and RKIDataLastUpdated into the permanant store
     
     -----------------------------------------------------------------------------------------------
     */
    public func saveUIData() {
        
        // make sure we have consistent data (for Ui alsways main thread!
        DispatchQueue.main.async(execute: {
            
            print("saveUIData just started")

            self.permanentStore.set(self.UIBrowserRKIAreaLevel, forKey: "CoBaT.UIBrowserRKIAreaLevel")
            self.permanentStore.set(self.UIBrowserRKISelectedID, forKey: "CoBaT.UIBrowserRKISelectedID")
            self.permanentStore.set(self.UIBrowserRKITitelString, forKey: "CoBaT.UIBrowserRKITitelString")
            print("self.UIBrowserRKISorting.rawValue: \(self.UIBrowserRKISorting.rawValue)")
            self.permanentStore.set(self.UIBrowserRKISorting.rawValue, forKey: "CoBaT.UIBrowserRKISorting")

         })
    }

  

}
