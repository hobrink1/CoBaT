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
class BrowseCountyDataTableViewController: UITableViewController {

    // ---------------------------------------------------------------------------------------------
    // MARK: - Local storage
    // ---------------------------------------------------------------------------------------------

    // this will be set by the calling View Controller to selct the desired State
    var StateSelected: String = "Rheinland-Pfalz"
    
    // local copy of County Data, susetted by selected State
    var localDataArray: [GlobalStorage.RKIDataStruct] = []
    var localDataArrayDelta0: [GlobalStorage.RKIDataStruct]?
    var localDataArrayDelta7: [GlobalStorage.RKIDataStruct]?

    
    // ---------------------------------------------------------------------------------------------
    // MARK: - Helper
    // ---------------------------------------------------------------------------------------------
    func RefreshLocalData() {
        
            //let test = GlobalStorage.unique.RKIData[0]
            // read the current content of the global storage
            GlobalStorageQueue.sync(execute: {
                
                
                // get the global storage, filtered to the current selected state
                self.localDataArray = GlobalStorage.unique.RKIData[GlobalStorage.unique.RKIDataCounty][0].filter(
                    { $0.stateID == "7"})
                
                // check if we got data
                if self.localDataArray.isEmpty == false {
                    
                    // yes we have data, so try to find the values of yesterday
                    let numberOfDays = GlobalStorage.unique.RKIData[GlobalStorage.unique.RKIDataCounty].count
                    
                    // check if we have at least one more day
                    if numberOfDays > 1 {
                        
                        // OK we have at least one more day, so get the "yesterday" values
                        self.localDataArrayDelta0 = GlobalStorage.unique.RKIData[GlobalStorage.unique.RKIDataCounty][0].filter(
                            { $0.stateID == "7"})
                        
                        // check if we found something
                        if self.localDataArrayDelta0?.isEmpty == false {
                            
                            // yes we have data!
                            
                        }

                    }
                    
                    
                }
            })
            
        
        
        
            // sort the local copy
            self.localDataArray.sort( by: { $0.name < $1.name } )
        
        // we use the main thread as our working thread, so we have no problems in UI updates
        DispatchQueue.main.async {

            // reload the cells
            self.tableView.reloadData()
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "CountyTableViewCell", for: indexPath) as! CountyTableViewCell
        
        // get the related data set from local storage
        let index = indexPath.row
        let myData = localDataArray[index]
        
        // get color schema for 7 day average caces per 100 K people
        let (backgroundColor, textColorToUse) = CovidRating.unique.getColorsForValue(myData.cases7DaysPer100K)
        
        // set the backgroun dof the cell
        cell.contentView.backgroundColor = backgroundColor
        
        // fill the data fileds and set text color
        cell.CountyName.text = myData.name
        cell.CountyName.textColor = textColorToUse
        
        cell.LabelCases7per100K.text = "Inzidenz 7 Tage / 100k"
        cell.LabelCases7per100K.textColor = textColorToUse
        cell.ValueCases7per100k.text = number1FractionFormatter.string(
            from: NSNumber(value: myData.cases7DaysPer100K))
        cell.ValueCases7per100k.textColor = textColorToUse
        
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
