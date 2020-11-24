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
    var localDataArray: [GlobalStorage.RKICountyDataStruct] = []
    
    
    // ---------------------------------------------------------------------------------------------
    // MARK: - Helper
    // ---------------------------------------------------------------------------------------------
    func RefreshLocalData() {
        
        DispatchQueue.main.async {
            self.localDataArray = GlobalStorage.unique.RKICountyData.filter(
                { $0.stateName == self.StateSelected})
            
            self.localDataArray.sort( by: { $0.countyName < $1.countyName } )
            
            self.tableView.reloadData()
            
        }
    }
    
    
    
    
    // ---------------------------------------------------------------------------------------------
    // MARK: - Life cycle
    // ---------------------------------------------------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        // we want the cell height self adjust to user selected text size
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 64

        // refresh the data
        self.RefreshLocalData()
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // refresh the data
        self.RefreshLocalData()
    }

    // ---------------------------------------------------------------------------------------------
    // MARK: - Table view data source
    // ---------------------------------------------------------------------------------------------

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.localDataArray.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "CountyTableViewCell", for: indexPath) as! CountyTableViewCell

        let index = indexPath.row
        let myData = localDataArray[index]
        
        let textColorToUse: UIColor
        if myData.Covid7DaysCasesPer100K < 35.0 {
            
            cell.contentView.backgroundColor = UIColor.systemGreen
            textColorToUse = UIColor.black
            
        } else if myData.Covid7DaysCasesPer100K < 50.0 {
            
            cell.contentView.backgroundColor = UIColor.systemYellow
            textColorToUse = UIColor.black

        } else if myData.Covid7DaysCasesPer100K < 100.0 {
            cell.contentView.backgroundColor = UIColor.systemOrange
            textColorToUse = UIColor.black

        } else  {
            cell.contentView.backgroundColor = UIColor.systemRed
            textColorToUse = UIColor.white
        }

        cell.CountyName.text = myData.countyName
        cell.CountyName.textColor = textColorToUse
        
        cell.LabelCases7per100K.text = "Inzidenzes 7 Tage pro 100 K"
        cell.LabelCases7per100K.textColor = textColorToUse
        cell.ValueCases7per100k.text = number1FractionFormatter.string(
            from: NSNumber(value: myData.Covid7DaysCasesPer100K))
        cell.ValueCases7per100k.textColor = textColorToUse

        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
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
