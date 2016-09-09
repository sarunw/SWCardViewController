//
//  SWCardViewCollectionViewFlowLayout.swift
//  Pods
//
//  Created by Sarun Wongpatcharapakorn on 8/9/16.
//
//

import UIKit

class SWCardViewCollectionViewFlowLayout: UICollectionViewFlowLayout {
    
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
    
        guard let collectionView = self.collectionView else {
            return super.targetContentOffset(forProposedContentOffset: proposedContentOffset, withScrollingVelocity: velocity)
        }
        
        
        let bounds = collectionView.bounds
        let halfWidth = bounds.size.width * 0.5;
        let proposedContentOffsetCenterX = proposedContentOffset.x + halfWidth;
        
        if let attributesForVisibleCells = layoutAttributesForElements(in: bounds) {
            
            var candidateAttributes : UICollectionViewLayoutAttributes?
            for attributes in attributesForVisibleCells {
                
                // == Skip comparison with non-cell items (headers and footers) == //
                if attributes.representedElementCategory != UICollectionElementCategory.cell {
                    continue
                }
                
                if let candAttrs = candidateAttributes {
                    
                    let a = attributes.center.x - proposedContentOffsetCenterX
                    let b = candAttrs.center.x - proposedContentOffsetCenterX
                    
                    if fabsf(Float(a)) < fabsf(Float(b)) {
                        candidateAttributes = attributes;
                    }
                    
                }
                else { // == First time in the loop == //
                    
                    candidateAttributes = attributes;
                    continue;
                }
                
                
            }
            
            return CGPoint(x: round(candidateAttributes!.center.x - halfWidth), y: proposedContentOffset.y)
            
        }
        
        return super.targetContentOffset(forProposedContentOffset: proposedContentOffset, withScrollingVelocity: velocity)
    }
//    override func finalLayoutAttributesForDisappearingItemAtIndexPath(itemIndexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
//        let attributes = super.finalLayoutAttributesForDisappearingItemAtIndexPath(itemIndexPath)
//        
////        attributes?.alpha = 0
//        print("final \(attributes?.alpha)")
//        return attributes
//    }
//    
//    override func initialLayoutAttributesForAppearingItemAtIndexPath(itemIndexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
//        let attributes = super.initialLayoutAttributesForAppearingItemAtIndexPath(itemIndexPath)
//        
//        print("initial \(attributes?.alpha)")
//        return attributes
//    }
}
