//
//  MainViewController.swift
//  CoBaT
//
//  Created by Hartwig Hopfenzitz on 20.11.20.
//

import UIKit



// -------------------------------------------------------------------------------------------------
// MARK: -
// MARK: - MainViewController
// -------------------------------------------------------------------------------------------------

// -------------------------------------------------------------------------------------------------
// MARK: -
// MARK: - Class
// -------------------------------------------------------------------------------------------------
class MainViewController: UIViewController {

    // ---------------------------------------------------------------------------------------------
    // MARK: - Properties
    // ---------------------------------------------------------------------------------------------

    // the oberservers have to be released, otherwise there wil be a memory leak.
    // this variables were set in "ViewDidApear()" and released in "ViewDidDisappear()"
    var userSelectedStateObserver: NSObjectProtocol?
    var userSelectedCountyObserver: NSObjectProtocol?

    // ---------------------------------------------------------------------------------------------
    // MARK: - UI Outlets
    // ---------------------------------------------------------------------------------------------

    @IBOutlet weak var DeutschlandButton: UIButton!
    @IBAction func DeutschlandButtonAction(_ sender: UIButton) {
        
        performSegue(withIdentifier: "CallBrowseRKIIViewController", sender: self)
        GlobalUIData.unique.UIBrowserRKITitelString = "Deutschland"
        GlobalUIData.unique.UIBrowserRKIAreaLevel = GlobalStorage.unique.RKIDataCountry
        GlobalUIData.unique.saveUIData()


    }
    
    @IBOutlet weak var StateButton: UIButton!
    @IBAction func StateButtonAction(_ sender: UIButton) {

        performSegue(withIdentifier: "CallBrowseRKIIViewController", sender: self)
        GlobalUIData.unique.UIBrowserRKITitelString = "Bundesländer"
        GlobalUIData.unique.UIBrowserRKIAreaLevel = GlobalStorage.unique.RKIDataState
        GlobalUIData.unique.saveUIData()

    }
   
    @IBOutlet weak var SelectedState: UILabel!
  
    @IBOutlet weak var CountyButton: UIButton!
    @IBAction func CountydButtonAction(_ sender: UIButton) {
        
        performSegue(withIdentifier: "CallBrowseRKIIViewController", sender: self)
        GlobalUIData.unique.UIBrowserRKITitelString = GlobalUIData.unique.UIBrowserRKISelectedStateName
        GlobalUIData.unique.UIBrowserRKIAreaLevel = GlobalStorage.unique.RKIDataCounty
        GlobalUIData.unique.saveUIData()
    }
   
    @IBOutlet weak var SelectedCounty: UILabel!
    
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
        
        self.title = "CoBaT"
        
    }

    /**
     -----------------------------------------------------------------------------------------------
     
     viewDidAppear()
     
     -----------------------------------------------------------------------------------------------
     */
    override func viewDidAppear(_ animated: Bool) {
        super .viewDidAppear(animated)
         // Do any additional setup after loading the view.
        
        self.SelectedState.text = GlobalUIData.unique.UIBrowserRKISelectedStateName
        self.SelectedCounty.text = GlobalUIData.unique.UIBrowserRKISelectedCountyName

        // add observer to recognise if user selcted new state
        userSelectedStateObserver = NotificationCenter.default.addObserver(
            forName: .CoBaT_UserDidSelectState,
            object: nil,
            queue: OperationQueue.main,
            using: { Notification in
                
                self.SelectedState.text = GlobalUIData.unique.UIBrowserRKISelectedStateName
                
                self.SelectedCounty.text = GlobalUIData.unique.UIBrowserRKISelectedCountyName
                
                #if DEBUG_PRINT_FUNCCALLS
                print("MainViewController just recieved signal .CoBaT_UserDidSelectState")
                #endif
            })
        
        // add observer to recognise if user selcted new state
        userSelectedStateObserver = NotificationCenter.default.addObserver(
            forName: .CoBaT_UserDidSelectCounty,
            object: nil,
            queue: OperationQueue.main,
            using: { Notification in
                
                self.SelectedCounty.text = GlobalUIData.unique.UIBrowserRKISelectedCountyName
                
                #if DEBUG_PRINT_FUNCCALLS
                print("MainViewController just recieved signal .CoBaT_UserDidSelectCounty")
                #endif
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
        if let observer = userSelectedStateObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        // remove the observer if set
        if let observer = userSelectedCountyObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // ---------------------------------------------------------------------------------------------
    // MARK: -
    // MARK: - Life Cycle
    // ---------------------------------------------------------------------------------------------

}

