//
//  CommonTabTableViewController.swift
//  CoBaT
//
//  Created by Hartwig Hopfenzitz on 02.12.20.
//

import UIKit
// -------------------------------------------------------------------------------------------------
// MARK: -
// MARK: - CommonTabViewController
// -------------------------------------------------------------------------------------------------

// -------------------------------------------------------------------------------------------------
// MARK: -
// MARK: - Class
// -------------------------------------------------------------------------------------------------


class CommonTabTableViewController: UITableViewController {
    // ---------------------------------------------------------------------------------------------
    // MARK: - Properties
    // ---------------------------------------------------------------------------------------------

    // the oberservers have to be released, otherwise there wil be a memory leak.
    // this variables were set in "ViewDidApear()" and released in "ViewDidDisappear()"
    var CommonTabBarChangedContentObserver: NSObjectProtocol?

    // the colorcodes and the grade
    var textColor: UIColor = GlobalUIData.unique.UITabBarCurentTextColor
    var backgroundColor: UIColor = GlobalUIData.unique.UITabBarCurentBackgroundColor
    var grade: Int = GlobalUIData.unique.UITabBarCurentGrade
    
    // we store the regulations in a two dimension matrix
    struct regulationsMatrixStruct {
        let image: UIImage
        let text: String
        
        init(_ image: UIImage, _ text: String) {
            self.image = image
            self.text = text
        }
    }
    
    
    let RegulationsMatrix: [[regulationsMatrixStruct]] = [
        // 0
        [
            regulationsMatrixStruct(UIImage(named: "Empty")!, "no covid, no regulations"),
        ],
        
        // 1
        [
            regulationsMatrixStruct(UIImage(named: "Distance")!,    "keep Distance"),
            regulationsMatrixStruct(UIImage(named: "Mask")!,        "wear mask"),
            regulationsMatrixStruct(UIImage(named: "Air Room")!,    "Air room "),
            regulationsMatrixStruct(UIImage(named: "Wash")!,        "Wash often"),
            regulationsMatrixStruct(UIImage(named: "Alkohol")!,     "Alkohol"),
            regulationsMatrixStruct(UIImage(named: "Inhouse")!,     "Inhouse limitations"),
            regulationsMatrixStruct(UIImage(named: "Outhouse")!,    "Outdoor limitations"),
       ],
        
        // 2
        [
            regulationsMatrixStruct(UIImage(named: "Distance")!,    "keep Distance"),
            regulationsMatrixStruct(UIImage(named: "Mask")!,        "wear mask"),
            regulationsMatrixStruct(UIImage(named: "Air Room")!,    "Air room "),
            regulationsMatrixStruct(UIImage(named: "Wash")!,        "Wash often"),
            regulationsMatrixStruct(UIImage(named: "Alkohol")!,     "Alkohol"),
            regulationsMatrixStruct(UIImage(named: "Inhouse")!,     "Inhouse limitations"),
            regulationsMatrixStruct(UIImage(named: "Outhouse")!,    "Outdoor limitations"),
        ],
        
        // 3
        [
            regulationsMatrixStruct(UIImage(named: "Distance")!,    "keep Distance"),
            regulationsMatrixStruct(UIImage(named: "Mask")!,        "wear mask"),
            regulationsMatrixStruct(UIImage(named: "Air Room")!,    "Air room "),
            regulationsMatrixStruct(UIImage(named: "Wash")!,        "Wash often"),
            regulationsMatrixStruct(UIImage(named: "Alkohol")!,     "Alkohol"),
            regulationsMatrixStruct(UIImage(named: "Inhouse")!,     "Inhouse limitations"),
            regulationsMatrixStruct(UIImage(named: "Outhouse")!,    "Outdoor limitations"),

        ],
        
        // 4
        [
            regulationsMatrixStruct(UIImage(named: "Distance")!,    "keep Distance"),
            regulationsMatrixStruct(UIImage(named: "Mask")!,        "wear mask"),
            regulationsMatrixStruct(UIImage(named: "Air Room")!,    "Air room "),
            regulationsMatrixStruct(UIImage(named: "Wash")!,        "Wash often"),
            regulationsMatrixStruct(UIImage(named: "Alkohol")!,     "Alkohol"),
            regulationsMatrixStruct(UIImage(named: "Inhouse")!,     "Inhouse limitations"),
            regulationsMatrixStruct(UIImage(named: "Outhouse")!,    "Outdoor limitations"),
        ],
        
        // 5
        [
            regulationsMatrixStruct(UIImage(named: "Distance")!,    "keep Distance"),
            regulationsMatrixStruct(UIImage(named: "Mask")!,        "wear mask"),
            regulationsMatrixStruct(UIImage(named: "Air Room")!,    "Air room "),
            regulationsMatrixStruct(UIImage(named: "Wash")!,        "Wash often"),
            regulationsMatrixStruct(UIImage(named: "Alkohol")!,     "Alkohol"),
            regulationsMatrixStruct(UIImage(named: "Inhouse")!,     "Inhouse limitations"),
            regulationsMatrixStruct(UIImage(named: "Outhouse")!,    "Outdoor limitations"),
        ],
    ]
    
