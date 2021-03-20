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
class MapViewController: UIViewController, MKMapViewDelegate {
    
    // ---------------------------------------------------------------------------------------------
    // MARK: - Class Properties
    // ---------------------------------------------------------------------------------------------
    // the oberserver have to be released, otherwise there wil be a memory leak.
    // this variable were set in "ViewDidApear()" and released in "ViewDidDisappear()"
    private var newRKIDataReadyObserver: NSObjectProtocol?
    private var UIDataRestoredObserver: NSObjectProtocol?
    private var enterBackgroundObserver: NSObjectProtocol?
    private var MapOverlayBuildObserver: NSObjectProtocol?
    
    
    private var currentIndex : Int = 0
    private var maxIndex : Int = 0
    private var oldIndex : Int = 0
    
    private let ButtonBorderColorUI = UIColor.label
    private let ButtonBorderColorCG = UIColor.label.cgColor
    private let ButtonBorderColorDimmendUI = UIColor.tertiaryLabel
    private let ButtonBorderColorDimmendCG = UIColor.tertiaryLabel.cgColor

    
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
    
    
    // ---------------------------------------------------------------------------------------------
    // the button to switch to the prevoius day
    @IBOutlet weak var BackwardButton: UIButton!
    @IBAction func BackwardButtonAction(_ sender: UIButton) {
        
        // check bounds
        if self.currentIndex < self.maxIndex {
            
            // check if we have to activate the forward button
            if self.currentIndex == 0 {
                
                DispatchQueue.main.async(execute: {
                    
                    self.ForwardButton.layer.borderColor = self.ButtonBorderColorCG
                    self.ForwardButton.tintColor = self.ButtonBorderColorUI
                    
                })
            }
            
            // just go one day into the past
            self.currentIndex += 1
            
            // remember that
            self.oldIndex = self.currentIndex
            
            // if we reach the end we better deactivate the button
            if self.currentIndex == self.maxIndex {
                
                DispatchQueue.main.async(execute: {
                    
                    self.BackwardButton.layer.borderColor = self.ButtonBorderColorDimmendCG
                    self.BackwardButton.tintColor = self.ButtonBorderColorDimmendUI
                    
                })
                
            }
            
            // Update the map
            self.updateMap()
            
        }
    }
    
    
    // ---------------------------------------------------------------------------------------------
    // the button to switch to the next day
    @IBOutlet weak var ForwardButton: UIButton!
    @IBAction func ForwardButtonAction(_ sender: UIButton) {
        
        // check bounds
        if self.currentIndex > 0 {
            
            // check if we have to activate the backward button
            if self.currentIndex == self.maxIndex {
                
                DispatchQueue.main.async(execute: {

                    self.BackwardButton.layer.borderColor = self.ButtonBorderColorCG
                    self.BackwardButton.tintColor = self.ButtonBorderColorUI
                    
                })
            }

            // just go one day into the future
            self.currentIndex -= 1
            
            // remember that
            self.oldIndex = self.currentIndex
            
            // Update the map
            self.updateMap()
            
            // check if we have to deactivate the button
            if self.currentIndex == 0 {
                
                 DispatchQueue.main.async(execute: {
                    
                    self.ForwardButton.layer.borderColor = self.ButtonBorderColorDimmendCG
                    self.ForwardButton.tintColor = self.ButtonBorderColorDimmendUI
                    
                })
            }
        }
     }
    
    
    // ---------------------------------------------------------------------------------------------
    // the button to toggle bewteen today and the last other selected
    @IBOutlet weak var TodayButton: UIButton!
    @IBAction func TodayButtonAction(_ sender: UIButton) {
        
        if (self.currentIndex == 0)
            && (self.oldIndex != 0) {
            
            // set the button styles
            DispatchQueue.main.async(execute: {
                
                self.ForwardButton.layer.borderColor = self.ButtonBorderColorCG
                self.ForwardButton.tintColor = self.ButtonBorderColorUI
                
            })
            
            
            self.currentIndex = self.oldIndex
            
            if (self.currentIndex == self.maxIndex) {
                
                DispatchQueue.main.async(execute: {
                    
                    self.BackwardButton.layer.borderColor = self.ButtonBorderColorDimmendCG
                    self.BackwardButton.tintColor = self.ButtonBorderColorDimmendUI
                })
            }
            
            self.updateMap()
            
            
        } else if (self.currentIndex != 0) {
            
            // set the button styles
            if (self.currentIndex == self.maxIndex) {
                
                DispatchQueue.main.async(execute: {
                    self.BackwardButton.layer.borderColor = self.ButtonBorderColorCG
                    self.BackwardButton.tintColor = self.ButtonBorderColorUI
                })
            }


                DispatchQueue.main.async(execute: {
                    self.ForwardButton.layer.borderColor = self.ButtonBorderColorDimmendCG
                    self.ForwardButton.tintColor = self.ButtonBorderColorDimmendUI
                })
            
            
            
            // set the new index
            self.currentIndex = 0
            
            // and execute
            self.updateMap()
        }
    }
    
