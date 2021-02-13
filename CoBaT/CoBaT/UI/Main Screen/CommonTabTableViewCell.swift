//
//  CommonTabTableViewCell.swift
//  CoBaT
//
//  Created by Hartwig Hopfenzitz on 02.12.20.
//

import UIKit

// ----------------------------------------------------------------------------------
// MARK: - Class
// ----------------------------------------------------------------------------------
final class CommonTabTableViewCell: UITableViewCell {

    // ------------------------------------------------------------------------------
    // MARK: - Class Properties
    // ------------------------------------------------------------------------------
    
    // ------------------------------------------------------------------------------
    // MARK: - IBOutlets
    // ------------------------------------------------------------------------------
    
    @IBOutlet weak var CellImage: UIImageView!
    @IBOutlet weak var CellLabel: UILabel!
    
    
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
