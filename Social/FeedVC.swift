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

class FeedVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPopoverPresentationControllerDelegate, SendDataToFeedVC {
    
    @IBOutlet weak var captionField: FancyField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var imageAdd: CircleView!
    @IBOutlet weak var mostPopularView: ShadowView!
    @IBOutlet weak var newestView: UIView!
    @IBOutlet weak var myPostsView: UIView!
    @IBOutlet weak var addPostView: UIView!
    @IBOutlet weak var userProfileView: UIView!
    
    var posts = [Post]()
    var ImagePicker: UIImagePickerController!
    static var imageCache: NSCache<NSString, UIImage> = NSCache()
    var imageSelected = false
    var userLblRef: FIRDatabaseReference!
    var userLbl: String!
    var profilePic: String!
    var captionFromAddPostVC: String!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        ImagePicker = UIImagePickerController()
        ImagePicker.allowsEditing = true
        ImagePicker.delegate = self

        // Listner on database for new posts
        DataService.ds.REF_POSTS.observe(.value, with: { (snapshot) in
            self.posts = []
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
    
    
    // Delegate function - Send caption data for add post
    
    func postToFirebaseFromAddPostVC(caption: String) {
        captionFromAddPostVC = caption
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
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if posts[indexPath.row].caption == "" {
            return 370
        } else if posts[indexPath.row].caption.characters.count < 60 {
            return 406
        } else if posts[indexPath.row].caption.characters.count >= 50 && posts[indexPath.row].caption.characters.count <= 100 {
            return 425
        } else {
            return 444
        }
    }
    
    
    // ImagePicker functions
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            imageAdd.image = image
            imageSelected = true
        } else {
            print("TREVOR: A valid image was not selected")
        }
        ImagePicker.dismiss(animated: true, completion: nil)
    }
    
    
    // Firebase functions

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
                "caption": self.captionFromAddPostVC as AnyObject,
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
        tableView.reloadData()
    }
    
    
    // Segue functions
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let screenSize = UIScreen.main.bounds
        let screenWidth = screenSize.width
        if let controller = segue.destination as? addPostVC {
            controller.preferredContentSize = CGSize(width: screenWidth * 0.95, height: 400)
            controller.sendDataDelegate = self
            let popoverController = controller.popoverPresentationController
            if popoverController != nil {
                popoverController!.delegate = self
                popoverController!.sourceView = addPostView
                popoverController!.sourceRect = addPostView.bounds
            }
        }
        if let controller = segue.destination as? UserProfileVC {
            controller.preferredContentSize = CGSize(width: screenWidth * 0.95, height: 400)
            let popoverController = controller.popoverPresentationController
            if popoverController != nil {
                popoverController!.delegate = self
                popoverController!.sourceView = userProfileView
                popoverController!.sourceRect = userProfileView.bounds
            }
        }
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
    
    
    // IBActions
    
    @IBAction func signOutTapped(_ sender: Any) {
        KeychainWrapper.standard.removeObject(forKey: KEY_UID)
        try! FIRAuth.auth()?.signOut()
        performSegue(withIdentifier: "goToSignIn", sender: nil)
    }
    
    @IBAction func mostPopularSortPressed(_ sender: UITapGestureRecognizer) {
        mostPopularView.backgroundColor = UIColor(red: 200/255, green: 137/255, blue: 123/255, alpha: 1)
        
        newestView.backgroundColor = UIColor(red: 144/255, green: 202/255, blue: 175/255, alpha: 1)
        myPostsView.backgroundColor = UIColor(red: 144/255, green: 202/255, blue: 175/255, alpha: 1)
        
        posts.sort() { ($0.likes) > ($1.likes) }
        tableView.reloadData()
    }

    @IBAction func newestSortPressed(_ sender: UITapGestureRecognizer) {
        newestView.backgroundColor = UIColor(red: 200/255, green: 137/255, blue: 123/255, alpha: 1)
        
        mostPopularView.backgroundColor = UIColor(red: 144/255, green: 202/255, blue: 175/255, alpha: 1)
        myPostsView.backgroundColor = UIColor(red: 144/255, green: 202/255, blue: 175/255, alpha: 1)
        
        tableView.reloadData()
    }

    @IBAction func myPostsSortPressed(_ sender: UITapGestureRecognizer) {
        myPostsView.backgroundColor = UIColor(red: 200/255, green: 137/255, blue: 123/255, alpha: 1)
        
        newestView.backgroundColor = UIColor(red: 144/255, green: 202/255, blue: 175/255, alpha: 1)
        mostPopularView.backgroundColor = UIColor(red: 144/255, green: 202/255, blue: 175/255, alpha: 1)
    }
    
    @IBAction func addPostPressed(_ sender: UITapGestureRecognizer) {
        performSegue(withIdentifier: "showAddPost", sender: self)
    }
    
    @IBAction func userProfilePressed(_ sender: UITapGestureRecognizer) {
        performSegue(withIdentifier: "showUserProfile", sender: self)
    }
}










