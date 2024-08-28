//
//  ProfileViewController.swift
//  ChattingApp
//
//  Created by Trần Quang Tuấn on 19/8/24.
//

import UIKit
import FirebaseAuth

class ProfileViewController: UIViewController {
        
    @IBOutlet weak var avatar: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupAvatar()
        displayUserInfo()
    }
    
    private func setupAvatar() {
        avatar.layer.cornerRadius = avatar.frame.width / 2
        avatar.layer.borderColor = UIColor.white.cgColor
        avatar.layer.borderWidth = 2
    }
    
    private func displayUserInfo() {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String
        else { return }
        
        let safeEmail = Utils.convertedEmail(Email: email)
        let fileName = safeEmail + "_profile_picture.png"
        let path = "images/" + fileName
        
        StorageManager.shared.downloadURL(for: path) { [weak self] result in
            guard let self else { return }
            
            switch result {
            case .success(let url):
                self.downloadImage(imageView: self.avatar, url: url)
            case .failure(let error):
                print("Download failed, \(error)")
            }
        }
    }
    
    private func downloadImage(imageView: UIImageView, url: URL) {
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                return
            }
            
            DispatchQueue.main.async {
                let image = UIImage(data: data)
                imageView.image = image
            }
            
        }.resume()
    }
    
    @IBAction func logoutTapped(_ sender: Any) {
        
        let alert = UIAlertController(title: "Log Out", message: "Are you sure to exit current account", preferredStyle: .alert)
        
        let dismiss = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let confirm = UIAlertAction(title: "Yes", style: .default) { _ in
            do {
                try FirebaseAuth.Auth.auth().signOut()
                
                let mainSB = UIStoryboard(name: "Main", bundle: .main)
                let mainTabbarVC = mainSB.instantiateViewController(identifier: "Login")
                
                guard let windown = UIApplication.shared.windown
                else { return }
                windown.rootViewController = mainTabbarVC
                windown.makeKeyAndVisible()
            } catch {
                print(error)
            }
        }
        
        alert.addAction(dismiss)
        alert.addAction(confirm)
        
        present(alert, animated: true)
    }
}
