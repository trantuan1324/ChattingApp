//
//  ChatUser.swift
//  ChattingApp
//
//  Created by Trần Quang Tuấn on 20/8/24.
//
import Foundation

struct ChatUser {
    let firstName: String
    let lastName: String
    let emailAddress: String
    var profilePictureFileName: String {
        return "\(Utils.convertedEmail(Email: emailAddress))_profile_picture.png"
    }
}



