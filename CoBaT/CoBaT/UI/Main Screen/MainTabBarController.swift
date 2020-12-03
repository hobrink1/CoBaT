//
//  MainTabBarController.swift
//  CoBaT
//
//  Created by Hartwig Hopfenzitz on 02.12.20.
//

import UIKit

// -------------------------------------------------------------------------------------------------
// MARK: -
// MARK: - MainTabBarController
// -------------------------------------------------------------------------------------------------

// -------------------------------------------------------------------------------------------------
// MARK: -
// MARK: - Class
// -------------------------------------------------------------------------------------------------

class MainTabBarController: UITabBarController, UITabBarControllerDelegate {

    // ---------------------------------------------------------------------------------------------
    // MARK: - Properties
    // ---------------------------------------------------------------------------------------------

    // the oberservers have to be released, otherwise there wil be a memory leak.
    // this variables were set in "ViewDidApear()" and released in "ViewDidDisappear()"
    var userSelectedStateObserver: NSObjectProtocol?
    var userSelectedCountyObserver: NSObjectProtocol?
    
    // this view is sometimes already loaded (and set) when the UISettings were restored (DataRace)
    // so we have a noticifaction to reset the UI after we restored the data
    var UIDataRestoredObserver: NSObjectProtocol?
    var UIDataAreRestored: Bool = false
    
    
    // ---------------------------------------------------------------------------------------------
    // MARK: - Helpers
    // ---------------------------------------------------------------------------------------------

    /**
     -----------------------------------------------------------------------------------------------
     
     Set the title texts for the TabBarItems according to the selected by user
     
     -----------------------------------------------------------------------------------------------
     */
    private func refreshBarItemTitles() {
        
        // as we change the UI, zuse main threat
        DispatchQueue.main.async(execute: {
            
            // first tab is always Country level
            self.tabBar.items?[GlobalStorage.unique.RKIDataCountry].title = "Deutschland"
            self.tabBar.items?[GlobalStorage.unique.RKIDataCountry].image = nil
            self.tabBar.items?[GlobalStorage.unique.RKIDataCountry].selectedImage = nil
            
            // set the state level
            self.tabBar.items?[GlobalStorage.unique.RKIDataState].title = GlobalUIData.unique.UIBrowserRKISelectedStateName
            self.tabBar.items?[GlobalStorage.unique.RKIDataState].image = nil
            self.tabBar.items?[GlobalStorage.unique.RKIDataState].selectedImage = nil
            
            self.tabBar.items?[GlobalStorage.unique.RKIDataCounty].title = GlobalUIData.unique.UIBrowserRKISelectedCountyName
            self.tabBar.items?[GlobalStorage.unique.RKIDataCounty].image = nil
            self.tabBar.items?[GlobalStorage.unique.RKIDataCounty].selectedImage = nil
        })
    }
    
    /**
     -----------------------------------------------------------------------------------------------
     
     Set the the index
     
     -----------------------------------------------------------------------------------------------
     */
    private func refreshAfterUIDataRestored() {
        
        // as we change the UI, zuse main threat
        DispatchQueue.main.async(execute: {
            
            
            // restore the selcted tab
            self.selectedIndex = GlobalUIData.unique.UIMainTabBarSelectedTab

            // the titles might alsoi changed
            self.refreshBarItemTitles()
            
//            // set the flag after all is done
//            DispatchQueue.main.async(execute: {
//                self.UIDataAreRestored = true
//            })
        })
    }

    
    // ---------------------------------------------------------------------------------------------
    // MARK: - Tab bar delegate
    // ---------------------------------------------------------------------------------------------
    override func tabBar(_: UITabBar, didSelect: UITabBarItem) {
     
        // we have to search for the selected item, as self.selectedIndex has still the old value
        // so loop over the tabbars
        for index in 0 ..< self.tabBar.items!.count {
            
            // get the current one
            let item = self.tabBar.items![index]
            
            // check the titlke
            if (item.title == didSelect.title)
                //&& (UIDataAreRestored == true)
                && (index != GlobalUIData.unique.UIMainTabBarSelectedTab) {
                
                // we found it and it changed, save it
                GlobalUIData.unique.UIMainTabBarSelectedTab = index
                GlobalUIData.unique.saveUIData()
                
                // we can break the loop
                break
            }
        }
    }
    
