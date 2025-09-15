//
//  WiFiModels.swift
//  maps-001
//
//  WiFi quality mapping models
//

import Foundation
import CoreLocation
import MapKit

struct WiFiSpot: Identifiable, Equatable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let venue: Venue
    let measurements: [WiFiMeasurement]
    let amenities: Set<Amenity>
    
    var averageSpeed: Double {
        guard !measurements.isEmpty else { return 0 }
        return measurements.map { $0.downloadSpeed }.reduce(0, +) / Double(measurements.count)
    }
    
    var reliability: Double {
        guard !measurements.isEmpty else { return 0 }
        return measurements.map { $0.signalStrength }.reduce(0, +) / Double(measurements.count)
    }
    
    var rating: Double {
        (averageSpeed / 100.0) * 0.6 + (reliability / 100.0) * 0.4
    }
}

struct Venue: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let type: VenueType
    let address: String
    let hours: [DayHours]
    let hasPassword: Bool
    let passwordHint: String?
    let floorPlan: FloorPlan?
}

struct WiFiMeasurement: Identifiable {
    let id = UUID()
    let timestamp: Date
    let downloadSpeed: Double // Mbps
    let uploadSpeed: Double // Mbps
    let ping: Double // ms
    let signalStrength: Double // 0-100
    let exactLocation: CLLocationCoordinate2D?
    let seatDescription: String?
    let userId: String
}

struct FloorPlan {
    let imageURL: URL?
    let seatLocations: [SeatLocation]
}

struct SeatLocation: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    let measurements: [WiFiMeasurement]
    
    var quality: WiFiQuality {
        guard !measurements.isEmpty else { return .unknown }
        let avgSpeed = measurements.map { $0.downloadSpeed }.reduce(0, +) / Double(measurements.count)
        
        switch avgSpeed {
        case 50...: return .excellent
        case 25..<50: return .good
        case 10..<25: return .fair
        case 1..<10: return .poor
        default: return .terrible
        }
    }
}

struct DayHours {
    let dayOfWeek: Int // 1-7
    let openTime: Date?
    let closeTime: Date?
    let isClosed: Bool
}

enum VenueType: String, CaseIterable {
    case cafe = "Cafe"
    case library = "Library"
    case coworking = "Coworking"
    case restaurant = "Restaurant"
    case university = "University"
    case publicSpace = "Public Space"
    case hotel = "Hotel"
    
    var icon: String {
        switch self {
        case .cafe: return "cup.and.saucer.fill"
        case .library: return "books.vertical.fill"
        case .coworking: return "building.2.fill"
        case .restaurant: return "fork.knife"
        case .university: return "graduationcap.fill"
        case .publicSpace: return "tree.fill"
        case .hotel: return "bed.double.fill"
        }
    }
}

enum Amenity: String, CaseIterable {
    case powerOutlets = "Power Outlets"
    case quietSpace = "Quiet Space"
    case outdoorSeating = "Outdoor Seating"
    case parking = "Parking"
    case food = "Food Available"
    case coffee = "Coffee"
    case printer = "Printer"
    case meetingRooms = "Meeting Rooms"
    case standingDesks = "Standing Desks"
    case airConditioning = "AC"
    
    var icon: String {
        switch self {
        case .powerOutlets: return "powerplug.fill"
        case .quietSpace: return "speaker.slash.fill"
        case .outdoorSeating: return "sun.max.fill"
        case .parking: return "car.fill"
        case .food: return "fork.knife"
        case .coffee: return "cup.and.saucer.fill"
        case .printer: return "printer.fill"
        case .meetingRooms: return "person.3.fill"
        case .standingDesks: return "desktopcomputer"
        case .airConditioning: return "snowflake"
        }
    }
}

enum WiFiQuality {
    case excellent
    case good
    case fair
    case poor
    case terrible
    case unknown
    
    var color: String {
        switch self {
        case .excellent: return "green"
        case .good: return "blue"
        case .fair: return "yellow"
        case .poor: return "orange"
        case .terrible: return "red"
        case .unknown: return "gray"
        }
    }
    
    var description: String {
        switch self {
        case .excellent: return "Excellent (50+ Mbps)"
        case .good: return "Good (25-50 Mbps)"
        case .fair: return "Fair (10-25 Mbps)"
        case .poor: return "Poor (1-10 Mbps)"
        case .terrible: return "Terrible (<1 Mbps)"
        case .unknown: return "No data"
        }
    }
}