//
//  Conversation.swift
//  ChattingApp
//
//  Created by Trần Quang Tuấn on 28/8/24.
//

import Foundation

struct Conversation {
    let id: String
    let name: String
    let otherUserEmail: String
    let latesrMessage: LatestMessage
}

struct LatestMessage {
    let date: String
    let text: String
    let isRead: Bool
}
