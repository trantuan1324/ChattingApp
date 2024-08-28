//
//  DatabaseManager.swift
//  ChattingApp
//
//  Created by Trần Quang Tuấn on 20/8/24.
//

import Foundation
import FirebaseDatabase

final class DatabaseManager {
    static let shared = DatabaseManager()
    
    private let database = Database.database().reference()
    
}
    /*
        users => [
           [
               "name":
               "safe_email":
           ],
           [
               "name":
            "safe_email":
           ]
       ]
     */
// Account Management
extension DatabaseManager {
    
    public func userExists(with email: String, completion: @escaping ((Bool) -> Void)) {
        
        let safeEmailConverted = Utils.convertedEmail(Email: email)
        
        database.child(safeEmailConverted).observeSingleEvent(of: .value) { snapshot in
            guard snapshot.value as? String != nil else {
                completion(false)
                return
            }
            
            completion(true)
        }
    }
    
    public func getAllUsers(completion: @escaping (Result<[[String:String]], Error>) -> Void) {
        database.child("users").observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value as? [[String:String]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            print(value)
            
            completion(.success(value))
        }
    }
    
    /// insert new user to database after register
    public func insertUser(with user: ChatUser, completion: @escaping(Bool) -> Void) {
        database.child(Utils.convertedEmail(Email: user.emailAddress)).setValue([
            "firstName": user.firstName,
            "lastName": user.lastName
        ], withCompletionBlock: { error, _ in
            guard error == nil else {
                print("Failed to write data to db")
                completion(false)
                return
            }
            
            self.database.child("users").observeSingleEvent(of: .value) { [weak self] snapshot in
                guard let self else { return }
                
                if var userCollection = snapshot.value as? [[String:String]] {
                    // append to user dictionary
                    let newElement = [
                        "name": user.firstName + " " + user.lastName,
                        "email": Utils.convertedEmail(Email: user.emailAddress)
                    ]
                    userCollection.append(newElement)
                    self.database.child("users").setValue(userCollection) { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        
                        completion(true)
                    }
                } else {
                    // create that array
                    let newCollection: [[String:String]] = [
                        [
                            "name": user.firstName + " " + user.lastName, 
                            "email": Utils.convertedEmail(Email: user.emailAddress)
                        ]
                    ]
                    
                    self.database.child("users").setValue(newCollection) { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        
                        completion(true)
                    }
                }
            }
        })
    }
    
    public enum DatabaseError: Error {
        case failedToFetch
    }
}

extension DatabaseManager {
    /*
     "sdjsaklsd" {
        "messages": [
            {
                "id": String,
                "type": txt, image, video,
                "content": String,
                "date": Date,
                "sender_email": String,
                "isRead": bool
            }
        ]
     }
     
     conversation => [
        [
            "conversation_id": "sdjsaklsd"
            "other_user_email":
            "lastest_msg" => {
                "date": Date()
                "lastest_msg": "msg"
                "is_read" : bool
            }
        ],
     ]
     
     */
    
