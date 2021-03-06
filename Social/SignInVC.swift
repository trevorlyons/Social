//
//  ViewController.swift
//  Social
//
//  Created by Trevor Lyons on 2017-03-27.
//  Copyright © 2017 Trevor Lyons. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit
import Firebase
import SwiftKeychainWrapper

class SignInVC: UIViewController, UIPopoverPresentationControllerDelegate, SignInProtocol {

    
    // MARK: IBOutlets
    
    @IBOutlet weak var test: UIImageView!
    @IBOutlet weak var EmailBtn: CircleView!

    
    // MARK: Variables and Constants
    
    var dict: [String: Any]!
    var username: String!
    var profileUrl: String!
    
    
    // MARK: viewDidLoad
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        test.isHidden = true
        }
    
    
    // MARK: viewDidAppear
    
    override func viewDidAppear(_ animated: Bool) {
        
        // checking if the id key has already been made so that signin is automatic if already signed up
        if let _ = KeychainWrapper.standard.string(forKey: KEY_UID) {
            performSegue(withIdentifier: "goToFeed", sender: nil)
        }
    }
    
    
    // MARK: Segue functions
    
    func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool {
        return false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? EmailSignInVC {
            controller.preferredContentSize = CGSize(width: 300, height: 300)
            controller.signInDelegate = self
            let popoverController = controller.popoverPresentationController
            if popoverController != nil {
                popoverController!.delegate = self
                popoverController!.sourceView = self.view
                popoverController!.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
                popoverController!.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
            }
        }
        if let controller = segue.destination as? AccountSetupVC {
            controller.preferredContentSize = CGSize(width: 300, height: 330)
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
    
    
    // MARK: Facebook Login functions

    func firebaseAuth(_ credential: AuthCredential) {
        Auth.auth().signIn(with: credential, completion: { (user, error) in
            if error != nil {
                print("TREVOR: Unable to authenticate with Firebase - \(String(describing: error))")
            } else {
                print("TREVOR: Successfully authenticated with Firebase")
                if let user = user {
                    let userData = ["provider": credential.provider]
                    self.completeSignIn(id: user.uid, userData: userData)
                    self.getFBUserData()
                }
            }
        })
        
    }
    
    func getFBUserData(){
        if((FBSDKAccessToken.current()) != nil){
            FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "id, name, first_name, last_name, picture.type(large), email"]).start(completionHandler: { (connection, result, error) -> Void in
                if (error == nil){
                    if let fbDict = result as? [String : Any] {
                        self.username = fbDict["name"] as! String
                    }
                    if let dict = result as? [String: Any] {
                        if let picture = dict["picture"] as? [String: Any] {
                            if let data = picture["data"] as? [String: Any] {
                                self.profileUrl = data["url"] as! String
                            }
                        }
                    }
                    print("TREVOR: Facebook user dictionary - \(result!)")
                    DataService.ds.REF_USER_CURRENT.child("Username").setValue(self.username!)
                    self.downloadFacebookProfileImg()
                }
            })
        }
    }
    
    func downloadFacebookProfileImg() {
        let url = URL(string: self.profileUrl)!
        DispatchQueue.global().async {
            do {
                let data = try Data(contentsOf: url)
                DispatchQueue.global().sync {
                    self.test.image = UIImage(data: data)
                    self.uploadFacebookProfileImgFirebase()
                }
            } catch  {
                
            }
        }
    }
    
    func uploadFacebookProfileImgFirebase() {
        let img = self.test.image
        if let imgData = UIImageJPEGRepresentation(img!, 0.2) {
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
                        self.postToFirebase(imgUrl: url)
                    }
                }
            }
        }
    }
    
    func postToFirebase(imgUrl: String) {
        let profileImage = imgUrl as AnyObject
        DataService.ds.REF_USER_CURRENT.child("ProfileImgUrl").setValue(profileImage)
    }
    
    
    // MARK: function to not repeat keychain code
    
    func completeSignIn(id: String, userData: Dictionary<String, String>) {
        DataService.ds.createFirebaseDBUser(uid: id, userData: userData)
        let keychainReuslt = KeychainWrapper.standard.set(id, forKey: KEY_UID)
        print("TREVOR: Data saved to Keychain \(keychainReuslt)")
        performSegue(withIdentifier: "goToFeed", sender: nil)
    }
    
    
    func completeSignInNew(id: String, userData: Dictionary<String, String>) {
        DataService.ds.createFirebaseDBUser(uid: id, userData: userData)
        let keychainReuslt = KeychainWrapper.standard.set(id, forKey: KEY_UID)
        print("TREVOR: Data saved to Keychain \(keychainReuslt)")
        dismiss(animated: true, completion: nil)
        performSegue(withIdentifier: "goToAccountSetup", sender: nil)
    }
    
    
    // MARK: IBActions
    
    @IBAction func unwindToSignInVC(segue: UIStoryboardSegue) {}
    
    @IBAction func emailViewTapped(_ sender: UITapGestureRecognizer) {
        performSegue(withIdentifier: "emailLogin", sender: self)
    }
    
    @IBAction func facebookViewTapped(_ sender: UITapGestureRecognizer) {
        let facebookLogin = FBSDKLoginManager()
        facebookLogin.logOut()
        facebookLogin.logIn(withReadPermissions: ["email"], from: self) { (result, error) in
            if error != nil {
                print("TREVOR: Unable to authenticate with Facebook - \(String(describing: error))")
            } else if result?.isCancelled == true {
                print("TREVOR: User cancelled Facebook authentication")
            } else {
                print("TREVOR: Successfully authenticated with Facebook")
                let credential = FacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
                self.firebaseAuth(credential)
            }
        }
    }
}

