//
//  HelpTableViewCell.swift
//  CoBaT
//
//  Created by Hartwig Hopfenzitz on 02.12.20.
//

import UIKit

// ----------------------------------------------------------------------------------
// MARK: - Class
// ----------------------------------------------------------------------------------


class HelpTableViewCell: UITableViewCell {

    // ------------------------------------------------------------------------------
    // MARK: - Class Properties
    // ------------------------------------------------------------------------------
    
    // ------------------------------------------------------------------------------
    // MARK: - IBOutlets
    // ------------------------------------------------------------------------------

    @IBOutlet weak var LabelTop: UILabel!
    @IBOutlet weak var LabelBottom: UILabel!
    
    // ------------------------------------------------------------------------------
    // MARK: - Life Cycle
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
    
}
