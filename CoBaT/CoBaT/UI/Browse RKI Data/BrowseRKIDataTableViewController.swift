//
//  BrowseCountyDataTableViewController.swift
//  CoBaT
//
//  Created by Hartwig Hopfenzitz on 24.11.20.
//

import UIKit

// -------------------------------------------------------------------------------------------------
// MARK: -
// MARK: - Browse County Data Table View Controller
// -------------------------------------------------------------------------------------------------
class BrowseRKIDataTableViewController: UITableViewController {

    // ---------------------------------------------------------------------------------------------
    // MARK: - Local storage
    // ---------------------------------------------------------------------------------------------

    // this will be set by the calling View Controller to selct the desired State
    var StateSelected: String = "Rheinland-Pfalz"
    
    // local copy of County Data, susetted by selected State
    var localDataArray: [GlobalStorage.RKIDataStruct] = []
    var localDataArrayDelta1: [GlobalStorage.RKIDataStruct] = []
    var localDataArrayDelta7: [GlobalStorage.RKIDataStruct] = []

    // the number of days available
    var numberOfDayAvailable: Int = 0
    
    // ---------------------------------------------------------------------------------------------
    // MARK: - Helper
    // ---------------------------------------------------------------------------------------------
    func RefreshLocalData() {
        
        var localDataArrayUnsorted: [GlobalStorage.RKIDataStruct] = []
        var localDataArrayDelta1Unsorted: [GlobalStorage.RKIDataStruct] = []
        var localDataArrayDelta7Unsorted: [GlobalStorage.RKIDataStruct] = []
        
        // read the current content of the global storage
        GlobalStorageQueue.sync(execute: {
            
            numberOfDayAvailable = GlobalStorage.unique.RKIData[GlobalStorage.unique.RKIDataCounty].count
            // get the global storage, filtered to the current selected state
            
            // check if we have current data
            if numberOfDayAvailable > 0 {
                
                // yes at least current data are available so try to get some
                if GlobalUIData.unique.UIBrowserRKIAreaLevel == GlobalStorage.unique.RKIDataCounty {
                    localDataArrayUnsorted = GlobalStorage.unique.RKIData[GlobalUIData.unique.UIBrowserRKIAreaLevel][0].filter(
                        { $0.stateID == GlobalUIData.unique.UIBrowserRKISelectedID})
                } else {
                    localDataArrayUnsorted = GlobalStorage.unique.RKIDataDeltas [GlobalUIData.unique.UIBrowserRKIAreaLevel][0]
                }
            }
            
            // check if we have data from yesterday
            if numberOfDayAvailable > 1 {
                
                // yes at least data from "yesterday" are available so try to get some
                if GlobalUIData.unique.UIBrowserRKIAreaLevel == GlobalStorage.unique.RKIDataCounty {
                    
                    localDataArrayDelta1Unsorted = GlobalStorage.unique.RKIDataDeltas [GlobalUIData.unique.UIBrowserRKIAreaLevel][1].filter(
                        { $0.stateID == GlobalUIData.unique.UIBrowserRKISelectedID})
                } else {
                    localDataArrayDelta1Unsorted = GlobalStorage.unique.RKIDataDeltas [GlobalUIData.unique.UIBrowserRKIAreaLevel][1]
                }
                
            }
            
            // check if we have data from several days
            if numberOfDayAvailable > 2 {
                
                // yes at least data from "yesterday" are available so try to get some
                if GlobalUIData.unique.UIBrowserRKIAreaLevel == GlobalStorage.unique.RKIDataCounty {
                    
                    // yes at least data from "yesterday" are available so try to get some
                    localDataArrayDelta7Unsorted = GlobalStorage.unique.RKIDataDeltas [GlobalUIData.unique.UIBrowserRKIAreaLevel][numberOfDayAvailable - 1].filter(
                        { $0.stateID == GlobalUIData.unique.UIBrowserRKISelectedID})
                } else {
                    localDataArrayDelta7Unsorted = GlobalStorage.unique.RKIDataDeltas [GlobalUIData.unique.UIBrowserRKIAreaLevel][numberOfDayAvailable - 1]
                }
                
                
            }
        })
        
        // sort the local copy
        print("sofar")
        self.sortLocalData(source0: localDataArrayUnsorted,
                           source1: localDataArrayDelta1Unsorted,
                           source7: localDataArrayDelta7Unsorted)
    }
    
