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

class SignInVC: UIViewController {

    @IBOutlet weak var emailField: FancyField!
    @IBOutlet weak var passwordField: FancyField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Facebook Login functions
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
            }
        })
        
    }
    
    // Email Sign in - Enable email sign in with Firebase console!
    @IBAction func signInTapped(_ sender: Any) {
        if let email = emailField.text, let pwd = passwordField.text {
            FIRAuth.auth()?.signIn(withEmail: email, password: pwd, completion: { (user, error) in
                if error == nil {
                    print("TREVOR: Email user authenticated with Firebase")
                } else {
                    FIRAuth.auth()?.createUser(withEmail: email, password: pwd, completion: { (user, error) in
                        if error != nil {
                            print("TREVOR: Unable to authenticate with Firebase using email")
                        } else {
                            print("TREVOR: Successfully authenticated with Firebase")
                        }
                    })
                }
            })
        }
    }
}

