//
//  WiFiMapView.swift
//  maps-001
//
//  WiFi quality map visualization
//

import SwiftUI
import MapKit
import CoreLocation

struct WiFiMapView: View {
    @StateObject private var wifiManager = WiFiSpotManager()
    @State private var position = MapCameraPosition.userLocation(fallback: .automatic)
    @State private var selectedSpot: WiFiSpot?
    @State private var showFilters = false
    @State private var selectedVenueTypes: Set<VenueType> = Set(VenueType.allCases)
    @State private var requiredAmenities: Set<Amenity> = []
    @State private var minimumSpeed: Double = 0
    @State private var showOnlyOpen = false
    @State private var showSpeedTest = false
    @State private var isContributing = false
    @State private var droppedPin: CLLocationCoordinate2D?
    @State private var showPinOptions = false
    @State private var selectedFloor = 1
    @State private var buildingName = ""
    
    var filteredSpots: [WiFiSpot] {
        wifiManager.spots.filter { spot in
            selectedVenueTypes.contains(spot.venue.type) &&
            spot.averageSpeed >= minimumSpeed &&
            (requiredAmenities.isEmpty || !requiredAmenities.isDisjoint(with: spot.amenities))
        }
    }
    
    var body: some View {
        ZStack {
            MapReader { proxy in
                Map(position: $position, selection: $selectedSpot) {
                    UserAnnotation()
                    
                    // Show dropped pin for new measurement
                    if let droppedPin = droppedPin {
                        Annotation("New Measurement", coordinate: droppedPin) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.title)
                                .foregroundColor(.blue)
                                .background(Circle().fill(.white).frame(width: 30, height: 30))
                        }
                    }
                    
                    ForEach(filteredSpots) { spot in
                        Annotation(spot.venue.name, coordinate: spot.coordinate) {
                            WiFiSpotMarker(spot: spot)
                                .onTapGesture {
                                    selectedSpot = spot
                                }
                        }
                        .tag(spot)
                        
                        // Add heatmap overlay for each spot
                        MapCircle(center: spot.coordinate, radius: 50)
                            .foregroundStyle((spot.rating > 0.7 ? Color.green : spot.rating > 0.4 ? Color.yellow : Color.red).opacity(0.3))
                            .stroke((spot.rating > 0.7 ? Color.green : spot.rating > 0.4 ? Color.yellow : Color.red).opacity(0.5), lineWidth: 1)
                    }
                }
                .onLongPressGesture(minimumDuration: 0.5) { location in
                    // Convert screen location to map coordinate
                    if let coordinate = proxy.convert(location, from: .local) {
                        droppedPin = coordinate
                        showPinOptions = true
                    }
                }
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                    MapScaleView()
                }
            }
            
            VStack {
                // Instruction banner
                if droppedPin == nil {
                    HStack {
                        Image(systemName: "hand.tap.fill")
                            .foregroundColor(.blue)
                        Text("Long press on map to add WiFi measurement")
                            .font(.caption)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(.thinMaterial)
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .padding(.top)
                }
                
                HStack {
                    Button(action: { showFilters.toggle() }) {
                        Label("Filters", systemImage: "line.3.horizontal.decrease.circle.fill")
                            .padding()
                            .background(.regularMaterial)
                            .cornerRadius(10)
                    }
                    
                    Spacer()
                    
                    Button(action: { 
                        // Test at current location
                        droppedPin = nil
                        showSpeedTest = true 
                    }) {
                        Label("Test Here", systemImage: "location.fill")
                            .padding()
                            .background(.regularMaterial)
                            .cornerRadius(10)
                    }
                }
                .padding()
                
                Spacer()
                
                if let selectedSpot = selectedSpot {
                    WiFiSpotDetailCard(spot: selectedSpot, onClose: {
                        self.selectedSpot = nil
                    })
                    .transition(.move(edge: .bottom))
                }
            }
        }
        .sheet(isPresented: $showFilters) {
            WiFiFilterView(
                selectedVenueTypes: $selectedVenueTypes,
                requiredAmenities: $requiredAmenities,
                minimumSpeed: $minimumSpeed,
                showOnlyOpen: $showOnlyOpen
            )
        }
        .sheet(isPresented: $showSpeedTest) {
            WiFiSpeedTestView(
                coordinate: droppedPin,
                floor: selectedFloor,
                buildingName: buildingName,
                onComplete: { measurement in
                    wifiManager.addMeasurement(measurement)
                    showSpeedTest = false
                    droppedPin = nil // Clear the pin after saving
                }
            )
        }
        .sheet(isPresented: $showPinOptions) {
            PinOptionsView(
                coordinate: droppedPin ?? CLLocationCoordinate2D(),
                floor: $selectedFloor,
                buildingName: $buildingName,
                onTestWiFi: {
                    showPinOptions = false
                    showSpeedTest = true
                },
                onCancel: {
                    showPinOptions = false
                    droppedPin = nil
                }
            )
        }
        .onAppear {
            wifiManager.loadNearbySpots()
        }
    }
}

