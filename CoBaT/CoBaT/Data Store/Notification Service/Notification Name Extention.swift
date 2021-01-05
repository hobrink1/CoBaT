//
//  Notification Name Extention.swift
//  CoBaT
//
//  Created by Hartwig Hopfenzitz on 28.11.20.
//


// holds the extentions of Notification.Name to ensure an error free name schema


import Foundation

// -------------------------------------------------------------------------------------------------
// MARK: -
// MARK: - extension Notification.Name
// -------------------------------------------------------------------------------------------------


extension Notification.Name {
    
    // ---------------------------------------------------------------------------------------------
    // MARK: -
    // MARK: - RKI Data
    // ---------------------------------------------------------------------------------------------

    // Event: New RKI data retrieved (GlobalStorage.refresh_RKIData())
    // This is just the event, that we did retrieve data.
    // In Addition, the event CoBaT_NewRKIDataReady signals that this data are different or new
    static let CoBaT_RKIDataRetrieved = Notification.Name(rawValue: "CoBaT.RKIDataRetrieved")

    // Event: New RKI data ready to show on UI (GlobalStorage.rebuildRKIDeltas())
    static let CoBaT_NewRKIDataReady = Notification.Name(rawValue: "CoBaT.NewRKIDataReady")

    
    // ---------------------------------------------------------------------------------------------
    // MARK: -
    // MARK: - Error log
    // ---------------------------------------------------------------------------------------------

    // Event: New error was stored (GlobalStorage.storeLastError())
    static let CoBat_NewErrorStored = Notification.Name(rawValue: "CoBaT.NewErrorStored")

    

    // ---------------------------------------------------------------------------------------------
    // MARK: -
    // MARK: - UI
    // ---------------------------------------------------------------------------------------------

    // Event: User selected a new sort strategy
    static let CoBaT_UserDidSelectSort = Notification.Name(rawValue: "CoBaT.UserDidSelectSort")

    // Event: User selected a state
    static let CoBaT_UserDidSelectState = Notification.Name(rawValue: "CoBaT.UserDidSelectState")
    
    // Event: User selected a county
    static let CoBaT_UserDidSelectCounty = Notification.Name(rawValue: "CoBaT.UserDidSelectCounty")
    
    // Event: saved UI Data restored
    static let CoBaT_UIDataRestored = Notification.Name(rawValue: "CoBaT.UIDataRestored")
    
    // Event: CommonTabBar did change its content, so the embedded TableView should update as well
    static let CoBaT_CommonTabBarChangedContent = Notification.Name(rawValue: "CoBaT.CommonTabBarChangedContent")

    // Event: FavoriteTabBar did change its content, so the embedded TableView should update as well
    static let CoBaT_FavoriteTabBarChangedContent = Notification.Name(rawValue: "CoBaT.FavoriteTabBarChangedContent")


    // ---------------------------------------------------------------------------------------------
    // MARK: -
    // MARK: - Graph
    // ---------------------------------------------------------------------------------------------

    // Event: User selected a new detail, so we have to rebuild the graph
    static let CoBaT_Graph_NewDetailSelected = Notification.Name(rawValue: "CoBaT.Graph.NewDetailSelected")
    
    // Event: DetailsRKIGraphic created a new set of graphs
    static let CoBaT_Graph_NewGraphAvailable = Notification.Name(rawValue: "CoBaT.Graph.NewGraphAvailable")
    


}
