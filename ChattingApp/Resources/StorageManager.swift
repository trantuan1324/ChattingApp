//
//  StorageManager.swift
//  ChattingApp
//
//  Created by Trần Quang Tuấn on 24/8/24.
//

import Foundation
import FirebaseStorage

final class StorageManager {
    
    static let shared = StorageManager()
    
    private let storage = Storage.storage().reference()
    
    typealias uploadPictureCompletion = (Result<String, Error>) -> Void
    
    /// Upload picture to firebase storage and return an URL to download picture
    func uploadProfilePicture(with data: Data, fileName: String, completion: @escaping uploadPictureCompletion) {
        self.storage.child("images/\(fileName)").putData(data, metadata: nil, completion: { metadata, error in
            guard error == nil else {
                print("Upload image failed")
                completion(.failure(StorageError.failedToUpload))
                return
            }
            
            self.storage.child("images/\(fileName)").downloadURL(completion: { url, error in
                guard let url = url else {
                    print("Download image failed")
                    completion(.failure(StorageError.failedToDownload))
                    return
                }
                
                let urlString = url.absoluteString
                print("returned url: \(urlString)")
                completion(.success(urlString))
            })
        })
    }
    
    public func downloadURL(for path: String, completion: @escaping(Result<URL, Error>)-> Void) {
        let reference = storage.child(path)
        
        reference.downloadURL() { url, error in
            guard let url = url, error == nil else {
                completion(.failure(StorageError.failedToDownload))
                return
            }
            
            completion(.success(url))
        }
    }
}

public enum StorageError: Error {
    case failedToUpload
    case failedToDownload
}
