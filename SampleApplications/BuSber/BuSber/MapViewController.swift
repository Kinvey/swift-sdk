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
    var buses = Array<Bus>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.showsUserLocation = true

        dataStore = DataStore<Bus>.getInstance(.Network)
        
        dataStore.find() { oldbuses, error in
            if let buses = oldbuses {
                self.buses = buses
                self.mapView.addAnnotations(self.buses)
            }
        }

        dataStore.subscribe { (type, bus, error) in
            if let bus = bus {
                //print("\(bus)")
                if type == LiveEventType.Create {
                    self.buses.append(bus)
                    self.mapView.addAnnotation(bus)
                }
                else if type == LiveEventType.Update {
                    for b in self.buses {
                        if b._id == bus._id {
                            b.location = bus.location
                        }
                    }
                }
            }
        }
        
        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.delegate = self

        var status = CLLocationManager.authorizationStatus()
            locationManager.requestAlwaysAuthorization()
            locationManager.startUpdatingLocation()
        
    }

    let regionRadius: CLLocationDistance = 1000

//    func centerMapOnLocation(location: CLLocation) {
//        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, regionRadius * 4.0, regionRadius * 4.0)
//        mapView.setRegion(coordinateRegion, animated: true)
//    }

    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last
        let center = CLLocationCoordinate2D(latitude: location!.coordinate.latitude, longitude: location!.coordinate.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02))
        
        mapView.setRegion(region, animated: false)
    }

//    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
////        // 1
//        let identifier = "Bus"
//
//        // 2
//        if annotation is Bus {
//            // 3
//            var annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier)
//            
//            if annotationView == nil {
//                //4
//                annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
//                annotationView!.canShowCallout = true
//                
//                // 5
//                let btn = UIButton(type: .DetailDisclosure)
//                btn.addTarget(self, action: #selector(pressed(_:)), forControlEvents: .TouchUpInside)
//                annotationView!.rightCalloutAccessoryView = btn
//            } else {
//                // 6
//                annotationView!.annotation = annotation
//            }
//            
//            return annotationView
//        }
//        
//        // 7
//        return nil
//    }

//    func pressed(sender: UIButton!) {
//        var alertView = UIAlertView();
//        alertView.addButtonWithTitle("Ok");
//        alertView.title = "title";
//        alertView.message = "message";
//        alertView.show();
//    }

}
