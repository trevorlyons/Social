//
//  Comment.swift
//  Social
//
//  Created by Trevor Lyons on 2017-09-04.
//  Copyright © 2017 Trevor Lyons. All rights reserved.
//

import Foundation
import Firebase

class Comment {
    
    let comment: String!
    let userName: String!
    let date: String!
    let postKey: String!
    let commentKey: String!
    let commentRef: DatabaseReference!
    
    init(commentKey: String, commentData: [String : AnyObject]) {
        self.commentKey = commentKey
        self.postKey = commentData["postKey"] as? String ?? "n/a"
        self.comment = commentData["comment"] as? String ?? "n/a"
        self.userName = commentData["userName"] as? String ?? "n/a"
        self.date = commentData["date"] as? String ?? "n/a"
        self.commentRef = DataService.ds.REF_COMMENTS.child(self.commentKey)
    }
    
}
