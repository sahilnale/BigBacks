import SwiftUI
import MapKit

class RestaurantSearchViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var searchQuery: String = ""
    @Published var places: [MKMapItem] = []
    
    private let locationManager = CLLocationManager()
    private var userLocation: CLLocationCoordinate2D?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    // CLLocationManagerDelegate to get user location
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last?.coordinate {
            userLocation = location
            if places.isEmpty {
                searchNearby(query: "")
            }
        }
    }
    
    func searchNearby(query: String) {
        guard let userLocation = userLocation else { return }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query.isEmpty ? "Restaurant OR Bar OR Food" : query
        request.region = MKCoordinateRegion(
            center: userLocation,
            latitudinalMeters: 5000,
            longitudinalMeters: 5000
        )
        
        let search = MKLocalSearch(request: request)
        search.start { [weak self] response, error in
            if let error = error {
                print("Search error: \(error.localizedDescription)")
                return
            }
            
            DispatchQueue.main.async {
                self?.places = response?.mapItems.prefix(10).map { $0 } ?? []
            }
        }
    }
}

struct RestaurantSearchView: View {
    @StateObject private var viewModel = RestaurantSearchViewModel()
    @Environment(\.dismiss) private var dismiss // Add dismiss environment variable

    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                HStack {
                    TextField("Search for food, bars, restaurants...", text: $viewModel.searchQuery)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .onChange(of: viewModel.searchQuery) { newValue in
                            viewModel.searchNearby(query: newValue)
                        }
                    
                    Button(action: {
                        viewModel.searchNearby(query: viewModel.searchQuery)
                    }) {
                        Image(systemName: "magnifyingglass")
                            .padding()
                    }
                }
                .padding()
                
                // List of results
                if viewModel.places.isEmpty {
                    Text("Showing preview data...")
                        .italic()
                        .foregroundColor(.gray)
                        .padding()
                    
                    // Mock preview list
                    List {
                        Text("Preview Restaurant 1 - 123 Main St")
                        Text("Preview Restaurant 2 - 456 Market St")
                        Text("Preview Restaurant 3 - 789 Broadway Ave")
                    }
                } else {
                    List(viewModel.places, id: \.self) { place in
                        VStack(alignment: .leading) {
                            Text(place.name ?? "Unknown Place")
                                .font(.headline)
                            if let address = place.placemark.title {
                                Text(address)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Find Nearby Places")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss() // Dismiss the view
                    }) {
                        Image(systemName: "arrow.left")
                            .foregroundColor(.accentColor)
                    }
                }
            }
        }
    }
}

// MARK: - Preview
struct RestaurantSearchView_Previews: PreviewProvider {
    static var previews: some View {
        // Static preview with mock data
        RestaurantSearchView()
    }
}
