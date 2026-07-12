//
//  HomeController.swift
//  PetCare
//
//  Created by שני שלו on 15/06/2026.
//

import Foundation
import UIKit
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn

class HomeController: UIViewController {

    @IBOutlet weak var home_LBL_petName: UILabel!
    @IBOutlet weak var home_LBL_petInfo: UILabel!
    @IBOutlet weak var home_IMG_pet: UIImageView!

    @IBOutlet weak var home_LBL_greeting: UILabel!

    @IBOutlet weak var home_LBL_upcomingTitle: UILabel!
    @IBOutlet weak var home_LBL_upcomingDate: UILabel!
    @IBOutlet weak var home_LBL_reminderTitle: UILabel!
    @IBOutlet weak var home_LBL_reminderDate: UILabel!
    @IBOutlet weak var home_LBL_lastVaccination: UILabel!
    @IBOutlet weak var home_LBL_weight: UILabel!
    @IBOutlet weak var home_LBL_lastVetVisit: UILabel!

    var petId: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        loadPet()
        loadGreeting()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !petId.isEmpty {
            loadCareNotes(petId: petId)
            loadUpcomingEvent(petId: petId)
        }
    }

    @IBAction func home_BTN_scheduleClicked(_ sender: UIButton) {
        tabBarController?.selectedIndex = 1
    }
    @IBAction func home_BTN_myPetsClicked(_ sender: UIButton) {
        performSegue(withIdentifier: "toPetProfile", sender: nil)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toPetProfile",
           let vc = segue.destination as? PetProfileViewController {
            vc.petId = petId
        }
    }

    func loadPet() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        Firestore.firestore()
            .collection("users")
            .document(userId)
            .getDocument { document, error in
                guard let petIds = document?.data()?["petIds"] as? [String],
                      let firstPetId = petIds.first else { return }

                self.petId = firstPetId
                self.loadUpcomingEvent(petId: firstPetId)
                self.loadCareNotes(petId: firstPetId)
                self.loadHealthOverview(petId: firstPetId)

                Firestore.firestore()
                    .collection("pets")
                    .document(firstPetId)
                    .getDocument { petDoc, error in
                        guard let data = petDoc?.data() else { return }
                        let name = data["name"] as? String ?? ""
                        let type = data["type"] as? String ?? ""
                        let breed = data["breed"] as? String ?? ""
                        let birthDate = data["birthDate"] as? String ?? ""
                        let age = birthDate.parsedAsBirthDate()?.petAgeText() ?? "Not added yet"

                        DispatchQueue.main.async {
                            self.home_LBL_petName.text = name.capitalized
                            self.home_LBL_petInfo.numberOfLines = 0
                            self.home_LBL_petInfo.text = "\(type.capitalized) • \(breed.capitalized)\n\(age)"
                        }
                    }
            }
    }

    func loadGreeting() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        Firestore.firestore()
            .collection("users")
            .document(userId)
            .getDocument { document, error in
                let firstName = document?.data()?["firstName"] as? String ?? ""
                DispatchQueue.main.async {
                    self.home_LBL_greeting.text = firstName.isEmpty ? "Hi!" : "Hi \(firstName.capitalized)"
                }
            }
    }

    func loadUpcomingEvent(petId: String) {
        let now = Timestamp(date: Date())
        Firestore.firestore()
            .collection("pets").document(petId)
            .collection("events")
            .whereField("date", isGreaterThanOrEqualTo: now)
            .order(by: "date")
            .limit(to: 1)
            .getDocuments { snapshot, _ in
                let doc = snapshot?.documents.first
                let type = doc?.data()["type"] as? String
                let timestamp = doc?.data()["date"] as? Timestamp
                DispatchQueue.main.async {
                    if let type = type, let ts = timestamp {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "MMM d, yyyy • HH:mm"
                        self.home_LBL_upcomingTitle.text = type
                        self.home_LBL_upcomingDate.text = formatter.string(from: ts.dateValue())
                    } else {
                        self.home_LBL_upcomingTitle.text = "No upcoming appointments"
                        self.home_LBL_upcomingDate.text = ""
                    }
                }
            }
    }

    func loadCareNotes(petId: String) {
        Firestore.firestore()
            .collection("pets").document(petId)
            .getDocument { petDoc, _ in
                let notes = petDoc?.data()?["notes"] as? String ?? ""
                let bullets = notes.split(separator: "\n", omittingEmptySubsequences: true).map { "• \($0)" }
                DispatchQueue.main.async {
                    self.home_LBL_reminderDate.isHidden = true
                    self.home_LBL_reminderTitle.numberOfLines = 0
                    self.home_LBL_reminderTitle.text = bullets.isEmpty ? "No notes added yet" : bullets.joined(separator: "\n")
                }
            }
    }

    func loadHealthOverview(petId: String) {
        Firestore.firestore()
            .collection("pets").document(petId)
            .getDocument { petDoc, _ in
                let data = petDoc?.data()
                let weightVal = data?["weight"] as? Double
                let birthDate = data?["birthDate"] as? String ?? ""
                let gender = data?["gender"] as? String
                let age = birthDate.parsedAsBirthDate()?.petAgeText() ?? "Not added yet"

                DispatchQueue.main.async {
                    self.home_LBL_lastVaccination.text = weightVal.map { "\($0) kg" } ?? "Not added yet"
                    self.home_LBL_weight.text = age
                    self.home_LBL_lastVetVisit.text = gender?.capitalized ?? "Not added yet"
                }
            }
    }
}
