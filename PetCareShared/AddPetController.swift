//
//  AddPetController.swift
//  PetCareShared
//
//  Created by שני שלו on 15/06/2026.
//

import Foundation
import UIKit
import FirebaseAuth
import FirebaseFirestore

class AddPetController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var addpet_TF_name: UITextField!
    @IBOutlet weak var addpet_TF_type: UITextField!
    @IBOutlet weak var addpet_TF_breed: UITextField!
    @IBOutlet weak var addpet_TF_birthDate: UITextField!
    @IBOutlet weak var addpet_BTN_save: UIButton!
    @IBOutlet weak var addpet_LBL_error: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
       
        addpet_LBL_error.text = ""
        addpet_LBL_error.isHidden = true
        addpet_TF_birthDate.delegate = self
        addpet_TF_birthDate.keyboardType = .numberPad
        addpet_TF_birthDate.placeholder = "DD/MM/YYYY"

    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard textField == addpet_TF_birthDate else { return true }
        let currentText = textField.text ?? ""
        let newText = (currentText as NSString).replacingCharacters(in: range, with: string)
        let digits = newText.replacingOccurrences(of: "/", with: "")
        guard digits.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil else { return false }
        guard digits.count <= 8 else { return false }
        if digits.count >= 2 {
            let day = Int(digits.prefix(2)) ?? 0
            if day < 1 || day > 31 { return false }
        }
        if digits.count >= 4 {
            let month = Int(digits.dropFirst(2).prefix(2)) ?? 0
            if month < 1 || month > 12 { return false }
        }
        var formatted = ""
        for (i, char) in digits.enumerated() {
            if i == 2 || i == 4 { formatted += "/" }
            formatted.append(char)
        }
        textField.text = formatted
        return false
    }

    @IBAction func addpet_BTN_saveClicked(_ sender: UIButton) {
        let name = addpet_TF_name.text ?? ""
        let type = addpet_TF_type.text ?? ""
        let breed = addpet_TF_breed.text ?? ""
        let birthDate = addpet_TF_birthDate.text ?? ""

        guard !name.isEmpty, !type.isEmpty, !breed.isEmpty, !birthDate.isEmpty else {
            addpet_LBL_error.text = "Please fill in all fields"
            addpet_LBL_error.isHidden = false
            return
        }

        guard let parsedDate = birthDate.parsedAsBirthDate() else {
            addpet_LBL_error.text = "Please enter a valid date (DD/MM/YYYY)"
            addpet_LBL_error.isHidden = false
            return
        }
        guard parsedDate <= Date() else {
            addpet_LBL_error.text = "Birth date cannot be in the future"
            addpet_LBL_error.isHidden = false
            return
        }

        guard let userId = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        let petRef = db.collection("pets").document()

        let petData: [String: Any] = [
            "name": name,
            "type": type,
            "breed": breed,
            "birthDate": birthDate,
            "ownerId": userId
        ]

        petRef.setData(petData) { error in
            if let error = error {
                self.addpet_LBL_error.text = error.localizedDescription
                self.addpet_LBL_error.isHidden = false
                return
            }

            db.collection("users").document(userId).updateData([
                "petIds": FieldValue.arrayUnion([petRef.documentID])
            ]) { error in
                if let error = error {
                    self.addpet_LBL_error.text = error.localizedDescription
                    self.addpet_LBL_error.isHidden = false
                    return
                }
                self.performSegue(withIdentifier: "toHome", sender: nil)
            }
        }
    }



}
