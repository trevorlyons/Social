//
//  CommentsVC.swift
//  Social
//
//  Created by Trevor Lyons on 2017-04-05.
//  Copyright © 2017 Trevor Lyons. All rights reserved.
//

import UIKit
import Firebase

class CommentsVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var textBox: TextViewStyle!
    @IBOutlet weak var textCount: UILabel!
    @IBOutlet weak var addCommentStack: UIStackView!
    @IBOutlet weak var addBtn: UIImageView!
    
    var userName: String!
    var postKey: String!
    var comments = [Comment]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        
        textBox.delegate = self
        textBox.text = "comment here..."
        textBox.textColor = UIColor.lightGray
        textBox.autocorrectionType = .no
        
        addCommentStack.isHidden = true
        
        DataService.ds.REF_COMMENTS.observe(.value, with: { (snapshot) in
            self.comments = []
            if let snapshot = snapshot.children.allObjects as? [DataSnapshot] {
                for snap in snapshot {
                    if let commentDict = snap.value as? [String: AnyObject] {
                        let searchPostKey = commentDict["postKey"] as? String ?? "n/a"
                        if searchPostKey == self.postKey {
                            let key = snap.key
                            let comment = Comment(commentKey: key, commentData: commentDict)
                            self.comments.append(comment)
                        }
                    }
                }
            }
            self.tableView.reloadData()
        })
    }
    
    
    // TextBox functions
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textBox.textColor == UIColor.lightGray {
            textBox.text = nil
            textBox.textColor = UIColor(red: 74/255, green: 74/255, blue: 74/255, alpha: 1)
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textBox.text.isEmpty {
            textBox.text = "comment here..."
            textBox.textColor = UIColor.lightGray
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let newText = (textBox.text as NSString).replacingCharacters(in: range, with: text)
        let numberOfChars = newText.characters.count
        textCount.text = "\(numberOfChars)"
        return numberOfChars < 140
    }
    
    
    // TableView
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell") as? CommentCell {
            cell.configureCell(comment: comments[indexPath.row])
            return cell
        } else {
            return CommentCell()
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    
    // Post to Firebase
    
    func postCommentToFirebase() {
        let commentSend = textBox.text
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        let result = formatter.string(from: date)
        let userRef = DataService.ds.REF_USER_CURRENT
        userRef.observeSingleEvent(of: .value, with: { (snapshot) in
            if let _ = snapshot.value as? NSNull {
                print("no username or profileimg")
            } else {
                if let userDict = snapshot.value as? [String: Any] {
                    self.userName = userDict["Username"] as! String
                }
            }
            let comment: [String : AnyObject] = [
            "postKey": self.postKey as AnyObject,
            "comment": commentSend as AnyObject,
            "userName": self.userName as AnyObject,
            "date": result as AnyObject
            ]
            
            let firebasePost = DataService.ds.REF_COMMENTS.childByAutoId()
            firebasePost.setValue(comment)
            
            let addCommentToUser = DataService.ds.REF_USER_CURRENT.child("comments").child(firebasePost.key)
            addCommentToUser.setValue(true)
            
            let addCommentToPost = DataService.ds.REF_POSTS.child(self.postKey).child("comments").child(firebasePost.key)
            addCommentToPost.setValue(true)
        })
    }
    
    
    // Scroll timer function
    
    func scrollToBottom() {
        if comments.count <= 1 {
            
        } else  {
            tableView.scrollToRow(at: IndexPath(row: (comments.count - 1), section: 0), at: .bottom, animated: true)
        }
    }
    

    // IBActions
    
    @IBAction func releaseToFeedVC(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func addCommentPressed(_ sender: UITapGestureRecognizer) {
        if addCommentStack.isHidden == true {
            addCommentStack.isHidden = false
            addBtn.image = UIImage(named: "down arrow")
        } else {
            addCommentStack.isHidden = true
            addBtn.image = UIImage(named: "add button")
            textBox.endEditing(true)
        }
    }

    @IBAction func postCommentPressed(_ sender: UITapGestureRecognizer) {
        if textBox.text == "comment here..." {
            textBox.text = ""
        }
        guard let noComment = textBox.text, noComment != "" else {
            print("you need a comment to comment silly cat!")
            return
        }
        postCommentToFirebase()
        addCommentStack.isHidden = true
        addBtn.image = UIImage(named: "add button")
        textBox.text = ""
        textBox.endEditing(true)
        Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(scrollToBottom), userInfo: nil, repeats: false)
    }
}
