//
//  DetailsRKIGraphTableViewCell.swift
//  CoBaT
//
//  Created by Hartwig Hopfenzitz on 14.12.20.
//

import UIKit
// ----------------------------------------------------------------------------------
// MARK: - Class
// ----------------------------------------------------------------------------------
final class DetailsRKIGraphTableViewCell: UITableViewCell {

    // ------------------------------------------------------------------------------
    // MARK: - Class Properties
    // ------------------------------------------------------------------------------
    
    // ------------------------------------------------------------------------------
    // MARK: - IBOutlets
    // ------------------------------------------------------------------------------

    @IBOutlet weak var LeftGraph: UIImageView!
    
    
    @IBOutlet weak var MiddleGraph: UIImageView!

    
    @IBOutlet weak var RightGraph: UIImageView!

    var LeftImage: UIImageView!
    var MiddleImage: UIImageView!
    var RightImage: UIImageView!

    
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
        
        // we give the three imageviews the optimal size, depending on the screen size of the device
        // the values are pre calculated at GlobalUIData() as they will not change over lifetime
        
        let screenWidth: CGFloat = GlobalUIData.unique.UIScreenWidth
        
        let sideMargins: CGFloat = GlobalUIData.unique.RKIGraphSideMargins
        let topMargin: CGFloat = GlobalUIData.unique.RKIGraphTopMargine
        
        let neededWidth = GlobalUIData.unique.RKIGraphNeededWidth
        let neededHeight = GlobalUIData.unique.RKIGraphNeededHeight
        
        
        // setup the images and add the images as subviews
        
        self.LeftImage = UIImageView(image: DetailsRKIGraphic.unique.GraphLeft)
        self.LeftImage.frame = CGRect(x: sideMargins, y: topMargin,
                                      width: neededWidth, height: neededHeight)
        
        self.LeftImage.layer.cornerRadius = 4
        self.LeftImage.clipsToBounds = true
        
        self.addSubview(self.LeftImage)
        
        
        
        self.MiddleImage = UIImageView(image: DetailsRKIGraphic.unique.GraphLeft)
        self.MiddleImage.frame = CGRect(x: (screenWidth / 2) - (neededWidth / 2), y: topMargin,
                                        width: neededWidth, height: neededHeight)
        
        self.MiddleImage.layer.cornerRadius = 4
        self.MiddleImage.clipsToBounds = true
        
        self.addSubview(self.MiddleImage)
        
        
        
        self.RightImage = UIImageView(image: DetailsRKIGraphic.unique.GraphLeft)
        self.RightImage.frame = CGRect(x: screenWidth - sideMargins - neededWidth, y: topMargin,
                                       width: neededWidth, height: neededHeight)
        
        self.RightImage.layer.cornerRadius = 4
        self.RightImage.clipsToBounds = true
        
        self.addSubview(self.RightImage)
        
    }

 
}
