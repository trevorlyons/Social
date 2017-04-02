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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

        }
    
    override func viewDidAppear(_ animated: Bool) {
        // checking is the id key has already been made so that signin is automatic if already signed up
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

                }
            }
        })
        
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
                                self.completeSignIn(id: user.uid, userData: userData)
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
        
        // editing segue to account setup
        performSegue(withIdentifier: "goToAccountSetup", sender: nil)
    }
}

