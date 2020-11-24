//
//  CountyTableViewCell.swift
//  CoBaT
//
//  Created by Hartwig Hopfenzitz on 24.11.20.
//

import UIKit

class CountyTableViewCell: UITableViewCell {

    @IBOutlet weak var CountyName: UILabel!
    
    @IBOutlet weak var LabelCases7per100K: UILabel!
    @IBOutlet weak var ValueCases7per100k: UILabel!
    
    @IBOutlet weak var CellContentView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
