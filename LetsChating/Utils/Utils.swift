//
//  Utils.swift
//  LetsChating
//
//  Created by Matias Gonzalez Portiglia on 08/06/2023.
//

import Foundation

extension Date {
    func timeAgoDisplay() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    func relativeDate() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

final class Utils {
    
    static func formatDateMessage(_ timestamp: Date?) -> String {
        var calendar = Calendar.current
        if let timeZone = TimeZone(identifier: "ARG") {
            calendar.timeZone = timeZone
        }
        
        guard let timestamp = timestamp else { return "" }
        
        let hour = calendar.component(.hour, from: timestamp)
        let minute = calendar.component(.minute, from: timestamp)
        
        return String(format: "%02d:%02d", hour, minute)
        
    }
    
    static func formatDateTimeAgo(_ timestamp: Date?) -> String {
        guard let timestamp = timestamp else { return "" }
        
        return timestamp.timeAgoDisplay()
    }
    
    static func todayIsGratherThan(_ timestamp: Date?) -> Bool {
        
        guard let timestamp = timestamp
        else { return false }
        
        let today = Date()
        
        var calendarToday = Calendar.current
        var calendarMessage = Calendar.current
        
        if let timeZone = TimeZone(identifier: "ARG") {
            calendarToday.timeZone = timeZone
            calendarMessage.timeZone = timeZone
        }
        
        let dayT = calendarToday.component(.day, from: today)
        let monthT = calendarToday.component(.month, from: today)
        let yearT = calendarToday.component(.year, from: today)
        
        let dayM = calendarMessage.component(.day, from: timestamp)
        let monthM = calendarMessage.component(.month, from: timestamp)
        let yearM = calendarMessage.component(.year, from: timestamp)
        
        let dateTodayConcat = Int("\(dayT)\(monthT)\(yearT)")!
        let dateMessageConcat = Int("\(dayM)\(monthM)\(yearM)")!
        
        if dateTodayConcat > dateMessageConcat {
            return true
        }
        
        return false
    }
    
    static func formatDate(timestamp: Date?) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        if let timestamp = timestamp {
            let dateString = dateFormatter.string(from: timestamp)
            return dateString
        }
        return ""
    }
}
