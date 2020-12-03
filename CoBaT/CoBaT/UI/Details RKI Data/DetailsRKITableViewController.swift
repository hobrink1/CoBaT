//
//  DetailsRKITableViewController.swift
//  CoBaT
//
//  Created by Hartwig Hopfenzitz on 29.11.20.
//

import UIKit

// -------------------------------------------------------------------------------------------------
// MARK: -
// MARK: - Browse County Data Table View Controller
// -------------------------------------------------------------------------------------------------

class DetailsRKITableViewController: UITableViewController {

    // ---------------------------------------------------------------------------------------------
    // MARK: - Local storage
    // ---------------------------------------------------------------------------------------------

    // the oberservers have to be released, otherwise there wil be a memory leak.
    // this variables were set in "ViewDidApear()" and released in "ViewDidDisappear()"
    
    var newRKIDataReadyObserver: NSObjectProtocol?
    
    
    
    enum showDeltaCellTypeEnum: Int {
        case current = 0, dayDiff = 1, weekDiff = 2
    }
    
    
    struct showDetailStruct {
        
        let rkiDataStruct: GlobalStorage.RKIDataStruct
        
        let deaths100k: Double
        let cases7Days: Double
        
        let cellType: showDeltaCellTypeEnum
        let sortKey: String
        let otherDayTimeStamp: TimeInterval
        
        let backgroundColor: UIColor
        let textColor: UIColor
        
        init(rkiDataStruct: GlobalStorage.RKIDataStruct,
             deaths100k: Double,
             cases7Days: Double,
             cellType: showDeltaCellTypeEnum,
             sortKey: String,
             otherDayTimeStamp: TimeInterval,
             backgroundColor: UIColor,
             textColor: UIColor)
        {
            
            self.rkiDataStruct      = rkiDataStruct
            self.deaths100k         = deaths100k
            self.cases7Days         = cases7Days
            self.cellType           = cellType
            self.sortKey            = sortKey
            self.otherDayTimeStamp  = otherDayTimeStamp
            self.backgroundColor    = backgroundColor
            self.textColor          = textColor
        }
    }

    var showDetailData: [showDetailStruct] = []

    // the id string of the selected item, to highlight the related cell
    var selectedItemID: String = ""


    
    // ---------------------------------------------------------------------------------------------
    // MARK: - Translated strings
    // ---------------------------------------------------------------------------------------------
    let casesText = NSLocalizedString("label-cases", comment: "Label text for cases")
    let incidencesText = NSLocalizedString("label-incidences", comment: "Label text for incidences")
    let inhabitantsText = NSLocalizedString("label-inhabitants", comment: "Label text for inhabitants")
    let deathsText = NSLocalizedString("label-deaths", comment: "Label text for deaths")

    let totalText = NSLocalizedString("label-total", comment: "Label text for total")
    let per100kText = NSLocalizedString("label-per-100k", comment: "Label text for per 100k")
    
    let changeText = NSLocalizedString("label-change", comment: "Text for changes")
    
    // ---------------------------------------------------------------------------------------------
    // MARK: - Helper
    // ---------------------------------------------------------------------------------------------

