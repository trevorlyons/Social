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

    
    // MARK: IBOutlets
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var warningLbl: UILabel!
    @IBOutlet weak var signInBtn: FancyView!
    
    
    // MARK: Variables and Constants
    
    var signInDelegate: SignInProtocol!
    
    
    // MARK: viewDidLoad
    
    override func viewDidLoad() {
        super.viewDidLoad()

        warningLbl.isHidden = true
        
        emailField.autocorrectionType = .no
        passwordField.autocorrectionType = .no
        
        signInBtn.isUserInteractionEnabled = true
    }
    
    
    // MARK: IBActions
    
    @IBAction func signInViewTapped(_ sender: UITapGestureRecognizer) {
        self.signInBtn.isUserInteractionEnabled = false
        if let email = emailField.text, let pwd = passwordField.text {
            Auth.auth().signIn(withEmail: email, password: pwd, completion: { (user, error) in
                if error == nil {
                    print("TREVOR: Email user authenticated with Firebase")
                    if let user = user {
                        let userData = ["provider": user.providerID]
                        self.signInDelegate.completeSignIn(id: user.uid, userData: userData)
//                        self.dismiss(animated: true, completion: nil)
                    }
                } else {
                    Auth.auth().createUser(withEmail: email, password: pwd, completion: { (user, error) in
                        if error != nil {
                            self.signInBtn.isUserInteractionEnabled = true
                            self.warningLbl.isHidden = false
                            print("TREVOR: Unable to authenticate with Firebase using email")
                        } else {
                            self.signInBtn.isUserInteractionEnabled = false
                            print("TREVOR: Successfully authenticated with Firebase")
                            if let user = user {
                                let userData = ["provider": user.providerID]
                                self.signInDelegate.completeSignInNew(id: user.uid, userData: userData)
                                self.dismiss(animated: true, completion: nil)
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
