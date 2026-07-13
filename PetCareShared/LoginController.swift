//
//  LoginController.swift
//  PetCare
//
//  Created by שני שלו on 14/06/2026.
//

import Foundation
import UIKit
import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import FirebaseFirestore

class LoginController: UIViewController {
    
    @IBOutlet weak var login_LBL_title: UILabel!
    @IBOutlet weak var login_LBL_error: UILabel!
    @IBOutlet weak var login_BTN_login: UIButton!
    @IBOutlet weak var login_TF_password: UITextField!
    @IBOutlet weak var login_TF_email: UITextField!
    @IBOutlet weak var login_TF_firstName: UITextField!
    @IBOutlet weak var login_TF_lastName: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        login_LBL_error.isHidden = true

        // Dismiss the keyboard when tapping outside a text field (cancelsTouchesInView = false keeps buttons/fields tappable)
        let tapToDismiss = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapToDismiss.cancelsTouchesInView = false
        view.addGestureRecognizer(tapToDismiss)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    
    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        let isSignUp = sender.selectedSegmentIndex == 1
        login_BTN_login.configuration?.title = isSignUp ? "Sign Up" : "Login"
        login_TF_firstName.isHidden = !isSignUp
        login_TF_lastName.isHidden = !isSignUp
    }
    
    
    @IBAction func clickedLogin(_ sender: UIButton) {
        let email = login_TF_email.text ?? ""
        let password = login_TF_password.text ?? ""

        if email.isEmpty || password.isEmpty {
            showError("Please enter email and password")
            return
        }

        if login_BTN_login.titleLabel?.text == "Sign Up" {
            let firstName = login_TF_firstName.text ?? ""
            let lastName = login_TF_lastName.text ?? ""
            guard !firstName.isEmpty, !lastName.isEmpty else {
                showError("Please enter your first and last name")
                return
            }
            Auth.auth().createUser(withEmail: email, password: password) { result, error in
                if let error = error { self.showError(error.localizedDescription); return }
                self.createUserDocumentIfNeeded(firstName: firstName, lastName: lastName) {
                    self.checkUserPets()
                }
            }
        } else {
            Auth.auth().signIn(withEmail: email, password: password) { result, error in
                if let error = error { self.showError(error.localizedDescription); return }
                self.createUserDocumentIfNeeded {
                    self.checkUserPets()
                }
            }
        }
    }
    
    
    @IBAction func clickedGoogleLogin(_ sender: UIButton) {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        GIDSignIn.sharedInstance.signIn(withPresenting: self) { result, error in
            if let error = error {
                self.showError(error.localizedDescription)
                return
            }

            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else { return }

            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: user.accessToken.tokenString)

            Auth.auth().signIn(with: credential) { result, error in
                if let error = error {
                    self.showError(error.localizedDescription)
                    return
                }
                self.createUserDocumentIfNeeded {
                    self.checkUserPets()
                }
            }
        }
    }
    
    func showError(_ message: String) {
        login_LBL_error.text = message
        login_LBL_error.isHidden = false
    }
    
    /////
    func createUserDocumentIfNeeded(firstName: String = "", lastName: String = "", completion: @escaping () -> Void) {
        guard let user = Auth.auth().currentUser else { return }

        let userRef = Firestore.firestore()
            .collection("users")
            .document(user.uid)

        userRef.getDocument { document, error in
            if let document = document, document.exists {
                completion()
                return
            }

            let userData: [String: Any] = [
                "email": user.email ?? "",
                "firstName": firstName,
                "lastName": lastName,
                "petIds": []
            ]

            userRef.setData(userData) { error in
                if let error = error {
                    self.showError(error.localizedDescription)
                    return
                }

                completion()
            }
        }
    }
    
    func checkUserPets() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        Firestore.firestore()
            .collection("users")
            .document(userId)
            .getDocument { document, error in
                
                if let error = error {
                    self.showError(error.localizedDescription)
                    return
                }

                let petIds = document?.data()?["petIds"] as? [String] ?? []

                if petIds.isEmpty {
                    self.performSegue(withIdentifier: "toAddFirstPet", sender: nil)
                } else {
                    self.performSegue(withIdentifier: "toHome", sender: nil)
                }
            }
    }
}