    private func refreshLocalData() {
        
        // create shortcuts
        let selectedAreaLevel = GlobalUIData.unique.UIDetailsRKIAreaLevel
        let selectedMyID = GlobalUIData.unique.UIDetailsRKISelectedMyID
        
        var localRKIDataLoaded : [GlobalStorage.RKIDataStruct] = []
        
        var localDataBuiling:[showDetailStruct] = []

        // get the related data from the global storage in sync
        GlobalStorageQueue.sync(execute: {
            
             
            for dayIndex in 0 ..< GlobalStorage.unique.RKIData[selectedAreaLevel].count {
                
                // shortcut
                let RKIDataToUse = GlobalStorage.unique.RKIData[selectedAreaLevel][dayIndex]
                
                // try to find the index of the requested ID
                if let RKIDataOfDay = RKIDataToUse.first(where: { $0.myID == selectedMyID } ) {
                    
                    // we found a valid record, so store the data locally
                    localRKIDataLoaded.append(RKIDataOfDay)
                    
                } else {
                    
                    // we did not found a valid index, report and use default values
                    GlobalStorage.unique.storeLastError(errorText: "DetailsRKITableViewController.refreshLocalData: Error: RKIData: did not found valid record for day \(dayIndex) of ID \"\(selectedMyID)/” of area level \"\(selectedAreaLevel)\", ignore record")
                }
            }
        })
        
        // Build the data to show
        
        
        
        for index in 0 ..< localRKIDataLoaded.count {
            
            let item = localRKIDataLoaded[index]
            
            let deaths100k = Double(item.deaths) / 100_000.0
            let cases7Days = item.cases7DaysPer100K
                           * Double(item.inhabitants)
                           / 100_000.0
            
            let indexString: String
            if let temp = numberNoFraction3DigitsFormatter.string(from: NSNumber(value: index)) {
                indexString = temp
            } else {
                indexString = "   "
            }
            
            let cellType: showDeltaCellTypeEnum = .current
            
            let sortKey = "\(indexString)\(cellType.rawValue)"
            
            let (backgroundColor, textColor, _) = CovidRating.unique.getColorsForValue(item.cases7DaysPer100K)
            
            localDataBuiling.append(showDetailStruct(
                                        rkiDataStruct: item,
                                        deaths100k: deaths100k,
                                        cases7Days: cases7Days,
                                        cellType: cellType,
                                        sortKey: sortKey,
                                        otherDayTimeStamp: 0,
                                        backgroundColor: backgroundColor,
                                        textColor: textColor))
 
        }
        
        let upperBorderFreezed = localDataBuiling.count - 1
        
        for index in 0 ..< upperBorderFreezed {
            
            let itemCurrent = localDataBuiling[index]
            let itemNextDay = localDataBuiling[index + 1]
            
            
            let diffInhabitants    = itemCurrent.rkiDataStruct.inhabitants       - itemNextDay.rkiDataStruct.inhabitants
            let diffCases          = itemCurrent.rkiDataStruct.cases             - itemNextDay.rkiDataStruct.cases
            let diffCases100k      = itemCurrent.rkiDataStruct.casesPer100k      - itemNextDay.rkiDataStruct.casesPer100k
            let diffDeaths         = itemCurrent.rkiDataStruct.deaths            - itemNextDay.rkiDataStruct.deaths
            let diffCases7Days100k = itemCurrent.rkiDataStruct.cases7DaysPer100K - itemNextDay.rkiDataStruct.cases7DaysPer100K
            
            let myRKIDataStruct = GlobalStorage.RKIDataStruct(
                stateID:            itemCurrent.rkiDataStruct.stateID,
                myID:               itemCurrent.rkiDataStruct.myID ?? "",
                name:               itemCurrent.rkiDataStruct.name,
                kindOf:             itemCurrent.rkiDataStruct.kindOf,
                inhabitants:        diffInhabitants,
                cases:              diffCases,
                deaths:             diffDeaths,
                casesPer100k:       diffCases100k,
                cases7DaysPer100K:  diffCases7Days100k,
                timeStamp:          itemCurrent.rkiDataStruct.timeStamp)
            
            
            let diffDeaths100k     = itemCurrent.deaths100k - itemNextDay.deaths100k
            let diffCases7Days     = itemCurrent.cases7Days - itemNextDay.cases7Days
            
            
            let indexString: String
            if let temp = numberNoFraction3DigitsFormatter.string(from: NSNumber(value: index)) {
                indexString = temp
            } else {
                indexString = "   "
            }
            
            let cellType: showDeltaCellTypeEnum = .dayDiff
            
            let sortKey = "\(indexString)\(cellType.rawValue)"
            
            localDataBuiling.append(showDetailStruct(
                                        rkiDataStruct: myRKIDataStruct,
                                        deaths100k: diffDeaths100k,
                                        cases7Days: diffCases7Days,
                                        cellType: cellType,
                                        sortKey: sortKey,
                                        otherDayTimeStamp: itemNextDay.rkiDataStruct.timeStamp,
                                        backgroundColor: itemCurrent.backgroundColor,
                                        textColor: itemCurrent.textColor))
        }
        
        
        localDataBuiling.sort(by: { $0.sortKey < $1.sortKey } )

        
        
        // set the label text on main thread
        DispatchQueue.main.async(execute: {
            
            self.showDetailData = localDataBuiling
            
            #if DEBUG_PRINT_FUNCCALLS
            print("DetailsRKITableViewController.refreshLocalData done")
            #endif
            
            // reload the cells
            self.tableView.reloadData()
        })
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

        self.refreshLocalData()
    }

    
    /**
     -----------------------------------------------------------------------------------------------
     
     viewDidAppear()
     
     -----------------------------------------------------------------------------------------------
     */
    override func viewDidAppear(_ animated: Bool) {
        super .viewDidAppear(animated)
        
        // add observer to recognise if user selcted new state
        newRKIDataReadyObserver = NotificationCenter.default.addObserver(
            forName: .CoBaT_NewRKIDataReady,
            object: nil,
            queue: nil,
            using: { Notification in
                
                #if DEBUG_PRINT_FUNCCALLS
                print("DetailsRKITableViewController just recieved signal .CoBaT_NewRKIDataReady, call RefreshLocalData()")
                #endif
                
                self.refreshLocalData()
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
        
    }

    

    
    // ---------------------------------------------------------------------------------------------
    // MARK: - Table view data source
    // ---------------------------------------------------------------------------------------------

    /**
     -----------------------------------------------------------------------------------------------
     
     numberOfSections:
     
     -----------------------------------------------------------------------------------------------
     */    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    /**
     -----------------------------------------------------------------------------------------------
     
     numberOfRowsInSection:
     
     -----------------------------------------------------------------------------------------------
     */    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.showDetailData.count
    }

    /**
     -----------------------------------------------------------------------------------------------
     
     cellForRowAt:
     
     -----------------------------------------------------------------------------------------------
     */
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // dequeue a cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "DetailsRKITableViewCellV2",
                                                 for: indexPath) as! DetailsRKITableViewCell
        
        
        // get the related data set from local storage
        let index = indexPath.row
        let myData = showDetailData[index]
        
