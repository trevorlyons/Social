//
//  CommentCell.swift
//  Social
//
//  Created by Trevor Lyons on 2017-09-04.
//  Copyright © 2017 Trevor Lyons. All rights reserved.
//

import UIKit

class CommentCell: UITableViewCell {

    @IBOutlet weak var commentText: UITextView!
    @IBOutlet weak var nameLbl: UILabel!
    @IBOutlet weak var dateLbl: UILabel!
    
    var comment: Comment!
    
    override func awakeFromNib() {
        super.awakeFromNib()

    }
    
    func configureCell(comment: Comment) {
        self.comment = comment
        self.commentText.text = comment.comment
        self.nameLbl.text = comment.userName
        self.dateLbl.text = comment.date
    }
}
