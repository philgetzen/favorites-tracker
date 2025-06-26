import SwiftUI
import MapKit
import CoreLocation

/// Location component for address input, map display, and GPS coordinates
struct LocationComponent: FormComponentProtocol {
    let definition: ComponentDefinition
    var value: Binding<CustomFieldValue?>
    
    @State private var locationText: String = ""
    @State private var coordinate: CLLocationCoordinate2D?
    @State private var validationResult: ComponentValidationResult = .valid
    @State private var showingMap = false
    @State private var isLoadingLocation = false
    @State private var searchResults: [MKMapItem] = []
    @State private var showingSearchResults = false
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // San Francisco default
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    @StateObject private var locationManager = LocationManager()
    
    var isValid: Bool { validationResult.isValid }
    var errorMessage: String? { validationResult.errorMessage }
    
    private var allowsCoordinates: Bool {
        let label = definition.label.lowercased()
        return label.contains("coordinates") || label.contains("gps") || label.contains("precise")
    }
    
    private var showMap: Bool {
        coordinate != nil || allowsCoordinates
    }
    
    init(definition: ComponentDefinition, value: Binding<CustomFieldValue?>) {
        self.definition = definition
        self.value = value
        
        // Initialize location from existing value
        if case .text(let text) = value.wrappedValue, !text.isEmpty {
            self._locationText = State(initialValue: text)
            
            // Try to parse coordinates if the format is "lat,lng:address"
            if let colonIndex = text.firstIndex(of: ":") {
                let coordPart = String(text[..<colonIndex])
                let addressPart = String(text[text.index(after: colonIndex)...])
                
                if let commaIndex = coordPart.firstIndex(of: ","),
                   let lat = Double(String(coordPart[..<commaIndex])),
                   let lng = Double(String(coordPart[coordPart.index(after: commaIndex)...])) {
                    self._coordinate = State(initialValue: CLLocationCoordinate2D(latitude: lat, longitude: lng))
                    self._locationText = State(initialValue: addressPart)
                }
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Label with required indicator
            HStack {
                Text(definition.label)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if definition.isRequired {
                    Text("*")
                        .foregroundColor(.red)
                        .font(.headline)
                }
                
                Spacer()
                
                // Location status indicator
                if coordinate != nil {
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text("Located")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            
            // Location input field
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "location")
                        .foregroundColor(.blue)
                    
                    TextField(placeholder, text: $locationText)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            searchLocation()
                        }
                    
                    if isLoadingLocation {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                
                // Location action buttons
                locationActionsView
            }
            
            // Map view
            if showMap {
                mapView
            }
            
            // Search results
            if showingSearchResults && !searchResults.isEmpty {
                searchResultsView
            }
            
            // Current coordinates display
            if let coordinate = coordinate, allowsCoordinates {
                coordinatesView(coordinate)
            }
            
            // Validation feedback
            if !validationResult.isValid, let errorMessage = validationResult.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                    
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .transition(.opacity)
            }
            
            // Helper text
            if let helperText = helperText, !helperText.isEmpty {
                Text(helperText)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            validateInput()
        }
        .onChange(of: locationText) { oldValue, newValue in
            if newValue.isEmpty {
                coordinate = nil
            }
            updateValue()
            validateInput()
        }
        .fullScreenCover(isPresented: $showingMap) {
            LocationMapView(
                region: $region,
                coordinate: $coordinate,
                locationText: $locationText,
                onLocationSelected: { coord, address in
                    coordinate = coord
                    locationText = address
                    updateValue()
                    validateInput()
                }
            )
        }
    }
    
    // MARK: - View Components
    
    private var locationActionsView: some View {
        HStack(spacing: 12) {
            // Current location button
            Button(action: {
                getCurrentLocation()
            }) {
                HStack {
                    Image(systemName: "location.circle")
                    Text("Current")
                }
                .foregroundColor(.blue)
                .font(.caption)
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(6)
            }
            .disabled(isLoadingLocation)
            
            // Search button
            Button(action: {
                searchLocation()
            }) {
                HStack {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }
                .foregroundColor(.green)
                .font(.caption)
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(Color.green.opacity(0.1))
                .cornerRadius(6)
            }
            .disabled(locationText.isEmpty || isLoadingLocation)
            
            // Map button
            Button(action: {
                showingMap = true
            }) {
                HStack {
                    Image(systemName: "map")
                    Text("Map")
                }
                .foregroundColor(.orange)
                .font(.caption)
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(6)
            }
            
            Spacer()
            
            // Clear button
            if !locationText.isEmpty || coordinate != nil {
                Button(action: {
                    clearLocation()
                }) {
                    Text("Clear")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
        }
    }
    
    private var mapView: some View {
        Map(coordinateRegion: .constant(mapRegion), annotationItems: mapAnnotations) { annotation in
            MapPin(coordinate: annotation.coordinate, tint: .red)
        }
        .frame(height: 200)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
        )
        .onTapGesture {
            showingMap = true
        }
    }
    
    private var searchResultsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Search Results")
                .font(.subheadline)
                .fontWeight(.medium)
            
            ForEach(Array(searchResults.prefix(5).enumerated()), id: \.offset) { index, item in
                Button(action: {
                    selectSearchResult(item)
                }) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.name ?? "Unknown Location")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        if let address = item.placemark.title {
                            Text(address)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private func coordinatesView(_ coordinate: CLLocationCoordinate2D) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Coordinates")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            HStack {
                Text("Lat: \(String(format: "%.6f", coordinate.latitude))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Lng: \(String(format: "%.6f", coordinate.longitude))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button(action: {
                    UIPasteboard.general.string = "\(coordinate.latitude),\(coordinate.longitude)"
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
    
    // MARK: - FormComponentProtocol
    
    func validate() -> ComponentValidationResult {
        guard let validationRule = definition.validation else {
            return .valid
        }
        
        // Check required field
        if validationRule.required && locationText.isEmpty {
            return .invalid("Please enter a location")
        }
        
        // Check minimum length
        if let minLength = validationRule.minLength, locationText.count < minLength {
            return .invalid("Location must be at least \(minLength) characters")
        }
        
        return .valid
    }
    
    // MARK: - Private Helpers
    
    private var placeholder: String {
        let label = definition.label.lowercased()
        
        if label.contains("address") {
            return "Enter address"
        } else if label.contains("city") {
            return "Enter city name"
        } else if label.contains("venue") {
            return "Enter venue name"
        }
        
        return "Enter location"
    }
    
    private var helperText: String? {
        let label = definition.label.lowercased()
        
        if label.contains("address") {
            return "Enter full address or search for a location"
        } else if label.contains("venue") {
            return "Enter venue name or select from map"
        } else if allowsCoordinates {
            return "Precise GPS coordinates will be saved"
        }
        
        return "Tap to search or use current location"
    }
    
    private var mapRegion: MKCoordinateRegion {
        if let coordinate = coordinate {
            return MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
        return region
    }
    
    private var mapAnnotations: [LocationAnnotation] {
        guard let coordinate = coordinate else { return [] }
        return [LocationAnnotation(coordinate: coordinate, title: locationText)]
    }
    
    private func getCurrentLocation() {
        isLoadingLocation = true
        
        locationManager.requestLocation { result in
            DispatchQueue.main.async {
                isLoadingLocation = false
                
                switch result {
                case .success(let location):
                    coordinate = location.coordinate
                    region = MKCoordinateRegion(
                        center: location.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )
                    
                    // Reverse geocode to get address
                    reverseGeocode(location.coordinate)
                    
                case .failure(let error):
                    print("Location error: \(error)")
                }
            }
        }
    }
    
    private func searchLocation() {
        guard !locationText.isEmpty else { return }
        
        isLoadingLocation = true
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = locationText
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            DispatchQueue.main.async {
                isLoadingLocation = false
                
                if let response = response {
                    searchResults = response.mapItems
                    showingSearchResults = true
                    
                    // If only one result, select it automatically
                    if response.mapItems.count == 1 {
                        selectSearchResult(response.mapItems[0])
                    }
                } else if let error = error {
                    print("Search error: \(error)")
                }
            }
        }
    }
    
    private func selectSearchResult(_ item: MKMapItem) {
        coordinate = item.placemark.coordinate
        locationText = item.placemark.title ?? item.name ?? locationText
        showingSearchResults = false
        
        region = MKCoordinateRegion(
            center: item.placemark.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        
        updateValue()
        validateInput()
    }
    
    private func reverseGeocode(_ coordinate: CLLocationCoordinate2D) {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            DispatchQueue.main.async {
                if let placemark = placemarks?.first {
                    let address = [
                        placemark.subThoroughfare,
                        placemark.thoroughfare,
                        placemark.locality,
                        placemark.administrativeArea,
                        placemark.postalCode
                    ].compactMap { $0 }.joined(separator: ", ")
                    
                    if !address.isEmpty {
                        locationText = address
                        updateValue()
                    }
                }
            }
        }
    }
    
    private func clearLocation() {
        locationText = ""
        coordinate = nil
        searchResults = []
        showingSearchResults = false
        updateValue()
        validateInput()
    }
    
    private func updateValue() {
        if locationText.isEmpty {
            value.wrappedValue = nil
        } else if let coordinate = coordinate {
            // Store format: "lat,lng:address"
            value.wrappedValue = .text("\(coordinate.latitude),\(coordinate.longitude):\(locationText)")
        } else {
            value.wrappedValue = .text(locationText)
        }
    }
    
    private func validateInput() {
        validationResult = validate()
    }
}

// MARK: - Supporting Views and Types

private struct LocationMapView: View {
    @Binding var region: MKCoordinateRegion
    @Binding var coordinate: CLLocationCoordinate2D?
    @Binding var locationText: String
    let onLocationSelected: (CLLocationCoordinate2D, String) -> Void
    
    @SwiftUI.Environment(\.dismiss) private var dismiss
    @State private var tempCoordinate: CLLocationCoordinate2D?
    
    var body: some View {
        NavigationView {
            ZStack {
                Map(coordinateRegion: $region, annotationItems: annotations) { annotation in
                    MapPin(coordinate: annotation.coordinate, tint: .red)
                }
                .onTapGesture { location in
                    // Convert tap location to coordinate
                    // This is a simplified implementation
                    let coordinate = region.center
                    tempCoordinate = coordinate
                    
                    // Reverse geocode the location
                    reverseGeocodeAndSelect(coordinate)
                }
                
                // Crosshair for center selection
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.red)
                        Spacer()
                    }
                    Spacer()
                }
                .allowsHitTesting(false)
            }
            .navigationTitle("Select Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Select Center") {
                        reverseGeocodeAndSelect(region.center)
                    }
                }
            }
        }
    }
    
    private var annotations: [LocationAnnotation] {
        if let coord = coordinate ?? tempCoordinate {
            return [LocationAnnotation(coordinate: coord, title: locationText)]
        }
        return []
    }
    
    private func reverseGeocodeAndSelect(_ coordinate: CLLocationCoordinate2D) {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            DispatchQueue.main.async {
                let address: String
                if let placemark = placemarks?.first {
                    address = [
                        placemark.subThoroughfare,
                        placemark.thoroughfare,
                        placemark.locality,
                        placemark.administrativeArea
                    ].compactMap { $0 }.joined(separator: ", ")
                } else {
                    address = "Selected Location"
                }
                
                onLocationSelected(coordinate, address)
                dismiss()
            }
        }
    }
}

