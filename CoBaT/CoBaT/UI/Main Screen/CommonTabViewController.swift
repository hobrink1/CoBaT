//
//  CommonTabViewController.swift
//  CoBaT
//
//  Created by Hartwig Hopfenzitz on 02.12.20.
//

import UIKit

// -------------------------------------------------------------------------------------------------
// MARK: -
// MARK: - CommonTabViewController
// -------------------------------------------------------------------------------------------------

// -------------------------------------------------------------------------------------------------
// MARK: -
// MARK: - Class
// -------------------------------------------------------------------------------------------------
final class CommonTabViewControllerV2: UIViewController {

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
    
    @IBOutlet var ControllerView: UIView!
    
    @IBOutlet weak var LabelSelectedName: UILabel!
    
    
    /**
     -----------------------------------------------------------------------------------------------
     
     SelectButton
     
     -----------------------------------------------------------------------------------------------
     */
    @IBOutlet weak var SelectButton: UIButton!
    @IBAction func SelectButtonAction(_ sender: UIButton) {
        
        // sync the access
        GlobalStorageQueue.async(flags: .barrier, execute: {
            
            switch GlobalUIData.unique.UITabBarCurrentlyActive {
            
            case GlobalStorage.unique.RKIDataCountry:
                
                DispatchQueue.main.async(execute: {
                    self.performSegue(
                        withIdentifier: "CallMapViewControllerFromCommonTabViewController",
                        sender: self)
                })
                
            case GlobalStorage.unique.RKIDataState:
                
                GlobalUIData.unique.UIBrowserRKITitelString = "Bundesländer"
                GlobalUIData.unique.UIBrowserRKIAreaLevel = GlobalStorage.unique.RKIDataState
                GlobalUIData.unique.saveUIData()
                
                DispatchQueue.main.async(execute: {
                    self.performSegue(
                        withIdentifier: "CallBrowseRKIIViewControllerFromCommonTabViewControllerV2",
                        sender: self)
                })
                
            case GlobalStorage.unique.RKIDataCounty:
                
                GlobalUIData.unique.UIBrowserRKITitelString = GlobalUIData.unique.UIBrowserRKISelectedStateName
                GlobalUIData.unique.UIBrowserRKIAreaLevel = GlobalStorage.unique.RKIDataCounty
                GlobalUIData.unique.saveUIData()
                
                DispatchQueue.main.async(execute: {
                    self.performSegue(
                        withIdentifier: "CallBrowseRKIIViewControllerFromCommonTabViewControllerV2",
                        sender: self)
                })
                
            default:
                break
            }
        })
        
    }
  
    
 
    
 
    // ---------------------------------------------------------------------------------------------
    // MARK: -
    // MARK: - Life Cycle
    // ---------------------------------------------------------------------------------------------

