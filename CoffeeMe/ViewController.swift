//
//  ViewController.swift
//  CoffeeMe
//
//  Created by Thomas Crawford on 2/28/17.
//  Copyright © 2017 VizNetwork. All rights reserved.
//

import UIKit
import MapKit

class MyPointAnnotation: MKPointAnnotation {
    var pinIndex    :Int!

}

class ViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet var coffeeSearchBar   :UISearchBar!
    @IBOutlet var coffeeMap       :MKMapView!
    
    var locationMgr = CLLocationManager()
    
    var coffeeArray = [Location]()
    
    //MARK: geo coding methods
    
    func addLocAndPinFor(placemarks: [CLPlacemark]?, title: String){
        guard let placemarks = placemarks, let placemark = placemarks.first else {
            return
        }
        let city = placemark.locality
        let state = placemark.administrativeArea
        let address = placemark.subThoroughfare! + " " + placemark.thoroughfare!
        let fullAddress = "\(address), \(city!), \(state!)"
        let newLoc = Location(name: title, address: fullAddress, lat: placemark.location!.coordinate.latitude, lon: placemark.location!.coordinate.longitude)
        coffeeArray.append(newLoc)
        let index = coffeeArray.index(of: newLoc)!
        coffeeMap.addAnnotation(pinFor(loc: newLoc, index: index))
        zoomToPins()
        
    }
    
    func latlonSearch(){
        coffeeSearchBar.resignFirstResponder()
        guard let searchText = coffeeSearchBar.text, let loc = locationFrom(string: searchText) else {
            return
        }
        let geoCoder = CLGeocoder()
        geoCoder.reverseGeocodeLocation(loc){(placemarks, error) in
            if let err = error {
                print ("Got error \(err.localizedDescription)")
            } else {
                self.addLocAndPinFor(placemarks: placemarks, title: "From Lat/Lon: \(searchText)")
            }
        
        }
    }
    
    func addressSearch(){
        coffeeSearchBar.resignFirstResponder()
        guard let searchText = coffeeSearchBar.text else {
            return
        }
        let geoCoder = CLGeocoder()
        geoCoder.geocodeAddressString(searchText) {(placemarks, error) in
            if let err = error {
                print ("Got error \(err.localizedDescription)")
            } else {
                self.addLocAndPinFor(placemarks: placemarks, title: "From Address: \(searchText)")
            }        }
    }
    
    func appleSearch(){
        coffeeSearchBar.resignFirstResponder()
        guard let searchText = coffeeSearchBar.text else {
            return
        }
        let request = MKLocalSearchRequest()
        request.naturalLanguageQuery = searchText
        request.region = coffeeMap.region
        let localSearch = MKLocalSearch(request: request)
        localSearch.start { (response, error) in
            if let err = error {
                print("got erorr \(err.localizedDescription)")
            } else {
                for item in response!.mapItems {
                    self.addLocAndPinFor(placemarks: [item.placemark], title: "From apple: \(item.placemark.name!)")
                    
                }
                
            }
            
        
        }
    }
    
    func locationFrom(string: String) -> CLLocation? {
        let coordItems = string.components(separatedBy: ",")
        if coordItems.count == 2 {
            guard let lat = Double(coordItems[0]), let lon = Double(coordItems[1]) else {
                return nil
            }
            return CLLocation(latitude: lat, longitude: lon)
        }
        return nil
    }
    
    //MARK: ineractivity methods
    
    @IBAction func valueChanged(segControl: UISegmentedControl){
        switch segControl.selectedSegmentIndex {
        case 0:
            latlonSearch()
        case 1:
            addressSearch()
        case 2:
            appleSearch()
        default:
            return
        }
    
    }
    
    @IBAction func longPressed(gesture: UILongPressGestureRecognizer){
        if gesture.state == .ended {
            print("Long Press")
            let point = gesture.location(in: coffeeMap)
            let coord = coffeeMap.convert(point, toCoordinateFrom: coffeeMap)
            let loc = Location(name: "Long Press \(coord.latitude), \(coord.longitude)",
                address: "n/a", lat: coord.latitude, lon: coord.longitude )
            coffeeArray.append(loc)
          //  annotateMapLocations()
            
            let index = coffeeArray.index(of: loc)!
            coffeeMap.addAnnotation(pinFor(loc: loc, index: index))
            let circle = MKCircle(center: coord, radius: 1000)
            coffeeMap.add(circle, level: .aboveRoads)
            
        }
    
    }
    
    //mark - map view delegate methods
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKCircle {
            let renderer = MKCircleRenderer(overlay: overlay)
            renderer.fillColor = .green
            renderer.alpha = 0.5
            return renderer
        
        }
        return MKOverlayRenderer()
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if !(annotation is MKUserLocation){
            var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: "Pin") as? MKPinAnnotationView
            if pinView == nil {
                pinView = MKPinAnnotationView(annotation:annotation, reuseIdentifier: "Pin")
            }
            pinView!.annotation = annotation
            pinView!.canShowCallout = true
            pinView!.animatesDrop = true
            pinView!.pinTintColor = .orange
            let pinButton = UIButton(type: .detailDisclosure)
            pinView!.rightCalloutAccessoryView = pinButton
            return pinView
            
        }
        return nil
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        print("pressed callout button")
        let annotation = view.annotation as! MyPointAnnotation
        let selectedLoc = coffeeArray[annotation.pinIndex]
        print("pressed callout button \(selectedLoc.locationName)")
    }
    
    //MARK: - Map View Methods
    func pinFor(loc: Location, index: Int) -> MKPointAnnotation{
        let pa = MyPointAnnotation()
        pa.pinIndex = index
        pa.title = loc.locationName
        pa.subtitle = loc.locationAddress
        pa.coordinate = CLLocationCoordinate2D(latitude: loc.locationLat,
                                               longitude: loc.locationLon)
        coffeeMap.addAnnotation(pa)
        return pa
    }
    
    
    func zoomToPins() {
        coffeeMap.showAnnotations(coffeeMap.annotations, animated: true)
    }
    
    func zoomToLocation(lat: Double, lon: Double, radius: Double) {
        if lat == 0 && lon == 0 {
            print("Invalid Data")
        } else {
            let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            let viewRegion = MKCoordinateRegionMakeWithDistance(coord, radius, radius)
            let adjustedRegion = coffeeMap.regionThatFits(viewRegion)
            coffeeMap.setRegion(adjustedRegion, animated: true)
        }
    }
    
    func buildArray() {
        let loc1 = Location(name: "Southern Ontario Waterfront", address: "Wow it's nice", lat: 42, lon: -83)
        let loc2 = Location(name: "Somewhere Someplace", address: "Who knows", lat: 42.123, lon: -83.123)
        let loc3 = Location(name: "I Wonder Where", address: "I hope this works", lat: 42.234, lon: -83.234)
        coffeeArray = [loc1, loc2, loc3]
    }
    
    func annotateMapLocations() {
        var pinsToRemove = [MKPointAnnotation]()
        for annotation in coffeeMap.annotations {
            if annotation is MKPointAnnotation {
                pinsToRemove.append(annotation as! MKPointAnnotation)
            }
        }
        coffeeMap.removeAnnotations(pinsToRemove)
        
        for (index, loc) in coffeeArray.enumerated() {
            coffeeMap.addAnnotation(pinFor(loc: loc, index: index))
         //   let pa = MKPointAnnotation()
         //   pa.title = loc.locationName
         //   pa.subtitle = loc.locationAddress
         //   pa.coordinate = CLLocationCoordinate2D(latitude: loc.locationLat, longitude: loc.locationLon)
         //   coffeeMap.addAnnotation(pa)
        }
//        zoomToPins()
    }
    
    //MARK: - Life Cycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        coffeeMap.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupLocationMonitoring()
        buildArray()
        annotateMapLocations()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}

extension ViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let lastLoc = locations.last!
        print("Last Loc: \(lastLoc.coordinate.latitude),\(lastLoc.coordinate.longitude)")
        zoomToLocation(lat: lastLoc.coordinate.latitude, lon: lastLoc.coordinate.longitude, radius: 500)
        manager.stopUpdatingLocation()
    }
 
    //MARK: - Location Authorization Methods
    
    func turnOnLocationMonitoring() {
        locationMgr.startUpdatingLocation()
        coffeeMap.showsUserLocation = true
    }
    
    func setupLocationMonitoring() {
        locationMgr.delegate = self
        locationMgr.desiredAccuracy = kCLLocationAccuracyBest
        if CLLocationManager.locationServicesEnabled() {
            switch CLLocationManager.authorizationStatus() {
            case .authorizedAlways, .authorizedWhenInUse:
                turnOnLocationMonitoring()
            case .denied, .restricted:
                print("Hey turn us back on in Settings!")
            case .notDetermined:
                if locationMgr.responds(to: #selector(CLLocationManager.requestAlwaysAuthorization)) {
                    locationMgr.requestAlwaysAuthorization()
                }
            }
        } else {
            print("Hey Turn Location On in Settings!")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        setupLocationMonitoring()
    }
}




























