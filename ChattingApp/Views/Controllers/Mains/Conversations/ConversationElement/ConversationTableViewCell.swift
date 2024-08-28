//
//  ConversationTableViewCell.swift
//  ChattingApp
//
//  Created by Trần Quang Tuấn on 28/8/24.
//

import UIKit
import SDWebImage

class ConversationTableViewCell: UITableViewCell {
    
    @IBOutlet weak var avatar: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var userMessageLabel: UILabel!
    
    static let identifier = "ConversationTableViewCell"
    
    static func uiNibRegister() -> UINib {
        return UINib(nibName: "ConversationTableViewCell", bundle: .main)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupAvatar()
    }
    
    private func setupAvatar() {
        avatar.contentMode = .scaleAspectFill
        avatar.layer.cornerRadius = 30
        avatar.layer.masksToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    public func configure(with model: Conversation) {
        userMessageLabel.text = model.latesrMessage.text
        userNameLabel.text = model.name

        let path = "images/\(model.otherUserEmail)_profile_picture.png"
        StorageManager.shared.downloadURL(for: path, completion: { [weak self] result in
            switch result {
            case .success(let url):

                DispatchQueue.main.async {
                    self?.avatar.sd_setImage(with: url, completed: nil)
                }

            case .failure(let error):
                print("failed to get image url: \(error)")
            }
        })
    }
    
}
