//
//  PostCell.swift
//  Social
//
//  Created by Trevor Lyons on 2017-03-28.
//  Copyright © 2017 Trevor Lyons. All rights reserved.
//

import UIKit
import Firebase

class PostCell: UITableViewCell {
    
    @IBOutlet weak var profileImg: UIImageView!
    @IBOutlet weak var usernameLbl: UILabel!
    @IBOutlet weak var postImg: UIImageView!
    @IBOutlet weak var caption: UITextView!
    @IBOutlet weak var likesLbl: UILabel!
    @IBOutlet weak var likeImg: UIImageView!
    @IBOutlet weak var deleteBtn: UIButton!
    
    var post: Post!
    var likesRef: FIRDatabaseReference!
    var myPostRef: FIRDatabaseReference!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(likeTapped))
        tap.numberOfTapsRequired = 1
        likeImg.addGestureRecognizer(tap)
        likeImg.isUserInteractionEnabled = true
        
        deleteBtn.isHidden = true
        
    }
    // Setting data in post cell
    func configureCell(post: Post, img: UIImage? = nil, img2: UIImage? = nil) {
        self.post = post
        likesRef = DataService.ds.REF_USER_CURRENT.child("likes").child(post.postKey)
        myPostRef = DataService.ds.REF_USER_CURRENT.child("posts").child(post.postKey)

        self.caption.text = post.caption
        self.likesLbl.text = "\(post.likes)"
        self.usernameLbl.text = post.usernameLbl

        if img != nil {
            self.postImg.image = img
        } else {
            let ref = FIRStorage.storage().reference(forURL: post.imageUrl)
            ref.data(withMaxSize: 2 * 1024 * 1024, completion: { (data, error) in
                if error != nil {
                    print("TREVOR: Unable to download image from Firebase storage")
                } else {
                    print("TREVOR: Image downloaded from Firebase storage")
                    if let imgData = data {
                        if let img = UIImage(data: imgData) {
                            self.postImg.image = img
                            FeedVC.imageCache.setObject(img, forKey: post.imageUrl as NSString)
                        }
                    }
                }
            })
        }
        if img2 != nil {
            self.profileImg.image = img2
        } else {
            let ref = FIRStorage.storage().reference(forURL: post.profileImg)
            ref.data(withMaxSize: 2 * 1024 * 1024, completion: { (data, error) in
                if error != nil {
                    print("TREVOR: Unable to download image from Firebase storage")
                } else {
                    print("TREVOR: Image downloaded from Firebase storage")
                    if let imgData = data {
                        if let img2 = UIImage(data: imgData) {
                            self.profileImg.image = img2
                            FeedVC.imageCache.setObject(img2, forKey: post.profileImg as NSString)
                        }
                    }
                }
            })
        }
        
        

        likesRef.observeSingleEvent(of: .value, with: { (snapshot) in
            if let _ = snapshot.value as? NSNull {
                self.likeImg.image = UIImage(named: "empty-heart")
            } else {
                self.likeImg.image = UIImage(named: "filled-heart")
            }
        })
        
        // Create single event type to observe if post is by the user. If it is, show option to delete post
        myPostRef.observeSingleEvent(of: .value, with: { (snapshot) in
            if let _ = snapshot.value as? NSNull {
                self.deleteBtn.isHidden = true
            } else {
                self.deleteBtn.isHidden = false
                
            }
        })
        
    }
    

    
    func likeTapped(sender: UITapGestureRecognizer ) {
        sender.isEnabled = false
        likesRef.observeSingleEvent(of: .value, with: { (snapshot) in
            if let _ = snapshot.value as? NSNull {
                self.likeImg.image = UIImage(named: "filled-heart")
                self.post.adjustLikes(addLike: true)
                self.likesRef.setValue(true)
            } else {
                self.likeImg.image = UIImage(named: "empty-heart")
                self.post.adjustLikes(addLike: false)
                self.likesRef.removeValue()
            }
            sender.isEnabled = true
        })
        
    }
    
    @IBAction func deletePressed(_ sender: Any) {
        self.post.deletePost()
        self.myPostRef.removeValue()
        self.likesRef.removeValue()
        
    }



}
