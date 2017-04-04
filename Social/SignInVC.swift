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

class SignInVC: UIViewController {

    @IBOutlet weak var emailField: FancyField!
    @IBOutlet weak var passwordField: FancyField!
    @IBOutlet weak var test: UIImageView!
    
    var dict: [String: Any]!
    var username: String!
    var profileUrl: String!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

        }
    
    override func viewDidAppear(_ animated: Bool) {
        // checking if the id key has already been made so that signin is automatic if already signed up
        if let _ = KeychainWrapper.standard.string(forKey: KEY_UID) {
            performSegue(withIdentifier: "goToFeed", sender: nil)
        }
    }

    
    // Facebook Login functions - Enable Facebook signin with Firebase and follow developers.facebook.com
    @IBAction func facebookBtnTapped(_ sender: Any) {
        
        let facebookLogin = FBSDKLoginManager()
        
        facebookLogin.logIn(withReadPermissions: ["email"], from: self) { (result, error) in
            if error != nil {
                print("TREVOR: Unable to authenticate with Facebook - \(error)")
            } else if result?.isCancelled == true {
                print("TREVOR: User cancelled Facebook authentication")
            } else {
                print("TREVOR: Successfully authenticated with Facebook")
                let credential = FIRFacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
                self.firebaseAuth(credential)
                
                // pass user data to users tree
                
            }
        }
        
    }
    
    func firebaseAuth(_ credential: FIRAuthCredential) {
        FIRAuth.auth()?.signIn(with: credential, completion: { (user, error) in
            if error != nil {
                print("TREVOR: Unable to authenticate with Firebase - \(error)")
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
                    //DataService.ds.REF_USER_CURRENT.child("ProfileImgUrl").setValue(self.profileUrl)
                    
                    
                    let url = URL(string: self.profileUrl)!
                
                    DispatchQueue.global().async {
                        do {
                            let data = try Data(contentsOf: url)
                            DispatchQueue.global().sync {
                                //self.imageAdd.image = UIImage(data: data)
                                self.test.image = UIImage(data: data)
                                let img = self.test.image
                                
                                if let imgData = UIImageJPEGRepresentation(img!, 0.2) {
                                    
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
                            
                        } catch  {
                 
                        }
                    }
                }
            })
        }
    }
    
    func postToFirebase(imgUrl: String) {
        let profileImage = imgUrl as AnyObject
        
        DataService.ds.REF_USER_CURRENT.child("ProfileImgUrl").setValue(profileImage)
    }
    
    
    
    // Email Sign in - Enable email sign in with Firebase console!
    @IBAction func signInTapped(_ sender: Any) {
        if let email = emailField.text, let pwd = passwordField.text {
            FIRAuth.auth()?.signIn(withEmail: email, password: pwd, completion: { (user, error) in
                if error == nil {
                    print("TREVOR: Email user authenticated with Firebase")
                    if let user = user {
                        let userData = ["provider": user.providerID]
                        self.completeSignIn(id: user.uid, userData: userData)
                    }
                } else {
                    FIRAuth.auth()?.createUser(withEmail: email, password: pwd, completion: { (user, error) in
                        if error != nil {
                            print("TREVOR: Unable to authenticate with Firebase using email")
                        } else {
                            print("TREVOR: Successfully authenticated with Firebase")
                            if let user = user {
                                let userData = ["provider": user.providerID]
                                self.completeSignInNew(id: user.uid, userData: userData)
                            }
                            
                        }
                    })
                }
            })
        }
    }
    
    // function to not repeat keychain code
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
        
        performSegue(withIdentifier: "goToAccountSetup", sender: nil)
    }
}

