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

class MapViewModel: UIViewController{
    private let map: MKMapView = {
        let map = MKMapView()
        return map
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(map)
        
        LocationManager.shared.getUserLocation { [weak self] location in
            DispatchQueue.main.async {
                guard let strongSelf = self else { return }
                let pin = MKPointAnnotation()
                pin.coordinate = location.coordinate
                strongSelf.map.setRegion(MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)), animated: true)
                strongSelf.map.addAnnotation(pin)
            }
        }
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
        // Handle any updates you need to make to the view controller here
    }
}
