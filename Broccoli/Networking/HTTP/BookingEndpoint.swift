//
//  BookingEndpoint.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 23/12/25.
//

import Foundation

// MARK: - Booking Endpoints
public enum BookingEndpoint: Endpoint {
    case availableTimeSlots(date: Date, isGP: String?, departmentId: String?, serviceId: String?)
    case createBooking([String: Any])
    case bookingDetails(String)
    case cancelBooking(String)
    case uploadDocument(bookingId: String, documentData: Data, fileName: String)
    case paymentInitialize([String: Any])
    case paymentConfirm([String: Any])
    case activeTreatments
    case treatmentDetails(String)
    case createPrescriptionOrder([String: Any])
    case initialisePrescriptionPayment(String)
    case confirmPrescriptionPayment(String)
    case loadServices(String)
    
    public var path: String {
        switch self {
        case .availableTimeSlots:
            return "/time-slots"
        case .createBooking:
            return "/bookings"
        case .bookingDetails(let bookingId):
            return "/api/bookings/\(bookingId)"
        case .cancelBooking(let bookingId):
            return "/api/bookings/\(bookingId)/cancel"
        case .uploadDocument(let bookingId, _, _):
            return "/api/bookings/\(bookingId)/documents"
        case .paymentInitialize:
            return "/payments/bookings/initialize"
        case .paymentConfirm:
            return "/payments/bookings/confirm"
        case .activeTreatments:
            return "/prescriptions/treatments"
        case .treatmentDetails(let treatment):
            return "/prescriptions/treatments/\(treatment)/questionnaire"
        case .createPrescriptionOrder:
            return "/prescriptions"
        case .initialisePrescriptionPayment(let prescription):
            return "/payments/prescriptions/\(prescription)/initialize"
        case .confirmPrescriptionPayment(let prescription):
            return "/payments/prescriptions/\(prescription)/confirm"
        case .loadServices(let department):
            return "/global/departments/\(department)/services"
        }
    }
    
    public var method: HTTPMethod {
        switch self {
        case .availableTimeSlots, .bookingDetails, .activeTreatments, .treatmentDetails, .loadServices:
            return .GET
        case .createBooking, .uploadDocument, .paymentInitialize, .paymentConfirm, .createPrescriptionOrder, .initialisePrescriptionPayment, .confirmPrescriptionPayment:
            return .POST
        case .cancelBooking:
            return .PUT
        }
    }
    
    public var body: [String: Any]? {
        switch self {
        case .createBooking(let data): 
            return data
        case .paymentInitialize(let data):
            return data
        case .paymentConfirm(let data):
            return data
        case .createPrescriptionOrder(let data):
            return data
        case .uploadDocument(_, let documentData, let fileName): 
            return nil
        default:
            return nil
        }
    }
    
    public var queryItems: [String: String]? {
        switch self {
        case .availableTimeSlots(let date, let isGP, let departmentId, let serviceId):
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            var items: [String: String] = [
                "date": formatter.string(from: date),
                "is_gp": isGP ?? "0"
            ]
            if let departmentId = departmentId {
                items["department_id"] = departmentId
            }
            if let serviceId = serviceId {
                items["service_id"] = serviceId
            }
            return items
        default:
            return nil
        }
    }
}
