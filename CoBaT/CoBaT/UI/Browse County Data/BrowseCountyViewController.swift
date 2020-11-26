//
//  BrowseCountyViewController.swift
//  CoBaT
//
//  Created by Hartwig Hopfenzitz on 24.11.20.
//

import UIKit

class BrowseCountyViewController: UIViewController {

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
        
        let numberOfDataRecords: Int = GlobalStorage.unique.RKIData[0].count
        
        if numberOfDataRecords == 0 {
            
            self.Explanation.text = "Leider sind noch keine Datensätze gespeichert, die anzeigt werden können"
            
        } else if numberOfDataRecords == 1 {
            
            self.Explanation.text = "Neuinfektionen der letzten 7 Tage per 100.000 Einwohner.\n\nJeden Tag werden Datensätze gespeichert. Sobald die Daten mehrerer Tage verfügbar sind, werden die Veränderung gegenüber des vorletzten und gegenüber dem ältesten Datensatz gezeigt\n"
            
        } else if numberOfDataRecords == 2 {
            
            self.Explanation.text = "Neuinfektionen der letzten 7 Tage per 100.000 Einwohner, sowie die Veränderung gegenüber des letzten Datensatzes"
            
        } else {

            self.Explanation.text = "Neuinfektionen der letzten 7 Tage per 100.000 Einwohner des aktuellen Datensatzes, sowie die Veränderung gegenüber des vorletzten und dem \(numberOfDataRecords). Datensatz"
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