    /**
     -----------------------------------------------------------------------------------------------
     
     
     
     -----------------------------------------------------------------------------------------------
     
     - Parameters:
     - :
     
     - Returns:
     
     */
    public func sortLocalData(source0: [GlobalStorage.RKIDataStruct],
                               source1: [GlobalStorage.RKIDataStruct],
                               source7: [GlobalStorage.RKIDataStruct])
    {
        
        // we use the main thread as our working thread, so we have no problems in UI updates
        DispatchQueue.main.async {
            
            print("sortLocalData just started")
            
            switch GlobalUIData.unique.UIBrowserRKISorting {
            
            case .alphabetically:
                self.localDataArray = source0.sorted( by: { $0.name < $1.name } )
                
            case .incidencesAscending:
                self.localDataArray = source0.sorted( by: { $0.cases7DaysPer100K < $1.cases7DaysPer100K } )

            case .incidencesDescending:
                self.localDataArray = source0.sorted( by: { $0.cases7DaysPer100K > $1.cases7DaysPer100K } )
            }
            
            
            self.localDataArrayDelta1.removeAll()
            self.localDataArrayDelta7.removeAll()
            
            if self.numberOfDayAvailable > 1 {
                
                for item in self.localDataArray {
                    
                    
                    if let index1InUnsorted = source1.firstIndex(where: { $0.name == item.name } ) {
                        
                        //print("\(item.name): index1InUnsorted: \(index1InUnsorted) of \(source1.count)")
                        self.localDataArrayDelta1.append(source1[index1InUnsorted])
                    } else {
                        
                        //print("\(item.name): index1InUnsorted: unknown of \(source1.count), new \(self.localDataArrayDelta1.count)")

                        self.localDataArrayDelta1.append(GlobalStorage.RKIDataStruct(
                                                        stateID:            item.stateID,
                                                        name:               item.name,
                                                        kindOf:             item.kindOf,
                                                        inhabitants:        0,
                                                        cases:              0,
                                                        deaths:             0,
                                                        casesPer100k:       0,
                                                        cases7DaysPer100K:  0,
                                                        timeStamp:          item.timeStamp))
                    }
                    
                    if self.numberOfDayAvailable > 2 {
                        if let index7InUnsorted = source7.firstIndex(where: { $0.name == item.name } ) {
                            
                            //print("\(item.name): index7InUnsorted: \(index7InUnsorted) of \(source7.count), new \(self.localDataArrayDelta1.count)")
                            self.localDataArrayDelta7.append(source7[index7InUnsorted])
                        } else {
                            //print("\(item.name): index7InUnsorted: unknown of \(source7.count)")
                            self.localDataArrayDelta7.append(GlobalStorage.RKIDataStruct(
                                                            stateID:            item.stateID,
                                                            name:               item.name,
                                                            kindOf:             item.kindOf,
                                                            inhabitants:        0,
                                                            cases:              0,
                                                            deaths:             0,
                                                            casesPer100k:       0,
                                                            cases7DaysPer100K:  0,
                                                            timeStamp:          item.timeStamp))
                        }
                    }
                }
            }
            print("sortLocalData done")

            // reload the cells
            self.tableView.reloadData()
        }

        
    }
    
