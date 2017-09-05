//
//  AccountSetupVC.swift
//  Social
//
//  Created by Trevor Lyons on 2017-04-02.
//  Copyright © 2017 Trevor Lyons. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper
import Firebase

class AccountSetupVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var userName: UITextField!
    @IBOutlet weak var profileImg: CircleView!
    
    var imagePicker: UIImagePickerController!
    var imageSelected = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            profileImg.image = image
            imageSelected = true
        } else {
            print("ACCOUNT SETUP: You need to select an image") // Use hidden label to appear to warn user to attach an image
        }
        imagePicker.dismiss(animated: true, completion: nil)
    }


    @IBAction func camaraBtnPressed(_ sender: UITapGestureRecognizer) {
        present(imagePicker, animated: true, completion: nil)
    }

    @IBAction func loginBtnPressed(_ sender: UITapGestureRecognizer) {
        guard let user = userName.text, user != "" else {
            print("ACCOUNT SETUP: User name must be entered")
            return
        }
        guard let img = profileImg.image, imageSelected == true else {
            print("ACCOUNT SETUP: An image must be selected")
            return
        }
        if let imgData = UIImageJPEGRepresentation(img, 0.2) {
            let imgUid = NSUUID().uuidString // creating a random id for upload images
            let metadata = FIRStorageMetadata()
            metadata.contentType = "image/jpeg"
            
            DataService.ds.REF_POST_IMAGES.child(imgUid).put(imgData, metadata: metadata) { (metadata, error) in
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
        performSegue(withIdentifier: "AccountToFeed", sender: nil)
    }
    
    func postToFirebase(imgUrl: String) {
        let profileUserName = userName.text! as AnyObject
        let profileImage = imgUrl as AnyObject
        
        let addToUser = DataService.ds.REF_USER_CURRENT
        addToUser.child("Username").setValue(profileUserName)
        addToUser.child("ProfileImgUrl").setValue(profileImage)
    }
}
