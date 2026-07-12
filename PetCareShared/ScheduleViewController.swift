import UIKit
import FirebaseAuth
import FirebaseFirestore

class ScheduleViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var schedule_TBL_events: UITableView!

    @IBOutlet weak var schedule_VIEW_dimBackground: UIView!
    @IBOutlet weak var schedule_VIEW_addEventCard: UIView!
    @IBOutlet weak var schedule_BTN_eventType: UIButton!
    @IBOutlet weak var schedule_DTP_eventDate: UIDatePicker!
    @IBOutlet weak var schedule_TF_eventNotes: UITextField!

    var petId: String = ""
    private var events: [[String: Any]] = []
    private var selectedType = "Vet Appointment"
    private let eventTypes = ["Vet Appointment", "Vaccination", "Grooming", "Medication", "Other"]

    override func viewDidLoad() {
        super.viewDidLoad()
        schedule_TBL_events.delegate = self
        schedule_TBL_events.dataSource = self
        schedule_VIEW_dimBackground.isHidden = true
        schedule_DTP_eventDate.datePickerMode = .dateAndTime
        updateTypeButton()
        if petId.isEmpty {
            loadPetThenEvents()
        } else {
            loadEvents()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !petId.isEmpty { loadEvents() }
    }

    @IBAction func schedule_BTN_addEventClicked(_ sender: UIButton) {
        showAddEventCard()
    }

    private func showAddEventCard() {
        selectedType = eventTypes.first ?? "Vet Appointment"
        updateTypeButton()
        schedule_DTP_eventDate.date = Date()
        schedule_TF_eventNotes.text = ""
        schedule_VIEW_dimBackground.isHidden = false
    }

    private func hideAddEventCard() {
        schedule_VIEW_dimBackground.isHidden = true
    }

    private func updateTypeButton() {
        schedule_BTN_eventType.setTitle(selectedType, for: .normal)
    }

    @IBAction func schedule_BTN_eventTypeClicked(_ sender: UIButton) {
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

    @IBAction func schedule_BTN_cancelEventClicked(_ sender: UIButton) {
        hideAddEventCard()
    }

    @IBAction func schedule_BTN_saveEventClicked(_ sender: UIButton) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let date = Timestamp(date: schedule_DTP_eventDate.date)
        let notes = schedule_TF_eventNotes.text?.trimmingCharacters(in: .whitespaces) ?? ""

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
                    self.hideAddEventCard()
                    self.loadEvents()
                }
            }
    }

    private func loadPetThenEvents() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        Firestore.firestore().collection("users").document(userId)
            .getDocument { document, _ in
                guard let firstPetId = (document?.data()?["petIds"] as? [String])?.first else { return }
                self.petId = firstPetId
                self.loadEvents()
            }
    }

    private func loadEvents() {
        Firestore.firestore()
            .collection("pets").document(petId)
            .collection("events")
            .order(by: "date")
            .getDocuments { snapshot, _ in
                let allEvents = snapshot?.documents.map { $0.data() } ?? []
                let now = Date()
                let upcoming = allEvents.filter { (($0["date"] as? Timestamp)?.dateValue() ?? .distantPast) >= now }
                let past = allEvents.filter { (($0["date"] as? Timestamp)?.dateValue() ?? .distantPast) < now }
                self.events = upcoming + past
                DispatchQueue.main.async {
                    self.schedule_TBL_events.reloadData()
                }
            }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.isEmpty ? 1 : events.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "eventCell", for: indexPath) as! EventCell
        if events.isEmpty {
            cell.event_LBL_type.text = "No events yet"
            cell.event_LBL_type.textColor = .secondaryLabel
            cell.event_LBL_date.text = ""
            return cell
        }
        let event = events[indexPath.row]
        let type = event["type"] as? String ?? ""
        let ts = event["date"] as? Timestamp
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy • HH:mm"
        let dateText = ts.map { formatter.string(from: $0.dateValue()) } ?? ""
        let isPast = (ts?.dateValue() ?? .distantFuture) < Date()

        if isPast {
            let strikethrough: [NSAttributedString.Key: Any] = [.strikethroughStyle: NSUnderlineStyle.single.rawValue]
            cell.event_LBL_type.attributedText = NSAttributedString(string: type, attributes: strikethrough)
            cell.event_LBL_date.attributedText = NSAttributedString(string: dateText, attributes: strikethrough)
            cell.event_LBL_type.textColor = .secondaryLabel
        } else {
            cell.event_LBL_type.text = type
            cell.event_LBL_date.text = dateText
            cell.event_LBL_type.textColor = .label
        }
        return cell
    }
}
