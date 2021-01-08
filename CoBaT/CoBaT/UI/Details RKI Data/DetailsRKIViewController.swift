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
    
    var selectedAreaLevel: Int = 0
    var selectedMyID: String = ""

    let IsFavoriteImage : UIImage = UIImage(systemName: "heart.fill")!
    let IsNotFavoriteImage: UIImage = UIImage(systemName: "heart")!
    
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
    
    
    
    @IBOutlet weak var FavoritesButton: UIBarButtonItem!
    @IBAction func FavoritesButtonAction(_ sender: UIBarButtonItem) {
        
        DispatchQueue.main.async(execute: {
            
            // we use the image as a flag if the item is already a favorite or not
            if self.FavoritesButton.image == self.IsNotFavoriteImage {
                
                // item is not a favorite, so save it as a favorite
                
                // switch image
                self.FavoritesButton.image = self.IsFavoriteImage
                
                // save it
                GlobalStorage.unique.saveNewFavorite(level: self.selectedAreaLevel,
                                                     id: self.selectedMyID)
                
            } else {
                
                // item was a favorite, so remove it
                
                // switch the image
                self.FavoritesButton.image = self.IsNotFavoriteImage
                
                // remove the item from the list
                GlobalStorage.unique.removeFavorite(level:  self.selectedAreaLevel,
                                                     id: self.selectedMyID)
            }
        })
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
                print("DetailsRKIViewControllerDetailsRKIViewController just recieved signal .CoBaT_NewRKIDataReady, call updateLabels()")
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
        
        // the details screen is called in two differnt scenarios: First form main screen and
        // in rki browser. to make sure that the right graph will be shown when user gets back
        // to the main screen, we have to save the selected arealevel and ID and restore it, when
        // the browsed detail screen disapeared
        // we do that by saving the two values in BrowseRKIDataTableViewController.detailsButtonTapped()
        // and restore it in DetailsRKIViewController.viewDidDisappear()

        // restore the vaues
        GlobalStorageQueue.async(flags: .barrier, execute: {
            GlobalUIData.unique.UIDetailsRKIAreaLevel = GlobalUIData.unique.UIDetailsRKIAreaLevelSaved
            GlobalUIData.unique.UIDetailsRKISelectedMyID = GlobalUIData.unique.UIDetailsRKISelectedMyIDSaved
            
            #if DEBUG_PRINT_FUNCCALLS
            print("DetailsRKIViewController.viewDidDisappear(): reset ID to \"\(GlobalUIData.unique.UIDetailsRKISelectedMyID)\" and Area to \(GlobalUIData.unique.UIDetailsRKIAreaLevel), post .CoBaT_Graph_NewDetailSelected")
            #endif
            
            
            DispatchQueue.main.async(execute: {
                NotificationCenter.default.post(Notification(name: .CoBaT_Graph_NewDetailSelected))
            })
        })

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
            self.selectedAreaLevel = GlobalUIData.unique.UIDetailsRKIAreaLevel
            self.selectedMyID = GlobalUIData.unique.UIDetailsRKISelectedMyID

            #if DEBUG_PRINT_FUNCCALLS
            print("DetailsRKIViewController.updateLabels(): will use ID to \"\(self.selectedMyID)\" and Area to \(self.selectedAreaLevel)")
            #endif

            // check if the item is a favorite, we will later set the image of the butto according to this flag
            let isAFavorite = GlobalStorage.unique.RKIFavorites[self.selectedAreaLevel].contains(self.selectedMyID)
            
            
            // shortcut
            let RKIDataToUse = GlobalStorage.unique.RKIData[self.selectedAreaLevel][0]

            // try to find the index of the requested ID
            if let indexRKIData = RKIDataToUse.firstIndex(where: { $0.myID == self.selectedMyID } ) {

                // we found a valid index, so store the data locally
                self.forTitel = RKIDataToUse[indexRKIData].name

            } else {

                // we did not found a valid index, report and use default values
                GlobalStorage.unique.storeLastError(errorText: "DetailsRKIViewController.updateLabels: Error: did not found valid index for ID \"\(self.selectedMyID)/” of area level \"\(self.selectedAreaLevel)\", use default texts")

                self.forTitel = NSLocalizedString("updateLabels-no-index",
                                             comment: "Label text that we did not found valid data")
            }
        //})

        // set the label text on main thread
            DispatchQueue.main.async(execute: {
                
                // set the title
                self.title = self.forTitel
                
                // check if it  is a favorite and set the image
                if isAFavorite == true {
                    self.FavoritesButton.image = self.IsFavoriteImage
                } else {
                    self.FavoritesButton.image = self.IsNotFavoriteImage
                }
                
                
                
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


