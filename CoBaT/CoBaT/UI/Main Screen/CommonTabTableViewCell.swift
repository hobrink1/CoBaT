//
//  CommonTabTableViewCell.swift
//  CoBaT
//
//  Created by Hartwig Hopfenzitz on 02.12.20.
//

import UIKit

class CommonTabTableViewCell: UITableViewCell {

    
    @IBOutlet weak var CellImage: UIImageView!
    @IBOutlet weak var CellLabel: UILabel!
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
