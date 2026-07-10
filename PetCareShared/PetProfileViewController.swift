//
//  PetCare
//
//  Created by שני שלו on 24/06/2026.
//


import UIKit
import FirebaseAuth
import FirebaseFirestore

class PetProfileViewController: UIViewController {

    var petId: String = ""
    private var currentNotes: String = ""

    @IBOutlet weak var petprofile_LBL_badgeType: UILabel!
    @IBOutlet weak var petprofile_LBL_name: UILabel!

    @IBOutlet weak var petprofile_LBL_badgeBreed: UILabel!

    @IBOutlet weak var petprofile_LBL_badgeAge: UILabel!

    @IBOutlet weak var petprofile_LBL_type: UILabel!

    @IBOutlet weak var petprofile_LBL_breed: UILabel!

    @IBOutlet weak var petprofile_LBL_birthDate: UILabel!

    @IBOutlet weak var petprofile_LBL_age: UILabel!

    @IBOutlet weak var petprofile_LBL_gender: UILabel!

    @IBOutlet weak var petprofile_LBL_weight: UILabel!

    @IBOutlet weak var petprofile_LBL_owner: UILabel!

    @IBOutlet weak var petprofile_LBL_careNotes: UILabel!

    @IBOutlet weak var petprofile_BTN_editNotes: UIButton!


    @IBAction func petprofile_BTN_editNotesClicked(_ sender: UIButton) {
        let alert = UIAlertController(title: "Add Care Note", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "e.g. Walk 3 times a day"
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Add", style: .default) { _ in
            let newNote = (alert.textFields?.first?.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !newNote.isEmpty else { return }
            self.addNote(newNote)
        })
        present(alert, animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        loadPet()
        loadOwner()
    }

    func loadPet() {
        Firestore.firestore()
            .collection("pets")
            .document(petId)
            .getDocument { document, error in
                guard let data = document?.data() else { return }

                let name = data["name"] as? String ?? ""
                let type = data["type"] as? String ?? ""
                let breed = data["breed"] as? String ?? ""
                let birthDate = data["birthDate"] as? String ?? ""
                let gender = data["gender"] as? String ?? ""
                let weight = data["weight"] as? Double
                let notes = data["notes"] as? String ?? ""
                let age = birthDate.parsedAsBirthDate()?.petAgeText() ?? "—"

                self.currentNotes = notes

                DispatchQueue.main.async {
                    self.petprofile_LBL_name.text = name.isEmpty ? "—" : name.capitalized

                    self.petprofile_LBL_badgeType.text = type.isEmpty ? "—" : type.capitalized
                    self.petprofile_LBL_badgeBreed.text = breed.isEmpty ? "—" : breed.capitalized
                    self.petprofile_LBL_badgeAge.text = age

                    self.petprofile_LBL_type.text = type.isEmpty ? "—" : type.capitalized
                    self.petprofile_LBL_breed.text = breed.isEmpty ? "—" : breed.capitalized
                    self.petprofile_LBL_birthDate.text = birthDate.isEmpty ? "—" : birthDate
                    self.petprofile_LBL_age.text = age
                    self.petprofile_LBL_gender.text = gender.isEmpty ? "—" : gender.capitalized
                    self.petprofile_LBL_weight.text = weight.map { "\($0) kg" } ?? "—"

                    self.displayNotes(notes)
                }
            }
    }

    func loadOwner() {
        let user = Auth.auth().currentUser
        let displayName = user?.displayName ?? ""
        let email = user?.email ?? ""
        petprofile_LBL_owner.text = !displayName.isEmpty ? displayName : (!email.isEmpty ? email : "—")
    }

    func addNote(_ note: String) {
        let existingLines = currentNotes.split(separator: "\n", omittingEmptySubsequences: true).map { String($0) }
        let updatedNotes = (existingLines + [note]).joined(separator: "\n")

        Firestore.firestore()
            .collection("pets")
            .document(petId)
            .updateData(["notes": updatedNotes]) { error in
                guard error == nil else { return }
                self.currentNotes = updatedNotes
                DispatchQueue.main.async {
                    self.displayNotes(updatedNotes)
                }
            }
    }

    func displayNotes(_ notes: String) {
        let bullets = notes.split(separator: "\n", omittingEmptySubsequences: true).map { "• \($0)" }
        petprofile_LBL_careNotes.numberOfLines = 0
        petprofile_LBL_careNotes.text = bullets.isEmpty ? "—" : bullets.joined(separator: "\n")
    }
}
