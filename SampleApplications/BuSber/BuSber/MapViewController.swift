//
//  MapViewController.swift
//  BuSber
//
//  Created by Vinay Gahlawat on 5/3/16.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Kinvey
import MapKit
import UIKit

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    @IBOutlet weak var mapView: MKMapView!
    var locationManager: CLLocationManager!
    var dataStore: DataStore<Bus>!
    let initialLocation = CLLocation(latitude: 42.60027777777778, longitude: -71.10805555555555)
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.showsUserLocation = true
        let bus = Bus()
        bus.location = [-71.10805555555555, 42.60027777777778]
        mapView.addAnnotation(bus)
        let dataStore = DataStore<Bus>.getInstance()
        
        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.delegate = self

        var status = CLLocationManager.authorizationStatus()
        if status == .NotDetermined || status == .Denied || status == .AuthorizedWhenInUse {
            locationManager.requestAlwaysAuthorization()
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
        }
        
        centerMapOnLocation(initialLocation)
        mapView.showsUserLocation = true
    }

    let regionRadius: CLLocationDistance = 1000

    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }

//    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        let location = locations.last
//        print("present location : \(newLocation.coordinate.latitude), \(newLocation.coordinate.longitude)")
//        let center = CLLocationCoordinate2D(latitude: location!.coordinate.latitude, longitude: location!.coordinate.longitude)
//        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
//        
//        mapView.setRegion(region, animated: true)
//    }
}
