//
//  Post.swift
//  Social
//
//  Created by Trevor Lyons on 2017-03-29.
//  Copyright © 2017 Trevor Lyons. All rights reserved.
//

import Foundation
import Firebase

class Post {
    
    private var _caption: String!
    private var _imageUrl: String!
    private var _likes: Int!
    private var _postKey: String!
    private var _profileImg: String!
    private var _usernameLbl: String!
    private var _postRef: DatabaseReference!
    
    
    var caption: String {
        return _caption
    }
    
    var imageUrl: String {
        return _imageUrl
    }
    
    var likes: Int {
        return _likes
    }
    
    var postKey: String {
        return _postKey
    }
    
    var profileImg: String {
        return _profileImg
    }
    
    var usernameLbl: String {
        return _usernameLbl
    }

    
    
    init(caption: String, imageUrl: String, likes: Int, profileImgUrl: String, nameLbl: String) {
        self._caption = caption
        self._imageUrl = imageUrl
        self._likes = likes
        self._profileImg = profileImg
        self._usernameLbl = usernameLbl
    }
    
    init(postKey: String, postData: Dictionary<String, AnyObject>) {
        self._postKey = postKey
        
        if let caption = postData["caption"] as? String {
            self._caption = caption
        }
        
        if let imageUrl = postData["imageUrl"] as? String {
            self._imageUrl = imageUrl
        }
        
        if let likes = postData["likes"] as? Int {
            self._likes = likes
        }
        if let profileImg = postData["profileImgUrl"] as? String {
            self._profileImg = profileImg
        }
        if let usernameLbl = postData["nameLbl"] as? String {
            self._usernameLbl = usernameLbl
        }
        
        _postRef = DataService.ds.REF_POSTS.child(_postKey)
        
    }
    
    func adjustLikes(addLike: Bool) {
        if addLike {
            _likes = _likes + 1
        } else {
            _likes = _likes - 1
        }
        _postRef.child("likes").setValue(_likes)

    }
    
    func deletePost() {
        _postRef.removeValue()
    }
    

    
}






