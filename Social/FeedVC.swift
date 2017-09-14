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

class FeedVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPopoverPresentationControllerDelegate, SendDataToFeedVC, SegueToComments {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var imageAdd: CircleView!
    @IBOutlet weak var mostPopularView: ShadowView!
    @IBOutlet weak var newestView: ShadowView!
    @IBOutlet weak var myPostsView: ShadowView!
    @IBOutlet weak var addPostView: UIView!
    @IBOutlet weak var userProfileView: UIView!
    @IBOutlet weak var mostPopularWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var myPostsWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var newestWidthConstraint: NSLayoutConstraint!
    
    var posts = [Post]()
    var myPosts = [Post]()
    var ImagePicker: UIImagePickerController!
    static var imageCache: NSCache<NSString, UIImage> = NSCache()
    var imageSelected = false
    var userLblRef: DatabaseReference!
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

        DataService.ds.REF_POSTS.observe(.value, with: { (snapshot) in
            self.posts = []
            if let snapshot = snapshot.children.allObjects as? [DataSnapshot] {
                if self.myPostsView.layer.shadowOpacity == 0.8 {
                    for snap in snapshot {
                        if let postDict = snap.value as? Dictionary<String, AnyObject> {
                            let nameLbl = postDict["nameLbl"] as? String ?? "n/a"
                            if nameLbl == self.userLbl {
                                let key = snap.key
                                let post = Post(postKey: key, postData: postDict)
                                self.posts.append(post)
                            }
                        }
                    }
                } else {
                    for snap in snapshot {
                        if let postDict = snap.value as? Dictionary<String, AnyObject> {
                            let key = snap.key
                            let post = Post(postKey: key, postData: postDict)
                            self.posts.append(post)
                        }
                    }
                }
            }
            if self.newestView.layer.shadowOpacity == 0.8 {
                self.posts.reverse()
                self.tableView.reloadData()
            } else if self.mostPopularView.layer.shadowOpacity == 0.8 {
                self.posts.sort() { ($0.likes) > ($1.likes) }
                self.tableView.reloadData()
            } else if self.myPostsView.layer.shadowOpacity == 0.8 {
                self.posts.reverse()
                self.tableView.reloadData()
            }
        })
        
