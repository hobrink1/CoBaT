//
//  HelpTableViewController.swift
//  CoBaT
//
//  Created by Hartwig Hopfenzitz on 02.12.20.
//

import UIKit


// -------------------------------------------------------------------------------------------------
// MARK: -
// MARK: - HelpTableViewController
// -------------------------------------------------------------------------------------------------

// -------------------------------------------------------------------------------------------------
// MARK: -
// MARK: - Class
// -------------------------------------------------------------------------------------------------
    
final class HelpTableViewController: UITableViewController {
    
    // ---------------------------------------------------------------------------------------------
    // MARK: - Class Properties
    // ---------------------------------------------------------------------------------------------

    enum localDataEnum {
        case singleString, doubleString, errorMessage, version
    }
    struct localDataStruct {
        let localDataType: localDataEnum
        let label1: String
        let label2: String
        
        init(dataType: localDataEnum, label1: String, label2: String) {
            self.localDataType = dataType
            self.label1 = label1
            self.label2 = label2
         }
    }
    
    // The dataType decides if the cell will be translated or not
    // .singleString and .doubleString will always translated
    // .errorMessage will never translated
    let AboutTexts: [localDataStruct] = [
        
        localDataStruct(dataType: .version, label1: "", label2: ""),
        localDataStruct(dataType: .singleString, label1: "RKI-Disclaimer", label2: ""),

    ]

    var localData: [localDataStruct] = []
    
    
    // ---------------------------------------------------------------------------------------------
    // MARK: - Helpers
    // ---------------------------------------------------------------------------------------------
    /**
     -----------------------------------------------------------------------------------------------
     
     refresh local data
     
     -----------------------------------------------------------------------------------------------
     */
    private func refreshLocalData() {
        
        var localDataBuild: [localDataStruct] = []
        
        for item in AboutTexts {
            
            switch item.localDataType {
            
            case .version:
                
                // just the version string
                // append a new record
                localDataBuild.append(localDataStruct(
                                        dataType: item.localDataType,
                                        label1: VersionLabel,
                                        label2: ""))
                
                
                
            case .singleString:
                
                // translate the label text
                let label1Text = NSLocalizedString(item.label1, comment: "")
                
                // append a new record
                localDataBuild.append(localDataStruct(
                                        dataType: item.localDataType,
                                        label1: label1Text,
                                        label2: ""))
                
                
            case .doubleString:
                
                // translate the label texts
                let label1Text = NSLocalizedString(item.label1, comment: "")
                let label2Text = NSLocalizedString(item.label2, comment: "")
                
                // append a new record
                localDataBuild.append(localDataStruct(
                                        dataType: item.localDataType,
                                        label1: label1Text,
                                        label2: label2Text))
                
                
            case .errorMessage:
                
                // append a new record
                localDataBuild.append(item)
                
            }
        }
        
        
        GlobalStorageQueue.sync(execute: {
            
            if GlobalStorage.unique.lastErrors.isEmpty == false {
                
                // translate the label text
                let label1Text = NSLocalizedString("Explanation-Error-Messages",
                                                   comment: "List of current error messages")
                
                
                
                // append a new record
                localDataBuild.append(localDataStruct(
                                        dataType: .singleString,
                                        label1: label1Text,
                                        label2: ""))
                
                // resort the erros so that newest is on top
                let sortedErrors = GlobalStorage.unique.lastErrors.sorted(
                    by: { $0.errorTimeStamp > $1.errorTimeStamp } )
                
                // walk over the sorted erros and list them
                for item in sortedErrors {
                    
                    let myDate: Date = Date(timeIntervalSinceReferenceDate: item.errorTimeStamp)
                    let timeStampString: String = mediumMediumSingleRelativeDateTimeFormatter.string(
                        from: myDate)
                    
                    localDataBuild.append(localDataStruct(
                                            dataType: .doubleString,
                                            label1: timeStampString,
                                            label2: item.errorText))
                }
                
            } else {
                
                // translate the label text
                let label1Text = NSLocalizedString("Explanation-No-Error-Messages",
                                                   comment: "no error messages")
                
                // append a new record
                localDataBuild.append(localDataStruct(
                                        dataType: .singleString,
                                        label1: label1Text,
                                        label2: ""))
            }
            
            
            DispatchQueue.main.async(execute: {
                
                self.localData = localDataBuild
                
                self.tableView.reloadData()
            })
        })
    }

    
    // ---------------------------------------------------------------------------------------------
    // MARK: - IB Outlets
    // ---------------------------------------------------------------------------------------------

    @IBOutlet weak var DoneButton: UIBarButtonItem!
    @IBAction func DoneButtonAction(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
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
        
        self.title = NSLocalizedString("Main-Button-Help", comment: "Help Button Title")
        self.refreshLocalData()
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
        return self.localData.count
    }

    /**
     -----------------------------------------------------------------------------------------------
     
     cellForRowAt:
     
     -----------------------------------------------------------------------------------------------
     */
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // dequeue a cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "HelpTableViewCell",
                                                 for: indexPath) as! HelpTableViewCell

        // get the related data set from local storage
        let index = indexPath.row
        let myData = localData[index]
        
        cell.LabelTop.text = myData.label1
        cell.LabelBottom.text = myData.label2

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
