//
//  BrowseRKIDataTableViewCell.swift
//  CoBaT
//
//  Created by Hartwig Hopfenzitz on 24.11.20.
//

import UIKit

// ----------------------------------------------------------------------------------
// MARK: - Button protocol
// ----------------------------------------------------------------------------------

protocol BrowseRKIDataTableViewCellPlacesDelegate {
    
    // the function to detect the button tap
    func selectButtonTapped(cell: BrowseRKIDataTableViewCell)
    
    // the function to detect the button tap
    func detailsButtonTapped(cell: BrowseRKIDataTableViewCell)
}

// ----------------------------------------------------------------------------------
// MARK: - Class
// ----------------------------------------------------------------------------------
final class BrowseRKIDataTableViewCell: UITableViewCell {

    // ------------------------------------------------------------------------------
    // MARK: - Class Properties
    // ------------------------------------------------------------------------------
    var myIndexPath: IndexPath!
    
    // ------------------------------------------------------------------------------
    // MARK: - IBOutlets
    // ------------------------------------------------------------------------------
    @IBOutlet weak var Name: UILabel!
    @IBOutlet weak var KindOf: UILabel!
    
    @IBOutlet weak var Cases: UILabel!
    @IBOutlet weak var FirstCases: UILabel!
    @IBOutlet weak var SecondCases: UILabel!
    @IBOutlet weak var ThirdCases: UILabel!
    
    @IBOutlet weak var Incidences: UILabel!
    @IBOutlet weak var FirstIncidences: UILabel!
    @IBOutlet weak var SecondIncidences: UILabel!
    @IBOutlet weak var ThirdIncidences: UILabel!
    
    @IBOutlet weak var ChevronRight: UIImageView!
    @IBOutlet weak var ChevronLeft: UIImageView!
    
    @IBOutlet weak var CellContentView: UIView!
   
    
    // ------------------------------------------------------------------------------
    // MARK: - Select Button
    // ------------------------------------------------------------------------------
    // var for the delegate, which will be set in "cellForRowAt:"
    var selectButtonDelegate: BrowseRKIDataTableViewCellPlacesDelegate?

    // the button outlet
     @IBOutlet weak var SelectButton: UIButton!
    
    // the action methode which simply called the protocol methode
    @IBAction func SelectButtonAction(_ sender: UIButton) {
        
         // check if the delegte is valid
        if let delegate = selectButtonDelegate {
            
            // yes, valid delegate, so call the function
            delegate.selectButtonTapped(cell: self)
            
        } else {
            
            GlobalStorage.unique.storeLastError(
                errorText: "BrowseRKIDataTableViewCell(Row:\(self.myIndexPath.row).SelectButtonAction() Error: delegate = selectButtonDelegate was nil")
        }
    }

    
    // ------------------------------------------------------------------------------
    // MARK: - details Button
    // ------------------------------------------------------------------------------
    // var for the delegate, which will be set in "cellForRowAt:"
    var detailsButtonDelegate: BrowseRKIDataTableViewCellPlacesDelegate?

    // the button outlet
    @IBOutlet weak var DetailsButton: UIButton!
    
    // the action methode which simply called the protocol methode
    @IBAction func DetailsButtonAction(_ sender: UIButton) {
        
        // check if the delegte is valid
       if let delegate = detailsButtonDelegate {
           
           // yes, valid delegate, so call the function
           delegate.detailsButtonTapped(cell: self)
           
       } else {
           
           GlobalStorage.unique.storeLastError(
               errorText: "BrowseRKIDataTableViewCell(Row:\(self.myIndexPath.row).detailsButtonAction() Error: delegate = detailsButtonDelegate was nil")
       }
    }
    
    
    // ------------------------------------------------------------------------------
    // MARK: - Life cycle
    // ------------------------------------------------------------------------------
    /**
     -----------------------------------------------------------------------------------------------
     
     awakeFromNib()
     
     -----------------------------------------------------------------------------------------------
     */
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        // we use a rounded cornder style
        self.layer.cornerRadius = 5
        self.layer.borderWidth = 1
    }
}
