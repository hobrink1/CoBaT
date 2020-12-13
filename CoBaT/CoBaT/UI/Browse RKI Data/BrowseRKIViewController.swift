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
        
        var thisIsCountryLevel: Bool = false
        
        GlobalStorageQueue.async(execute: {
            
            // check if we are on Country level
            if GlobalUIData.unique.UIBrowserRKIAreaLevel == GlobalStorage.unique.RKIDataCountry {
                thisIsCountryLevel = true
            }
            
            // we manage UI so main thread
            DispatchQueue.main.async(execute: {
                
                // check if we are on Country level
                if thisIsCountryLevel == true {
                    
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
        })
    }
    
    
    /**
     -----------------------------------------------------------------------------------------------
     
     showExplanation()
     
     -----------------------------------------------------------------------------------------------
     */
    func showExplanation() {
        
        var explanationString: String = ""
        var selectString: String = ""
        var usageString: String = ""
        var detailsString: String = ""

        
        GlobalStorageQueue.async(execute: {
            
            let numberOfDataRecords: Int = GlobalStorage.unique.RKIData[GlobalStorage.unique.RKIDataCounty].count
            
            if numberOfDataRecords == 0 {
                
                explanationString = NSLocalizedString("Explanation-No-Data",
                                                      comment: "Explanation if no data available")
                
            } else if numberOfDataRecords == 1 {
                
                let timeIntervalOfToday = GlobalStorage.unique.RKIData[GlobalStorage.unique.RKIDataCounty][0][0].timeStamp
                let dateOfToday = Date(timeIntervalSinceReferenceDate: timeIntervalOfToday)
                let stringOfToday = shortSingleRelativeDateFormatter.string(from: dateOfToday)
                let formatString = NSLocalizedString("Explanation-One-Day",
                                                     comment: "Explanation if only one day of data available")
                explanationString = String(format: formatString, stringOfToday)

                
            } else {

                let timeIntervalOfToday = GlobalStorage.unique.RKIData[GlobalStorage.unique.RKIDataCounty][0][0].timeStamp
                let dateOfToday = Date(timeIntervalSinceReferenceDate: timeIntervalOfToday)
                let stringOfToday = shortSingleRelativeDateFormatter.string(from: dateOfToday)
                
                let timeIntervalOfYesterday = GlobalStorage.unique.RKIData[GlobalStorage.unique.RKIDataCounty][1][0].timeStamp
                let dateOfYesterday = Date(timeIntervalSinceReferenceDate: timeIntervalOfYesterday)
                let stringOfYesterday = shortSingleRelativeDateFormatter.string(from: dateOfYesterday)

                let formatString = NSLocalizedString("Explanation-Two-Days",
                                                     comment: "Explanation that we have more days available")
                explanationString = String(format: formatString, stringOfToday, stringOfYesterday)
                
            }
            
            // show "< select" if usefull
            if GlobalUIData.unique.UIBrowserRKIAreaLevel == GlobalStorage.unique.RKIDataCountry {
                selectString = ""
            } else {
                selectString = NSLocalizedString("Explanation-select-If-Useful",
                                                 comment: "usage line hint \"< Select\" if usefull")
            }
            
            // the rest of the usage line
            usageString = NSLocalizedString("Explanation-At-Each-Record",
                                            comment: "usage line hint \"usable for each record\" ")
            
            detailsString = NSLocalizedString("Explanation-Details",
                                              comment: " usage line hint \"Details available\"")
            
            DispatchQueue.main.async(execute: {
                self.Explanation.text = explanationString
                self.Select.text      = selectString
                self.Usage.text       = usageString
                self.Details.text     = detailsString
            })
        })
        
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