        // get color schema for 7 day average caces per 100 K people
        let backgroundColor = myData.backgroundColor
        let textColorToUse = myData.textColor
        
        // set the background of the cell
        cell.contentView.backgroundColor = backgroundColor
       
        
        // set the text colors
        cell.LabelDate.textColor = textColorToUse

        //cell.LabelInhabitans.textColor = textColorToUse
        //cell.ValueInhabitans.textColor = textColorToUse

        cell.LabelTotal.textColor = textColorToUse
        cell.LabelPer100k.textColor = textColorToUse

        cell.LabelCases.textColor = textColorToUse
        cell.CasesTotal.textColor = textColorToUse
        cell.Cases100k.textColor = textColorToUse

        cell.LabelDeaths.textColor = textColorToUse
        cell.DeathsTotal.textColor = textColorToUse
        cell.Deaths100k.textColor = textColorToUse

        cell.LabelIncidences.textColor = textColorToUse
        cell.IncidencesTotal.textColor = textColorToUse
        cell.Incidences100k.textColor = textColorToUse
        
        // set the fixed texts (labels etc.)
        cell.LabelCases.text = casesText
        cell.LabelDeaths.text = deathsText
        cell.LabelIncidences.text = incidencesText
        
        cell.LabelTotal.text = totalText
        cell.LabelPer100k.text = per100kText
        
