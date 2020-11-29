//
//  BrowseRKIViewController.swift
//  CoBaT
//
//  Created by Hartwig Hopfenzitz on 24.11.20.
//

import UIKit

// -------------------------------------------------------------------------------------------------
// MARK: -
// MARK: - BrowseRKIViewController
// -------------------------------------------------------------------------------------------------

// -------------------------------------------------------------------------------------------------
// MARK: -
// MARK: - Class
// -------------------------------------------------------------------------------------------------
class BrowseRKIViewController: UIViewController {

    // ---------------------------------------------------------------------------------------------
    // MARK: - UI Outlets
    // ---------------------------------------------------------------------------------------------
    @IBOutlet weak var Explanation: UILabel!
    
    @IBOutlet weak var Usage: UILabel!
    
    @IBOutlet weak var Select: UILabel!
    @IBOutlet weak var Details: UILabel!
    
    
    @IBOutlet weak var NavBarTitle: UINavigationItem!
    
    @IBOutlet weak var DoneButton: UIBarButtonItem!
    @IBAction func DoneButtonAction(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
        
    
    // ---------------------------------------------------------------------------------------------
    // MARK: - Sort
    // ---------------------------------------------------------------------------------------------
    @IBOutlet weak var SortButton: UIBarButtonItem!
    @IBAction func SortButtonAction(_ sender: UIBarButtonItem) {
        
        // chec current situation and switch one step further
        switch GlobalUIData.unique.UIBrowserRKISorting {
        
        case .alphabetically:
            GlobalUIData.unique.UIBrowserRKISorting = .incidencesDescending
  
        case .incidencesDescending:
            GlobalUIData.unique.UIBrowserRKISorting = .incidencesAscending

        case .incidencesAscending:
            GlobalUIData.unique.UIBrowserRKISorting = .alphabetically

        }
        
        // update UI
        self.setSortButton()

        // save the date
        GlobalUIData.unique.saveUIData()

        // local notification to update UI
        NotificationCenter.default.post(Notification(name: .CoBaT_UserDidSelectSort))
        
        #if DEBUG_PRINT_FUNCCALLS
        print("SortButtonAction just posted .CoBaT_UserDidSelectSort")
        #endif
    }
    
    
    // ---------------------------------------------------------------------------------------------
    // MARK: -
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
        
        // set title and sortButton
        self.title = GlobalUIData.unique.UIBrowserRKITitelString
        
        self.setSortButton()

        // show the explanation
        self.showExplanation()
    }
    
    
    // ---------------------------------------------------------------------------------------------
    // MARK: - UI Helpers
    // ---------------------------------------------------------------------------------------------
    
    /**
     -----------------------------------------------------------------------------------------------
     
     Displays the correct image for the sort button according to GlobalUIData.unique.UIBrowserRKISorting
     
     Hides the button, if GlobalUIData.unique.UIBrowserRKIAreaLevel == GlobalStorage.unique.RKIDataCountry
     
     -----------------------------------------------------------------------------------------------
     */
    private func setSortButton() {
        
        // we manage UI so main thread
        DispatchQueue.main.async(execute: {
            
            // check if we are on Country level
            if GlobalUIData.unique.UIBrowserRKIAreaLevel == GlobalStorage.unique.RKIDataCountry {
                
                // yes we are on country level, so hide the button
                self.SortButton.isEnabled = false
                self.SortButton.title = ""
                self.SortButton.image = nil
                
            } else {
                
                // no not country level, so do all required actions
                self.SortButton.isEnabled = true
                self.SortButton.title = ""
                
                // check the sorting strategy
                switch GlobalUIData.unique.UIBrowserRKISorting {
                
                case .alphabetically:
                    self.SortButton.image = UIImage(systemName: "arrow.up.arrow.down")
                    
                case .incidencesAscending:
                    self.SortButton.image = UIImage(systemName: "arrow.up")
                    
                case .incidencesDescending:
                    self.SortButton.image = UIImage(systemName: "arrow.down")
                }
            }
        })
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
        
        // show "< select" if usefull
        if GlobalUIData.unique.UIBrowserRKIAreaLevel == GlobalStorage.unique.RKIDataCountry {
            self.Select.text = ""
        } else {
            self.Select.text = NSLocalizedString("Explanation-select-If-Useful",
                                                 comment: "usage line hint \"< Select\" if usefull")
        }

        // the rest of the usage line
        self.Usage.text = NSLocalizedString("Explanation-At-Each-Record",
                                            comment: "usage line hint \"usable for each record\" ")
        
        self.Details.text = NSLocalizedString("Explanation-Details",
                                              comment: " usage line hint \"Details available\"")
    }

    // ---------------------------------------------------------------------------------------------
    // MARK: - Navigation
    // ---------------------------------------------------------------------------------------------

//    // In a storyboard-based application, you will often want to do a little preparation before navigation
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        // Get the new view controller using segue.destination.
//        // Pass the selected object to the new view controller.
//
//        if (segue.identifier == "CallEmbeddedBrowseRKIDataTableViewController") {
//            myEmbeddedTableViewController = segue.destination as? BrowseRKIDataTableViewController
//        }
//    }
}
