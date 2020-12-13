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
class BrowseRKIDataTableViewController: UITableViewController, BrowseRKIDataTableViewCellPlacesDelegate {

    // ---------------------------------------------------------------------------------------------
    // MARK: - Local storage
    // ---------------------------------------------------------------------------------------------

    // the oberservers have to be released, otherwise there wil be a memory leak.
    // this variables were set in "ViewDidApear()" and released in "ViewDidDisappear()"
    var userDidSelectSortObserver: NSObjectProtocol?
    var newRKIDataReadyObserver: NSObjectProtocol?


    // local copy of County Data, susetted by selected State
    var localDataArray: [GlobalStorage.RKIDataStruct] = []
    var localDataArrayDelta1: [GlobalStorage.RKIDataStruct] = []
    var localDataArrayDelta7: [GlobalStorage.RKIDataStruct] = []

    // the number of days available
    var numberOfDayAvailable: Int = 0
    
    // label texts, translated
    let casesText = NSLocalizedString("label-cases", comment: "Label text for cases")
    let IncidencesText = NSLocalizedString("label-incidences", comment: "Label text for incidences")
    
    // the id string of the selected item, to highlight the related cell
    var selectedItemID: String = ""

    // ----------------------------------------------------------------------------------
    // MARK: - Delegate for select button
    // ----------------------------------------------------------------------------------

    /**
     -----------------------------------------------------------------------------------------------
     
     selectButtonTapped(cell:
     
     -----------------------------------------------------------------------------------------------
     */
    func selectButtonTapped(cell: BrowseRKIDataTableViewCell) {

        #if DEBUG_PRINT_FUNCCALLS
        print("selectButtonTapped just started, row: \(cell.myIndexPath.row)")
        #endif
        
        // get the row
        let row = cell.myIndexPath.row
        
        // which arae level we have
        switch GlobalUIData.unique.UIBrowserRKIAreaLevel {
        
        case GlobalStorage.unique.RKIDataCountry:
            
            // Country Level: nothing to do
            break
            
            
        case GlobalStorage.unique.RKIDataState:
            
            // State Level: set the selected state and his ID, save both and report it
            GlobalUIData.unique.UIBrowserRKISelectedStateName = localDataArray[row].name
            GlobalUIData.unique.UIBrowserRKISelectedStateID = localDataArray[row].stateID
            
            let (countyIndex, countyID, countyName) = GlobalUIData.unique.getCountyFromStateID(
                stateID: localDataArray[row].stateID)
                
            GlobalUIData.unique.UIBrowserRKISelectedCountyID = countyID
            GlobalUIData.unique.UIBrowserRKISelectedCountyName = countyName
            
            #if DEBUG_PRINT_FUNCCALLS
            print("selectButtonTapped: set state \(GlobalUIData.unique.UIBrowserRKISelectedStateName), ID: \(GlobalUIData.unique.UIBrowserRKISelectedStateID), got countyIndex (\(countyIndex)), countyID (\(countyID)), countyName (\(countyName))")
            #endif
            
            // save the data
            GlobalUIData.unique.saveUIData()
            
            // local notification to update UI
            NotificationCenter.default.post(Notification(name: .CoBaT_UserDidSelectState))
            
            #if DEBUG_PRINT_FUNCCALLS
            print("selectButtonTapped just posted .CoBaT_UserDidSelectState")
            #endif

            self.dismiss(animated: true, completion: nil)
            
            
        case GlobalStorage.unique.RKIDataCounty:
            
            // County Level: set the selected county, save it and report
            GlobalUIData.unique.UIBrowserRKISelectedCountyName = localDataArray[row].name
            GlobalUIData.unique.UIBrowserRKISelectedCountyID = localDataArray[row].myID ?? ""
            
            GlobalUIData.unique.UIBrowserCountyIDPerStateID[GlobalUIData.unique.UIBrowserRKISelectedStateID] = GlobalUIData.unique.UIBrowserRKISelectedCountyID

            #if DEBUG_PRINT_FUNCCALLS
            print("selectButtonTapped: set county \(GlobalUIData.unique.UIBrowserRKISelectedStateName), ID: \(GlobalUIData.unique.UIBrowserRKISelectedCountyID), set UIBrowserCountyIDPerStateID[\(GlobalUIData.unique.UIBrowserRKISelectedStateID)] = \(GlobalUIData.unique.UIBrowserRKISelectedCountyID)")
            #endif
            
            // save the data
            GlobalUIData.unique.saveUIData()
            
            // local notification to update UI
            NotificationCenter.default.post(Notification(name: .CoBaT_UserDidSelectCounty))
            
            #if DEBUG_PRINT_FUNCCALLS
            print("selectButtonTapped just posted .CoBaT_UserDidSelectCounty")
            #endif
        
            self.dismiss(animated: true, completion: nil)
            
            
        default:
            break
        }
    }