struct WiFiSpotMarker: View {
    let spot: WiFiSpot
    
    var body: some View {
        ZStack {
            Circle()
                .fill(spot.rating > 0.7 ? Color.green : spot.rating > 0.4 ? Color.yellow : Color.red)
                .frame(width: 30, height: 30)
            
            Image(systemName: spot.venue.type.icon)
                .foregroundColor(.white)
                .font(.system(size: 16))
        }
    }
}

struct WiFiSpotDetailCard: View {
    let spot: WiFiSpot
    let onClose: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(spot.venue.name)
                        .font(.headline)
                    Text(spot.venue.type.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
            
            HStack(spacing: 20) {
                VStack {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(.blue)
                    Text("\(String(format: "%.1f", spot.averageSpeed)) Mbps")
                        .font(.caption)
                    Text("Download")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Image(systemName: "wifi")
                        .foregroundColor(spot.reliability > 70 ? Color.green : spot.reliability > 40 ? Color.yellow : Color.red)
                    Text("\(Int(spot.reliability))%")
                        .font(.caption)
                    Text("Reliability")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Image(systemName: "person.3.fill")
                        .foregroundColor(.purple)
                    Text("\(spot.measurements.count)")
                        .font(.caption)
                    Text("Reports")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            if !spot.amenities.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(Array(spot.amenities), id: \.self) { amenity in
                            Label(amenity.rawValue, systemImage: amenity.icon)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(5)
                        }
                    }
                }
            }
            
            HStack {
                Button(action: {}) {
                    Label("Directions", systemImage: "arrow.triangle.turn.up.right.circle.fill")
                }
                .buttonStyle(.borderedProminent)
                
                Button(action: {}) {
                    Label("View Details", systemImage: "info.circle")
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(15)
        .padding()
    }
}

struct WiFiFilterView: View {
    @Binding var selectedVenueTypes: Set<VenueType>
    @Binding var requiredAmenities: Set<Amenity>
    @Binding var minimumSpeed: Double
    @Binding var showOnlyOpen: Bool
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Venue Types") {
                    ForEach(VenueType.allCases, id: \.self) { type in
                        Toggle(isOn: Binding(
                            get: { selectedVenueTypes.contains(type) },
                            set: { isSelected in
                                if isSelected {
                                    selectedVenueTypes.insert(type)
                                } else {
                                    selectedVenueTypes.remove(type)
                                }
                            }
                        )) {
                            Label(type.rawValue, systemImage: type.icon)
                        }
                    }
                }
                
                Section("Required Amenities") {
                    ForEach(Amenity.allCases, id: \.self) { amenity in
                        Toggle(isOn: Binding(
                            get: { requiredAmenities.contains(amenity) },
                            set: { isSelected in
                                if isSelected {
                                    requiredAmenities.insert(amenity)
                                } else {
                                    requiredAmenities.remove(amenity)
                                }
                            }
                        )) {
                            Label(amenity.rawValue, systemImage: amenity.icon)
                        }
                    }
                }
                
                Section("Minimum Speed") {
                    VStack {
                        Text("\(Int(minimumSpeed)) Mbps")
                        Slider(value: $minimumSpeed, in: 0...100, step: 5)
                    }
                }
                
