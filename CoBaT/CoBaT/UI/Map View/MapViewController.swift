//
//  MapViewController.swift
//  CoBaT
//
//  Created by Hartwig Hopfenzitz on 17.03.21.
//

import UIKit
import MapKit

// -------------------------------------------------------------------------------------------------
// MARK: -
// MARK: - MapViewController
// -------------------------------------------------------------------------------------------------

// -------------------------------------------------------------------------------------------------
// MARK: -
// MARK: - Class
// -------------------------------------------------------------------------------------------------
class MapViewController: UIViewController {
    
    // ---------------------------------------------------------------------------------------------
    // MARK: - Class Properties
    // ---------------------------------------------------------------------------------------------
    // the oberserver have to be released, otherwise there wil be a memory leak.
    // this variable were set in "ViewDidApear()" and released in "ViewDidDisappear()"
    private var newRKIDataReadyObserver: NSObjectProtocol?
    private var UIDataRestoredObserver: NSObjectProtocol?
    private var enterBackgroundObserver: NSObjectProtocol?
    
    
    private var currentIndex : Int = 0
    private var maxIndex : Int = 0
    private var oldIndex : Int = 0
    
    
    // ---------------------------------------------------------------------------------------------
    // MARK: - UI Outlets
    // ---------------------------------------------------------------------------------------------