    // ---------------------------------------------------------------------------------------------
    // MARK: - Helper
    // ---------------------------------------------------------------------------------------------

    /**
     -----------------------------------------------------------------------------------------------
     
     refreshes the content
     
     -----------------------------------------------------------------------------------------------
     */
    private func refreshContent() {
       
        // set the local variables
        self.textColor = GlobalUIData.unique.UITabBarCurentTextColor
        self.backgroundColor = GlobalUIData.unique.UITabBarCurentBackgroundColor
        self.grade = GlobalUIData.unique.UITabBarCurentGrade

        // refresh content on main thread
        DispatchQueue.main.async(execute: {
            
            // set color of table view background
            self.tableView.backgroundColor = self.backgroundColor

            // reload all cells
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

        self.tableView.backgroundColor = self.backgroundColor
    }
    
    /**
     -----------------------------------------------------------------------------------------------
     
     viewDidAppear()
     
     -----------------------------------------------------------------------------------------------
     */
    override func viewDidAppear(_ animated: Bool) {
        super .viewDidAppear(animated)
        // Do any additional setup after loading the view.
        
        // add observer to recognise if user selcted new state
        CommonTabBarChangedContentObserver = NotificationCenter.default.addObserver(
            forName: .CoBaT_CommonTabBarChangedContent,
            object: nil,
            queue: OperationQueue.main,
            using: { Notification in
                
                #if DEBUG_PRINT_FUNCCALLS
                print("CommonTabTableViewController just recieved signal .CoBaT_CommonTabBarChangedContent")
                #endif
                
                // update content
                self.refreshContent()

            })
        
        
        // update content first time
        self.refreshContent()
     }
 
    /**
     -----------------------------------------------------------------------------------------------
     
     viewDidDisappear()
     
     -----------------------------------------------------------------------------------------------
     */
    override func viewDidDisappear(_ animated: Bool) {
        super .viewDidDisappear(animated)
        
        // remove the observer if set
        if let observer = CommonTabBarChangedContentObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
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
        return RegulationsMatrix[0].count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // dequeue a cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "CommonTabTableViewCell",
                                                 for: indexPath) as! CommonTabTableViewCell
        
         
        // get the related data set from local storage
        let index = indexPath.row
        let myData = RegulationsMatrix[self.grade][index]
        
        cell.backgroundColor = self.backgroundColor
        
        cell.CellImage.image = myData.image
        cell.CellImage.tintColor = self.textColor
        
        cell.CellLabel.text = myData.text
        cell.CellLabel.textColor = self.textColor
        
        // Configure the cell...

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
