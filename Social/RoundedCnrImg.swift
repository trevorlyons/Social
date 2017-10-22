//
//  RoundedCnrImg.swift
//  Social
//
//  Created by Trevor Lyons on 2017-08-16.
//  Copyright © 2017 Trevor Lyons. All rights reserved.
//

import UIKit

class RoundedCnrImg: UIImageView {

    override func layoutSubviews() {
        super.layoutSubviews()
        
        layer.cornerRadius = 10.0
    }

}