        // Check which cell type it is and set border color and values accordingly
        if myData.cellType == .current {
            
            // It is an actual day
            cell.layer.borderColor = textColorToUse.cgColor
            
            cell.LabelDate.font = UIFont.preferredFont(forTextStyle: .body)
            
            // set the values
            let shortDate = shortSingleRelativeDateFormatter.string(
                from: Date(timeIntervalSinceReferenceDate: myData.rkiDataStruct.timeStamp))
            
            let shortTime = shortSingleTimeFormatter.string(
                from: Date(timeIntervalSinceReferenceDate: myData.rkiDataStruct.timeStamp))
            
            let weekday = dateFormatterLocalizedWeekdayShort.string(
                from: Date(timeIntervalSinceReferenceDate: myData.rkiDataStruct.timeStamp))
            
            cell.LabelDate.text = "\(shortDate) (\(weekday)), \(shortTime)"
            
            //cell.ValueInhabitans.text = numberNoFractionFormatter.string(
            //    from: NSNumber(value: myData.rkiDataStruct.inhabitants))
            
            cell.CasesTotal.text = numberNoFractionFormatter.string(
                from: NSNumber(value: myData.rkiDataStruct.cases))
            
            cell.Cases100k.text = numberNoFractionFormatter.string(
                from: NSNumber(value: myData.rkiDataStruct.casesPer100k))
            
            cell.DeathsTotal.text = numberNoFractionFormatter.string(
                from: NSNumber(value: myData.rkiDataStruct.deaths))
            
            cell.Deaths100k.text = number3FractionFormatter.string(
                from: NSNumber(value: myData.deaths100k))
            
            cell.IncidencesTotal.text = numberNoFractionFormatter.string(
                from: NSNumber(value: myData.cases7Days))
            
            cell.Incidences100k.text = numberNoFractionFormatter.string(
                from: NSNumber(value: myData.rkiDataStruct.cases7DaysPer100K))
            
        } else {
            
            // it is a cell with differences
            cell.layer.borderColor = backgroundColor.cgColor
            
            cell.LabelDate.font = UIFont.preferredFont(forTextStyle: .subheadline)
            
            // set the values
            let fromDate = shortSingleRelativeDateFormatter.string(
                from: Date(timeIntervalSinceReferenceDate: myData.rkiDataStruct.timeStamp))
           
            let fromWeekday = dateFormatterLocalizedWeekdayShort.string(
                from: Date(timeIntervalSinceReferenceDate: myData.rkiDataStruct.timeStamp))

            let untilDate = shortSingleRelativeDateFormatter.string(
                from: Date(timeIntervalSinceReferenceDate: myData.otherDayTimeStamp))

            let untilWeekday = dateFormatterLocalizedWeekdayShort.string(
                from: Date(timeIntervalSinceReferenceDate: myData.otherDayTimeStamp))

            cell.LabelDate.text = "\(changeText) \(fromDate) (\(fromWeekday)) -> \(untilDate) (\(untilWeekday))"
            
            //cell.ValueInhabitans.text = getFormattedDeltaTextInt(
            //    number: myData.rkiDataStruct.inhabitants)
            
            cell.CasesTotal.text = getFormattedDeltaTextInt(
                number:  myData.rkiDataStruct.cases)
            
            cell.Cases100k.text = getFormattedDeltaTextDouble(
                number: myData.rkiDataStruct.casesPer100k,
                fraction: 1)
            
            cell.DeathsTotal.text = getFormattedDeltaTextInt(
                number:  myData.rkiDataStruct.deaths)
            
            cell.Deaths100k.text = getFormattedDeltaTextDouble(
                number:  myData.deaths100k,
                fraction: 3)
            
            cell.IncidencesTotal.text = getFormattedDeltaTextDouble(
                number:  myData.cases7Days,
                fraction: 0)
            
            cell.Incidences100k.text = getFormattedDeltaTextDouble(
                number:  myData.rkiDataStruct.cases7DaysPer100K,
                fraction: 0)

        }

 
        return cell
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
