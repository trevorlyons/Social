//
//  PostCell.swift
//  Social
//
//  Created by Trevor Lyons on 2017-03-28.
//  Copyright © 2017 Trevor Lyons. All rights reserved.
//

import UIKit
import Firebase

protocol SegueToComments {
    func segueToComments(postKey: String)
}

class PostCell: UITableViewCell, UIPopoverPresentationControllerDelegate {
    
    
    // MARK: IBOutlets
    
    @IBOutlet weak var profileImg: UIImageView!
    @IBOutlet weak var usernameLbl: UILabel!
    @IBOutlet weak var postImg: UIImageView!
    @IBOutlet weak var caption: UITextView!
    @IBOutlet weak var likesLbl: UILabel!
    @IBOutlet weak var likeImg: UIImageView!
    @IBOutlet weak var deleteBtn: UIButton!
    
    
    // MARK: Variables and Constants
    
    var post: Post!
    var likesRef: DatabaseReference!
    var myPostRef: DatabaseReference!
    var segueDelegate: SegueToComments!

    
    // MARK: awakeFromNib
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(likeTapped))
        tap.numberOfTapsRequired = 1
        likeImg.addGestureRecognizer(tap)
        likeImg.isUserInteractionEnabled = true
        
        deleteBtn.isHidden = true
    }
    
    
    // MARK: Setting data in post cell
    
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
            let ref = Storage.storage().reference(forURL: post.imageUrl)
            ref.getData(maxSize: 2 * 1024 * 1024, completion: { (data, error) in
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
            let ref = Storage.storage().reference(forURL: post.profileImg)
            ref.getData(maxSize: 2 * 500 * 500, completion: { (data, error) in
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
                self.likeImg.image = UIImage(named: "uncheckedHeart")
            } else {
                self.likeImg.image = UIImage(named: "checkedHeart")
            }
        })
        
        myPostRef.observeSingleEvent(of: .value, with: { (snapshot) in
            if let _ = snapshot.value as? NSNull {
                self.deleteBtn.isHidden = true
            } else {
                self.deleteBtn.isHidden = false
            }
        })
    }
    
    
    // MARK: IBActions
    
    func likeTapped(sender: UITapGestureRecognizer ) {
        sender.isEnabled = false
        likesRef.observeSingleEvent(of: .value, with: { (snapshot) in
            if let _ = snapshot.value as? NSNull {
                self.likeImg.image = UIImage(named: "checkedHeart")
                self.post.adjustLikes(addLike: true)
                self.likesRef.setValue(true)
            } else {
                self.likeImg.image = UIImage(named: "uncheckedHeart")
                self.post.adjustLikes(addLike: false)
                self.likesRef.removeValue()
            }
            sender.isEnabled = true
        })
    }
    
    @IBAction func deletePressed(_ sender: Any) {
        let alertController = UIAlertController(title: "", message: "Are you sure you want to delete this beautiful post meow?", preferredStyle: .alert)
        let deleteAction = UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction!) in
            self.post.deletePost()
            self.myPostRef.removeValue()
            self.likesRef.removeValue()
        })
        let cancelAction = UIAlertAction(title: "No", style: .default, handler: nil)
        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)
        
        parentViewController?.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func commentsPressed(_ sender: Any) {
        let postKey = post.postKey
        segueDelegate.segueToComments(postKey: postKey)
    }
}


extension UIView {
    var parentViewController: UIViewController? {
        var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder!.next
            if parentResponder is UIViewController {
                return parentResponder as! UIViewController!
            }
        }
        return nil
    }
}
