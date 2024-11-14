import SwiftUI
import MapKit

//struct MapView: View {
//    @State private var region = MKCoordinateRegion(
//        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
//        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
//    )
//    
//    var body: some View {
//        Map(coordinateRegion: $region)
//            .edgesIgnoringSafeArea(.all)
//            .overlay(
//                Button(action: {
//                    // Add new post
//                }) {
//                    Image(systemName: "plus.circle.fill")
//                        .font(.system(size: 44))
//                        .foregroundColor(.accentColor)
//                        .background(Color.white)
//                        .clipShape(Circle())
//                        .shadow(radius: 4)
//                }
//                .padding(),
//                alignment: .bottomTrailing
//            )
//    }
//}


class MapViewModel: UIViewController {
    private let map: MKMapView = {
        let map = MKMapView()
        map.showsUserLocation = true
        map.userTrackingMode = .followWithHeading // Keeps the user's location centered on the map
        return map
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(map)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        map.frame = view.bounds
    }
}

struct MapView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> MapViewModel {
        return MapViewModel()
    }

    func updateUIViewController(_ uiViewController: MapViewModel, context: Context) {
        // Handle any updates to the view controller here
    }
}

