//
//  MapViewCardCollectionViewFlowLayout.swift
//  Trail of History
//
//  Created by Mark Flowers on 9/20/16.
//  Copyright © 2016 CLT Mobile. All rights reserved.
//

import UIKit

class CardCollectionLayout: UICollectionViewFlowLayout {
    
    override func targetContentOffsetForProposedContentOffset(proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {

        // The user has stopped scrolling the collection view. The proposed content offset tells us where the left hand side of the
        // collection view (i.e. the visible portion of the collection) will be positioned relative to the start of the collection's
        // content (the total width of the content is greater than the width of the collection view). We are being given the opportunity
        // to alter that offset.
        //
        // We are going to alter the offset such that the collection view will be centered on a cell. The cell that we will choose
        // is the one whose center would be closest to the center of the collection view were we to accept the proposed offset.

        if let collectionView = self.collectionView {

            let collectionViewBounds = collectionView.bounds
            let halfWidth = collectionViewBounds.size.width * 0.5;

            // This is the content offset that would occupy the center of the collection view were we to accept the proposed offset.
            let proposedCenterX = proposedContentOffset.x + halfWidth;
            
            if let attributesForVisibleCells = self.layoutAttributesForElementsInRect(collectionViewBounds) {

                // Find the cell that would be closest to the center of the collection view were we to accept the proposed offset.
                var target: UICollectionViewLayoutAttributes?
                for candidate in attributesForVisibleCells where candidate.representedElementCategory == UICollectionElementCategory.Cell {
                    
                    if target == nil { // First time thru
                        target = candidate;
                    }
                    else {
                        let targetDistance = target!.center.x - proposedCenterX
                        let candidateDistance = candidate.center.x - proposedCenterX

                        if fabsf(Float(candidateDistance)) < fabsf(Float(targetDistance)) {
                            target = candidate;
                        }
                    }
                }
 
                // Adjust the offset such that our target cell will be centered in the collection view.
                return CGPoint(x: round(target!.center.x - halfWidth), y: proposedContentOffset.y)
            }
        }
        
        // Fallback
        return super.targetContentOffsetForProposedContentOffset(proposedContentOffset)
    }
}