                Section("Hours") {
                    Toggle("Show Only Open Now", isOn: $showOnlyOpen)
                }
            }
            .navigationTitle("Filter WiFi Spots")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct WiFiSpeedTestView: View {
    let coordinate: CLLocationCoordinate2D?
    let floor: Int
    let buildingName: String
    let onComplete: (WiFiMeasurement) -> Void
    @StateObject private var speedTest = NetworkSpeedTest()
    @Environment(\.dismiss) var dismiss
    @State private var testCompleted = false
    @State private var lastMeasurement: WiFiMeasurement?
    @State private var autoSaveTimer: Timer?
    @State private var seatDescription = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                if speedTest.isTestRunning {
                    VStack(spacing: 20) {
                        ProgressView("Testing WiFi Speed...")
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(1.5)
                        
                        ProgressView(value: speedTest.testProgress)
                            .progressViewStyle(.linear)
                            .padding(.horizontal)
                        
                        Text("\(Int(speedTest.testProgress * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    VStack(spacing: 20) {
                        HStack(spacing: 30) {
                            VStack {
                                Image(systemName: "arrow.down.circle.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(.blue)
                                Text("\(String(format: "%.1f", speedTest.downloadSpeed))")
                                    .font(.title)
                                Text("Mbps")
                                    .font(.caption)
                            }
                            
                            VStack {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(.green)
                                Text("\(String(format: "%.1f", speedTest.uploadSpeed))")
                                    .font(.title)
                                Text("Mbps")
                                    .font(.caption)
                            }
                            
                            VStack {
                                Image(systemName: "timer")
                                    .font(.largeTitle)
                                    .foregroundColor(.orange)
                                Text("\(Int(speedTest.latency))")
                                    .font(.title)
                                Text("ms")
                                    .font(.caption)
                            }
                        }
                        
                        if testCompleted, let measurement = lastMeasurement {
                            VStack(spacing: 15) {
                                Text("Auto-saving in 3 seconds...")
                                    .font(.headline)
                                    .foregroundColor(.green)
                                
                                // Location info
                                if let coord = coordinate {
                                    VStack(alignment: .leading, spacing: 5) {
                                        if !buildingName.isEmpty {
                                            Text("Building: \(buildingName)")
                                                .font(.caption)
                                        }
                                        Text("Floor: \(floor)")
                                            .font(.caption)
                                        Text("Lat: \(String(format: "%.6f", coord.latitude))")
                                            .font(.caption2)
                                        Text("Lon: \(String(format: "%.6f", coord.longitude))")
                                            .font(.caption2)
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                                }
                                
                                TextField("Add location details (optional)", text: $seatDescription)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.caption)
                                
                                HStack(spacing: 15) {
                                    Button(action: runSpeedTest) {
                                        Label("Test Again", systemImage: "arrow.clockwise")
                                    }
                                    .buttonStyle(.bordered)
                                    
                                    Button(action: {
                                        saveAndDismiss()
                                    }) {
                                        Label("Save Now", systemImage: "checkmark.circle.fill")
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                            }
                        } else {
                            Button(action: runSpeedTest) {
                                Label("Start Test", systemImage: "play.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            .disabled(speedTest.isTestRunning)
                        }
                    }
                }
            }
            .padding()
            .navigationTitle("WiFi Speed Test")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    func runSpeedTest() {
        testCompleted = false
        // Cancel any existing timer
        autoSaveTimer?.invalidate()
        
        speedTest.runSpeedTest { measurement in
            // Update measurement with location data
            var updatedMeasurement = measurement
            updatedMeasurement.exactLocation = coordinate.map { SeatLocation(
                latitude: $0.latitude,
                longitude: $0.longitude,
                floor: floor,
                section: buildingName.isEmpty ? nil : buildingName,
                seatNumber: seatDescription.isEmpty ? nil : seatDescription
            )}
            updatedMeasurement.seatDescription = seatDescription.isEmpty ? "Floor \(floor)" : seatDescription
            
            lastMeasurement = updatedMeasurement
            testCompleted = true
            
            // Auto-save after 3 seconds
            autoSaveTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
                saveAndDismiss()
            }
        }
    }
    
    func saveAndDismiss() {
        autoSaveTimer?.invalidate()
        if var measurement = lastMeasurement {
            // Update with final seat description if changed
            measurement.seatDescription = seatDescription.isEmpty ? "Floor \(floor)" : seatDescription
            onComplete(measurement)
        }
        dismiss()
    }
}

class WiFiSpotManager: ObservableObject {
    @Published var spots: [WiFiSpot] = []
    @Published var userMeasurements: [WiFiMeasurement] = []
    
    func loadNearbySpots() {
        // Simulate loading spots - in production, fetch from backend
        spots = generateSampleSpots()
    }
    
    func addMeasurement(_ measurement: WiFiMeasurement) {
        // Store user measurement
        userMeasurements.append(measurement)
        
        // Find or create spot for this location
        if let location = measurement.exactLocation {
            let coordinate = CLLocationCoordinate2D(
                latitude: location.latitude,
                longitude: location.longitude
            )
            
            // Check if there's an existing spot nearby (within 50 meters)
            if let existingSpotIndex = spots.firstIndex(where: { spot in
                let distance = CLLocation(latitude: spot.coordinate.latitude, longitude: spot.coordinate.longitude)
                    .distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
                return distance < 50
            }) {
                // Add to existing spot
                spots[existingSpotIndex].measurements.append(measurement)
            } else {
                // Create new spot
                let newSpot = WiFiSpot(
                    coordinate: coordinate,
                    venue: Venue(
                        name: location.section ?? "User Added Location",
                        type: .other,
                        address: "Floor \(location.floor)",
                        hours: [],
                        hasPassword: false,
                        passwordHint: nil,
                        floorPlan: nil
                    ),
                    measurements: [measurement],
                    amenities: []
                )
                spots.append(newSpot)
            }
        }
        
        print("Measurement saved: \(measurement.downloadSpeed) Mbps at \(measurement.seatDescription ?? "unknown location")")
    }
    
    private func generateSampleSpots() -> [WiFiSpot] {
        [
            WiFiSpot(
                coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                venue: Venue(
                    name: "Blue Bottle Coffee",
                    type: .cafe,
                    address: "123 Market St",
                    hours: [],
                    hasPassword: true,
                    passwordHint: "Ask at counter",
                    floorPlan: nil
                ),
                measurements: [
                    WiFiMeasurement(timestamp: Date(), downloadSpeed: 45, uploadSpeed: 20, ping: 15, signalStrength: 85, exactLocation: nil, seatDescription: "Window seat", userId: "user1"),
                    WiFiMeasurement(timestamp: Date(), downloadSpeed: 50, uploadSpeed: 25, ping: 12, signalStrength: 90, exactLocation: nil, seatDescription: "Back corner", userId: "user2")
                ],
                amenities: [.powerOutlets, .coffee, .quietSpace]
            ),
            WiFiSpot(
                coordinate: CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4094),
                venue: Venue(
                    name: "SF Public Library",
                    type: .library,
                    address: "100 Larkin St",
                    hours: [],
                    hasPassword: false,
                    passwordHint: nil,
                    floorPlan: nil
                ),
                measurements: [
                    WiFiMeasurement(timestamp: Date(), downloadSpeed: 75, uploadSpeed: 50, ping: 8, signalStrength: 95, exactLocation: nil, seatDescription: "3rd floor study room", userId: "user3")
                ],
                amenities: [.powerOutlets, .quietSpace, .printer, .airConditioning]
            )
        ]
    }
}

// Pin Options View for location selection
struct PinOptionsView: View {
    let coordinate: CLLocationCoordinate2D
    @Binding var floor: Int
    @Binding var buildingName: String
    let onTestWiFi: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("📍 New WiFi Measurement")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                VStack(alignment: .leading, spacing: 15) {
                    // Building name
                    VStack(alignment: .leading) {
                        Text("Building/Venue Name")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("e.g., Starbucks Main St", text: $buildingName)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    // Floor selector
                    VStack(alignment: .leading) {
                        Text("Floor")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Picker("Floor", selection: $floor) {
                            Text("Basement").tag(-1)
                            Text("Ground").tag(0)
                            ForEach(1..<10) { level in
                                Text("Floor \(level)").tag(level)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    // Coordinates display
                    VStack(alignment: .leading) {
                        Text("Location")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Lat: \(String(format: "%.6f", coordinate.latitude))")
                            .font(.system(.caption, design: .monospaced))
                        Text("Lon: \(String(format: "%.6f", coordinate.longitude))")
                            .font(.system(.caption, design: .monospaced))
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                .padding()
                
                Spacer()
                
                VStack(spacing: 12) {
                    Button(action: onTestWiFi) {
                        Label("Test WiFi at this Location", systemImage: "wifi")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    
                    Button(action: onCancel) {
                        Text("Cancel")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    WiFiMapView()
}