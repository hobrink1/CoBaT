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

final class DetailsRKITableViewController: UITableViewController {

    // ---------------------------------------------------------------------------------------------
    // MARK: - Local storage
    // ---------------------------------------------------------------------------------------------

    // the oberservers have to be released, otherwise there wil be a memory leak.
    // this variables were set in "ViewDidApear()" and released in "ViewDidDisappear()"
    
    private var newRKIDataReadyObserver: NSObjectProtocol?
    private var commonTabBarChangedContentObserver: NSObjectProtocol?
    private var newGraphReadyObserver: NSObjectProtocol?
    
    // flag if the initial data are displayed. Will be used in refreshCellWithGraph()
    private var initialDataAreDone: Bool = false
    
    // color codes for the first row
    private var myBackgroundColor = UIColor.systemBackground
    private var myTextColor = UIColor.label
    
    // the variables to fill the "kindOf" and "Inhabitants" labels
    private let rowNumberForInhabitantsCell: Int = 0
    private var myKindOfString : String = ""
    private var myInhabitantsValueString: String = ""
    private var myInhabitantsLabelString: String = ""
    
    // the color for the row which have the same weekday than the current one
    private let rowHighlightedBackgroundUIColor: UIColor = UIColor.systemOrange
    private let rowhBarHighlightedBackgroundCGColor: CGColor = UIColor.systemOrange.cgColor
    private let rowHighlightedTextUIColor: UIColor = UIColor.black
    private let rowhBarHighlightedTextCGColor: CGColor = UIColor.black.cgColor

    private var weekdayOfCurrentDay: Int = 0
    
    // the three images
    private var leftImage: UIImage?
    private var middleImage: UIImage?
    private var rightImage: UIImage?
        
    // the cell with the three graphs
    private let rowNumberForGraphCells: Int = 1
    
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
        let dayOfWeek: Int
        
        let backgroundColor: UIColor
        let textColor: UIColor
        let textColorLower: UIColor
        
