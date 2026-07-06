//
//  HomeController.swift
//  PetCareShared
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

    @IBAction func home_BTN_scheduleClicked(_ sender: UIButton) {
        performSegue(withIdentifier: "toSchedule", sender: nil)
    }
    @IBAction func home_BTN_myPetsClicked(_ sender: UIButton) {
        performSegue(withIdentifier: "toMyPets", sender: nil)
    }
    @IBAction func home_BTN_sharedClicked(_ sender: UIButton) {
        performSegue(withIdentifier: "toShared", sender: nil)
    }
    @IBAction func home_BTN_viewProfileClicked(_ sender: UIButton) {
        performSegue(withIdentifier: "toPetProfile", sender: nil)
    }
    @IBAction func home_BTN_viewAllScheduleClicked(_ sender: UIButton) {
        performSegue(withIdentifier: "toSchedule", sender: nil)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toPetProfile",
           let vc = segue.destination as? PetProfileViewController {
            vc.petId = petId
        }
        if segue.identifier == "toSchedule",
           let vc = segue.destination as? ScheduleViewController {
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
                self.loadTodo(petId: firstPetId)
                self.loadHealthOverview(petId: firstPetId)

                Firestore.firestore()
                    .collection("pets")
                    .document(firstPetId)
                    .getDocument { petDoc, error in
                        guard let data = petDoc?.data() else { return }
                        let name = data["name"] as? String ?? ""
                        let type = data["type"] as? String ?? ""
                        let birthDate = data["birthDate"] as? String ?? ""

                        // Firestore runs on a background thread — UI updates must happen on the main thread
                        DispatchQueue.main.async {
                            self.home_LBL_petName.text = name.capitalized
                            self.home_LBL_petInfo.text = "\(type.capitalized) • \(birthDate.parsedAsBirthDate()?.petAgeText() ?? "")"
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
                        self.home_LBL_upcomingTitle.text = "Not added yet"
                        self.home_LBL_upcomingDate.text = ""
                    }
                }
            }
    }

    func loadTodo(petId: String) {
        Firestore.firestore()
            .collection("pets").document(petId)
            .collection("tasks")
            .whereField("done", isEqualTo: false)
            .limit(to: 1)
            .getDocuments { snapshot, _ in
                let doc = snapshot?.documents.first
                let title = doc?.data()["title"] as? String
                DispatchQueue.main.async {
                    if let title = title {
                        self.home_LBL_reminderTitle.text = title
                        self.home_LBL_reminderDate.text = ""
                    } else {
                        self.home_LBL_reminderTitle.text = "No tasks"
                        self.home_LBL_reminderDate.text = ""
                    }
                }
            }
    }

    func loadHealthOverview(petId: String) {
        let petRef = Firestore.firestore().collection("pets").document(petId)
        let now = Timestamp(date: Date())
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d, yyyy"

        petRef.getDocument { petDoc, _ in
            let weightVal = petDoc?.data()?["weight"] as? Double

            petRef.collection("events")
                .whereField("type", isEqualTo: "Vaccination")
                .whereField("date", isLessThanOrEqualTo: now)
                .order(by: "date", descending: true)
                .limit(to: 1)
                .getDocuments { vaccSnap, _ in
                    let vaccTs = vaccSnap?.documents.first?.data()["date"] as? Timestamp

                    petRef.collection("events")
                        .whereField("type", isEqualTo: "Vet Appointment")
                        .whereField("date", isLessThanOrEqualTo: now)
                        .order(by: "date", descending: true)
                        .limit(to: 1)
                        .getDocuments { vetSnap, _ in
                            let vetTs = vetSnap?.documents.first?.data()["date"] as? Timestamp
                            DispatchQueue.main.async {
                                self.home_LBL_weight.text = weightVal.map { "\($0) kg" } ?? "Not added yet"
                                self.home_LBL_lastVaccination.text = vaccTs.map { fmt.string(from: $0.dateValue()) } ?? "Not added yet"
                                self.home_LBL_lastVetVisit.text = vetTs.map { fmt.string(from: $0.dateValue()) } ?? "Not added yet"
                            }
                        }
                }
        }
    }
}
