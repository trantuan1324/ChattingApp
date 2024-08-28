//
//  Utils.swift
//  ChattingApp
//
//  Created by Trần Quang Tuấn on 23/8/24.
//
import Foundation

final class Utils {
    static func convertedEmail(Email email: String) -> String {
        return email
            .replacingOccurrences(of: ".", with: "-")
            .replacingOccurrences(of: "@", with: "-")
    }
    
    public static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        return formatter
    }()
}
