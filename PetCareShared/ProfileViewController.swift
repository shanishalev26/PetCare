import UIKit
import FirebaseAuth
import FirebaseFirestore

class ProfileViewController: UIViewController {

    @IBOutlet weak var profile_LBL_firstName: UILabel!
    @IBOutlet weak var profile_LBL_lastName: UILabel!
    @IBOutlet weak var profile_LBL_email: UILabel!
    @IBOutlet weak var profile_BTN_logout: UIButton!

    @IBAction func profile_BTN_logoutClicked(_ sender: UIButton) {
        do {
            try Auth.auth().signOut()
            tabBarController?.dismiss(animated: true)
        } catch {
            print(error.localizedDescription)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        loadUserProfile()
    }

    func loadUserProfile() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        Firestore.firestore()
            .collection("users")
            .document(userId)
            .getDocument { document, error in
                let firstName = document?.data()?["firstName"] as? String ?? ""
                let lastName = document?.data()?["lastName"] as? String ?? ""
                let email = document?.data()?["email"] as? String ?? ""

                DispatchQueue.main.async {
                    self.profile_LBL_firstName.text = firstName.isEmpty ? "—" : firstName.capitalized
                    self.profile_LBL_lastName.text = lastName.isEmpty ? "—" : lastName.capitalized
                    self.profile_LBL_email.text = email.isEmpty ? "—" : email
                }
            }
    }
}
