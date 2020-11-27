//
//  BrowseRKIDataTableViewCell.swift
//  CoBaT
//
//  Created by Hartwig Hopfenzitz on 24.11.20.
//

import UIKit

class BrowseRKIDataTableViewCell: UITableViewCell {

    @IBOutlet weak var Name: UILabel!
    
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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
