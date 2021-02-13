//
//  FavoritesTabViewController.swift
//  CoBaT
//
//  Created by Hartwig Hopfenzitz on 05.01.21.
//

import UIKit


// -------------------------------------------------------------------------------------------------
// MARK: -
// MARK: - FavoritesTabViewController
// -------------------------------------------------------------------------------------------------

// -------------------------------------------------------------------------------------------------
// MARK: -
// MARK: - Class
// -------------------------------------------------------------------------------------------------
final class FavoritesTabViewController: UIViewController {

    // ---------------------------------------------------------------------------------------------
    // MARK: - Life cycle
    // ---------------------------------------------------------------------------------------------
    /**
     -----------------------------------------------------------------------------------------------
     
     viewDidLoad()
     
     -----------------------------------------------------------------------------------------------
     */
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
      
    }
    
    /**
     -----------------------------------------------------------------------------------------------
     
     viewDidAppear()
     
     -----------------------------------------------------------------------------------------------
     */
    override func viewDidAppear(_ animated: Bool) {
        super .viewDidAppear(animated)
        
        GlobalStorageQueue.async(flags: .barrier, execute: {
            
            // setup for browser
            //       GlobalUIData.unique.UIBrowserRKITitelString = "Favoriten"
            GlobalUIData.unique.UIBrowserRKIAreaLevel = GlobalStorage.unique.RKIDataFavorites
            GlobalUIData.unique.saveUIData()
            
            // Finally, report we are done
            DispatchQueue.main.async(execute: {
                NotificationCenter.default.post(Notification(name: .CoBaT_FavoriteTabBarChangedContent))
            })
            
        })
     }
 
//    /**
//     -----------------------------------------------------------------------------------------------
//
//     viewDidDisappear()
//
//     -----------------------------------------------------------------------------------------------
//     */
//    override func viewDidDisappear(_ animated: Bool) {
//        super .viewDidDisappear(animated)
//    }



    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