    /**
     -----------------------------------------------------------------------------------------------
     
     detailsButtonTapped(cell:
     
     -----------------------------------------------------------------------------------------------
     */
    func detailsButtonTapped(cell: BrowseRKIDataTableViewCell) {

        #if DEBUG_PRINT_FUNCCALLS
        print("detailsButtonTapped just started, row: \(cell.myIndexPath.row)")
        #endif
        
        // get the row
        let row = cell.myIndexPath.row
        
        // which arae level we have
        switch GlobalUIData.unique.UIBrowserRKIAreaLevel {
        
        case GlobalStorage.unique.RKIDataCountry:
            
            // Country Level: just the colors
            // set the colors according to the current cell
            GlobalUIData.unique.UIDetailsRKITextColor = cell.Cases.textColor
            GlobalUIData.unique.UIDetailsRKIBackgroundColor = cell.contentView.backgroundColor
                ?? UIColor.systemBackground
            break
            
            
        case GlobalStorage.unique.RKIDataState:
            
            GlobalUIData.unique.UIDetailsRKIAreaLevel = GlobalStorage.unique.RKIDataState
            GlobalUIData.unique.UIDetailsRKISelectedMyID = localDataArray[row].stateID
            
            // set the colors according to the current cell
            GlobalUIData.unique.UIDetailsRKITextColor = cell.Cases.textColor
            GlobalUIData.unique.UIDetailsRKIBackgroundColor = cell.contentView.backgroundColor
                ?? UIColor.systemBackground

            performSegue(withIdentifier: "CallDetailsRKIViewControllerFromBrowser", sender: self)

            
        case GlobalStorage.unique.RKIDataCounty:
            
            GlobalUIData.unique.UIDetailsRKIAreaLevel = GlobalStorage.unique.RKIDataCounty
            GlobalUIData.unique.UIDetailsRKISelectedMyID = localDataArray[row].myID ?? ""
            
            // set the colors according to the current cell
            GlobalUIData.unique.UIDetailsRKITextColor = cell.Cases.textColor
            GlobalUIData.unique.UIDetailsRKIBackgroundColor = cell.contentView.backgroundColor
                ?? UIColor.systemBackground
            
            performSegue(withIdentifier: "CallDetailsRKIViewControllerFromBrowser", sender: self)

            
        default:
            break
        }
    }


    
    
    // ---------------------------------------------------------------------------------------------
    // MARK: - Helper
    // ---------------------------------------------------------------------------------------------