    /**
     -----------------------------------------------------------------------------------------------
     
     Refreshes the IBOutlets of this view
     
     -----------------------------------------------------------------------------------------------
     */
    private func refreshOwnDataOutlets() {
        
        // this is a complex func, maybe to rework later
        //
        // there are three phases:
        //
        // first: get the data for at least today, if available also for yesterday and for last week
        // if no data available, create dummy data
        //
        // second: based on the found data, set the colors for background and text based on incidents of today
        //
        // third: set the label texts
        
        // -----------------------------------------------------------------------------------------
        // first: get the data
        //
        // this data will be shown
        var localDataName: String = ""
        var localDataToday: GlobalStorage.RKIDataStruct!
        
        // this will be used to produce dummy data to prevent the UI from crash
        var didNotFoundAnythingUseful: Bool = false
        
        // we need the number of days available to get a useful screen output
        var numberOfDaysAvailable = 0
        
        // sync the access
        GlobalStorageQueue.async(flags: .barrier, execute: {
            
            #if DEBUG_PRINT_FUNCCALLS
            print("CommonTabViewControllerV2.refreshOwnDataOutlets() just started")
            #endif
            
            // shortcut for the selected tab => selected area Level
            let selectedArea = GlobalUIData.unique.UITabBarCurrentlyActive
            
            
            // Get the Id to look for and set the variables for the details
            var myIDToLookFor: String = ""
            switch selectedArea {
            
            case GlobalStorage.unique.RKIDataCountry:
                
                myIDToLookFor = "0"
                GlobalUIData.unique.UIDetailsRKIAreaLevel = GlobalStorage.unique.RKIDataCountry
                GlobalUIData.unique.UIDetailsRKISelectedMyID = "0"

                
            case  GlobalStorage.unique.RKIDataState:
                
                myIDToLookFor = GlobalUIData.unique.UIBrowserRKISelectedStateID
                GlobalUIData.unique.UIDetailsRKIAreaLevel = GlobalStorage.unique.RKIDataState
                GlobalUIData.unique.UIDetailsRKISelectedMyID = GlobalUIData.unique.UIBrowserRKISelectedStateID

                
            case  GlobalStorage.unique.RKIDataCounty:
                
                myIDToLookFor = GlobalUIData.unique.UIBrowserRKISelectedCountyID
                GlobalUIData.unique.UIDetailsRKIAreaLevel = GlobalStorage.unique.RKIDataCounty
                GlobalUIData.unique.UIDetailsRKISelectedMyID = GlobalUIData.unique.UIBrowserRKISelectedCountyID

                
            default:
                GlobalUIData.unique.UIDetailsRKISelectedMyID = ""

                break
            }
            
            #if DEBUG_PRINT_FUNCCALLS
            print("CommonTabViewControllerV2.refreshOwnDataOutlets(): just set ID: \"\(GlobalUIData.unique.UIDetailsRKISelectedMyID)\" and Area to \(GlobalUIData.unique.UIDetailsRKIAreaLevel), post .CoBaT_Graph_NewDetailSelected")
            #endif

            // report that we have selected a new detail
            DispatchQueue.main.async(execute: {
                NotificationCenter.default.post(Notification(name: .CoBaT_Graph_NewDetailSelected))
            })
            
            // Check if we found a usefull ID
            if myIDToLookFor != "" {
                
                // yes, we found a usefull ID, so we can start to collect the data
                
                
                // check how many days of data we have available
                numberOfDaysAvailable = GlobalStorage.unique.RKIData[selectedArea].count
                
                // check if we have at least one day
                if numberOfDaysAvailable > 0 {
                    
                    // we have at least data from Today, so get them
                    let myToday = GlobalStorage.unique.RKIData[selectedArea][0]
                    
                    // if we look for the country Data, we have a shortcut
                    if selectedArea == GlobalStorage.unique.RKIDataCountry {
                        
                        // we look for the country data, which is easy, as there is only one country
                        localDataToday = myToday.first!
                        localDataName = localDataToday.name
                        
                    } else if let myLocalToday = myToday.first(where: { $0.myID == myIDToLookFor} ) {
                        
                        // get the data from today
                        localDataToday = myLocalToday
                        localDataName = localDataToday.name
                        
                    } else {
                        
                        // did not find useful data for today, so report and set flag to produce dummy data
                        didNotFoundAnythingUseful = true
                        GlobalStorage.unique.storeLastError(
                            errorText: "CoBaT.CommonTabViewController.refreshOwnDataOutlets(): ID: \"\(myIDToLookFor)\", did not find useful data for today, show dummy data")
                    }
                    
                     
                } else {
                    
                    // not at least one day available, so report and set flag to produce dummy data
                    didNotFoundAnythingUseful = true
                    GlobalStorage.unique.storeLastError(
                        errorText: "CoBaT.CommonTabViewController.refreshOwnDataOutlets(): ID: \"\(myIDToLookFor)\", not at least one day available, show dummy data")
                }
                
                
            } else {
                
                // did not found usefull ID, so report and set flag to produce dummy data
                didNotFoundAnythingUseful = true
                GlobalStorage.unique.storeLastError(
                    errorText: "CoBaT.CommonTabViewController.refreshOwnDataOutlets(): did not found usefull ID, show dummy data")
                
            }
            
            if didNotFoundAnythingUseful == true {
                
                // did not found anything, so create some dumma data
                
                numberOfDaysAvailable = 1
                localDataName = NSLocalizedString("updateLabels-no-index", comment: "")
                localDataToday = GlobalStorage.RKIDataStruct(
                    stateID: "", myID: "", name: "", kindOf: "", inhabitants: 0, cases: 0, deaths: 0,
                    casesPer100k: 0.0, cases7DaysPer100K: 0.0, timeStamp: 0.0)
            }
            
            
            
            // -------------------------------------------------------------------------------------
            // second: prepare UI
            //
            
            // get the colors
            let (backgroundColor, textColor, _, grade) = CovidRating.unique.getColorsForValue(localDataToday.cases7DaysPer100K)
            
            // save the colors for embedded CommonTabTableViewController
            GlobalUIData.unique.UITabBarCurentTextColor = textColor
            GlobalUIData.unique.UITabBarCurentBackgroundColor = backgroundColor
            GlobalUIData.unique.UITabBarCurentGrade = grade
            
            // save the colors for the embedded DetailsRKITabViewController
            GlobalUIData.unique.UIDetailsRKITextColor = textColor
            GlobalUIData.unique.UIDetailsRKIBackgroundColor = backgroundColor

 
            // update UI on main thread
            DispatchQueue.main.async(execute: {
                
                // set the colors
                self.ControllerView.backgroundColor = backgroundColor
                self.LabelSelectedName.textColor = textColor
                
                // Buttons
                
                // we do not need a select button on Country level, so check if we have to hide it
//                if selectedArea == GlobalStorage.unique.RKIDataCountry {
//
//                    // yes, country level, so hide the button
//                    self.SelectButton.isHidden = true
//                    self.SelectButton.isEnabled = false
//
//                } else {
                    
                    // no, not country level, so make sure the button is working
                    self.SelectButton.isHidden = false
                    self.SelectButton.isEnabled = true
                    
                    self.SelectButton.setTitleColor(textColor, for: .normal)
                    self.SelectButton.layer.borderColor = textColor.cgColor
//                }
                
                
                // ---------------------------------------------------------------------------------
                // third: set the content
                
                // the selected name
                self.LabelSelectedName.text = localDataName
                
                
                // Finally, report we are done
                DispatchQueue.main.async(execute: {
                    NotificationCenter.default.post(Notification(name: .CoBaT_CommonTabBarChangedContent))
                })
            })
            
            #if DEBUG_PRINT_FUNCCALLS
            print("refreshOwnDataOutlets just finished")
            #endif

        }) // GlobalStorageQueue
        
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
        
        // make a nice appearence for the buttons
        self.SelectButton.layer.cornerRadius = 5
        self.SelectButton.layer.borderWidth = 1
        self.SelectButton.layer.borderColor = self.view.tintColor.cgColor
        
        switch GlobalUIData.unique.UITabBarCurrentlyActive {
        
        case GlobalStorage.unique.RKIDataCountry:
            
            self.SelectButton.setTitle(
                NSLocalizedString("Title-Map-Button",
                                  comment: "Title of Map Button"),
                for: .normal)
            
        default:
            
            self.SelectButton.setTitle(
                NSLocalizedString("Title-Select-Button",
                                  comment: "Title of Select Button"),
                for: .normal)
            
        }
    }
    
