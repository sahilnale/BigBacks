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
    private var userPin: MKPointAnnotation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(map)
        
        LocationManager.shared.startUpdatingLocation { [weak self] location in
            DispatchQueue.main.async {
                guard let strongSelf = self else { return }
                
                if let userPin = strongSelf.userPin {
                    userPin.coordinate = location.coordinate
                }
                else {
                    let newPin = MKPointAnnotation()
                    newPin.coordinate = location.coordinate
                    strongSelf.userPin = newPin
                    strongSelf.map.addAnnotation(newPin)
                }
                strongSelf.map.setRegion(MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003)), animated: true)
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
