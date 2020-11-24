//
//  BrowseCountyViewController.swift
//  CoBaT
//
//  Created by Hartwig Hopfenzitz on 24.11.20.
//

import UIKit

class BrowseCountyViewController: UIViewController {

    var selectedState: String = "Rheinland-Pfalz"
    @IBOutlet weak var StateToDisplay: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.StateToDisplay.text = self.selectedState
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
