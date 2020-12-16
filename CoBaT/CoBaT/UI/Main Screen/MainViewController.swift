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
final class MainViewController: UIViewController {

    // ---------------------------------------------------------------------------------------------
    // MARK: - Properties
    // ---------------------------------------------------------------------------------------------

    // the oberservers have to be released, otherwise there wil be a memory leak.
    // this variables were set in "ViewDidApear()" and released in "ViewDidDisappear()"
    var userSelectedStateObserver: NSObjectProtocol?
    var userSelectedCountyObserver: NSObjectProtocol?
    
    var RKIDataRetrievedObserver: NSObjectProtocol?
    var NewRKIDataReadyObserver: NSObjectProtocol?


    // ---------------------------------------------------------------------------------------------
    // MARK: - UI Outlets
    // ---------------------------------------------------------------------------------------------

    @IBOutlet weak var LabelRKIAsOf: UILabel!
    @IBOutlet weak var ValueRKIAsOf: UILabel!
    
    @IBOutlet weak var LabelRKILastRetrieved: UILabel!
    @IBOutlet weak var ValueRKILastRetrieved: UILabel!
  
    
    /**
     -----------------------------------------------------------------------------------------------
     
     Help Button
     
     -----------------------------------------------------------------------------------------------
     */
    @IBOutlet weak var HelpButton: UIButton!
    @IBAction func HelpButtonAction(_ sender: UIButton) {
    }
   
    
    /**
     -----------------------------------------------------------------------------------------------
     
     Refresh Button
     
     -----------------------------------------------------------------------------------------------
     */
    @IBOutlet weak var RefreshButton: UIButton!
    @IBAction func RefreshButtonAction(_ sender: UIButton) {
        
        // get fresh data
        RKIDataDownload.unique.getRKIData()
    }
   
    
    
    
    
    // ---------------------------------------------------------------------------------------------
    // MARK: -
    // MARK: - Helpers
    // ---------------------------------------------------------------------------------------------
    /**
     -----------------------------------------------------------------------------------------------
     
     updates the label "RKI As Of"
     
     -----------------------------------------------------------------------------------------------
      */
    private func updateRKIAsOfLabel() {
        
        // check if we have a timeInterval
        if GlobalStorage.unique.RKIDataTimeStamps[0].isEmpty == false {
            
            let myDate: Date = Date(timeIntervalSinceReferenceDate: GlobalStorage.unique.RKIDataTimeStamps[0][0])
        
            self.ValueRKIAsOf.text = longSingleRelativeDateTimeFormatter.string(from: myDate)
            
         } else {
            
            // tell the user, that we do not have any data
            self.ValueRKIAsOf.text = NSLocalizedString("No-RKI-Available", comment: "No RKI Data available message")
        }
    }
    
    
    /**
     -----------------------------------------------------------------------------------------------
     
     updates the label "RKI Last Retrieved"
     
     -----------------------------------------------------------------------------------------------
      */
    private func updateRKILastRetrieved() {
        
        if GlobalStorage.unique.RKIDataLastRetreived != 0 {
            
            let myDate: Date = Date(timeIntervalSinceReferenceDate: GlobalStorage.unique.RKIDataLastRetreived)
            ValueRKILastRetrieved.text = mediumMediumSingleRelativeDateTimeFormatter.string(from: myDate)
            
        } else {
            
            // tell the user, that we do not have any data
            self.ValueRKILastRetrieved.text = NSLocalizedString("Never-retrieved-RKI-data", comment: "Never retriev RKI Data message")
        }
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
        
        self.title = "CoBaT"
        
        self.LabelRKIAsOf.text = NSLocalizedString("RKI-Data-As-Of", comment: "Label RKI Data As Of")
        self.LabelRKILastRetrieved.text = NSLocalizedString("RKI-Data-Last-Retrieved", comment: "Label RKI Data last retrieved")
 
        self.HelpButton.setTitle(NSLocalizedString("Main-Button-Help", comment: "Help Button"),
                                 for: .normal)
        
        self.HelpButton.layer.cornerRadius = 5
        self.HelpButton.layer.borderWidth = 1
        self.HelpButton.layer.backgroundColor = UIColor.systemBackground.cgColor
        self.HelpButton.layer.borderColor = self.HelpButton.tintColor.cgColor
        
        
        self.RefreshButton.setTitle(NSLocalizedString("Main-Button-Refresh", comment: "Refresh Button"),
                                 for: .normal)
        
        self.RefreshButton.layer.cornerRadius = 5
        self.RefreshButton.layer.borderWidth = 1
        self.RefreshButton.layer.backgroundColor = UIColor.systemBackground.cgColor
        self.RefreshButton.layer.borderColor = self.RefreshButton.tintColor.cgColor
        

        // values will be set in
    }

    /**
     -----------------------------------------------------------------------------------------------
     
     viewDidAppear()
     
     -----------------------------------------------------------------------------------------------
     */
    override func viewDidAppear(_ animated: Bool) {
        super .viewDidAppear(animated)
        // Do any additional setup after loading the view.
        
        // add observer to recognise if user selcted new state
        userSelectedStateObserver = NotificationCenter.default.addObserver(
            forName: .CoBaT_UserDidSelectState,
            object: nil,
            queue: OperationQueue.main,
            using: { Notification in
                
                
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
                
                #if DEBUG_PRINT_FUNCCALLS
                print("MainViewController just recieved signal .CoBaT_UserDidSelectCounty")
                #endif
            })
        
        
        // add observer to recognise a new retrieved status
        RKIDataRetrievedObserver = NotificationCenter.default.addObserver(
            forName: .CoBaT_RKIDataRetrieved,
            object: nil,
            queue: OperationQueue.main,
            using: { Notification in
                
                self.updateRKILastRetrieved()
                #if DEBUG_PRINT_FUNCCALLS
                print("MainViewController just recieved signal .CoBaT_RKIDataRetrieved")
                #endif
            })
        
        // add observer to recognise if new data are available
        NewRKIDataReadyObserver = NotificationCenter.default.addObserver(
            forName: .CoBaT_NewRKIDataReady,
            object: nil,
            queue: OperationQueue.main,
            using: { Notification in
                
                self.updateRKIAsOfLabel()
                
                #if DEBUG_PRINT_FUNCCALLS
                print("MainViewController just recieved signal .CoBaT_NewRKIDataReady")
                #endif
            })
        
        // update the labels first time
        self.updateRKIAsOfLabel()
        self.updateRKILastRetrieved()
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
        
        // remove the observer if set
        if let observer = RKIDataRetrievedObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        // remove the observer if set
        if let observer = NewRKIDataReadyObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

 }

