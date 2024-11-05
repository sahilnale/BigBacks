import MapKit

struct Restaurant: Identifiable {
    let id = UUID()
    let name: String
    let rating: Double
    let image: String
    let coordinate: CLLocationCoordinate2D
}