    /**
     -----------------------------------------------------------------------------------------------
     
     build a formatted string of the number with the correct sign (+, ±, -)
     
     -----------------------------------------------------------------------------------------------
     
     - Parameters:
        - number: the integer number to convert into a string
     
     - Returns: the string
     
     */
    private func getFormattedDeltaTextInt(number: Int) -> String {
        
        var returnString: String = ""
        
        if let valueString = numberNoFractionFormatter.string(from: NSNumber(value: number)) {
            
            if number > 0 {
                returnString = "+"
            } else if number == 0 {
                returnString = "±"
            }
            
            returnString += valueString
            
        } else {
            
            returnString = "---"
        }
        
        return returnString
    }
    
    
    /**
     -----------------------------------------------------------------------------------------------
     
     build a formatted string of the number with the correct sign (+, ±, -)
     
     -----------------------------------------------------------------------------------------------
     
     - Parameters:
        - number: the double number to convert into a string
     
     - Returns: the string
     
     */
    private func getFormattedDeltaTextDouble(number: Double, withFraction: Bool) -> String {
        
        var returnString: String = ""
        
        if withFraction == true {
            if let valueString = number1FractionFormatter.string(from: NSNumber(value: number)) {
                
                if number > 0 {
                    returnString = "+"
                } else if number == 0 {
                    returnString = "±"
                }
                
                returnString += valueString
                
            } else {
                
                returnString = "---"
            }
            
        } else {
            
            if let valueString = numberNoFractionFormatter.string(from: NSNumber(value: number)) {
                
                if number > 0 {
                    returnString = "-"
                } else if number == 0 {
                    returnString = "±"
                }
                
                returnString += valueString
            }
        }
        
        return returnString
    }
    
    
    
    // ---------------------------------------------------------------------------------------------
    // MARK: - Life cycle
    // ---------------------------------------------------------------------------------------------
    /**
     -----------------------------------------------------------------------------------------------
     
     viewDidLoad()
     
     -----------------------------------------------------------------------------------------------
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        // we want the cell height self adjust to user selected text size
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 64
        
        // we want a refresh every time the view gets alavie or came back from background
        let notificationCenter = NotificationCenter.default
        //        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(appBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        // refresh the data
        self.RefreshLocalData()
    }
    
    
    /**
     -----------------------------------------------------------------------------------------------
     
     viewDidLoad()
     
     -----------------------------------------------------------------------------------------------
     */
    //    override func viewDidAppear(_ animated: Bool) {
    //        super.viewDidAppear(animated)
    //
    //        // refresh the data
    //        self.RefreshLocalData()
    //    }
    
    //    @objc func appMovedToBackground() {
    //           print("App moved to background!")
    //        }
    
    
    /**
     -----------------------------------------------------------------------------------------------
     
     appBecomeActive()
     
     -----------------------------------------------------------------------------------------------
     */
    @objc func appBecomeActive() {
        
        print("App become active")
        
        // refresh the data
        self.RefreshLocalData()
    }
    
    
    /**
     -----------------------------------------------------------------------------------------------
     
     viewWillDisappear()
     
     -----------------------------------------------------------------------------------------------
     */
    override func viewWillDisappear(_ animated: Bool) {
        
        let notificationCenter = NotificationCenter.default
        
        //            notificationCenter.removeObserver(self, name:UIApplication.willResignActiveNotification, object: nil)
        notificationCenter.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        
        super.viewWillDisappear(animated)
    }
    
    // ---------------------------------------------------------------------------------------------
    // MARK: - Table view data source
    // ---------------------------------------------------------------------------------------------
    