    /**
     -----------------------------------------------------------------------------------------------
     
     RefreshLocalData()
     
     -----------------------------------------------------------------------------------------------
     */
    func RefreshLocalData() {
        
        #if DEBUG_PRINT_FUNCCALLS
        print("RefreshLocalData just started, ID: \(GlobalUIData.unique.UIBrowserRKISelectedStateID)")
        #endif
        
        var localDataArrayUnsorted: [GlobalStorage.RKIDataStruct] = []
        var localDataArrayDelta1Unsorted: [GlobalStorage.RKIDataStruct] = []
        var localDataArrayDelta7Unsorted: [GlobalStorage.RKIDataStruct] = []
        
        // read the current content of the global storage
        GlobalStorageQueue.async(flags: .barrier, execute: {
            
            self.numberOfDayAvailable = GlobalStorage.unique.RKIData[GlobalStorage.unique.RKIDataCounty].count
            // get the global storage, filtered to the current selected state
            
            // check if we have current data
            if self.numberOfDayAvailable > 0 {
                
                // yes at least current data are available so try to get some
                if GlobalUIData.unique.UIBrowserRKIAreaLevel == GlobalStorage.unique.RKIDataCounty {
                    localDataArrayUnsorted = GlobalStorage.unique.RKIData[GlobalUIData.unique.UIBrowserRKIAreaLevel][0].filter(
                        { $0.stateID == GlobalUIData.unique.UIBrowserRKISelectedStateID})
                } else {
                    localDataArrayUnsorted = GlobalStorage.unique.RKIDataDeltas [GlobalUIData.unique.UIBrowserRKIAreaLevel][0]
                }
            }
            
            // check if we have data from yesterday
            if self.numberOfDayAvailable > 1 {
                
                // yes at least data from "yesterday" are available so try to get some
                if GlobalUIData.unique.UIBrowserRKIAreaLevel == GlobalStorage.unique.RKIDataCounty {
                    
                    localDataArrayDelta1Unsorted = GlobalStorage.unique.RKIDataDeltas [GlobalUIData.unique.UIBrowserRKIAreaLevel][1].filter(
                        { $0.stateID == GlobalUIData.unique.UIBrowserRKISelectedStateID})
                    
                } else {
                    localDataArrayDelta1Unsorted = GlobalStorage.unique.RKIDataDeltas [GlobalUIData.unique.UIBrowserRKIAreaLevel][1]
                }
                
            }
            
            // check if we have data from several days
            if self.numberOfDayAvailable > 2 {
                
                // yes at least data from "yesterday" are available so try to get some
                if GlobalUIData.unique.UIBrowserRKIAreaLevel == GlobalStorage.unique.RKIDataCounty {
                    
                    // yes at least data from "yesterday" are available so try to get some
                    localDataArrayDelta7Unsorted = GlobalStorage.unique.RKIDataDeltas [GlobalUIData.unique.UIBrowserRKIAreaLevel][2].filter(
                        { $0.stateID == GlobalUIData.unique.UIBrowserRKISelectedStateID})
                } else {
                    localDataArrayDelta7Unsorted = GlobalStorage.unique.RKIDataDeltas [GlobalUIData.unique.UIBrowserRKIAreaLevel][2]
                }
            }
            
            
            // sort the local copy
            self.sortLocalData(source0: localDataArrayUnsorted,
                               source1: localDataArrayDelta1Unsorted,
                               source7: localDataArrayDelta7Unsorted)
            
            #if DEBUG_PRINT_FUNCCALLS
            print("RefreshLocalData done")
            #endif
        })
        
    }
    
