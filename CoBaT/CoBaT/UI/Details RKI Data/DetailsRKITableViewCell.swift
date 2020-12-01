//
//  DetailsRKITableViewCell.swift
//  CoBaT
//
//  Created by Hartwig Hopfenzitz on 29.11.20.
//

import UIKit

// ----------------------------------------------------------------------------------
// MARK: - Class
// ----------------------------------------------------------------------------------
class DetailsRKITableViewCell: UITableViewCell {

    // ------------------------------------------------------------------------------
    // MARK: - Class Properties
    // ------------------------------------------------------------------------------
    
    // ------------------------------------------------------------------------------
    // MARK: - IBOutlets
    // ------------------------------------------------------------------------------

    @IBOutlet weak var LabelDate: UILabel!

    @IBOutlet weak var LabelInhabitans: UILabel!
    @IBOutlet weak var ValueInhabitans: UILabel!

    @IBOutlet weak var LabelTotal: UILabel!
    @IBOutlet weak var LabelPer100k: UILabel!

    @IBOutlet weak var LabelCases: UILabel!
    @IBOutlet weak var CasesTotal: UILabel!
    @IBOutlet weak var Cases100k: UILabel!

    @IBOutlet weak var LabelDeaths: UILabel!
    @IBOutlet weak var DeathsTotal: UILabel!
    @IBOutlet weak var Deaths100k: UILabel!

    @IBOutlet weak var LabelIncidences: UILabel!
    @IBOutlet weak var IncidencesTotal: UILabel!
    @IBOutlet weak var Incidences100k: UILabel!


    // ------------------------------------------------------------------------------
    // MARK: - Life cycle
    // ------------------------------------------------------------------------------

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        // we use a rounded style
        self.layer.cornerRadius = 5
        self.layer.borderWidth = 1

    }

}