    // go back button
    @IBOutlet weak var DoneButton: UIBarButtonItem!
    @IBAction func DoneButtonAction(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // The map itself
    @IBOutlet weak var MyMapView: MKMapView!
    
    
    // the button to switch to the prevoius day
    @IBOutlet weak var BackwardButton: UIButton!
    @IBAction func BackwardButtonAction(_ sender: UIButton) {
        
        // check bounds
        if self.currentIndex < self.maxIndex {
            
            // just go one day into the past
            self.currentIndex += 1
            
            // remember that
            self.oldIndex = self.currentIndex
            
            // Update the map
            self.updateMap()
        }
        
    }
    
    
    // the button to switch to the next day
    @IBOutlet weak var ForwardButton: UIButton!
    @IBAction func ForwardButtonAction(_ sender: UIButton) {
        
        // check bounds
        if self.currentIndex > 0 {
            
            // just go one day into the future
            self.currentIndex -= 1
            
            // remember that
            self.oldIndex = self.currentIndex
            
            // Update the map
            self.updateMap()
        }
     }
    
    
    // the button to toggle bewteen today and the last other selected
    @IBOutlet weak var TodayButton: UIButton!
    @IBAction func TodayButtonAction(_ sender: UIButton) {
        
        if (self.currentIndex == 0)
            && (self.oldIndex != 0) {
            
            self.currentIndex = self.oldIndex
            
            self.updateMap()
            
        } else if (self.currentIndex != 0) {
            
            self.currentIndex = 0
            self.updateMap()
        }
    }
    
    
    // the label showing the current selcted day
    @IBOutlet weak var CurrentDayLabel: UILabel!
    
    
    // spinner which is displayed while we update the map
    @IBOutlet weak var ActivityIndicator: UIActivityIndicatorView!
    
    
    // A label we show, if we do not have any map data (yet)
    @IBOutlet weak var NotYetLabel: UILabel!
    
    
    // ---------------------------------------------------------------------------------------------
    // MARK: - UI Helpers
    // ---------------------------------------------------------------------------------------------
    /**
     -----------------------------------------------------------------------------------------------
     
     finds the label texts and displays these, based on GlobalUIData.unique.UIDetailsRKIAreaLevel and GlobalUIData.unique.UIDetailsRKISelectedMyID
     
     -----------------------------------------------------------------------------------------------
     */
    private func updateMap() {

        
        // switch the spinner ON
        DispatchQueue.main.async(execute: {
            self.ActivityIndicator.isHidden = false
            self.ActivityIndicator.startAnimating()
            
            self.CurrentDayLabel.text = ""
        })
        
        // get the related data from the global storage in sync
        GlobalStorageQueue.async(execute: {
 
            // check if we have data
            if GlobalStorage.unique.RKIData[GlobalStorage.unique.RKIDataCounty].isEmpty == true {
                
                DispatchQueue.main.async(execute: {
                    
                    // hide the buttons and deactivate them
                    self.BackwardButton.isHidden = true
                    self.ForwardButton.isHidden = true
                    self.TodayButton.isHidden = true

                    self.BackwardButton.isEnabled = false
                    self.ForwardButton.isEnabled = false
                    self.TodayButton.isEnabled = false

                    self.CurrentDayLabel.isHidden = true

                    // switch the spinner OFF
                    self.ActivityIndicator.stopAnimating()
                    self.ActivityIndicator.isHidden = true

                    // show the message
                    self.NotYetLabel.isHidden = false
                    self.NotYetLabel.text = NSLocalizedString("no-County-data",
                                                              comment: "no County Data available")
                    
                })
                
            } else {
                
                // get the current max index
                self.maxIndex = GlobalStorage.unique.RKIData[GlobalStorage.unique.RKIDataCounty].count - 1
                
                // check bounds
                if self.currentIndex > self.maxIndex {
                    
                    self.currentIndex = self.maxIndex
                }
                
                if self.oldIndex > self.maxIndex {
                    
                    self.oldIndex = self.maxIndex
                }

                // get the current data
                let currentDayData = GlobalStorage.unique.RKIData[GlobalStorage.unique.RKIDataCounty][self.currentIndex]

                
                // build the date string
                
                let myDate = shortSingleRelativeDateFormatter.string(
                    from: Date(timeIntervalSinceReferenceDate: currentDayData[0].timeStamp))
                
                let myWeekday = dateFormatterLocalizedWeekdayShort.string(
                    from: Date(timeIntervalSinceReferenceDate: currentDayData[0].timeStamp))

                let dateString = "\(myDate) (\(myWeekday))"
                
                DispatchQueue.main.async(execute: {
                    
                    // so we have something to show
                    self.NotYetLabel.isHidden = true
                    
                    // show and activate the buttons
                    self.BackwardButton.isHidden = false
                    self.ForwardButton.isHidden = false
                    self.TodayButton.isHidden = false
                    
                    self.BackwardButton.isEnabled = true
                    self.ForwardButton.isEnabled = true
                    self.TodayButton.isEnabled = true

                    // and show the label
                    self.CurrentDayLabel.isHidden = false
                    self.CurrentDayLabel.text = dateString
                    
                    //usleep(2)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2), execute:  {
                        // switch the spinner OFF
                        self.ActivityIndicator.stopAnimating()
                        self.ActivityIndicator.isHidden = true
                        
                    })
                })
            }

        })

    }

    
    /**
     -----------------------------------------------------------------------------------------------
     
     resetMapRegion()
     
     -----------------------------------------------------------------------------------------------
     */
    private func resetMapRegion() {
        
        // build the map region to display and show it on the map
        GlobalStorageQueue.async(execute: {
            
            // get the data and build the region
            let centerOfMap = GlobalUIData.unique.UIMapLastCenterCoordinate
            let regionToDisplay = MKCoordinateRegion(center: centerOfMap,
                                                     span: GlobalUIData.unique.UIMapLastSpan)
            
            // set the map
            DispatchQueue.main.async(execute: {
                self.MyMapView.setCenter(centerOfMap, animated: false)
                self.MyMapView.setRegion(regionToDisplay, animated: false)
            })
        })
    }
    
    /**
     -----------------------------------------------------------------------------------------------
     
     saveMapRegion()
     
     -----------------------------------------------------------------------------------------------
     */
    private func saveMapRegion() {
        
        // save the center coordinate and span persistent
        GlobalStorageQueue.async(flags: .barrier, execute: {
            
            GlobalUIData.unique.UIMapLastCenterCoordinate = self.MyMapView.centerCoordinate
            GlobalUIData.unique.UIMapLastSpan = self.MyMapView.region.span
            
            GlobalUIData.unique.saveMapRegion()
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
        
        // build the map region to display and show it on the map
        self.resetMapRegion()
        
        
        // set the buttons and labels
        let borderColor = UIColor.label.cgColor
        let borderWidth: CGFloat = 1
        let borderRadius: CGFloat = 10
        
        self.BackwardButton.layer.borderColor = borderColor
        self.BackwardButton.layer.borderWidth = borderWidth
        self.BackwardButton.layer.cornerRadius = borderRadius
        self.BackwardButton.isHidden = true
        self.BackwardButton.isEnabled = false

        self.ForwardButton.layer.borderColor = borderColor
        self.ForwardButton.layer.borderWidth = borderWidth
        self.ForwardButton.layer.cornerRadius = borderRadius
        self.ForwardButton.isHidden = true
        self.ForwardButton.isEnabled = false

        self.TodayButton.isHidden = true
        self.TodayButton.isEnabled = false

        self.CurrentDayLabel.layer.borderColor = borderColor
        self.CurrentDayLabel.layer.borderWidth = borderWidth
        self.CurrentDayLabel.layer.cornerRadius = borderRadius
        self.CurrentDayLabel.isHidden = true

        self.NotYetLabel.layer.borderColor = borderColor
        self.NotYetLabel.layer.borderWidth = borderWidth
        self.NotYetLabel.layer.cornerRadius = borderRadius
        self.NotYetLabel.isHidden = true

        self.ActivityIndicator.layer.borderColor = borderColor
        self.ActivityIndicator.layer.borderWidth = borderWidth
        self.ActivityIndicator.layer.cornerRadius = borderRadius
        self.ActivityIndicator.isHidden = true

    }
    
    
    
    /**
     -----------------------------------------------------------------------------------------------
     
     viewDidAppear()
     
     -----------------------------------------------------------------------------------------------
     */
    override func viewDidAppear(_ animated: Bool) {
        super .viewDidAppear(animated)
        
        
        // add observer to recognise if new data did araived. just in case the name was changed by RKI
        if let observer = newRKIDataReadyObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        newRKIDataReadyObserver = NotificationCenter.default.addObserver(
            forName: .CoBaT_NewRKIDataReady,
            object: nil,
            queue: OperationQueue.main,
            using: { Notification in
                
                #if DEBUG_PRINT_FUNCCALLS
                print("MapViewController just recieved signal .CoBaT_NewRKIDataReady, call updateMap()")
                #endif
                
                self.updateMap()
            })
        
        
        if let observer = UIDataRestoredObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        UIDataRestoredObserver = NotificationCenter.default.addObserver(
            forName: .CoBaT_UIDataRestored,
            object: nil,
            queue: OperationQueue.main,
            using: { Notification in
                
                #if DEBUG_PRINT_FUNCCALLS
                print("MapViewController just recieved signal .CoBaT_UIDataRestored, call resetMapRegion()")
                #endif
                
                self.resetMapRegion()

            })
        
        

        if let observer = enterBackgroundObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        enterBackgroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: OperationQueue.main,
            using: { Notification in
                
                #if DEBUG_PRINT_FUNCCALLS
                print("MapViewController just recieved signal .didEnterBackgroundNotification, call saveMapRegion()")
                #endif
                
                self.saveMapRegion()
            })
        
        
        
        
        // do it the first time
        self.updateMap()
        
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

        if let observer = UIDataRestoredObserver {
            NotificationCenter.default.removeObserver(observer)
        }

        if let observer = enterBackgroundObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        // save the center coordinate and span persistent
        self.saveMapRegion()

    }

    /**
     -----------------------------------------------------------------------------------------------
     
     deinit
     
     -----------------------------------------------------------------------------------------------
     */
    deinit {
        
        // remove the observer if set
        if let observer = newRKIDataReadyObserver {
            NotificationCenter.default.removeObserver(observer)
        }
  
        if let observer = UIDataRestoredObserver {
            NotificationCenter.default.removeObserver(observer)
        }

        if let observer = enterBackgroundObserver {
            NotificationCenter.default.removeObserver(observer)
        }

        // save the center coordinate and span persistent
        self.saveMapRegion()

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

