//
//  DetailsInhabitantsTableViewCell.swift
//  CoBaT
//
//  Created by Hartwig Hopfenzitz on 11.12.20.
//

import UIKit

// ----------------------------------------------------------------------------------
// MARK: - Class
// ----------------------------------------------------------------------------------
final class DetailsInhabitantsTableViewCell: UITableViewCell {

    // ------------------------------------------------------------------------------
    // MARK: - Class Properties
    // ------------------------------------------------------------------------------
    
    // ------------------------------------------------------------------------------
    // MARK: - IBOutlets
    // ------------------------------------------------------------------------------

    @IBOutlet weak var ValueKindOf: UILabel!
    @IBOutlet weak var ValueInhabitants: UILabel!
    @IBOutlet weak var LabelInhabitants: UILabel!
    

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
    }

//    override func setSelected(_ selected: Bool, animated: Bool) {
//        super.setSelected(selected, animated: animated)
//
//        // Configure the view for the selected state
//    }

}
