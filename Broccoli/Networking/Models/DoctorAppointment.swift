//
//  DoctorAppointment.swift
//  Broccoli
//
//  Created by AI Assistant on 16/10/25.
//

import Foundation

enum AppointmentStatus: String, Codable {
    case pending
    case scheduled
    case completed
    case cancelled
}

struct DoctorAppointment: Identifiable, Codable {
    let id: Int
    let patientName: String
    let patientAvatar: String
    let startTime: String
    let endTime: String
    var status: AppointmentStatus
}
