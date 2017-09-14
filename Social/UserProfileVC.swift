//
//  UserProfileVC.swift
//  Social
//
//  Created by Trevor Lyons on 2017-08-16.
//  Copyright © 2017 Trevor Lyons. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper
import Firebase

class UserProfileVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var privacyPolicyStackView: UIStackView!
    @IBOutlet weak var profileImgStackView: UIStackView!
    @IBOutlet weak var privacyPolicyArrow: UIImageView!
    @IBOutlet weak var profileImageArrow: UIImageView!
    @IBOutlet weak var privacyPolicyText: UITextView!
    @IBOutlet weak var privacyPolicyHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var acknowledgementsArrow: UIImageView!
    @IBOutlet weak var acknowledgementsStackView: UIStackView!
    @IBOutlet weak var acknowledgementsText: UITextView!
    @IBOutlet weak var acknowledgementsHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var profilePhoto: CircleView!
    @IBOutlet weak var updateProfileImgBtn: FancyView!
    
    var imagePicker: UIImagePickerController!
    var imageSelected = false
    var textFromFile = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
        
        profileImgStackView.isHidden = false
        privacyPolicyStackView.isHidden = true
        acknowledgementsStackView.isHidden = true
        updateProfileImgBtn.isHidden = true
        
        
        
        privacyPolicyText.text = textFromFile
        if let path = Bundle.main.path(forResource: "CatChatPrivacyPolicy", ofType: "txt") {
            if let contents = try? String(contentsOfFile: path) {
                privacyPolicyText.text = contents
            }
        }
        
        acknowledgementsText.text = "Cat Chat would like to thank Firebase for it's purrrrfect databse system.\n\n Also, a big thank you to all the cats who have made this community what it is today - from tom cats to kittens to tigers to persians, we are all a happy family on Cat Chat.\n\n One love."
        
        
        getProfileImg()
    }
    
    
    // Height constraints for textviews
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        privacyPolicyHeightConstraint.constant = privacyPolicyText.contentSize.height
        acknowledgementsHeightConstraint.constant = acknowledgementsText.contentSize.height
        privacyPolicyText.layoutIfNeeded()
        acknowledgementsText.layoutIfNeeded()
    }
    
    
    // UIImagePickerController
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            profilePhoto.image = image
            imageSelected = true
            updateProfileImgBtn.isHidden = false
        } else {
            print("No image selected. Staying the same")
        }
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    
    // Assign profile image
    
    func getProfileImg() {
        let userRef = DataService.ds.REF_USER_CURRENT
        userRef.observeSingleEvent(of: .value, with: { (snapshot) in
            if let _ = snapshot.value as? NSNull {
                print("User has no assigned profile image or name")
            } else {
                if let profileImgs = snapshot.value as? [String: Any] {
                    let profileImgUrl = profileImgs["ProfileImgUrl"] as? String ?? "https://firebasestorage.googleapis.com/v0/b/social-81475.appspot.com/o/post-pics%2FB9E32155-1E86-42BC-A473-C84AD2E954AB?alt=media&token=5f77095e-7b22-46c2-938a-f78302378e2e"
                    let ref = Storage.storage().reference(forURL: profileImgUrl)
                    ref.getData(maxSize: 2 * 500 * 500, completion: { (data, error) in
                        if error != nil {
                            print("Not able to download profile image from Firebase")
                        } else {
                            if let imgData = data {
                                self.profilePhoto.image = UIImage(data: imgData)
                            }
                        }
                    })
                }
            }
        })
    }
    
    func uploadNewProfileImg() {
        let img = profilePhoto.image
        if let imgData = UIImageJPEGRepresentation(img!, 0.2) {
            let imgUid = NSUUID().uuidString
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            DataService.ds.REF_POST_IMAGES.child(imgUid).putData(imgData, metadata: metadata) { (metadata, error) in
                if error != nil {
                    print("ACCOUNT SETUP: Unable to upload image to Firebase storage")
                } else {
                    print("ACCOUNT SETUP: Successfully uploaded image to Firebase storage")
                    let downloadUrl = metadata?.downloadURL()?.absoluteString
                    if let url = downloadUrl {
                        self.postToFirebase(imgUrl: url)
                    }
                }
            }
        }
    }
    
    func postToFirebase(imgUrl: String) {
        let profileImage = imgUrl as AnyObject
        let addToUser = DataService.ds.REF_USER_CURRENT
        addToUser.child("ProfileImgUrl").setValue(profileImage)
    }
    
    
    // IBActions
    
    @IBAction func userProfileSectionPressed(_ sender: UITapGestureRecognizer) {
        if profileImgStackView.isHidden == false {
            profileImgStackView.isHidden = true
            profileImageArrow.image = UIImage(named: "down arrow")
        } else {
            profileImgStackView.isHidden = false
            profileImageArrow.image = UIImage(named: "up arrow")
        }
    }
    
    @IBAction func privacyPolicySectionPressed(_ sender: UITapGestureRecognizer) {
        if privacyPolicyStackView.isHidden == false {
            privacyPolicyStackView.isHidden = true
            privacyPolicyArrow.image = UIImage(named: "down arrow")
        } else {
            privacyPolicyStackView.isHidden = false
            privacyPolicyArrow.image = UIImage(named: "up arrow")
        }
    }
    
    @IBAction func acknowledgementsPressed(_ sender: UITapGestureRecognizer) {
        if acknowledgementsStackView.isHidden == false {
            acknowledgementsStackView.isHidden = true
            acknowledgementsArrow.image = UIImage(named: "down arrow")
        } else {
            acknowledgementsStackView.isHidden = false
            acknowledgementsArrow.image = UIImage(named: "up arrow")
        }
    }
    
    @IBAction func logoutPressed(_ sender: UITapGestureRecognizer) {
        KeychainWrapper.standard.removeObject(forKey: KEY_UID)
        try! Auth.auth().signOut()
        performSegue(withIdentifier: "unwindToSignInVC", sender: self)
    }
    
    @IBAction func changePhotoPressed(_ sender: UITapGestureRecognizer) {
        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func updateProfileImgPressed(_ sender: UITapGestureRecognizer) {
        uploadNewProfileImg()
        updateProfileImgBtn.isHidden = true
    }
}
