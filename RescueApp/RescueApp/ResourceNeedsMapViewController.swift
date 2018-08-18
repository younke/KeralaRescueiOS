//
//  ResourceNeedsMapViewController.swift
//  RescueApp
//
//  Created by Jayahari Vavachan on 8/17/18.
//  Copyright © 2018 Jayahari Vavachan. All rights reserved.
//

import UIKit
import MapKit

class ResourceNeedsMapViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    
    
    private var requests = [RequestModel]()
    private let locationManager = CLLocationManager()
    
    struct C {
        static let animationIdentifier = "ResourceListViewControllerFlip"
        static let ResourceListViewController = "ResourceNeedsListViewController"
        static let mapAnnotationIdentifier = "MapAnnotationIdentifier"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        getResources()
        
        getCurrentLocation()
    }
    
    @IBAction func onTouchUpList(_ sender: UIButton) {
        let vc = storyboard?.instantiateViewController(withIdentifier: C.ResourceListViewController)
        UIView.beginAnimations(C.animationIdentifier, context: nil)
        UIView.setAnimationDuration(1.0)
        UIView.setAnimationCurve(.easeInOut)
        UIView.setAnimationTransition(.flipFromRight, for: (navigationController?.view)!, cache: false)
        navigationController?.pushViewController(vc!, animated: true)
        UIView.commitAnimations()
    }

}


extension ResourceNeedsMapViewController {
    func getResources() {
        Overlay.shared.show()
        ApiClient.shared.getResourceNeeds { [weak self] (requests) in
            Overlay.shared.remove()
            self?.requests = requests
            DispatchQueue.main.async { [weak self] in
                self?.updateMap()
            }
        }
    }
    
    func updateMap() {
        let allAnnotations = mapView.annotations
        mapView.removeAnnotations(allAnnotations)
        mapView.addAnnotations(requests)
    }
    
    /**
     gets current location.
     */
    func getCurrentLocation() {
        locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
    }
}

// MARK: AddToiletViewController -> CLLocationManagerDelegate

extension ResourceNeedsMapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationManager.stopUpdatingLocation()
        if let location = manager.location {
            let annotation = MKPointAnnotation()
            annotation.coordinate = location.coordinate
            mapView.addAnnotation(annotation)
            let region = MKCoordinateRegion(center: location.coordinate,
                                            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02))
            mapView.setRegion(region, animated: true)
        }
        
    }
}

// MARK: MapViewController -> MKMapViewDelegate

extension ResourceNeedsMapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        guard let annotation = annotation as? RequestModel else { return nil }
        
        var view: MKMarkerAnnotationView
        
        if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: C.mapAnnotationIdentifier)
            as? MKMarkerAnnotationView {
            dequeuedView.annotation = annotation
            view = dequeuedView
        } else {
            
            view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: C.mapAnnotationIdentifier)
            view.canShowCallout = true
            view.calloutOffset = CGPoint(x: -5, y: 5)
            view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        return view
    }
}
