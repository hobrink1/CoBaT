//
//  MainViewController.swift
//  CoBaT
//
//  Created by Hartwig Hopfenzitz on 20.11.20.
//

import UIKit





class MainViewController: UIViewController {

    @IBOutlet weak var DeutschlandButton: UIButton!
    @IBAction func DeutschlandButtonAction(_ sender: UIButton) {
        
        performSegue(withIdentifier: "CallBrowseRKIIViewController", sender: self)
        GlobalUIData.unique.UIBrowserRKITitelString = "Deutschland"
        GlobalUIData.unique.UIBrowserRKISelectedID = "0"
        GlobalUIData.unique.UIBrowserRKIAreaLevel = GlobalStorage.unique.RKIDataCountry
        GlobalUIData.unique.saveUIData()


    }
    
    @IBOutlet weak var StateButton: UIButton!
    @IBAction func StateButtonAction(_ sender: UIButton) {

        performSegue(withIdentifier: "CallBrowseRKIIViewController", sender: self)
        GlobalUIData.unique.UIBrowserRKIAreaLevel = GlobalStorage.unique.RKIDataState
        GlobalUIData.unique.UIBrowserRKITitelString = "Bundesländer"
        GlobalUIData.unique.UIBrowserRKISelectedID = "0"
        GlobalUIData.unique.saveUIData()

    }
   
    @IBOutlet weak var CountyButton: UIButton!
    @IBAction func CountydButtonAction(_ sender: UIButton) {
        
        performSegue(withIdentifier: "CallBrowseRKIIViewController", sender: self)
        GlobalUIData.unique.UIBrowserRKIAreaLevel = GlobalStorage.unique.RKIDataCounty
        GlobalUIData.unique.UIBrowserRKITitelString = "Rheinland-Pfalz"
        GlobalUIData.unique.UIBrowserRKISelectedID = "7"
        GlobalUIData.unique.saveUIData()
    }
   
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.title = "CoBaT"
        
        
        
        
    }


}

