//
//  TextViewStyle.swift
//  Social
//
//  Created by Trevor Lyons on 2017-08-16.
//  Copyright © 2017 Trevor Lyons. All rights reserved.
//

import UIKit

class TextViewStyle: UITextView {

    override func layoutSubviews() {
        super.layoutSubviews()
        
        layer.cornerRadius = 10.0
        layer.borderWidth = 0.5
        layer.borderColor = UIColor(red: 74/255, green: 74/255, blue: 74/255, alpha: 1).cgColor
    }
}