private struct LocationAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let title: String
}

private class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var completion: ((Result<CLLocation, Error>) -> Void)?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestLocation(completion: @escaping (Result<CLLocation, Error>) -> Void) {
        self.completion = completion
        
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            completion(.failure(LocationError.accessDenied))
        @unknown default:
            completion(.failure(LocationError.unknown))
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        completion?(.success(location))
        completion = nil
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        completion?(.failure(error))
        completion = nil
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.requestLocation()
        } else if status == .denied || status == .restricted {
            completion?(.failure(LocationError.accessDenied))
            completion = nil
        }
    }
}

private enum LocationError: Error, LocalizedError {
    case accessDenied
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Location access denied. Please enable location services in Settings."
        case .unknown:
            return "Unknown location error occurred."
        }
    }
}

// MARK: - Preview Support

#if DEBUG
struct LocationComponent_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Basic location component
            LocationComponent(
                definition: ComponentDefinition(
                    id: "location",
                    type: .location,
                    label: "Location",
                    isRequired: true,
                    validation: ValidationRule(required: true)
                ),
                value: .constant(.text("123 Main St, San Francisco, CA"))
            )
            
            // Address component with coordinates
            LocationComponent(
                definition: ComponentDefinition(
                    id: "precise_location",
                    type: .location,
                    label: "GPS Coordinates",
                    isRequired: false,
                    validation: ValidationRule(minLength: 5)
                ),
                value: .constant(.text("37.7749,-122.4194:San Francisco, CA, USA"))
            )
            
            // Venue location component
            LocationComponent(
                definition: ComponentDefinition(
                    id: "venue",
                    type: .location,
                    label: "Venue Location",
                    isRequired: false
                ),
                value: .constant(nil)
            )
        }
        .padding()
    }
}
#endif