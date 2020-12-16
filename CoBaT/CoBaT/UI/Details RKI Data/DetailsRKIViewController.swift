//
//  DetailsRKIViewController.swift
//  CoBaT
//
//  Created by Hartwig Hopfenzitz on 29.11.20.
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
final class DetailsRKIViewController: UIViewController {
    
    // ---------------------------------------------------------------------------------------------
    // MARK: - Class Properties
    // ---------------------------------------------------------------------------------------------
    // the oberserver have to be released, otherwise there wil be a memory leak.
    // this variable were set in "ViewDidApear()" and released in "ViewDidDisappear()"
    var newRKIDataReadyObserver: NSObjectProtocol?
    var newGraphReadyObserver: NSObjectProtocol?

    // variables to hold the related strings for the Labels
    var forTitel: String = ""
    var forLabelKindOf: String = ""
    var forLabelInhabitants: String = ""
    var forValueInhabitants: String = ""
    
    
    
    // ---------------------------------------------------------------------------------------------
    // MARK: - Translated texts
    // ---------------------------------------------------------------------------------------------
    let inhabitantsText = NSLocalizedString("label-inhabitants", comment: "Label text for inhabitants")

    
    // ---------------------------------------------------------------------------------------------
    // MARK: - UI Outlets
    // ---------------------------------------------------------------------------------------------
    
//    @IBOutlet weak var labelKindOf: UILabel!
//
//    @IBOutlet weak var labelInhabitants: UILabel!
//    @IBOutlet weak var ValueInhabitants: UILabel!
   
    
    @IBOutlet weak var DoneButton: UIBarButtonItem!
    @IBAction func DoneButtonAction(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
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
        
        // set title and label
        self.updateLabels()
    }
    
    /**
     -----------------------------------------------------------------------------------------------
     
     viewDidAppear()
     
     -----------------------------------------------------------------------------------------------
     */
    override func viewDidAppear(_ animated: Bool) {
        super .viewDidAppear(animated)
        
        
        // add observer to recognise if new data did araived. just in case the name was changed by RKI
        newRKIDataReadyObserver = NotificationCenter.default.addObserver(
            forName: .CoBaT_NewRKIDataReady,
            object: nil,
            queue: OperationQueue.main,
            using: { Notification in

                #if DEBUG_PRINT_FUNCCALLS
                print("DetailsRKIViewController just recieved signal .CoBaT_NewRKIDataReady, call updateLabels()")
                #endif

                self.updateLabels()
            })
        
 
        
    }
 
    /**
     -----------------------------------------------------------------------------------------------
     
     viewDidDisappear()
     
     -----------------------------------------------------------------------------------------------
     */
    override func viewDidDisappear(_ animated: Bool) {
        super .viewDidDisappear(animated)
        
        // remove the observer if set
        if let observer = newRKIDataReadyObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = newGraphReadyObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    
    
    // ---------------------------------------------------------------------------------------------
    // MARK: - UI Helpers
    // ---------------------------------------------------------------------------------------------
    /**
     -----------------------------------------------------------------------------------------------
     
     finds the label texts and displays these, based on GlobalUIData.unique.UIDetailsRKIAreaLevel and GlobalUIData.unique.UIDetailsRKISelectedMyID
     
     -----------------------------------------------------------------------------------------------
     */
    private func updateLabels() {

        // get the related data from the global storage in sync
        GlobalStorageQueue.async(execute: {

            // create shortcuts
            let selectedAreaLevel = GlobalUIData.unique.UIDetailsRKIAreaLevel
            let selectedMyID = GlobalUIData.unique.UIDetailsRKISelectedMyID

            // shortcut
            let RKIDataToUse = GlobalStorage.unique.RKIData[selectedAreaLevel][0]

            // try to find the index of the requested ID
            if let indexRKIData = RKIDataToUse.firstIndex(where: { $0.myID == selectedMyID } ) {

                // we found a valid index, so store the data locally
                self.forTitel = RKIDataToUse[indexRKIData].name

//                forLabelKindOf = RKIDataToUse[indexRKIData].kindOf
//
//                forValueInhabitants = numberNoFractionFormatter.string(
//                    from: NSNumber(value: RKIDataToUse[indexRKIData].inhabitants))
//                    ?? NSLocalizedString("updateLabels-no-index", comment: "Label text that we did not found valid data")
//
//                forLabelInhabitants = NSLocalizedString("label-inhabitants",
//                                                        comment: "Label text for inhabitants")

            } else {

                // we did not found a valid index, report and use default values
                GlobalStorage.unique.storeLastError(errorText: "DetailsRKIViewController.updateLabels: Error: did not found valid index for ID \"\(selectedMyID)/” of area level \"\(selectedAreaLevel)\", use default texts")

                self.forTitel = NSLocalizedString("updateLabels-no-index",
                                             comment: "Label text that we did not found valid data")
//                forLabelKindOf = ""
//
//                forValueInhabitants = ""

            }
        //})

        // set the label text on main thread
        DispatchQueue.main.async(execute: {

            self.title = self.forTitel
//            self.labelKindOf.text = self.forLabelKindOf
//
//            self.labelInhabitants.text = self.forLabelInhabitants
//            self.ValueInhabitants.text = self.forValueInhabitants
        })
    })
    }
    
//     ---------------------------------------------------------------------------------------------
//     MARK: - Navigation
//     ---------------------------------------------------------------------------------------------
//
//        // In a storyboard-based application, you will often want to do a little preparation before navigation
//        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//            // Get the new view controller using segue.destination.
//            // Pass the selected object to the new view controller.
//
//            if (segue.identifier == "CallEmbeddedDetailsRKITableViewController") {
//                myEmbeddedTableViewController = segue.destination as? DetailsRKITableViewController
//            }
//        }
}


