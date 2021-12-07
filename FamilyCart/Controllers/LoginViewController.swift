import UIKit
import Firebase

class LoginViewController: UIViewController {
  // MARK: Constants
  let loginToCarts = "LoginToCarts"
  
  // MARK: Outlets
  @IBOutlet weak var enterEmail: UITextField!
  @IBOutlet weak var enterPassword: UITextField!
  
  // MARK: Properties
  var handle: AuthStateDidChangeListenerHandle?
  
  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }
  
  // MARK: UIViewController Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    enterEmail.delegate = self
    enterPassword.delegate = self
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.setNavigationBarHidden(true, animated: false)
    handle = Auth.auth().addStateDidChangeListener { _, user in
      if user == nil {
        self.navigationController?.popToRootViewController(animated: true)
      } else {
        self.performSegue(withIdentifier: self.loginToCarts, sender: nil)
        self.enterEmail.text = nil
        self.enterPassword.text = nil
      }
    }
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    navigationController?.setNavigationBarHidden(false, animated: false)
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    guard let handle = handle else { return }
    Auth.auth().removeStateDidChangeListener(handle)
  }
  
  // MARK: Actions
  @IBAction func loginDidTouch(_ sender: AnyObject) {
    guard
      let email = enterEmail.text,
      let password = enterPassword.text,
      !email.isEmpty,
      !password.isEmpty
    else { return }
    
    Auth.auth().signIn(withEmail: email, password: password) { user, error in
      if let error = error, user == nil {
        let alert = UIAlertController(
          title: "Sign In Failed",
          message: error.localizedDescription,
          preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true, completion: nil)
      }
    }
  }
  
  @IBAction func signUpDidTouch(_ sender: AnyObject) {
    guard
      let email = enterEmail.text,
      let password = enterPassword.text,
      !email.isEmpty,
      !password.isEmpty
    else { return }
    
    Auth.auth().createUser(withEmail: email, password: password) { _, error in
      if error == nil {
        Auth.auth().signIn(withEmail: email, password: password)
      } else {
        print("Error in createUser: \(error?.localizedDescription ?? "")")
      }
    }
  }
}

// MARK: - UITextFieldDelegate
extension LoginViewController: UITextFieldDelegate {
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    if textField == enterEmail {
      enterPassword.becomeFirstResponder()
    }
    
    if textField == enterPassword {
      textField.resignFirstResponder()
    }
    return true
  }
}
