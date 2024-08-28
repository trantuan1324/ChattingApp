//
//  LoginViewController.swift
//  ChattingApp
//
//  Created by Trần Quang Tuấn on 15/8/24.
//

import UIKit
import FirebaseAuth
import ProgressHUD

class LoginViewController: UIViewController {

    @IBOutlet weak var emailTF: UITextField!
    @IBOutlet weak var passwordTF: UITextField!
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        emailTF.delegate = self
//        passwordTF.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if FirebaseAuth.Auth.auth().currentUser != nil {
            let mainSB = UIStoryboard(name: "Main", bundle: .main)
            let mainTabbarVC = mainSB.instantiateViewController(identifier: "MainScreen")
            
            guard let windown = UIApplication.shared.windown
            else { return }
            windown.rootViewController = mainTabbarVC
            windown.makeKeyAndVisible()
        }
    }
    
    @IBAction func loginTapped() {
        emailTF.resignFirstResponder()
        passwordTF.resignFirstResponder()
                
        guard let emailStr = emailTF.text, let passwordStr = passwordTF.text,
        !emailStr.isEmpty, passwordStr.count >= 8 else {
            alertLoginMessage(title: "Warning", message: "Email or password is incorrect")
            return
        }
        
        ProgressHUD.animate("Please wait...", .barSweepToggle)
        
        FirebaseAuth.Auth.auth().signIn(withEmail: emailStr, password: passwordStr) { authResult, error in
            
            ProgressHUD.dismiss()
            
            guard let result = authResult, error == nil else {
                print("Failed to login \(String(describing: error))")
                return
            }
            
            let user = result.user
            
            let safeEmail = Utils.convertedEmail(Email: emailStr)
            
            
            
            UserDefaults.standard.set(emailStr, forKey: "email")
            UserDefaults.standard.set("\()", forKey: <#T##String#>)
            let mainSB = UIStoryboard(name: "Main", bundle: .main)
            let mainTabbarVC = mainSB.instantiateViewController(identifier: "MainScreen")
            
            guard let windown = UIApplication.shared.windown
            else { return }
            windown.rootViewController = mainTabbarVC
            windown.makeKeyAndVisible()
            // dismiss this view controller if login succeed
            
        }
    }
    
    private func alertLoginMessage(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let onDismiss = UIAlertAction(title: "Dismiss", style: .cancel) { _ in
            alert.dismiss(animated: true)
        }
        
        alert.addAction(onDismiss)
        
        present(alert, animated: true)
    }
    
}

extension UIApplication {
    var windown: UIWindow? {
        return UIApplication.shared.connectedScenes
            .filter {$0.activationState == .foregroundActive }
            .compactMap {$0 as? UIWindowScene }
            .first?
            .keyWindow
    }
}

//extension LoginViewController: UITextFieldDelegate {
//    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
//        if textField == emailTF {
//            passwordTF.becomeFirstResponder()
//        } else if textField == passwordTF {
//            loginTapped()
//        }
//        return true
//    }
//}
