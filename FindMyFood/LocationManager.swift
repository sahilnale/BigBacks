//
//  LocationManager.swift
//  FindMyFood
//
//  Created by Shaina Grover on 11/5/24.
//

import Foundation
import CoreLocation

class LocationManager: NSObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    
    let manager = CLLocationManager()
    
    var completion: ((CLLocation)->Void)?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
//    public func getUserLocation(completion: @escaping((CLLocation)->Void)) {
//        self.completion = completion
//        manager.requestWhenInUseAuthorization()
//        manager.delegate = self
//        manager.startUpdatingLocation()
//    }
    
    public func startUpdatingLocation(completion: @escaping((CLLocation)->Void)) {
            self.completion = completion
            manager.requestWhenInUseAuthorization()
            manager.startUpdatingLocation()
        }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            return
        }
        completion?(location)
        //manager.stopUpdatingLocation()
        
    }
}
