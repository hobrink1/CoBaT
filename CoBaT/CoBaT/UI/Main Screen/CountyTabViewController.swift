//
//  CountyTabViewController.swift
//  CoBaT
//
//  Created by Hartwig Hopfenzitz on 02.12.20.
//

import UIKit


// -------------------------------------------------------------------------------------------------
// MARK: -
// MARK: - CountyTabViewController
// -------------------------------------------------------------------------------------------------

// -------------------------------------------------------------------------------------------------
// MARK: -
// MARK: - Class
// -------------------------------------------------------------------------------------------------
final class CountyTabViewController: UIViewController {

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
        
        // set the variable, will signal the CommonTabBarController what to do
        GlobalUIData.unique.UITabBarCurrentlyActive = GlobalStorage.unique.RKIDataCounty
        
        // Do any additional setup after loading the view.
        
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
