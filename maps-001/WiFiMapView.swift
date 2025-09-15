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
    
    var filteredSpots: [WiFiSpot] {
        wifiManager.spots.filter { spot in
            selectedVenueTypes.contains(spot.venue.type) &&
            spot.averageSpeed >= minimumSpeed &&
            (requiredAmenities.isEmpty || !requiredAmenities.isDisjoint(with: spot.amenities))
        }
    }
    
    var body: some View {
        ZStack {
            Map(position: $position, selection: $selectedSpot) {
                UserAnnotation()
                
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
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
            }
            
            VStack {
                HStack {
                    Button(action: { showFilters.toggle() }) {
                        Label("Filters", systemImage: "line.3.horizontal.decrease.circle.fill")
                            .padding()
                            .background(.regularMaterial)
                            .cornerRadius(10)
                    }
                    
                    Spacer()
                    
                    Button(action: { showSpeedTest = true }) {
                        Label("Test WiFi", systemImage: "wifi")
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
            WiFiSpeedTestView(onComplete: { measurement in
                wifiManager.addMeasurement(measurement)
                showSpeedTest = false
            })
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
    let onComplete: (WiFiMeasurement) -> Void
    @StateObject private var speedTest = NetworkSpeedTest()
    @Environment(\.dismiss) var dismiss
    
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
        speedTest.runSpeedTest { measurement in
            onComplete(measurement)
            dismiss()
        }
    }
}

class WiFiSpotManager: ObservableObject {
    @Published var spots: [WiFiSpot] = []
    
    func loadNearbySpots() {
        // Simulate loading spots - in production, fetch from backend
        spots = generateSampleSpots()
    }
    
    func addMeasurement(_ measurement: WiFiMeasurement) {
        // Add new measurement to nearest spot
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

#Preview {
    WiFiMapView()
}