        init(rkiDataStruct: GlobalStorage.RKIDataStruct,
             deaths100k: Double,
             cases7Days: Double,
             cellType: showDeltaCellTypeEnum,
             sortKey: String,
             otherDayTimeStamp: TimeInterval,
             dayOfWeek: Int,
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
            self.dayOfWeek          = dayOfWeek
            self.backgroundColor    = backgroundColor
            self.textColor          = textColor
            self.textColorLower     = textColorLower
        }
    }

    private var showDetailData: [showDetailStruct] = []

    // the id string of the selected item, to highlight the related cell
    private var selectedItemID: String = ""


    
    // ---------------------------------------------------------------------------------------------
    // MARK: - Translated strings
    // ---------------------------------------------------------------------------------------------
    private let inhabitantsText = NSLocalizedString("label-inhabitants", comment: "Label text for inhabitants")

    
    private let casesText = NSLocalizedString("label-cases", comment: "Label text for cases")
    private let casesTextNew = NSLocalizedString("RKIGraph-Cases", comment: "Label text for graph \"new cases\"")
    
    private let deathsText = NSLocalizedString("label-deaths", comment: "Label text for deaths")
    private let deathsTextNew = NSLocalizedString("RKIGraph-Deaths", comment: "Label text for graph \"new deaths\"")

    private let incidencesText = NSLocalizedString("label-cases-7days", comment: "Label text for cases in 7 days")
    private let incidencesTextNew = NSLocalizedString("label-cases-7days-new", comment: "Label text for new cases in 7 days")


    private let totalText = NSLocalizedString("label-total", comment: "Label text for total")
    private let per100kText = NSLocalizedString("label-per-100k", comment: "Label text for per 100k")
    
    private let changeText = NSLocalizedString("label-change", comment: "Text for changes")
    
    // ---------------------------------------------------------------------------------------------
    // MARK: - Helper
    // ---------------------------------------------------------------------------------------------

    /**
     -----------------------------------------------------------------------------------------------
     
     refreshLocalData()
     
     -----------------------------------------------------------------------------------------------
     */
    private func refreshLocalData() {
        
        // get the related data from the global storage in sync
        GlobalStorageQueue.async(execute: {
            
            // create shortcuts
            let selectedAreaLevel = GlobalUIData.unique.UIDetailsRKIAreaLevel
            let selectedMyID = GlobalUIData.unique.UIDetailsRKISelectedMyID
            
            var localRKIDataLoaded : [GlobalStorage.RKIDataStruct] = []
            var selectedWekdays: [Int] = GlobalStorage.unique.RKIDataWeekdays[selectedAreaLevel]
            if selectedWekdays.isEmpty == false {
                self.weekdayOfCurrentDay = selectedWekdays.first!
            }
            
            var localDataBuilding:[showDetailStruct] = []
            
            
            // set the colors for the inhabitants cell
            self.myBackgroundColor = GlobalUIData.unique.UIDetailsRKIBackgroundColor
            self.myTextColor = GlobalUIData.unique.UIDetailsRKITextColor
            
            // get the graphs
            RKIGraphicQueue.sync(execute: {
                self.leftImage = DetailsRKIGraphic.unique.GraphLeft
                self.middleImage = DetailsRKIGraphic.unique.GraphMiddle
                self.rightImage = DetailsRKIGraphic.unique.GraphRight
            })
            
            
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
                
                //}
                
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
                    
                    localDataBuilding.append(showDetailStruct(
                                                rkiDataStruct: item,
                                                deaths100k: deaths100k,
                                                cases7Days: cases7Days,
                                                cellType: cellType,
                                                sortKey: sortKey,
                                                otherDayTimeStamp: 0,
                                                dayOfWeek: selectedWekdays[index],
                                                backgroundColor: backgroundColor,
                                                textColor: textColor,
                                                textColorLower: textColorLower))
                    
                }
                
                // just to prevent crashes (empty localDataBuiling[])
                //if localDataBuiling.isEmpty == false {
                
                // get the deltas
                for index in 0 ..< (localDataBuilding.count - 1) {
                    
                    let itemCurrent = localDataBuilding[index]
                    let itemNextDay = localDataBuilding[index + 1]
                    
                    
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
                    
                    
                    localDataBuilding.append(showDetailStruct(
                                                rkiDataStruct: myRKIDataStruct,
                                                deaths100k: diffDeaths100k,
                                                cases7Days: diffCases7Days,
                                                cellType: cellType,
                                                sortKey: sortKey,
                                                otherDayTimeStamp: itemNextDay.rkiDataStruct.timeStamp,
                                                dayOfWeek: selectedWekdays[index],
                                                backgroundColor: itemCurrent.backgroundColor,
                                                textColor: itemCurrent.textColorLower,
                                                textColorLower: itemCurrent.textColorLower))
                }
                
                // sort it to get the deltas inbetween teir original data cells
                localDataBuilding.sort(by: { $0.sortKey < $1.sortKey } )
                
            } // localDataBuiling.isEmpty
            
            // set the label text on main thread
            DispatchQueue.main.async(execute: {
                
                self.showDetailData = localDataBuilding
                
                #if DEBUG_PRINT_FUNCCALLS
                print("DetailsRKITableViewController.refreshLocalData done")
                #endif
                
                // reload the cells
                self.tableView.reloadData()
                
                self.initialDataAreDone = true
            })
        })
        
    }
    
    /**
     -----------------------------------------------------------------------------------------------
     
     refreshCellWithGraph()
     
     -----------------------------------------------------------------------------------------------
     */
    private func refreshCellWithGraph() {
        
        DispatchQueue.main.async(execute: {
            
            if (self.initialDataAreDone == true)
                && (self.tableView.numberOfRows(inSection: 0) >= self.rowNumberForGraphCells) {
                
                RKIGraphicQueue.sync(execute: {
                    self.leftImage = DetailsRKIGraphic.unique.GraphLeft
                    self.middleImage = DetailsRKIGraphic.unique.GraphMiddle
                    self.rightImage = DetailsRKIGraphic.unique.GraphRight
                })

                self.tableView.reloadRows(at: [IndexPath(row: self.rowNumberForGraphCells, section: 0)], with: .fade)
                
            } else {
               
                #if DEBUG_PRINT_FUNCCALLS
                print("refreshCellWithGraph() initialDataAreDone == false or numberOfRows < 1")
                #endif
            }
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
     
     viewWillAppear()
     
     -----------------------------------------------------------------------------------------------
     */

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 222
    }
    
//    override func viewWillLayoutSubviews() {
//        super.viewWillLayoutSubviews()
//
//
//    }
    
    
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
        
        // we have new graphs available
        newGraphReadyObserver = NotificationCenter.default.addObserver(
            forName: .CoBaT_Graph_NewGraphAvailable,
            object: nil,
            queue: OperationQueue.main,
            using: { Notification in

                #if DEBUG_PRINT_FUNCCALLS
                print("DetailsRKITableViewController just recieved signal .CoBaT_Graph_NewGraphAvailable, call refreshCellWithGraph()")
                #endif

                self.refreshCellWithGraph()
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
        
        // remove the observer if set
        if let observer = newGraphReadyObserver {
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
            
            //tableView.estimatedRowHeight = 116
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
        
        case rowNumberForInhabitantsCell:
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
            
            
        case rowNumberForGraphCells:
            
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
            //RKIGraphicQueue.sync(execute: {
            cell.LeftImage.image = self.leftImage
            cell.MiddleImage.image = self.middleImage
            cell.RightImage.image = self.rightImage
            //})

            return cell
            
            
        default:
            // the usual details content
            
            // we have a cell with the usual content (details)
            let myData = showDetailData[index - 2]
            
            // dequeue a cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "DetailsRKITableViewCellV2",
                                                     for: indexPath) as! DetailsRKITableViewCell
            

            if myData.dayOfWeek == self.weekdayOfCurrentDay {
                
            }
            // get color schema f
            let backgroundColor: UIColor
            let textColorToUse: UIColor
            
            if (myData.dayOfWeek == self.weekdayOfCurrentDay)
                && (myData.cellType == .dayDiff) {
                
                backgroundColor = self.rowHighlightedBackgroundUIColor
                textColorToUse = self.rowHighlightedTextUIColor

            } else {
                
                backgroundColor = myData.backgroundColor
                textColorToUse = myData.textColor
            }
            
            
            
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
            if myData.cellType == .current {
                
                cell.LabelCases.text = casesText
                cell.LabelDeaths.text = deathsText
                cell.LabelIncidences.text = incidencesText

            } else {
                
                cell.LabelCases.text = casesTextNew
                cell.LabelDeaths.text = deathsTextNew
                cell.LabelIncidences.text = incidencesTextNew
                

            }
            
            
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
                cell.LabelDate.text = "\(fromDate) (\(fromWeekday)) <> \(untilDate) (\(untilWeekday))"
                
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
            
//            cell.sizeToFit()
//            cell.setNeedsLayout()
            
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
