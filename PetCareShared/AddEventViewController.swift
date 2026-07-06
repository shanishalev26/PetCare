import UIKit
import FirebaseAuth
import FirebaseFirestore

class AddEventViewController: UIViewController {

    @IBOutlet weak var addEvent_BTN_type: UIButton!
    @IBOutlet weak var addEvent_DTP_datetime: UIDatePicker!
    @IBOutlet weak var addEvent_TF_notes: UITextField!

    var petId: String = ""
    private var selectedType = "Vet Appointment"
    private let eventTypes = ["Vet Appointment", "Vaccination", "Grooming", "Medication", "Other"]

    override func viewDidLoad() {
        super.viewDidLoad()
        addEvent_DTP_datetime.datePickerMode = .dateAndTime
        addEvent_DTP_datetime.preferredDatePickerStyle = .inline
        updateTypeButton()
    }

    private func updateTypeButton() {
        addEvent_BTN_type.setTitle(selectedType, for: .normal)
    }

    @IBAction func addEvent_BTN_typeClicked(_ sender: UIButton) {
        let alert = UIAlertController(title: "Select Event Type", message: nil, preferredStyle: .actionSheet)
        for type in eventTypes {
            alert.addAction(UIAlertAction(title: type, style: .default) { _ in
                self.selectedType = type
                self.updateTypeButton()
            })
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    @IBAction func addEvent_BTN_saveClicked(_ sender: UIButton) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let date = Timestamp(date: addEvent_DTP_datetime.date)
        let notes = addEvent_TF_notes.text?.trimmingCharacters(in: .whitespaces) ?? ""

        var data: [String: Any] = [
            "type": selectedType,
            "date": date,
            "addedBy": userId,
            "createdAt": Timestamp(date: Date())
        ]
        if !notes.isEmpty { data["notes"] = notes }

        Firestore.firestore()
            .collection("pets").document(petId)
            .collection("events")
            .addDocument(data: data) { error in
                guard error == nil else { return }
                DispatchQueue.main.async {
                    self.navigationController?.popViewController(animated: true)
                }
            }
    }
}
