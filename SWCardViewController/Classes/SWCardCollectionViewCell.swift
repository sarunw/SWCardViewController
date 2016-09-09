//
//  SWCardCollectionViewCell.swift
//  Pods
//
//  Created by Sarun Wongpatcharapakorn on 8/8/16.
//
//

import UIKit

class SWCardCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var containerView: UIView!
    
    weak var viewController: UIViewController?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        clipsToBounds = false
        
        contentView.clipsToBounds = false
        contentView.layer.shadowRadius = 5
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOffset = CGSize(width: 0, height: 2)
        contentView.layer.shadowOpacity = 0.3
        
//        containerView.layer.cornerRadius = 5
//        containerView.clipsToBounds = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: 5)
        contentView.layer.shadowPath = shadowPath.cgPath
    }
}
