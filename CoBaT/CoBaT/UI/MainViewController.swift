//
//  MainViewController.swift
//  CoBaT
//
//  Created by Hartwig Hopfenzitz on 20.11.20.
//

import UIKit

var UIBrowseRKIAreaLevel: Int = GlobalStorage.unique.RKIDataCounty
var UIBrowseRKISelectedID: String = "7"



class MainViewController: UIViewController {

    @IBOutlet weak var DeutschlandButton: UIButton!
    @IBAction func DeutschlandButtonAction(_ sender: UIButton) {
        
        performSegue(withIdentifier: "CallBrowseRKIIViewController", sender: self)
        UIBrowseRKIAreaLevel = GlobalStorage.unique.RKIDataCountry

    }
    
    @IBOutlet weak var StateButton: UIButton!
    @IBAction func StateButtonAction(_ sender: UIButton) {

        performSegue(withIdentifier: "CallBrowseRKIIViewController", sender: self)
        UIBrowseRKIAreaLevel = GlobalStorage.unique.RKIDataState
    }
   
    @IBOutlet weak var CountyButton: UIButton!
    @IBAction func CountydButtonAction(_ sender: UIButton) {
        
        performSegue(withIdentifier: "CallBrowseRKIIViewController", sender: self)
        UIBrowseRKIAreaLevel = GlobalStorage.unique.RKIDataCounty
    }
   
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
    }


}

