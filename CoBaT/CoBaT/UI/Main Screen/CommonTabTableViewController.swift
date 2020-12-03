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
        // 0: no covid
        [
            regulationsMatrixStruct(UIImage(named: "Empty")!, "no covid, no regulations"),
        ],
        
        // 1: green
        [
            regulationsMatrixStruct(UIImage(named: "Distance")!,    "keep Distance"),
            regulationsMatrixStruct(UIImage(named: "Wash")!,        "Wash often"),
            regulationsMatrixStruct(UIImage(named: "Air Room")!,    "Air Room"),
            regulationsMatrixStruct(UIImage(named: "Mask")!,        "wear mask in public"),
            regulationsMatrixStruct(UIImage(named: "Inhouse")!,     "Inhouse max 100"),
            regulationsMatrixStruct(UIImage(named: "Outhouse")!,    "Outdoor max 200"),
        ],
        
        // 2: Yellow
        [
            regulationsMatrixStruct(UIImage(named: "Distance")!,    "keep Distance"),
            regulationsMatrixStruct(UIImage(named: "Wash")!,        "Wash often"),
            regulationsMatrixStruct(UIImage(named: "Air Room")!,    "Air Room"),
            regulationsMatrixStruct(UIImage(named: "Mask")!,        "wear mask in schools"),
            regulationsMatrixStruct(UIImage(named: "Alkohol")!,     "Alkohol 11 PM"),
            regulationsMatrixStruct(UIImage(named: "Inhouse")!,     "Inhouse max 10"),
            regulationsMatrixStruct(UIImage(named: "Outhouse")!,    "Outdoor max 200"),
        ],
        
        // 3: Red
        [
            regulationsMatrixStruct(UIImage(named: "Distance")!,    "keep Distance"),
            regulationsMatrixStruct(UIImage(named: "Wash")!,        "Wash often"),
            regulationsMatrixStruct(UIImage(named: "Air Room")!,    "Air Room"),
            regulationsMatrixStruct(UIImage(named: "Mask")!,        "wear mask in schools"),
            regulationsMatrixStruct(UIImage(named: "Alkohol")!,     "Alkohol 10 PM"),
            regulationsMatrixStruct(UIImage(named: "Inhouse")!,     "Inhouse max 5"),
            regulationsMatrixStruct(UIImage(named: "Outhouse")!,    "Outdoor max 200"),
            
        ],
        
        // 4: dark red
        [
            regulationsMatrixStruct(UIImage(named: "Distance")!,    "keep Distance"),
            regulationsMatrixStruct(UIImage(named: "Wash")!,        "Wash often"),
            regulationsMatrixStruct(UIImage(named: "Air Room")!,    "Air Room"),
            regulationsMatrixStruct(UIImage(named: "Mask")!,        "wear mask in schools"),
            regulationsMatrixStruct(UIImage(named: "Alkohol")!,     "Alkohol 9 PM"),
            regulationsMatrixStruct(UIImage(named: "Inhouse")!,     "Inhouse max 5"),
            regulationsMatrixStruct(UIImage(named: "Inhouse")!,     "Inhouse events max 50"),
            regulationsMatrixStruct(UIImage(named: "Outhouse")!,    "Outdoor max 50"),
        ],
        
        // 5: purple
        [
            regulationsMatrixStruct(UIImage(named: "Distance")!,    "keep Distance"),
            regulationsMatrixStruct(UIImage(named: "Wash")!,        "Wash often"),
            regulationsMatrixStruct(UIImage(named: "Air Room")!,    "Air Room"),
            regulationsMatrixStruct(UIImage(named: "Mask")!,        "wear mask in schools"),
            regulationsMatrixStruct(UIImage(named: "Alkohol")!,     "Alkohol 9 PM"),
            regulationsMatrixStruct(UIImage(named: "Inhouse")!,     "Inhouse max 5"),
            regulationsMatrixStruct(UIImage(named: "Outhouse")!,    "Outdoor max 50"),
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
            
            // set the color of seperator between cells
            self.tableView.separatorColor = self.textColor

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

    /**
     -----------------------------------------------------------------------------------------------
     
     numberOfSections())
     
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
        return RegulationsMatrix[self.grade].count
    }

    /**
     -----------------------------------------------------------------------------------------------
     
     cellForRowAt:
     
     -----------------------------------------------------------------------------------------------
     */
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
        
        cell.CellLabel.text = NSLocalizedString(myData.text, comment: "see localization")
        cell.CellLabel.textColor = self.textColor
        
        // Configure the cell...

        return cell
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
