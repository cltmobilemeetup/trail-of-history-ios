//
//  MapViewCardCollectionViewFlowLayout.swift
//  Trail of History
//
//  Created by Mark Flowers on 9/20/16.
//  Copyright © 2016 CLT Mobile. All rights reserved.
//

import UIKit

class MapViewCardCollectionViewLayout: UICollectionViewFlowLayout {
    
    required init?(coder aDecoder: NSCoder) {
        super.init()
        self.scrollDirection = .Horizontal
    }
    
    override func targetContentOffsetForProposedContentOffset(proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        
        if let collectionView = self.collectionView {
            
            let collectinoViewBounds = collectionView.bounds
            let newWidth = collectinoViewBounds.size.width * 0.2;
            let proposedContentOffsetCenterX = proposedContentOffset.x + newWidth;
            
            if let attributesForVisibleCells = self.layoutAttributesForElementsInRect(collectinoViewBounds) {
                
                var candidateAttributes : UICollectionViewLayoutAttributes?
                for attributes in attributesForVisibleCells {
                    
                    // == Skip comparison with non-cell items (headers and footers) == //
                    if attributes.representedElementCategory != UICollectionElementCategory.Cell {
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
                
                return CGPoint(x : candidateAttributes!.center.x - newWidth, y : proposedContentOffset.y);
                
            }
            
        }
        
        // Fallback
        return super.targetContentOffsetForProposedContentOffset(proposedContentOffset)
    }
    
}