    // ---------------------------------------------------------------------------------------------
    // MARK: - Life Cycle
    // ---------------------------------------------------------------------------------------------

    /**
     -----------------------------------------------------------------------------------------------
     
     viewDidLoad()
     
     -----------------------------------------------------------------------------------------------
     */
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        #if DEBUG_PRINT_FUNCCALLS
        print("MainTabBarController.viedDidLoad() just started")
        #endif

        // restore the selcted tab
        self.selectedIndex = GlobalUIData.unique.UIMainTabBarSelectedTab
        
        // we use a largher font for the barItems, as we do not use images
        let appearance = UITabBarItem.appearance()
        let attributes = [NSAttributedString.Key.font:UIFont.systemFont(ofSize: 17)]
        appearance.setTitleTextAttributes(attributes as [NSAttributedString.Key : Any], for: .normal)

        // set the tab names
        self.refreshBarItemTitles()
         
        self.delegate = self
    }
    
    /**
     -----------------------------------------------------------------------------------------------
     
     viewDidAppear()
     
     -----------------------------------------------------------------------------------------------
     */
    override func viewDidAppear(_ animated: Bool) {
        super .viewDidAppear(animated)
        // Do any additional setup after loading the view.
        
        // add observer to recognise if user selcted new state
        userSelectedStateObserver = NotificationCenter.default.addObserver(
            forName: .CoBaT_UserDidSelectState,
            object: nil,
            queue: OperationQueue.main,
            using: { Notification in
                
                // refresh the tab bar item titels to reflect the new selection by user
                self.refreshBarItemTitles()

                #if DEBUG_PRINT_FUNCCALLS
                print("MainTabBarController just recieved signal .CoBaT_UserDidSelectState")
                #endif
            })
        
        // add observer to recognise if user selcted new state
        userSelectedStateObserver = NotificationCenter.default.addObserver(
            forName: .CoBaT_UserDidSelectCounty,
            object: nil,
            queue: OperationQueue.main,
            using: { Notification in
                
                // refresh the tab bar item titels to reflect the new selection by user
                self.refreshBarItemTitles()
                
                #if DEBUG_PRINT_FUNCCALLS
                print("MainTabBarController just recieved signal .CoBaT_UserDidSelectCounty")
                #endif
            })
        
        // add observer to recognise if user selcted new state
         UIDataRestoredObserver = NotificationCenter.default.addObserver(
            forName: .CoBaT_UIDataRestored,
            object: nil,
            queue: OperationQueue.main,
            using: { Notification in
                
                // refresh the tab bar item titels to reflect the new selection by user
                self.refreshAfterUIDataRestored()
                
                #if DEBUG_PRINT_FUNCCALLS
                print("MainTabBarController just recieved signal .CoBaT_UIDataRestored")
                #endif
            })
        
        DispatchQueue.main.async(execute: {
            // and to avoid a dataRace at all
            // restore the selcted tab
            self.selectedIndex = GlobalUIData.unique.UIMainTabBarSelectedTab
        })

      }
 
    /**
     -----------------------------------------------------------------------------------------------
     
     viewDidDisappear()
     
     -----------------------------------------------------------------------------------------------
     */
    override func viewDidDisappear(_ animated: Bool) {
        super .viewDidDisappear(animated)
        
        // remove the observer if set
        if let observer = userSelectedStateObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        // remove the observer if set
        if let observer = userSelectedCountyObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        // remove the observer if set
        if let observer = UIDataRestoredObserver {
            NotificationCenter.default.removeObserver(observer)
        }

        
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