    /**
     -----------------------------------------------------------------------------------------------
     
     viewDidAppear()
     
     -----------------------------------------------------------------------------------------------
     */
    override func viewDidAppear(_ animated: Bool) {
        super .viewDidAppear(animated)
        
        // add observer to recognise if user selcted new state
        if let observer = userSelectedStateObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        userSelectedStateObserver = NotificationCenter.default.addObserver(
            forName: .CoBaT_UserDidSelectState,
            object: nil,
            queue: OperationQueue.main,
            using: { Notification in
                
                #if DEBUG_PRINT_FUNCCALLS
                print("CommonTabViewController just recieved signal .CoBaT_UserDidSelectState")
                #endif
                
                self.refreshOwnDataOutlets()
            })
        
        // add observer to recognise if user selcted new state
        if let observer = userSelectedCountyObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        userSelectedCountyObserver = NotificationCenter.default.addObserver(
            forName: .CoBaT_UserDidSelectCounty,
            object: nil,
            queue: OperationQueue.main,
            using: { Notification in
                
                #if DEBUG_PRINT_FUNCCALLS
                print("CommonTabViewController just recieved signal .CoBaT_UserDidSelectCounty")
                #endif
                
                self.refreshOwnDataOutlets()
            })
        
        
        // add observer to recognise a new retrieved status
        if let observer = RKIDataRetrievedObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        RKIDataRetrievedObserver = NotificationCenter.default.addObserver(
            forName: .CoBaT_RKIDataRetrieved,
            object: nil,
            queue: OperationQueue.main,
            using: { Notification in

                #if DEBUG_PRINT_FUNCCALLS
                print("CommonTabViewController just recieved signal .CoBaT_RKIDataRetrieved")
                #endif
                
                self.refreshOwnDataOutlets()
            })
        
        // add observer to recognise if new data are available
        if let observer = NewRKIDataReadyObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        NewRKIDataReadyObserver = NotificationCenter.default.addObserver(
            forName: .CoBaT_NewRKIDataReady,
            object: nil,
            queue: OperationQueue.main,
            using: { Notification in
                
                #if DEBUG_PRINT_FUNCCALLS
                print("CommonTabViewController just recieved signal .CoBaT_NewRKIDataReady")
                #endif
                
                self.refreshOwnDataOutlets()
            })

        
        // sometimes the button has the wrong label, so set it again
        switch GlobalUIData.unique.UITabBarCurrentlyActive {
        
        case GlobalStorage.unique.RKIDataCountry:
            
            self.SelectButton.setTitle(
                NSLocalizedString("Title-Map-Button",
                                  comment: "Title of Map Button"),
                for: .normal)
            
        default:
            
            self.SelectButton.setTitle(
                NSLocalizedString("Title-Select-Button",
                                  comment: "Title of Select Button"),
                for: .normal)
            
        }
        self.refreshOwnDataOutlets()
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

    /**
     -----------------------------------------------------------------------------------------------
     
     deinit
     
     -----------------------------------------------------------------------------------------------
     */
    deinit {
        
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

