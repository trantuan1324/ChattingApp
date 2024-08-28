//
//  Message.swift
//  ChattingApp
//
//  Created by Trần Quang Tuấn on 26/8/24.
//

import MessageKit

struct UserMessage: MessageType {
    public var sender: any MessageKit.SenderType
    public var messageId: String
    public var sentDate: Date
    public var kind: MessageKit.MessageKind
}

struct Sender: MessageKit.SenderType {
    public var photoURL: String
    public var senderId: String
    public var displayName: String
}

extension MessageKind {
    var messageKindString: String {
        switch self {
        case .text(_):
            return "text"
        case .attributedText(_):
            return "attributed_text"
        case .photo(_):
            return "photo"
        case .video(_):
            return "video"
        case .location(_):
            return "location"
        case .emoji(_):
            return "emoji"
        case .audio(_):
            return "audio"
        case .contact(_):
            return "contact"
        case .custom(_):
            return "customc"
        case .linkPreview(_):
            return "link"
        }
    }
}
