# iOS Maps Demo

A native iOS maps application built with SwiftUI and MapKit, demonstrating Apple Maps integration without requiring external dependencies or API keys.

## Features

- 🗺️ **Interactive Maps** - Full-screen map with smooth pan, zoom, and rotation
- 📍 **User Location** - Real-time location tracking with permission handling
- 🔍 **Place Search** - Search for locations, businesses, and points of interest
- 🧭 **Turn-by-Turn Directions** - Route planning from current location to destination
- 🎛️ **Map Controls** - Compass, scale, pitch toggle, and user location button
- 📱 **Native iOS** - Built with SwiftUI for modern iOS devices

## Screenshots

<img width="300" alt="Map View" src="https://github.com/user-attachments/assets/placeholder">

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Installation

1. Clone the repository:
```bash
git clone https://github.com/ebowwa/ios-maps-demo.git
cd ios-maps-demo
```

2. Open in Xcode:
```bash
open maps-001.xcodeproj
```

3. Configure Location Permissions:
   - Select your project in Xcode
   - Go to the Info tab
   - Add `Privacy - Location When In Use Usage Description`
   - Set value: "This app needs your location to show your position on the map and provide directions"

4. Build and run on simulator or device

## Usage

### Basic Navigation
- **Pan**: Drag to move around the map
- **Zoom**: Pinch to zoom in/out
- **Rotate**: Two-finger rotate gesture
- **3D View**: Two-finger drag up/down to adjust pitch

### Search for Places
1. Tap the search bar at the top
2. Enter a location or business name
3. Select from search results
4. Tap "Get Directions" for navigation

### User Location
- Tap the location button to center on your current position
- Location permission will be requested on first use
- Map automatically follows your location when enabled

## Key Components

### ContentView.swift
Main view containing:
- MapKit integration
- Search functionality
- Route calculation
- Location management

### Core Technologies
- **MapKit**: Apple's native mapping framework
- **CoreLocation**: Location services and permissions
- **SwiftUI**: Modern declarative UI framework
- **MKLocalSearch**: Place search API
- **MKDirections**: Route and directions API

## Features in Detail

### Location Services
```swift
@State private var position = MapCameraPosition.userLocation(fallback: .automatic)
```
Automatically centers on user location with fallback handling.

### Search Implementation
```swift
func searchPlaces() {
    let request = MKLocalSearch.Request()
    request.naturalLanguageQuery = searchText
    request.region = MKCoordinateRegion(...)
}
```
Natural language search with results displayed as map annotations.

### Directions
```swift
func getDirections() {
    let request = MKDirections.Request()
    request.source = MKMapItem.forCurrentLocation()
    request.destination = selectedResult
}
```
Calculates and displays routes with polyline overlays.

## Privacy

This app requires location permissions to:
- Show your current position on the map
- Provide directions from your location
- Search for nearby places

Location data is only used within the app and is not stored or transmitted.

## License

MIT License - See LICENSE file for details

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Acknowledgments

Built with Apple's MapKit framework, providing free native maps for iOS developers without requiring API keys or usage limits for native apps.

## Author

Created by Elijah Arbee

## Support

For issues, questions, or suggestions, please open an issue on GitHub.