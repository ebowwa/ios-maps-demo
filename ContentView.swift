import SwiftUI
import MapKit

struct ContentView: View {
    @State private var position = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
    )
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var selectedResult: MKMapItem?
    @State private var route: MKRoute?
    @State private var showUserLocation = true
    
    var body: some View {
        Map(position: $position, selection: $selectedResult) {
            if showUserLocation {
                UserAnnotation()
            }
            
            ForEach(searchResults, id: \.self) { item in
                if let location = item.placemark.location?.coordinate {
                    Marker(item.name ?? "Unknown", coordinate: location)
                        .tint(.red)
                        .tag(item)
                }
            }
            
            if let route {
                MapPolyline(route.polyline)
                    .stroke(.blue, lineWidth: 5)
            }
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
            MapPitchToggle()
        }
        .safeAreaInset(edge: .top) {
            VStack(spacing: 10) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search places...", text: $searchText)
                        .textFieldStyle(.plain)
                        .onSubmit {
                            searchPlaces()
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            searchResults = []
                            selectedResult = nil
                            route = nil
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()
                .background(.regularMaterial)
                .cornerRadius(10)
                .padding(.horizontal)
                
                if !searchResults.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(searchResults, id: \.self) { item in
                                Button(action: {
                                    selectPlace(item)
                                }) {
                                    VStack(alignment: .leading) {
                                        Text(item.name ?? "Unknown")
                                            .font(.headline)
                                        if let address = item.placemark.title {
                                            Text(address)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding()
                                    .background(selectedResult == item ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                if selectedResult != nil {
                    HStack {
                        Button("Get Directions") {
                            getDirections()
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("Clear Route") {
                            route = nil
                        }
                        .buttonStyle(.bordered)
                        .disabled(route == nil)
                    }
                    .padding(.horizontal)
                }
            }
        }
        .onChange(of: searchText) { _, _ in
            if searchText.isEmpty {
                searchResults = []
                selectedResult = nil
                route = nil
            }
        }
    }
    
    func searchPlaces() {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = MKCoordinateRegion(
            center: position.region?.center ?? CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        )
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let response = response else { return }
            searchResults = response.mapItems
            
            if let firstResult = searchResults.first {
                selectPlace(firstResult)
            }
        }
    }
    
    func selectPlace(_ item: MKMapItem) {
        selectedResult = item
        if let location = item.placemark.location?.coordinate {
            withAnimation {
                position = .region(MKCoordinateRegion(
                    center: location,
                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                ))
            }
        }
    }
    
    func getDirections() {
        guard let selectedResult = selectedResult else { return }
        
        let request = MKDirections.Request()
        request.source = MKMapItem.forCurrentLocation()
        request.destination = selectedResult
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            guard let response = response else { return }
            route = response.routes.first
            
            if let route = route {
                withAnimation {
                    position = .region(MKCoordinateRegion(route.polyline.boundingMapRect))
                }
            }
        }
    }
}

extension MapCameraPosition {
    var region: MKCoordinateRegion? {
        switch self {
        case .region(let region):
            return region
        default:
            return nil
        }
    }
}

#Preview {
    ContentView()
}