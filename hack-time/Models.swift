//
//  Models.swift
//  hack-time
//
//  Created by Thomas Stubblefield on 10/29/24.
//

import SwiftUI

// Auth Models
struct TokenResponse: Codable {
    let token: String
}

struct User: Codable {
    let email: String
    let name: String
    var profilePictureUrl: String?
    let token: String
    var events: [String: Event]
    
    enum CodingKeys: String, CodingKey {
        case email
        case name
        case profilePictureUrl = "profile_picture_url"
        case token
        case events
    }
}

struct ProfilePictureResponse: Codable {
    let profilePictureUrl: String
}

enum AuthError: Error {
    case invalidCredentials
    case emailInUse
    case invalidToken
    case invalidResponse
    case serverError
    case invalidCode
}

// Event Models
struct Event: Codable {
    let id: String
    let title: String
    let owner: String
    let calendar_events: [APICalendarEvent]
    let teamMembers: [TeamMember]
    var tasks: [EventTask]
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case owner
        case calendar_events = "calendar_events"
        case teamMembers
        case tasks
    }
}

struct TeamMember: Codable {
    let name: String
    let profilePicture: String?
    let email: String
    let roleDescription: String
}

struct CalendarEvent: Identifiable {
    let id: UUID
    var title: String
    var startTime: Date
    var endTime: Date
    var color: Color
    
    init(id: UUID = UUID(), title: String, startTime: Date, endTime: Date, color: Color) {
        self.id = id
        self.title = title
        self.startTime = startTime
        self.endTime = endTime
        self.color = color
    }
}

struct APICalendarEvent: Codable {
    let id: String
    let title: String
    let startTime: Date
    let endTime: Date
    let color: String
}

struct APICalendarEventResponse: Codable {
    let id: String
    let title: String
    let startTime: Date
    let endTime: Date
    let color: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case startTime = "start_time"
        case endTime = "end_time"
        case color
    }
}

struct CreateCalendarEventRequest: Codable {
    let token: String
    let eventId: String
    let calendarEventId: String
    let title: String
    let startTime: Date
    let endTime: Date
    let color: String
}

struct CreateCalendarEventResponse: Codable {
    let id: String
    let title: String
    let startTime: Date
    let endTime: Date
    let color: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case startTime = "start_time"
        case endTime = "end_time"
        case color
    }
}

struct PartialCalendarEventResponse: Codable {
    let id: String
    let color: String?
    let title: String?
    let startTime: Date?
    let endTime: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case color
        case title
        case startTime = "start_time"
        case endTime = "end_time"
    }
}

struct ErrorResponse: Codable {
    let error: String
}

struct EventTask: Codable {
    let id: String
    var title: String
    var description: String
    var startTime: Date
    var endTime: Date
    let assignedTo: [AssignedUser]
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case startTime = "startTime"
        case endTime = "endTime"
        case assignedTo = "assignedTo"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        startTime = try container.decode(Date.self, forKey: .startTime)
        endTime = try container.decode(Date.self, forKey: .endTime)
        
        if let singleAssignee = try? container.decode(String.self, forKey: .assignedTo) {
            assignedTo = [AssignedUser(
                name: "New Assignee",
                profilePicture: nil,
                email: singleAssignee
            )]
        } else {
            assignedTo = try container.decode([AssignedUser].self, forKey: .assignedTo)
        }
    }
}

struct AssignedUser: Codable {
    let name: String
    let profilePicture: String?
    let email: String
}

// Add this extension to Event
extension Event {
    func tasksForUser(email: String) -> [EventTask] {
        return tasks.filter { task in
            task.assignedTo.contains { member in
                member.email == email
            }
        }
    }
}
