//
//  EmailSignInVC.swift
//  Social
//
//  Created by Trevor Lyons on 2017-08-12.
//  Copyright © 2017 Trevor Lyons. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit
import Firebase
import SwiftKeychainWrapper

protocol SignInProtocol {
    func completeSignIn(id: String, userData: Dictionary<String, String>)
    func completeSignInNew(id: String, userData: Dictionary<String, String>)
}

class EmailSignInVC: UIViewController {

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    var signInDelegate: SignInProtocol!
    
    override func viewDidLoad() {
        super.viewDidLoad()


    }
    
    @IBAction func signInViewTapped(_ sender: UITapGestureRecognizer) {
        if let email = emailField.text, let pwd = passwordField.text {
            FIRAuth.auth()?.signIn(withEmail: email, password: pwd, completion: { (user, error) in
                if error == nil {
                    print("TREVOR: Email user authenticated with Firebase")
                    if let user = user {
                        let userData = ["provider": user.providerID]
                        self.signInDelegate.completeSignIn(id: user.uid, userData: userData)
                    }
                } else {
                    FIRAuth.auth()?.createUser(withEmail: email, password: pwd, completion: { (user, error) in
                        if error != nil {
                            print("TREVOR: Unable to authenticate with Firebase using email")
                        } else {
                            print("TREVOR: Successfully authenticated with Firebase")
                            if let user = user {
                                let userData = ["provider": user.providerID]
                                self.signInDelegate.completeSignInNew(id: user.uid, userData: userData)
                            }
                        }
                    })
                }
            })
        }
    }
    
    @IBAction func xViewTapped(_ sender: UITapGestureRecognizer) {
        dismiss(animated: true, completion: nil)
    }
}
