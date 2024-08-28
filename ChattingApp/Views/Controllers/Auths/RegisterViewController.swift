//
//  RegisterViewController.swift
//  ChattingApp
//
//  Created by Trần Quang Tuấn on 15/8/24.
//

import UIKit
import FirebaseAuth
import ProgressHUD

class RegisterViewController: UIViewController {

    @IBOutlet weak var emailRegisterTF: UITextField!
    @IBOutlet weak var passwordRegisterTF: UITextField!
    @IBOutlet weak var firstNameTF: UITextField!
    @IBOutlet weak var lastNameTF: UITextField!
    @IBOutlet weak var userAvatarIV: UIImageView!
            
    override func viewDidLoad() {
        super.viewDidLoad()

        userAvatarIV.isUserInteractionEnabled = true
        let gesture = UITapGestureRecognizer(target: self, action: #selector(changeProfileTapped))
        userAvatarIV.addGestureRecognizer(gesture)
        userAvatarIV.layer.cornerRadius = 50
    }
    
    @objc 
    private func changeProfileTapped() {
        presentPhotoActionSheet()
    }
    
    @IBAction func registerTapped() {
        emailRegisterTF.resignFirstResponder()
        passwordRegisterTF.resignFirstResponder()
        firstNameTF.resignFirstResponder()
        lastNameTF.resignFirstResponder()
        
        guard let emailStr = emailRegisterTF.text, 
            let passwordStr = passwordRegisterTF.text,
              !emailStr.isEmpty, passwordStr.count >= 8,
              let firstNameStr = firstNameTF.text,
              let lastNameStr = lastNameTF.text,
              !firstNameStr.isEmpty, !lastNameStr.isEmpty
        else {
            alertRegisterMessage(title: "Invalid information", message: "Please completed all fields", isPopVC: false)
            return
        }
        
        ProgressHUD.animate("Please wait...", .barSweepToggle)
        
        DatabaseManager.shared.userExists(with: emailStr) { [weak self] isExits in
            guard let self else { return }
            
            ProgressHUD.dismiss()
            
            guard !isExits else {
                self.alertRegisterMessage(title: "Failed!!", message: "This email was registed", isPopVC: false)
                return
            }
            
            FirebaseAuth.Auth.auth().createUser(withEmail: emailStr, password: passwordStr) { (result, error) in
                
                guard result != nil, error == nil else {
                    self.alertRegisterMessage(title: "Failed!", message: "Please check your information and try again", isPopVC: false)
                    return
                }
                
                let newUser = ChatUser(firstName: firstNameStr, lastName: lastNameStr, emailAddress: emailStr)
                
                DatabaseManager.shared.insertUser(with: newUser) { success in
                    if success {
                        guard let image = self.userAvatarIV.image,
                            let data = image.pngData() else {
                            return
                        }
                        
                        let fileName = newUser.profilePictureFileName
                        StorageManager.shared.uploadProfilePicture(with: data, fileName: fileName) { result in
                            switch result {
                            case .success(let downloadUrl):
                                UserDefaults.standard.set(downloadUrl, forKey: "profile_picture_url")
                                print(downloadUrl)
                            case .failure(let error):
                                print("Storage manager error: \(error)")
                            }
                        }
                    }
                }
                
                self.alertRegisterMessage(title: "Successful!!!", message: "Now come back to login screen", isPopVC: true)
            }
        }

    }
    
    
    func alertRegisterMessage(title: String, message: String, isPopVC: Bool) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let onDismiss = UIAlertAction(title: "Dismiss", style: .cancel) { [weak self] _ in
            if isPopVC {
                self?.navigationController?.popViewController(animated: true)
            }
            alert.dismiss(animated: true)
        }
        
        alert.addAction(onDismiss)
        
        present(alert, animated: true)
    }
}

extension RegisterViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func presentPhotoActionSheet() {
        let actionSheet = UIAlertController(title: "Choose your avatar", 
                                            message: "Pick a picture to your profile",
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Cancel", 
                                            style: .cancel,
                                            handler: nil))
        actionSheet.addAction(UIAlertAction(title: "Take photo",
                                            style: .default) { [weak self] _ in
            self?.presentCamera()
        })
        actionSheet.addAction(UIAlertAction(title: "Choose photo from photo",
                                            style: .default) { [weak self] _ in
            self?.presentPhotoPicker()
        })
        
        present(actionSheet, animated: true)
        
    }
    
    func presentCamera() {
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.delegate = self
        vc.allowsEditing = true
        
        present(vc, animated: true)
    }
    
    func presentPhotoPicker() {
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.delegate = self
        vc.allowsEditing = true
        
        present(vc, animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        guard let selectedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage else {
            return
        }
        
        self.userAvatarIV.image = selectedImage
    }
}
