//
//  CountryTabViewController.swift
//  CoBaT
//
//  Created by Hartwig Hopfenzitz on 02.12.20.
//

import UIKit

// -------------------------------------------------------------------------------------------------
// MARK: -
// MARK: - CountryTabViewController
// -------------------------------------------------------------------------------------------------

// -------------------------------------------------------------------------------------------------
// MARK: -
// MARK: - Class
// -------------------------------------------------------------------------------------------------
class CountryTabViewController: UIViewController {

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
        GlobalUIData.unique.UITabBarCurrentlyActive = GlobalStorage.unique.RKIDataCountry
        
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