    // ---------------------------------------------------------------------------------------------

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
     
     
     
     -----------------------------------------------------------------------------------------------
     
     - Parameters:
     - :
     
     - Returns:
     
     */
    private func loadOverlays() {
        
        // get the related data from the global storage in sync
        GlobalStorageQueue.async(execute: {
            
            // check if we have data
            if (GlobalStorage.unique.RKIData[GlobalStorage.unique.RKIDataCounty].isEmpty == true)
                || (GlobalUIData.unique.RKIMapOverlaysBuild == false) {
                
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
                    
                    if GlobalUIData.unique.RKIMapOverlaysBuild == false {
                        self.NotYetLabel.text = NSLocalizedString("no-Overlay-data",
                                                                  comment: "no County Data available")
                    } else {
                        self.NotYetLabel.text = NSLocalizedString("no-County-data",
                                                                  comment: "no County Data available")
                    }
                })
                
            } else {
                
                // prepare the overlays and add them to the map
                for index in 0 ..< GlobalUIData.unique.RKIMapOverlays.count {
                    
                    // connect the map with the overlay
                    GlobalUIData.unique.RKIMapOverlays[index].mapToServe = self.MyMapView
                }

                DispatchQueue.main.async(execute: {
                    self.MyMapView.addOverlays(GlobalUIData.unique.RKIMapOverlays,
                                               level: .aboveRoads)
                    
                    
                    // refresh the map
                    self.updateMap()
                })
            }
        })
    }
    
    
    /**
     -----------------------------------------------------------------------------------------------
     
     
     
     -----------------------------------------------------------------------------------------------
     
     - Parameters:
     - :
     
     - Returns:
     
     */
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        // variable for return a renderer
        let renderer: MKOverlayRenderer
        
        if overlay is RKIMapOverlay {
            
            // this is our renderer for the map
            renderer = RKI_Map_Overlay_Renderer(overlay: overlay)
            
        } else {
            
            // default
            renderer = MKOverlayRenderer(overlay: overlay)
        }
        
        return renderer
    } // func

    
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
            
            // get the current max index (could be changed because of new loaded data)
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
            
            
            // build the string for the country incideces as part of the today label
            var incidenceString: String = ""
            if GlobalStorage.unique.RKIData[GlobalStorage.unique.RKIDataCountry].isEmpty == false {
                if GlobalStorage.unique.RKIData[GlobalStorage.unique.RKIDataCountry].count > self.currentIndex {
                    if GlobalStorage.unique.RKIData[GlobalStorage.unique.RKIDataCountry][self.currentIndex].isEmpty == false {
                        
                        let curremtIncidence = GlobalStorage.unique.RKIData[GlobalStorage.unique.RKIDataCountry][self.currentIndex].first!.cases7DaysPer100K
                        
                        
                        if let incidenceNumber = number1FractionFormatter.string(from: NSNumber(value: curremtIncidence)) {
                             
                            incidenceString = " - \(incidenceNumber)"
                        }
                    }
                }
            }

            // build the final label
            let dateString = "\(myDate) (\(myWeekday))\(incidenceString)"
            
            // update IBOutlets
            DispatchQueue.main.async(execute: {
                
                // so we have something to show
                self.NotYetLabel.isHidden = true
                
                // show and activate the buttons
                self.BackwardButton.isHidden = false
                self.BackwardButton.isEnabled = true
                
                self.ForwardButton.isHidden = false
                self.ForwardButton.isEnabled = true
                
                self.TodayButton.isHidden = false
                self.TodayButton.isEnabled = true

                if (self.currentIndex == 0) {
                    
                    self.ForwardButton.layer.borderColor = self.ButtonBorderColorDimmendCG
                    self.ForwardButton.tintColor = self.ButtonBorderColorDimmendUI
                    
                    if self.currentIndex == self.maxIndex {
                        
                        self.BackwardButton.layer.borderColor = self.ButtonBorderColorDimmendCG
                        self.BackwardButton.tintColor = self.ButtonBorderColorDimmendUI

                    } else {
                        
                        self.BackwardButton.layer.borderColor = self.ButtonBorderColorCG
                        self.BackwardButton.tintColor = self.ButtonBorderColorUI
                    }
                    
                } else {
                    
                    self.ForwardButton.isEnabled = true
                    self.ForwardButton.layer.borderColor = self.ButtonBorderColorCG
                    
                    if self.currentIndex == self.maxIndex {
                        
                        self.BackwardButton.layer.borderColor = self.ButtonBorderColorDimmendCG
                        self.BackwardButton.tintColor = self.ButtonBorderColorDimmendUI

                    } else {
                        
                        self.BackwardButton.layer.borderColor = self.ButtonBorderColorCG
                        self.BackwardButton.tintColor = self.ButtonBorderColorUI
                    }
                }
                                
                // and show the label
                self.CurrentDayLabel.isHidden = false
                self.CurrentDayLabel.text = dateString
                
            }) // main
            
            // set the newDaycode (will force a redraw)
            for index in 0 ..< GlobalUIData.unique.RKIMapOverlays.count {
                GlobalUIData.unique.RKIMapOverlays[index].changeDayIndex(newIndex: self.currentIndex)
            }
            
            // switch spinner OFF
            DispatchQueue.main.async(execute:  {
                
                // switch the spinner OFF
                self.ActivityIndicator.stopAnimating()
                self.ActivityIndicator.isHidden = true
                
            }) // main
            
        }) // GlobalStorageQueue
    }

    
    /**
     -----------------------------------------------------------------------------------------------
     
     restoreMapRegion()
     
     -----------------------------------------------------------------------------------------------
     */
    private func restoreMapRegion() {
        
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
        
        self.MyMapView.delegate = self
        
        self.MyMapView.isRotateEnabled = false
        self.MyMapView.isPitchEnabled = false
        
        // set the title
        self.title = NSLocalizedString("Title-Map-Button",
                                       comment: "Title of Map Button")

        
        // build the map region to display and show it on the map
        self.restoreMapRegion()
        
        
        // set the buttons and labels
        let borderWidth: CGFloat = 1
        let borderRadius: CGFloat = 10
        
        self.BackwardButton.layer.borderColor = self.ButtonBorderColorCG
        self.BackwardButton.layer.borderWidth = borderWidth
        self.BackwardButton.layer.cornerRadius = borderRadius
        self.BackwardButton.isHidden = true
        self.BackwardButton.isEnabled = false

        self.ForwardButton.layer.borderColor = self.ButtonBorderColorDimmendCG
        self.ForwardButton.layer.borderWidth = borderWidth
        self.ForwardButton.layer.cornerRadius = borderRadius
        self.ForwardButton.isHidden = true
        self.ForwardButton.isEnabled = false

        self.TodayButton.isHidden = true
        self.TodayButton.isEnabled = false

        self.CurrentDayLabel.layer.borderColor = self.ButtonBorderColorCG
        self.CurrentDayLabel.layer.borderWidth = borderWidth
        self.CurrentDayLabel.layer.cornerRadius = borderRadius
        self.CurrentDayLabel.layer.masksToBounds = true
        self.CurrentDayLabel.isHidden = true

        self.NotYetLabel.layer.borderColor = self.ButtonBorderColorCG
        self.NotYetLabel.layer.borderWidth = borderWidth
        self.NotYetLabel.layer.cornerRadius = borderRadius
        self.NotYetLabel.layer.masksToBounds = true
        self.NotYetLabel.isHidden = true

        self.ActivityIndicator.layer.borderColor = self.ButtonBorderColorCG
        self.ActivityIndicator.layer.borderWidth = borderWidth
        self.ActivityIndicator.layer.cornerRadius = borderRadius
        self.ActivityIndicator.isHidden = true
        
        // load the overlays
        self.loadOverlays()

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
                
                self.restoreMapRegion()

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
        
        
        
        if let observer = MapOverlayBuildObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        MapOverlayBuildObserver = NotificationCenter.default.addObserver(
            forName: .CoBaT_Map_OverlaysBuild,
            object: nil,
            queue: OperationQueue.main,
            using: { Notification in
                
                #if DEBUG_PRINT_FUNCCALLS
                print("MapViewController just recieved signal .CoBaT_Map_OverlaysBuild, call loadOverlays()")
                #endif
                
                self.loadOverlays()
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
        
        if let observer = MapOverlayBuildObserver {
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

        if let observer = MapOverlayBuildObserver {
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

