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
    
    var localRKIData: [GlobalStorage.RKIDataStruct] = []

    // ---------------------------------------------------------------------------------------------
    // MARK: - Helper
    // ---------------------------------------------------------------------------------------------

    private func refreshLocalData() {
        
        // create shortcuts
        let selectedAreaLevel = GlobalUIData.unique.UIDetailsRKIAreaLevel
        let selectedMyID = GlobalUIData.unique.UIDetailsRKISelectedMyID
        
        var localRKIDataLoaded : [GlobalStorage.RKIDataStruct] = []
        
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
            
            for dayIndex in 1 ..< GlobalStorage.unique.RKIDataDeltas[selectedAreaLevel].count {
                
                // shortcut
                let RKIDataToUse = GlobalStorage.unique.RKIDataDeltas[selectedAreaLevel][dayIndex]
                
                // try to find the index of the requested ID
                if let RKIDataOfDay = RKIDataToUse.first(where: { $0.myID == selectedMyID } ) {
                    
                    // we found a valid record, so store the data locally
                    localRKIDataLoaded.append(RKIDataOfDay)
                    
                } else {
                    
                    // we did not found a valid index, report and use default values
                    GlobalStorage.unique.storeLastError(errorText: "DetailsRKITableViewController.refreshLocalData: Error: RKIDataDeltas: did not found valid record for day \(dayIndex) of ID \"\(selectedMyID)/” of area level \"\(selectedAreaLevel)\", ignore record")
                    
                }
            }
        })
        
        // set the label text on main thread
        DispatchQueue.main.async(execute: {
            
            self.localRKIData = localRKIDataLoaded
            
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
        return self.localRKIData.count
    }

    /**
     -----------------------------------------------------------------------------------------------
     
     cellForRowAt:
     
     -----------------------------------------------------------------------------------------------
     */
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // dequeue a cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "DetailsRKITableViewCell",
                                                 for: indexPath) as! DetailsRKITableViewCell
        
        
        // get the related data set from local storage
        let index = indexPath.row
        let myData = localRKIData[index]
        
        // get color schema for 7 day average caces per 100 K people
        let (backgroundColor, textColorToUse) = CovidRating.unique.getColorsForValue(myData.cases7DaysPer100K)
        
        // set the background of the cell
        cell.contentView.backgroundColor = backgroundColor
       
        // set the text colors
        cell.LabelDate.textColor = textColorToUse

        cell.LabelInhabitans.textColor = textColorToUse
        cell.ValueInhabitans.textColor = textColorToUse

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


        // set the values
        // dateFormatterLocalizedWeekdayShort
        cell.LabelDate.text = longSingleRelativeDateTimeFormatter.string(
            from: Date(timeIntervalSinceReferenceDate: myData.timeStamp))

        //cell.LabelInhabitans.textColor = textColorToUse
        cell.ValueInhabitans.text = numberNoFractionFormatter.string(
            from: NSNumber(value: myData.inhabitants))

        //cell.LabelTotal.textColor = textColorToUse
        //cell.LabelPer100k.textColor = textColorToUse

        //cell.LabelCases.textColor = textColorToUse
        cell.CasesTotal.text = numberNoFractionFormatter.string(
            from: NSNumber(value: myData.cases))
        cell.Cases100k.text = numberNoFractionFormatter.string(
            from: NSNumber(value: myData.casesPer100k))

        //cell.LabelDeaths.textColor = textColorToUse
        cell.DeathsTotal.text = numberNoFractionFormatter.string(
            from: NSNumber(value: myData.deaths))
        cell.Deaths100k.text = ""

        //cell.LabelIncidences.textColor = textColorToUse
        cell.IncidencesTotal.text = ""
        cell.Incidences100k.text = numberNoFractionFormatter.string(
            from: NSNumber(value: myData.cases7DaysPer100K))

        
 
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
