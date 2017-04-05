//
//  FeedVC.swift
//  Social
//
//  Created by Trevor Lyons on 2017-03-28.
//  Copyright © 2017 Trevor Lyons. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper
import Firebase

class FeedVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var captionField: FancyField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var imageAdd: CircleView!
    
    var posts = [Post]()
    var ImagePicker: UIImagePickerController!
    static var imageCache: NSCache<NSString, UIImage> = NSCache()
    var imageSelected = false
    var userLblRef: FIRDatabaseReference!
    var userLbl: String!
    var profilePic: String!
    var captionSend: String!

    


    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        ImagePicker = UIImagePickerController()
        ImagePicker.allowsEditing = true
        ImagePicker.delegate = self

        
        DataService.ds.REF_POSTS.observe(.value, with: { (snapshot) in
            
            // resets posts array to nil so that posts are not repeated
            self.posts = []
            
            // loop over all objects in database and add to posts array
            if let snapshot = snapshot.children.allObjects as? [FIRDataSnapshot] {
                for snap in snapshot {
                    print("SNAP: \(snap)")
                    if let postDict = snap.value as? Dictionary<String, AnyObject> {
                        let key = snap.key
                        let post = Post(postKey: key, postData: postDict)
                        self.posts.append(post)
                    }
                }
            }
            
            self.posts.reverse()
            self.tableView.reloadData()
        })

    }
    
    // TableView functions
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let post = posts[indexPath.row]
        
        // dequeue cell for cached or download new image
        if let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell") as? PostCell {
            
            if let img = FeedVC.imageCache.object(forKey: post.imageUrl as NSString), let img2 = FeedVC.imageCache.object(forKey: post.profileImg as NSString) {
                cell.configureCell(post: post, img: img, img2: img2)
                return cell
            } else {
                cell.configureCell(post: post)
                return cell
            }

        } else {
            return PostCell()
        }
    }
    
    // Once image is selected, dismiss image picker
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            imageAdd.image = image
            imageSelected = true
        } else {
            print("TREVOR: A valid image was not selected")
        }
        
        ImagePicker.dismiss(animated: true, completion: nil)
    }

    // Signout button functionality
    @IBAction func signOutTapped(_ sender: Any) {
        KeychainWrapper.standard.removeObject(forKey: KEY_UID)
        try! FIRAuth.auth()?.signOut()
        performSegue(withIdentifier: "goToSignIn", sender: nil)
    }
    
    // Add image button functionality
    @IBAction func addImageTapped(_ sender: Any) {
        present(ImagePicker, animated: true, completion: nil)
    }
    
    // New Post button functionality
    @IBAction func postBtnTapped(_ sender: Any) {
        guard let caption = captionField.text, caption != "" else {
            print("TREVOR: Caption must be entered")
            return
        }
        guard let img = imageAdd.image, imageSelected == true else {
            print("TREVOR: An image must be selected")
            return
        }
        captionSend = captionField.text
        
        // compression of images uploaded
        if let imgData = UIImageJPEGRepresentation(img, 0.2) {
            
            let imgUid = NSUUID().uuidString // creating a random id for upload images
            let metadata = FIRStorageMetadata()
            metadata.contentType = "image/jpeg"
            
            DataService.ds.REF_POST_IMAGES.child(imgUid).put(imgData, metadata: metadata) { (metadata, error) in
                if error != nil {
                    print("TREVOR: Unable to upload image to Firebase storage")
                } else {
                    print("TREVOR: Successfully uploaded image to Firebase storage")
                    let downloadUrl = metadata?.downloadURL()?.absoluteString
                    if let url = downloadUrl {
                        self.postToFirebase(imgUrl: url)
                        

                    }
                    
                }
                
                
            }
        }
    }
    
    func postToFirebase(imgUrl: String) {
        
        userLblRef = DataService.ds.REF_USER_CURRENT
        userLblRef.observeSingleEvent(of: .value, with: { (snapshot) in
            if let _ = snapshot.value as? NSNull {
                print("TREVOR: User magically has no profileImg or nameLbl :/")
            } else {
                if let userDict = snapshot.value as? [String: Any] {
                    self.userLbl = userDict["Username"] as! String
                }
                if let profilePics = snapshot.value as? [String: Any] {
                    self.profilePic = profilePics["ProfileImgUrl"] as! String
                }
            }
            let post: Dictionary<String, AnyObject> = [
                "caption": self.captionSend as AnyObject,
                "imageUrl": imgUrl as AnyObject,
                "likes": 0 as AnyObject,
                "profileImgUrl": self.profilePic as AnyObject,
                "nameLbl": self.userLbl as AnyObject
            ]
            
            // Posting dictionary of new post under an AutoId
            let firebasePost = DataService.ds.REF_POSTS.childByAutoId()
            firebasePost.setValue(post)
            
            
            // Adding the post AutoId to the user for ownership of post
            let addPostToUser = DataService.ds.REF_USER_CURRENT.child("posts").child(firebasePost.key)
            addPostToUser.setValue(true)
        })

        // Resetting post fields
        self.captionField.text = ""
        self.imageSelected = false
        self.imageAdd.image = UIImage(named: "add-image")

        tableView.reloadData()
    }
    

}










