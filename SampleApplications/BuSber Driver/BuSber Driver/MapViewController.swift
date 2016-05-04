//
//  MapViewController.swift
//  BuSber Driver
//
//  Created by Victor Barros on 2016-05-04.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import UIKit
import MapKit
import Kinvey

class MapViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    let locationManager = CLLocationManager()
    let store = DataStore<Bus>.getInstance(.Network)
    var bus: Bus?
    let queue = NSOperationQueue()
    let lock = NSCondition()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        queue.maxConcurrentOperationCount = 1

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        
        mapView.region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 42.3546833, longitude: -71.0677118), span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015))
        
        store.find(Query(format: "name == %@", "Bus1")) { buses, error in
            if let buses = buses, let bus = buses.first {
                self.bus = bus
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func locationManager(manager: CLLocationManager, didUpdateToLocation newLocation: CLLocation, fromLocation oldLocation: CLLocation) {
        if let bus = bus {
            let coordinate = newLocation.coordinate
            queue.addOperationWithBlock({
                self.lock.lock()
                bus.location = [coordinate.longitude, coordinate.latitude]
                self.store.save(bus) { bus, error in
                    self.lock.lock()
                    self.lock.signal()
                    self.lock.unlock()
                }
                self.lock.wait()
                self.lock.unlock()
            })
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