    /**
     -----------------------------------------------------------------------------------------------
     
     numberOfSections()
     
     -----------------------------------------------------------------------------------------------
     */
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    /**
     -----------------------------------------------------------------------------------------------
     
     numberOfRowsInSection:
     
     -----------------------------------------------------------------------------------------------
     */
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.localDataArray.count
    }
    
    
    /**
     -----------------------------------------------------------------------------------------------
     
     cellForRowAt:
     
     -----------------------------------------------------------------------------------------------
     */
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // dequeue a cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "BrowseRKIDataTableViewCell", for: indexPath) as! BrowseRKIDataTableViewCell
        
        // get the related data set from local storage
        let index = indexPath.row
        let myData = localDataArray[index]
        
        // get color schema for 7 day average caces per 100 K people
        let (backgroundColor, textColorToUse) = CovidRating.unique.getColorsForValue(myData.cases7DaysPer100K)
        
        // set the background of the cell
        cell.contentView.backgroundColor = backgroundColor
        
        // color the two chevrons
        cell.ChevronLeft.tintColor = textColorToUse
        cell.ChevronRight.tintColor = textColorToUse
        
        if GlobalUIData.unique.UIBrowserRKIAreaLevel == GlobalStorage.unique.RKIDataCountry {
            cell.ChevronLeft.isHidden = true
        } else {
            cell.ChevronLeft.isHidden = false
        }
        
        
        // fill the data fileds and set text color

        // set the text colors
        cell.Name.textColor = textColorToUse
        
        cell.Cases.textColor = textColorToUse
        cell.FirstCases.textColor = textColorToUse
        cell.SecondCases.textColor = textColorToUse
        cell.ThirdCases.textColor = textColorToUse
        
        cell.Incidences.textColor = textColorToUse
        cell.FirstIncidences.textColor = textColorToUse
        cell.SecondIncidences.textColor = textColorToUse
        cell.ThirdIncidences.textColor = textColorToUse
        
        // set the fixed labels
        cell.Name.text = myData.name
        
        cell.Cases.text = NSLocalizedString("label-cases", comment: "Label text for cases")
        
        cell.Incidences.text = NSLocalizedString("label-incidences", comment: "Label text for incidences")

        // now fill the data fields according to number of available days
        if numberOfDayAvailable == 1 {
            
            cell.FirstCases.text = ""
            cell.SecondCases.text = ""
            
            cell.ThirdCases.text = numberNoFractionFormatter.string(
                from: NSNumber(value: myData.cases))
            
            
            cell.FirstIncidences.text = ""
            cell.SecondIncidences.text = ""
            
            cell.ThirdIncidences.text = number1FractionFormatter.string(
                from: NSNumber(value: myData.cases7DaysPer100K))

            
        } else if (numberOfDayAvailable == 2)
                    && (localDataArrayDelta1.count >= index) {
            
            
            cell.FirstCases.text = ""
            
            cell.SecondCases.text = numberNoFractionFormatter.string(
                from: NSNumber(value: myData.cases))
            
            cell.ThirdCases.text = getFormattedDeltaTextInt(number: localDataArrayDelta1[index].cases)
            
            
            
            cell.FirstIncidences.text = ""
            cell.SecondIncidences.text = number1FractionFormatter.string(
                from: NSNumber(value: myData.cases7DaysPer100K))
            
            cell.ThirdIncidences.text = getFormattedDeltaTextDouble(
                number: localDataArrayDelta1[index].cases7DaysPer100K, withFraction: true)
            
            
        } else if (numberOfDayAvailable > 2)
                    && (localDataArrayDelta1.count >= index)
                    && (localDataArrayDelta7.count >= index) {
            
            
            cell.FirstCases.text = numberNoFractionFormatter.string(
                from: NSNumber(value: myData.cases))
            
            cell.SecondCases.text = getFormattedDeltaTextInt(number: localDataArrayDelta1[index].cases)
            
            cell.ThirdCases.text = getFormattedDeltaTextInt(number: localDataArrayDelta7[index].cases)
            
            
            
            cell.FirstIncidences.text = number1FractionFormatter.string(
                from: NSNumber(value: myData.cases7DaysPer100K))
            
            cell.SecondIncidences.text = getFormattedDeltaTextDouble(
                number: localDataArrayDelta1[index].cases7DaysPer100K, withFraction: true)
            
            cell.ThirdIncidences.text = getFormattedDeltaTextDouble(
                number: localDataArrayDelta7[index].cases7DaysPer100K, withFraction: true)
            
            
        } else {
            
            // something went wrtong, so just show the current numbers
            cell.FirstCases.text = ""
            cell.SecondCases.text = ""
            
            cell.ThirdCases.text = numberNoFractionFormatter.string(
                from: NSNumber(value: myData.cases))
            
            
            cell.FirstIncidences.text = ""
            cell.SecondIncidences.text = ""
            
            cell.ThirdIncidences.text = number1FractionFormatter.string(
                from: NSNumber(value: myData.cases7DaysPer100K))
            
        }
        
        
        // ready to run
        return cell
    }
    
    /**
     -----------------------------------------------------------------------------------------------
     
     heightForRowAt:
     
     -----------------------------------------------------------------------------------------------
     */
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        // we want automatic height (text size adapts to size selectuon by user, cell has to adapt)
        return UITableView.automaticDimension
    }
    
    /*
     // Override to support conditional editing of the table view.
     override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */
    
    /*
     // Override to support editing the table view.
     override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
     if editingStyle == .delete {
     // Delete the row from the data source
     tableView.deleteRows(at: [indexPath], with: .fade)
     } else if editingStyle == .insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */
    
    /*
     // Override to support rearranging the table view.
     override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}