    /**
     -----------------------------------------------------------------------------------------------
     
     sortLocalData
     
     -----------------------------------------------------------------------------------------------
     */
    public func sortLocalData(source0: [GlobalStorage.RKIDataStruct],
                               source1: [GlobalStorage.RKIDataStruct],
                               source7: [GlobalStorage.RKIDataStruct])
    {
        
        // we use the main thread as our working thread, so we have no problems in UI updates
        DispatchQueue.main.async(execute: {
            
            #if DEBUG_PRINT_FUNCCALLS
            print("sortLocalData just started")
            #endif
            
            switch GlobalUIData.unique.UIBrowserRKISorting {
            
            case .alphabetically:
                
                // we had to combine two keys ($0.name + $0.kindOf) as "Regensburg" exist two times (Kreisfreie Stadt and Landkreis)
                // by this we introduced a new key "$0.myID", but we have to wait 7 days to get the data cleaned out by age
                // TODO: TODO: change key to $0.myID after December 5th 2020

                self.localDataArray = source0.sorted(
                    by: { ($0.name + $0.kindOf) < ($1.name + $0.kindOf) } )
                
            case .incidencesAscending:
                self.localDataArray = source0.sorted(
                    by: { $0.cases7DaysPer100K < $1.cases7DaysPer100K } )

            case .incidencesDescending:
                self.localDataArray = source0.sorted(
                    by: { $0.cases7DaysPer100K > $1.cases7DaysPer100K } )
            }
            
            
            self.localDataArrayDelta1.removeAll()
            self.localDataArrayDelta7.removeAll()
            
            if self.numberOfDayAvailable > 1 {
                
                for item in self.localDataArray {
                    
                    // we had to combine two keys ($0.name + $0.kindOf) as "Regensburg" exist two times (Kreisfreie Stadt and Landkreis)
                    // by this we introduced a new key "$0.myID", but we have to wait 7 days to get the data cleaned out by age
                    // TODO: TODO: change key to $0.myID after December 5th 2020

                    if let index1InUnsorted = source1.firstIndex(
                        where: { ($0.name + $0.kindOf) == (item.name + item.kindOf) } ) {
                        
                        //print("\(item.kindOf) \(item.name): index1InUnsorted: \(index1InUnsorted) of \(source1.count)")

                        self.localDataArrayDelta1.append(source1[index1InUnsorted])
                        
                    } else {
                        
                        //print("\(item.kindOf) \(item.name)): index1InUnsorted: unknown of \(source1.count), new \(self.localDataArrayDelta1.count)")

                        self.localDataArrayDelta1.append(
                            GlobalStorage.RKIDataStruct(
                                stateID:            item.stateID,
                                myID:               item.myID ?? "",
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
                        
                        // we had to combine two keys ($0.name + $0.kindOf) as "Regensburg" exist two times (Kreisfreie Stadt and Landkreis)
                        // by this we introduced a new key "$0.myID", but we have to wait 7 days to get the data cleaned out by age
                        // TODO: TODO: change key to $0.myID after December 5th 2020

                        if let index7InUnsorted = source7.firstIndex(
                            where: { ($0.name + $0.kindOf) == (item.name + item.kindOf) } ) {
                            
                            //print("\(item.kindOf) \(item.name): index7InUnsorted: \(index7InUnsorted) of \(source7.count), new \(self.localDataArrayDelta1.count)")
                            
                            self.localDataArrayDelta7.append(source7[index7InUnsorted])
                            
                        } else {
                            
                            //print("\(item.kindOf) \(item.name): index7InUnsorted: unknown of \(source7.count)")
                            
                            self.localDataArrayDelta7.append(
                                GlobalStorage.RKIDataStruct(
                                    stateID:            item.stateID,
                                    myID:               item.myID ?? "",
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
            
            #if DEBUG_PRINT_FUNCCALLS
            print("sortLocalData done")
            #endif

            // reload the cells
            self.tableView.reloadData()
            
            // and scroll right
            self.scrollToSelectedItem()
        })
    }
    
    /**
     -----------------------------------------------------------------------------------------------
     
     Scrolls to the selected item (UIBrowserRKISelectedStateID or UIBrowserRKISelectedCountyID)
     
     -----------------------------------------------------------------------------------------------
     */
    private func scrollToSelectedItem() {
        
        // which arae level we have
        switch GlobalUIData.unique.UIBrowserRKIAreaLevel {
        
        case GlobalStorage.unique.RKIDataCountry:
            
            // Country Level: nothing to do
            break
            
            
        case GlobalStorage.unique.RKIDataState:
            
            // try to find the selected state in the local data, if found scroll to it
            if let row = self.localDataArray.firstIndex(where: { $0.myID == self.selectedItemID } ) {
                
                self.tableView.scrollToRow(at: IndexPath(item: row, section: 0), at: .top, animated: true)
            }


        case GlobalStorage.unique.RKIDataCounty:
            
            // try to find the selected state in the local data, if found scroll to it
            if let row = self.localDataArray.firstIndex(where: { $0.myID == self.selectedItemID } ) {
                
                self.tableView.scrollToRow(at: IndexPath(item: row, section: 0), at: .top, animated: true)
            }
            
        default:
            break
      }

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
        
        // set the id of the selected item
        switch GlobalUIData.unique.UIBrowserRKIAreaLevel {
   
        case GlobalStorage.unique.RKIDataCountry:
            break
            
        case GlobalStorage.unique.RKIDataState:
            self.selectedItemID = GlobalUIData.unique.UIBrowserRKISelectedStateID
            
        case GlobalStorage.unique.RKIDataCounty:
            self.selectedItemID = GlobalUIData.unique.UIBrowserRKISelectedCountyID
            
        default:
            break
      }

        // refresh the data
        self.RefreshLocalData()
    }
    
    /**
     -----------------------------------------------------------------------------------------------
     
     viewDidAppear()
     
     -----------------------------------------------------------------------------------------------
     */
    override func viewDidAppear(_ animated: Bool) {
        super .viewDidAppear(animated)
        
        // add observer to recognise if user selcted new sort strategy
        userDidSelectSortObserver = NotificationCenter.default.addObserver(
            forName: .CoBaT_UserDidSelectSort,
            object: nil,
            queue: OperationQueue.main,
            using: { Notification in
                
                #if DEBUG_PRINT_FUNCCALLS
                print("BrowseRKIDataTableViewController just recieved signal .CoBaT_UserDidSelectSort, call RefreshLocalData()")
                #endif
                
                self.RefreshLocalData()
            })
        
        // add observer to recognise if user selcted new state
        newRKIDataReadyObserver = NotificationCenter.default.addObserver(
            forName: .CoBaT_NewRKIDataReady,
            object: nil,
            queue: OperationQueue.main,
            using: { Notification in
                
                #if DEBUG_PRINT_FUNCCALLS
                print("BrowseRKIDataTableViewController just recieved signal .CoBaT_NewRKIDataReady, call RefreshLocalData()")
                #endif
                
                self.RefreshLocalData()
            })

        // scroll the content to the selected item
        //self.scrollToSelectedItem()

    }
 
    /**
     -----------------------------------------------------------------------------------------------
     
     viewDidDisappear()
     
     -----------------------------------------------------------------------------------------------
     */
    override func viewDidDisappear(_ animated: Bool) {
        super .viewDidDisappear(animated)
        
        // remove the observer if set
        if let observer = userDidSelectSortObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        // remove the observer if set
        if let observer = newRKIDataReadyObserver {
            NotificationCenter.default.removeObserver(observer)
        }
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "BrowseRKIDataTableViewCellV2",
                                                 for: indexPath) as! BrowseRKIDataTableViewCell
        
        // set the cell properties (index path and that we are the one to serve the selectButtonDelegate)
        cell.myIndexPath = indexPath
        cell.selectButtonDelegate = self
        cell.detailsButtonDelegate = self
        
        // get the related data set from local storage
        let index = indexPath.row
        let myData = localDataArray[index]
        
        // get color schema for 7 day average caces per 100 K people
        let (backgroundColor, textColorToUse, _, _) = CovidRating.unique.getColorsForValue(myData.cases7DaysPer100K)
        
        // set the background of the cell
        cell.contentView.backgroundColor = backgroundColor
        
        // set the border color, so the selected cell will be highlighted
        if myData.myID == self.selectedItemID {
            cell.layer.borderColor = textColorToUse.cgColor
        } else {
            cell.layer.borderColor = backgroundColor.cgColor
        }
   
        // color the two chevrons
        cell.ChevronLeft.tintColor = textColorToUse
        cell.ChevronRight.tintColor = textColorToUse
        
        // on country level, we do not need to select an item, so hide the left chevron and disable the button
        if GlobalUIData.unique.UIBrowserRKIAreaLevel == GlobalStorage.unique.RKIDataCountry {
            
            // no chevron and no button
            cell.ChevronLeft.isHidden = true
            cell.SelectButton.isEnabled = false
            
        } else {
            
            // show the chevron and enable the button
            cell.ChevronLeft.isHidden = false
            cell.SelectButton.isEnabled = true
        }
        
        
        // set text colors

        // set the text colors
        cell.Name.textColor = textColorToUse
        cell.KindOf.textColor = textColorToUse
        
        cell.Cases.textColor = textColorToUse
        cell.FirstCases.textColor = textColorToUse
        cell.SecondCases.textColor = textColorToUse
        //cell.ThirdCases.textColor = textColorToUse
        
        cell.Incidences.textColor = textColorToUse
        cell.FirstIncidences.textColor = textColorToUse
        cell.SecondIncidences.textColor = textColorToUse
        //cell.ThirdIncidences.textColor = textColorToUse
        
        // set the fixed labels
        cell.Name.text = myData.name
        cell.KindOf.text = myData.kindOf
        
        cell.Cases.text = self.casesText
        cell.Incidences.text = self.IncidencesText
        
        // now fill the data fields according to number of available days
        if numberOfDayAvailable == 1 {
            
            cell.FirstCases.text = ""
            //cell.SecondCases.text = ""
            
            cell.SecondCases.text = numberNoFractionFormatter.string(
                from: NSNumber(value: myData.cases))
            
            
            cell.FirstIncidences.text = ""
            //cell.SecondIncidences.text = ""
            
            cell.SecondIncidences.text = number1FractionFormatter.string(
                from: NSNumber(value: myData.cases7DaysPer100K))

            
        } else if (numberOfDayAvailable >= 2)
                    && (localDataArrayDelta1.count >= index) {
            
            
            //cell.FirstCases.text = ""
            
            cell.FirstCases.text = numberNoFractionFormatter.string(
                from: NSNumber(value: myData.cases))
            
            cell.SecondCases.text = getFormattedDeltaTextInt(number: localDataArrayDelta1[index].cases)
            
            //cell.FirstIncidences.text = ""
            
            cell.FirstIncidences.text = number1FractionFormatter.string(
                from: NSNumber(value: myData.cases7DaysPer100K))
            
            cell.SecondIncidences.text = getFormattedDeltaTextDouble(
                number: localDataArrayDelta1[index].cases7DaysPer100K, fraction: 1)
            
            
//        } else if (numberOfDayAvailable > 2)
//                    && (localDataArrayDelta1.count >= index)
//                    && (localDataArrayDelta7.count >= index) {
//
//            cell.FirstCases.text = numberNoFractionFormatter.string(
//                from: NSNumber(value: myData.cases))
//
//            cell.SecondCases.text = getFormattedDeltaTextInt(number: localDataArrayDelta1[index].cases)
//
//            cell.ThirdCases.text = getFormattedDeltaTextInt(number: localDataArrayDelta7[index].cases)
//
//            cell.FirstIncidences.text = number1FractionFormatter.string(
//                from: NSNumber(value: myData.cases7DaysPer100K))
//
//            cell.SecondIncidences.text = getFormattedDeltaTextDouble(
//                number: localDataArrayDelta1[index].cases7DaysPer100K, fraction: 1)
//
//            cell.ThirdIncidences.text = getFormattedDeltaTextDouble(
//                number: localDataArrayDelta7[index].cases7DaysPer100K, fraction: 1)
            
        } else {
            
            // something went wrtong, so just show the current numbers
            cell.FirstCases.text = ""
            //cell.SecondCases.text = ""
            
            cell.SecondCases.text = numberNoFractionFormatter.string(
                from: NSNumber(value: myData.cases))
            
            
            cell.FirstIncidences.text = ""
            //cell.SecondIncidences.text = ""
            
            cell.SecondIncidences.text = number1FractionFormatter.string(
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
    
    /**
     -----------------------------------------------------------------------------------------------
     
     didSelectRowAt:
     
     -----------------------------------------------------------------------------------------------
     */
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // deselct, to keep enviroemt clean
        tableView.deselectRow(at: indexPath, animated: true)
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