    /// create a new conversation with email and first message was sent
    public func createNewConversation(with otherUserEmail: String, name: String, firstMessage: UserMessage, completion: @escaping (Bool) -> Void) {
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String,
        let currentName = UserDefaults.standard.value(forKey: "name") as? String else { return }
        let safeEmail = Utils.convertedEmail(Email: currentEmail)
        
        let ref = database.child("\(safeEmail)")
        ref.observeSingleEvent(of: .value, with: { [weak self] snapshot in
            guard let self else { return }
            guard var userNode = snapshot.value as? [String: Any] else {
                completion(false)
                print("user not found")
                return
            }
            
            let messageDate = firstMessage.sentDate
            let dateStr = Utils.dateFormatter.string(from: messageDate)
            
            var message = ""
            
            switch firstMessage.kind {
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .custom(_), .linkPreview(_):
                break
            }
            
            let conversationId = "conversation_\(firstMessage.messageId)"
            
            let newConversationData = [
                "id": conversationId,
                "other_user_email": otherUserEmail,
                "name": name,
                "latest_message": [
                    "date": dateStr,
                    "message": message,
                    "is_read": false
                ]
            ]
            
            let recipientNewConversationData = [
                "id": conversationId,
                "other_user_email": safeEmail,
                "name": currentName,
                "latest_message": [
                    "date": dateStr,
                    "message": message,
                    "is_read": false
                ]
            ]
            
            // Update recipient conversation entry
            self.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
                
                if var conversations = snapshot.value as? [[String: Any]] {
                    // append
                    conversations.append(recipientNewConversationData)
                    self.self.database.child("\(otherUserEmail)/conversations").setValue(conversationId)
                } else {
                    // create
                    self.database.child("\(otherUserEmail)/conversations").setValue([recipientNewConversationData])
                }
            })
            // Update current user conversation entry
            if var conversations = userNode["conversations"] as? [[String: Any]] {
                // conversation array exists for current user
                // you should append

                conversations.append(newConversationData)
                userNode["conversations"] = conversations
                ref.setValue(userNode, withCompletionBlock: { [weak self] error, _ in
                    
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    
                    self?.finishCreatingConversation(name: name, conversationId: conversationId, firstMessage: firstMessage, completion: completion)
                })
            } else {
                // conversation array does NOT exist
                // create it
                userNode["conversations"] = [
                    newConversationData
                ]
                
                ref.setValue(userNode, withCompletionBlock: { [weak self] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation(name: name, conversationId: conversationId, firstMessage: firstMessage, completion: completion)

                })
            }
        })
    }
    
    private func finishCreatingConversation(name: String, conversationId: String, firstMessage: UserMessage, completion: @escaping (Bool) -> Void) {
        let messageDate = firstMessage.sentDate
        let dateStr = Utils.dateFormatter.string(from: messageDate)
        
        var message = ""
        
        switch firstMessage.kind {
        case .text(let messageText):
            message = messageText
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .custom(_), .linkPreview(_):
            break
        }
        
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        
        let safeCurrentUserEmail = Utils.convertedEmail(Email: currentUserEmail)
        
        let collectionMessage: [String:Any] = [
            "id": firstMessage.messageId,
            "type": firstMessage.kind.messageKindString,
            "content": message,
            "date": dateStr,
            "sender_email": safeCurrentUserEmail,
            "is_read": false,
            "name": name
        ]
        
        let value: [String: Any] = [
            "messages": [
                collectionMessage
            ]
        ]
        
        print("adding: \(conversationId)")
        
        database.child("\(conversationId)").setValue(value, withCompletionBlock: { error, _ in
            guard error == nil else {
                completion(false)
                return
            }
            completion(true)
        })
    }
    
    /// fetch and return all conversations for the user with passed email
    public func getAllConversations(for email: String, completion: @escaping (Result<[Conversation], Error>) -> Void) {
        database.child("\(email)/conversations").observe(.value, with: { snapshot in
            guard let value = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            let conversations: [Conversation] = value.compactMap({ dictionary in
                guard let conversationId = dictionary["id"] as? String,
                let name = dictionary["name"] as? String,
                let otherUserEmail = dictionary["other_user_email"] as? String,
                let latestMessage = dictionary["latest_message"] as? [String: Any],
                let date = latestMessage["date"] as? String,
                let message = latestMessage["message"] as? String,
                let isRead = latestMessage["is_read"] as? Bool
                else { return nil }
                
                let latestMessageObj = LatestMessage(date: date, text: message, isRead: isRead)
                
                return Conversation(id: conversationId, name: name, otherUserEmail: otherUserEmail, latesrMessage: latestMessageObj)
            })
            
            completion(.success(conversations))
        })
    }
    
    // get all message for a given conversation
    public func getAllMessagesForConversation(with id: String, completion: @escaping (Result<[UserMessage], Error>) -> Void) {
        database.child("\(id)/messages").observe(.value, with: { snapshot in
            guard let value = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            let messages: [UserMessage] = value.compactMap({ dictionary in
                guard let name = dictionary["name"] as? String,
                    let isRead = dictionary["is_read"] as? Bool,
                    let messageID = dictionary["id"] as? String,
                    let content = dictionary["content"] as? String,
                    let senderEmail = dictionary["sender_email"] as? String,
                    let type = dictionary["type"] as? String,
                    let dateString = dictionary["date"] as? String,
                    let date = Utils.dateFormatter.date(from: dateString) else { return nil }
                
                let sender = Sender(photoURL: "", senderId: senderEmail, displayName: name)
                return UserMessage(sender: sender, messageId: messageID, sentDate: date, kind: .text(content))
            })
            
            completion(.success(messages))
        })
    }
    
    /// send a message with target conversation and message
    public func sendMessage(to conversation: String, message: UserMessage, completion: @escaping (Bool) -> Void) {
        
    }
}

extension DatabaseManager {
    public func getDataFor(path: String, completion: @escaping (Result<Any, Error>) -> Void) {
        database.child("\(path)").observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(value))
        }
    }
}
