//
//  StackViewColours.swift
//  Social
//
//  Created by Trevor Lyons on 2017-08-15.
//  Copyright © 2017 Trevor Lyons. All rights reserved.
//

import UIKit

//@IBDesignable
class StackViewColours: UIStackView {

    private var color: UIColor?
    override var backgroundColor: UIColor? {
        get { return color }
        set {
            color = newValue
            self.setNeedsLayout()
        }
    }
    
    private lazy var backgroundLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        self.layer.insertSublayer(layer, at: 0)
        return layer
    }()
    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundLayer.path = UIBezierPath(rect: self.bounds).cgPath
        backgroundLayer.fillColor = self.backgroundColor?.cgColor
    }
}
