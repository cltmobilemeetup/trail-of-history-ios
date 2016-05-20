//
//  TrailMapOverlayView.swift
//  Trail of History
//
//  Created by Dagna Bieda on 5/20/16.
//  Copyright © 2016 CLT Mobile. All rights reserved.
//

import UIKit
import MapKit

class TrailMapOverlayView: MKOverlayRenderer {
    var overlayImage: UIImage

    init(overlay: MKOverlay, overlayImage: UIImage) {
        self.overlayImage = overlayImage
        super.init(overlay: overlay)
    }

    override func drawMapRect(mapRect: MKMapRect, zoomScale: MKZoomScale, inContext context: CGContext) {
        let imageReference = overlayImage.CGImage

        let theMapRect = overlay.boundingMapRect
        let theRect = rectForMapRect(theMapRect)

        CGContextScaleCTM(context, 1.0, -1.0)
        CGContextTranslateCTM(context, 0.0, -theRect.size.height)
        CGContextDrawImage(context, theRect, imageReference)
    }
}
