//
//  BrowseRKIViewController.swift
//  CoBaT
//
//  Created by Hartwig Hopfenzitz on 24.11.20.
//

import UIKit



class BrowseRKIViewController: UIViewController {

    var selectedState: String = "Rheinland-Pfalz"
    
    @IBOutlet weak var Explanation: UILabel!
    
    @IBOutlet weak var Usage: UILabel!
    
    @IBOutlet weak var Select: UILabel!
    @IBOutlet weak var Details: UILabel!
    
    
    @IBOutlet weak var NavBarTitle: UINavigationItem!
    
    @IBOutlet weak var DoneButton: UIBarButtonItem!
    @IBAction func DoneButtonAction(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBOutlet weak var SortButton: UIBarButtonItem!
    @IBAction func SortButtonAction(_ sender: UIBarButtonItem) {
    }
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        self.showExplanation()
        
        self.Usage.text = "Pro Datensatz:"
        self.Select.text = "< Auswahl"
        self.Details.text = "Details >"
    }
    
    
    /**
     -----------------------------------------------------------------------------------------------
     
     showExplanation()
     
     -----------------------------------------------------------------------------------------------
     */
    func showExplanation() {
        
        let numberOfDataRecords: Int = GlobalStorage.unique.RKIData[GlobalStorage.unique.RKIDataCounty].count
        
        if numberOfDataRecords == 0 {
            
            self.Explanation.text = NSLocalizedString("Explanation-No-Data",
                                                      comment: "Explanation if no data available")
            
        } else if numberOfDataRecords == 1 {
            
            self.Explanation.text = NSLocalizedString("Explanation-One-Day",
                                                      comment: "Explanation if only one day of data available")
            
        } else if numberOfDataRecords == 2 {
            
            self.Explanation.text = NSLocalizedString("Explanation-Two-Days",
                                                      comment: "Explanation if exactly two days of data are available")
            
        } else {

            self.Explanation.text = String.localizedStringWithFormat(
                
                NSLocalizedString("Explanation-Three-Days",
                                  comment: "Explanation if three or more days of data are available"),
                numberOfDataRecords
            )
            
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
