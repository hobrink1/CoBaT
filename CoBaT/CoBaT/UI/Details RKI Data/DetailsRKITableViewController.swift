//
//  DetailsRKITableViewController.swift
//  CoBaT
//
//  Created by Hartwig Hopfenzitz on 29.11.20.
//

import UIKit

// -------------------------------------------------------------------------------------------------
// MARK: -
// MARK: - Details RKI Table View Controller
// -------------------------------------------------------------------------------------------------

class DetailsRKITableViewController: UITableViewController {

    // ---------------------------------------------------------------------------------------------
    // MARK: - Local storage
    // ---------------------------------------------------------------------------------------------

    // the oberservers have to be released, otherwise there wil be a memory leak.
    // this variables were set in "ViewDidApear()" and released in "ViewDidDisappear()"
    
    var newRKIDataReadyObserver: NSObjectProtocol?
    var commonTabBarChangedContentObserver: NSObjectProtocol?

    // color codes for the first row
    var myBackgroundColor = UIColor.systemBackground
    var myTextColor = UIColor.label
    
    // the variables to fill the "kindOf" and "Inhabitants" labels
    var myKindOfString : String = ""
    var myInhabitantsValueString: String = ""
    var myInhabitantsLabelString: String = ""
    
    // we have three different kind of detail cells, this is the enum for them
    enum showDeltaCellTypeEnum: Int {
        case current = 0, dayDiff = 1, weekDiff = 2
    }
    
    // we use this struct to precalculate all data
    struct showDetailStruct {
        
        let rkiDataStruct: GlobalStorage.RKIDataStruct
        
        let deaths100k: Double
        let cases7Days: Double
        
        let cellType: showDeltaCellTypeEnum
        let sortKey: String
        let otherDayTimeStamp: TimeInterval
        
        let backgroundColor: UIColor
        let textColor: UIColor
        let textColorLower: UIColor
        
        init(rkiDataStruct: GlobalStorage.RKIDataStruct,
             deaths100k: Double,
             cases7Days: Double,
             cellType: showDeltaCellTypeEnum,
             sortKey: String,
             otherDayTimeStamp: TimeInterval,
             backgroundColor: UIColor,
             textColor: UIColor,
             textColorLower: UIColor)
        {
            
            self.rkiDataStruct      = rkiDataStruct
            self.deaths100k         = deaths100k
            self.cases7Days         = cases7Days
            self.cellType           = cellType
            self.sortKey            = sortKey
            self.otherDayTimeStamp  = otherDayTimeStamp
            self.backgroundColor    = backgroundColor
            self.textColor          = textColor
            self.textColorLower     = textColorLower
        }
    }

    var showDetailData: [showDetailStruct] = []

    // the id string of the selected item, to highlight the related cell
    var selectedItemID: String = ""


    
    // ---------------------------------------------------------------------------------------------
    // MARK: - Translated strings
    // ---------------------------------------------------------------------------------------------
    let casesText = NSLocalizedString("label-cases", comment: "Label text for cases")
    let incidencesText = NSLocalizedString("label-cases-7days", comment: "Label text for cases in 7 days")
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
        GlobalStorageQueue.async(execute: {
            
            // set the colors for the inhabitants cell
            self.myBackgroundColor = GlobalUIData.unique.UIDetailsRKIBackgroundColor
            self.myTextColor = GlobalUIData.unique.UIDetailsRKITextColor
            
            
            // go over the data
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
            
            // Build the data to show
            
            // inhabitants
            if localRKIDataLoaded.isEmpty == false {
                
                let item = localRKIDataLoaded.first!
                self.myKindOfString = item.kindOf
                self.myInhabitantsValueString = numberNoFractionFormatter.string(from: NSNumber(value: item.inhabitants)) ?? ""
                self.myInhabitantsLabelString = self.inhabitantsText
                
            }
            
            for index in 0 ..< localRKIDataLoaded.count {
                
                let item = localRKIDataLoaded[index]
                
                let deaths100k = Double(item.deaths)
                    / Double(item.inhabitants)
                    * 100_000.0
                
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
                
                let (backgroundColor, textColor, textColorLower, _) = CovidRating.unique.getColorsForValue(item.cases7DaysPer100K)
                
                localDataBuiling.append(showDetailStruct(
                                            rkiDataStruct: item,
                                            deaths100k: deaths100k,
                                            cases7Days: cases7Days,
                                            cellType: cellType,
                                            sortKey: sortKey,
                                            otherDayTimeStamp: 0,
                                            backgroundColor: backgroundColor,
                                            textColor: textColor,
                                            textColorLower: textColorLower))
                
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
                                            textColor: itemCurrent.textColorLower,
                                            textColorLower: itemCurrent.textColorLower))
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
            queue: OperationQueue.main,
            using: { Notification in
                
                #if DEBUG_PRINT_FUNCCALLS
                print("DetailsRKITableViewController just recieved signal .CoBaT_NewRKIDataReady, call RefreshLocalData()")
                #endif
                
                self.refreshLocalData()
            })
        