        let screenWidth = UIScreen.main.bounds.width
        mostPopularWidthConstraint.constant = screenWidth / 3.05
        myPostsWidthConstraint.constant = screenWidth / 3.05
        newestWidthConstraint.constant = screenWidth / 3.05
    }
    
    
    // Delegate function - Send caption data for add post
    
    func postToFirebaseFromAddPostVC(caption: String) {
        captionFromAddPostVC = caption
    }
    
    
    // Delegate function - Perform segue from cell
    
    func segueToComments(postKey: String) {
        performSegue(withIdentifier: "toComments", sender: postKey)
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
        if let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell") as? PostCell {
            cell.segueDelegate = self
            cell.postImg.image = UIImage(named: "")
            cell.profileImg.image = UIImage(named: "")
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
        } else {
            return UITableViewAutomaticDimension
        }
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if posts[indexPath.row].caption == "" {
            return 370
        } else {
            return UITableViewAutomaticDimension
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
            
            let firebasePost = DataService.ds.REF_POSTS.childByAutoId()
            firebasePost.setValue(post)
            
            let addPostToUser = DataService.ds.REF_USER_CURRENT.child("posts").child(firebasePost.key)
            addPostToUser.setValue(true)
        })
        tableView.reloadData()
    }
    
    
    // Segue functions
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let screenSize = UIScreen.main.bounds
        let screenWidth = screenSize.width
        let screenHeight = screenSize.height
        if let controller = segue.destination as? addPostVC {
            controller.preferredContentSize = CGSize(width: screenWidth * 0.95, height: 400)
            controller.sendDataDelegate = self
            let popoverController = controller.popoverPresentationController
            if popoverController != nil {
                popoverController!.delegate = self
                popoverController!.sourceView = addPostView
                popoverController!.sourceRect = addPostView.bounds
            }
        } else if let controller = segue.destination as? UserProfileVC {
            controller.preferredContentSize = CGSize(width: screenWidth * 0.95, height: 400)
            let popoverController = controller.popoverPresentationController
            if popoverController != nil {
                popoverController!.delegate = self
                popoverController!.sourceView = userProfileView
                popoverController!.sourceRect = userProfileView.bounds
            }
        } else if let controller = segue.destination as? CommentsVC {
            controller.preferredContentSize = CGSize(width: screenWidth * 0.85, height: screenHeight * 0.85)
            if let x = sender {
                controller.postKey = x as! String
            }
            let popoverController = controller.popoverPresentationController
            if popoverController != nil {
                popoverController!.delegate = self
                popoverController!.sourceView = self.view
                popoverController!.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
                popoverController!.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
            }
        }
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
    
    
    // IBActions
    
    @IBAction func mostPopularSortPressed(_ sender: UITapGestureRecognizer) {
        if posts.count != 0 {
            tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
        }
        mostPopularView.backgroundColor = UIColor(red: 200/255, green: 137/255, blue: 123/255, alpha: 1)
        mostPopularView.layer.shadowOpacity = 0.8
        newestView.backgroundColor = UIColor(red: 144/255, green: 202/255, blue: 175/255, alpha: 1)
        newestView.layer.shadowOpacity = 0.0
        myPostsView.backgroundColor = UIColor(red: 144/255, green: 202/255, blue: 175/255, alpha: 1)
        myPostsView.layer.shadowOpacity = 0.0
        
        DataService.ds.REF_POSTS.observeSingleEvent(of: .value, with: { (snapshot) in
            self.posts = []
            if let snapshot = snapshot.children.allObjects as? [DataSnapshot] {
                for snap in snapshot {
                    if let postDict = snap.value as? [String: AnyObject] {
                        let key = snap.key
                        let post = Post(postKey: key, postData: postDict)
                        self.posts.append(post)
                    }
                }
            }
            self.posts.sort() { ($0.likes) > ($1.likes) }
            self.tableView.reloadData()
        })
    }

    @IBAction func newestSortPressed(_ sender: UITapGestureRecognizer) {
        if posts.count != 0 {
            tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
        }
        newestView.backgroundColor = UIColor(red: 200/255, green: 137/255, blue: 123/255, alpha: 1)
        newestView.layer.shadowOpacity = 0.8
        mostPopularView.backgroundColor = UIColor(red: 144/255, green: 202/255, blue: 175/255, alpha: 1)
        mostPopularView.layer.shadowOpacity = 0.0
        myPostsView.backgroundColor = UIColor(red: 144/255, green: 202/255, blue: 175/255, alpha: 1)
        myPostsView.layer.shadowOpacity = 0.0
        
        DataService.ds.REF_POSTS.observeSingleEvent(of: .value, with: { (snapshot) in
            self.posts = []
            if let snapshot = snapshot.children.allObjects as? [DataSnapshot] {
                for snap in snapshot {
                    if let postDict = snap.value as? [String: AnyObject] {
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

    @IBAction func myPostsSortPressed(_ sender: UITapGestureRecognizer) {
        if posts.count != 0 {
            tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
        }
        myPostsView.backgroundColor = UIColor(red: 200/255, green: 137/255, blue: 123/255, alpha: 1)
        myPostsView.layer.shadowOpacity = 0.8
        newestView.backgroundColor = UIColor(red: 144/255, green: 202/255, blue: 175/255, alpha: 1)
        newestView.layer.shadowOpacity = 0.0
        mostPopularView.backgroundColor = UIColor(red: 144/255, green: 202/255, blue: 175/255, alpha: 1)
        mostPopularView.layer.shadowOpacity = 0.0
        
        DataService.ds.REF_USER_CURRENT.observeSingleEvent(of: .value, with: { (snapshot) in
            if let userDict = snapshot.value as? [String: Any] {
                self.userLbl = userDict["Username"] as! String
            }
            DataService.ds.REF_POSTS.observeSingleEvent(of: .value, with: { (snapshot) in
                self.posts = []
                if let snapshot = snapshot.children.allObjects as? [DataSnapshot] {
                    for snap in snapshot {
                        if let postDict = snap.value as? Dictionary<String, AnyObject> {
                            let nameLbl = postDict["nameLbl"] as? String ?? "n/a"
                            if nameLbl == self.userLbl {
                                let key = snap.key
                                let post = Post(postKey: key, postData: postDict)
                                self.posts.append(post)
                            }
                        }
                    }
                }
                self.posts.reverse()
                self.tableView.reloadData()
            })
        })
    }
    
    @IBAction func addPostPressed(_ sender: UITapGestureRecognizer) {
        performSegue(withIdentifier: "showAddPost", sender: self)
    }
    
    @IBAction func userProfilePressed(_ sender: UITapGestureRecognizer) {
        performSegue(withIdentifier: "showUserProfile", sender: self)
    }
}










