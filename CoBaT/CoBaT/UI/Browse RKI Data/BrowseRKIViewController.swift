//
//  BrowseRKIViewController.swift
//  CoBaT
//
//  Created by Hartwig Hopfenzitz on 24.11.20.
//

import UIKit



class BrowseRKIViewController: UIViewController {

    var myEmbeddedTableViewController: BrowseRKIDataTableViewController?
    
    @IBOutlet weak var Explanation: UILabel!
    
    @IBOutlet weak var Usage: UILabel!
    
    @IBOutlet weak var Select: UILabel!
    @IBOutlet weak var Details: UILabel!
    
    
    @IBOutlet weak var NavBarTitle: UINavigationItem!
    
    @IBOutlet weak var DoneButton: UIBarButtonItem!
    @IBAction func DoneButtonAction(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBOutlet weak var EmbeddedContainerView: UIView!
    
    @IBOutlet weak var SortButton: UIBarButtonItem!
    @IBAction func SortButtonAction(_ sender: UIBarButtonItem) {
        
        switch GlobalUIData.unique.UIBrowserRKISorting {
        
        case .alphabetically:
            GlobalUIData.unique.UIBrowserRKISorting = .incidencesAscending
            print("SortButtonAction, UIBrowserRKISorting.rawValue = \(GlobalUIData.unique.UIBrowserRKISorting.rawValue)")
            GlobalUIData.unique.saveUIData()
            
        case .incidencesAscending:
            GlobalUIData.unique.UIBrowserRKISorting = .incidencesDescending
            print("SortButtonAction, UIBrowserRKISorting.rawValue = \(GlobalUIData.unique.UIBrowserRKISorting.rawValue)")
            GlobalUIData.unique.saveUIData()

        case .incidencesDescending:
            GlobalUIData.unique.UIBrowserRKISorting = .alphabetically
            print("SortButtonAction, UIBrowserRKISorting.rawValue = \(GlobalUIData.unique.UIBrowserRKISorting.rawValue)")
            GlobalUIData.unique.saveUIData()
        }
        
        self.setSortButton()
        self.myEmbeddedTableViewController?.RefreshLocalData()
        
    }
    
    /**
     -----------------------------------------------------------------------------------------------
     
     
     
     -----------------------------------------------------------------------------------------------
     
     - Parameters:
     - :
     
     - Returns:
     
     */
    private func setSortButton() {
        
        DispatchQueue.main.async(execute: {
            switch GlobalUIData.unique.UIBrowserRKISorting {
            
            case .alphabetically:
                self.SortButton.image = UIImage(systemName: "arrow.up.arrow.down")
                
                break
                
            case .incidencesAscending:
                self.SortButton.image = UIImage(systemName: "arrow.up")
                
                break
                
            case .incidencesDescending:
                self.SortButton.image = UIImage(systemName: "arrow.down")
                
                
                break
            }
        })
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        // set title and sortButton
        self.title = GlobalUIData.unique.UIBrowserRKITitelString
        self.setSortButton()

        // show the explanation
        self.showExplanation()


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

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
     
        if (segue.identifier == "CallEmbeddedBrowseRKIDataTableViewController") {
            myEmbeddedTableViewController = segue.destination as? BrowseRKIDataTableViewController
        }
     
    }
    

}