        // add observer to recognise if user selcted other tab
        commonTabBarChangedContentObserver = NotificationCenter.default.addObserver(
            forName: .CoBaT_CommonTabBarChangedContent,
            object: nil,
            queue: OperationQueue.main,
            using: { Notification in
                
                #if DEBUG_PRINT_FUNCCALLS
                print("DetailsRKITableViewController just recieved signal .CoBaT_CommonTabBarChangedContent, call RefreshLocalData()")
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
        
        // remove the observer if set
        if let observer = commonTabBarChangedContentObserver {
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

        // we have the arry and one special row for the inhabitants
        return self.showDetailData.count + 2
    }

    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
        
        case 1:
            
            return GlobalUIData.unique.RKIGraphTopMargine
                + GlobalUIData.unique.RKIGraphNeededHeight
                + GlobalUIData.unique.RKIGraphBottomMargine
        
        default:
            
            return UITableView.automaticDimension
            
        }
    }
    /**
     -----------------------------------------------------------------------------------------------
     
     cellForRowAt:
     
     -----------------------------------------------------------------------------------------------
     */
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
         
        // get the related data set from local storage
        let index = indexPath.row
        
        switch index {
        
        case 0:
            // line with kind of elment and the inhabitants
            // dequeue a cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "DetailsInhabitantsTableViewCell",
                                                     for: indexPath) as! DetailsInhabitantsTableViewCell
            
            // save the colors for embedded CommonTabTableViewController
            let textColor = self.myTextColor
            let backgroundColor = self.myBackgroundColor
  
            // set the background of the cell
            cell.contentView.backgroundColor = backgroundColor
            
            // set the text colors
            cell.ValueKindOf.textColor = textColor
            cell.ValueInhabitants.textColor = textColor
            cell.LabelInhabitants.textColor = textColor
            
            // set the content
            cell.ValueKindOf.text = self.myKindOfString
            cell.ValueInhabitants.text = self.myInhabitantsValueString
            cell.LabelInhabitants.text = self.myInhabitantsLabelString

            // return the cell
            return cell
            
            
        case 1:
            
            // three graphs to show development
            // dequeue a cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "DetailsRKIGraphTableViewCell",
                                                     for: indexPath) as! DetailsRKIGraphTableViewCell
            
            // save the colors for embedded CommonTabTableViewController
            //let textColor = self.myTextColor
            let backgroundColor = self.myBackgroundColor
  
            // set the background of the cell
            cell.contentView.backgroundColor = backgroundColor

            // get the graphs
            cell.LeftImage.image = DetailsRKIGraphic.unique.GraphLeft
            cell.MiddleImage.image = DetailsRKIGraphic.unique.GraphMiddle
            cell.RightImage.image = DetailsRKIGraphic.unique.GraphRight

            return cell
            
            
        default:
            // the usual details content
            
            // we have a cell with the usual content (details)
            let myData = showDetailData[index - 2]
            
            // dequeue a cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "DetailsRKITableViewCellV2",
                                                     for: indexPath) as! DetailsRKITableViewCell
            

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
                
                cell.Cases100k.text = number1FractionFormatter.string(
                    from: NSNumber(value: myData.rkiDataStruct.casesPer100k))
                
                cell.DeathsTotal.text = numberNoFractionFormatter.string(
                    from: NSNumber(value: myData.rkiDataStruct.deaths))
                
                cell.Deaths100k.text = number1FractionFormatter.string(
                    from: NSNumber(value: myData.deaths100k))
                
                cell.IncidencesTotal.text = numberNoFractionFormatter.string(
                    from: NSNumber(value: myData.cases7Days))
                
                cell.Incidences100k.text = number1FractionFormatter.string(
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
                
                //cell.LabelDate.text = "\(changeText) \(fromDate) (\(fromWeekday)) <> \(untilDate) (\(untilWeekday))"
                cell.LabelDate.text = "<\(fromDate) (\(fromWeekday)) <> \(untilDate) (\(untilWeekday))>"
                
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
                    fraction: 1)
                
                cell.IncidencesTotal.text = getFormattedDeltaTextDouble(
                    number:  myData.cases7Days,
                    fraction: 0)
                
                cell.Incidences100k.text = getFormattedDeltaTextDouble(
                    number:  myData.rkiDataStruct.cases7DaysPer100K,
                    fraction: 1)
                
            }
            
            return cell

        }
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
