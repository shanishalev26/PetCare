import UIKit
import FirebaseAuth
import FirebaseFirestore

class ScheduleViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var schedule_TBL_events: UITableView!

    var petId: String = ""
    private var events: [[String: Any]] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        schedule_TBL_events.delegate = self
        schedule_TBL_events.dataSource = self
        schedule_TBL_events.register(UITableViewCell.self, forCellReuseIdentifier: "eventCell")
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
        performSegue(withIdentifier: "toAddEvent", sender: nil)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toAddEvent",
           let vc = segue.destination as? AddEventViewController {
            vc.petId = petId
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
                self.events = snapshot?.documents.map { $0.data() } ?? []
                DispatchQueue.main.async {
                    self.schedule_TBL_events.reloadData()
                }
            }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.isEmpty ? 1 : events.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "eventCell", for: indexPath)
        if events.isEmpty {
            cell.textLabel?.text = "No events yet"
            cell.textLabel?.textColor = .secondaryLabel
            cell.detailTextLabel?.text = ""
            return cell
        }
        let event = events[indexPath.row]
        let type = event["type"] as? String ?? ""
        let ts = event["date"] as? Timestamp
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy • HH:mm"
        cell.textLabel?.text = type
        cell.detailTextLabel?.text = ts.map { formatter.string(from: $0.dateValue()) } ?? ""
        return cell
    }
}
