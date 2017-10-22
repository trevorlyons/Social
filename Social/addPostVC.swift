//
//  addPostVC.swift
//  Social
//
//  Created by Trevor Lyons on 2017-08-15.
//  Copyright © 2017 Trevor Lyons. All rights reserved.
//

import UIKit
import Firebase

protocol SendDataToFeedVC {
    func postToFirebaseFromAddPostVC(caption: String)
    func postToFirebase(imgUrl: String)
}

class addPostVC: UIViewController, UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    
    // MARK: IBOutlets
    
    @IBOutlet weak var textField: UITextView!
    @IBOutlet weak var characterCountLbl: UILabel!
    @IBOutlet weak var imageAdd: RoundedCnrImg!
    @IBOutlet weak var selectPhotoWarningLbl: UILabel!
    
    
    // MARK: Variables and Constants
    
    var imagePicker: UIImagePickerController!
    var imageSelected = false
    var caption: String!
    var imageUrl: String!
    var sendDataDelegate: SendDataToFeedVC!
    
    
    // MARK: viewDidLoad
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
        
        textField.delegate = self
        textField.text = "comment here..."
        textField.textColor = UIColor.lightGray
        textField.autocorrectionType = .no
        
        selectPhotoWarningLbl.isHidden = true
    }
    
    
    // MARK: ImagePicker functions
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            imageAdd.image = image
            imageSelected = true
            selectPhotoWarningLbl.isHidden = true
        } else {
            print("TREVOR: A valid image was not selected")
        }
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    
    // MARK: TextField fuctions
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = UIColor(red: 74/255, green: 74/255, blue: 74/255, alpha: 1)
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "comment here..."
            textView.textColor = UIColor.lightGray
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)
        let numberOfChars = newText.characters.count
        characterCountLbl.text = "\(numberOfChars)"
        return numberOfChars < 140
    }
    
    
    // MARK: IBActions
    
    @IBAction func addPhotoPressed(_ sender: UITapGestureRecognizer) {
        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func addPostPressed(_ sender: UITapGestureRecognizer) {
        if textField.text == "comment here..." {
            textField.text = ""
        }
        let caption = textField.text

        guard let img = imageAdd.image, imageSelected == true else {
            print("TREVOR: An image must be selected")
            selectPhotoWarningLbl.isHidden = false
            return
        }
        sendDataDelegate?.postToFirebaseFromAddPostVC(caption: caption!)
        if let imgData = UIImageJPEGRepresentation(img, 0.2) {
            let imgUid = NSUUID().uuidString // creating a random id for upload images
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            DataService.ds.REF_POST_IMAGES.child(imgUid).putData(imgData, metadata: metadata) { (metadata, error) in
                if error != nil {
                    print("TREVOR: Unable to upload image to Firebase storage")
                } else {
                    print("TREVOR: Successfully uploaded image to Firebase storage")
                    let downloadUrl = metadata?.downloadURL()?.absoluteString
                    if let url = downloadUrl {
                        self.sendDataDelegate.postToFirebase(imgUrl: url)
                    }
                }
            }
        }
        dismiss(animated: true, completion: nil)
    }
}
