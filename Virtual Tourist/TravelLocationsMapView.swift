//
//  TravelLocationsMapView.swift
//  Virtual Tourist
//
//  Created by grace montoya on 7/26/16.
//  Copyright © 2016 grace montoya. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsMapView: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    var latitude: Double! = nil
    var longitude: Double! = nil
    var nameOfPlace: String! = nil
    
    var stack:CoreDataStack! = nil
    var pinAnnotation:Pin! = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Get the stack
        let delegate = UIApplication.shared.delegate as! AppDelegate
        stack = delegate.stack
        
        mapView.delegate = self
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(TravelLocationsMapView.handleTap(_:)))
        longPress.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(longPress)
        
        loadPinsFromDB()
    }
    
    /*handles the tapping and holding from http://stackoverflow.com/questions/30858360/adding-a-pin-annotation-to-a-map-view-on-a-long-press-in-swift */
    
    //pin with name of the place
    func handleTap(_ gestureRecognizer:UIGestureRecognizer){
        if gestureRecognizer.state == UIGestureRecognizerState.began {
            let touchPoint = gestureRecognizer.location(in: mapView)
            let newCoordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            
            CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: newCoordinates.latitude, longitude: newCoordinates.longitude), completionHandler: {(placemarks, error) -> Void in
                if error == nil && placemarks!.count > 0 {
                    let placemark = placemarks![0]
                    self.nameOfPlace = placemark.name
                    //instantiates a pin as the annotation
                    self.pinAnnotation = Pin(latitude: newCoordinates.latitude, longitude: newCoordinates.longitude, context: self.stack.context)
                    self.pinAnnotation.title = placemark.name
                    self.mapView.addAnnotation(self.pinAnnotation!)
                    
                    self.latitude = newCoordinates.latitude
                    self.longitude = newCoordinates.longitude
                    
                } else {
                    
                    self.displayErrorAlert("Error", error: "Could not find your location. Try again")
                }
            })
        }
    }
    
    // loads a pin that's already stored
    func loadPinsFromDB() {
        var pins = [Pin]()
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        do {
            let results = try stack.context.fetch(fetchRequest)
            if let results = results as? [Pin] {
                pins = results
            }
        } catch {
            print("Couldn't find any Pins")
        }
        mapView.addAnnotations(pins)
    }
    
    
    // displays an error alert
    func displayErrorAlert(_ title: String, error: String) {
        let alert = UIAlertController(title: title, message: error, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: - ------ MKMapViewDelegate
    
    // Here we create a view with a "right callout accessory view".
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
           // pinView!.pinTintColor = UIColor.purpleColor()
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    // This delegate method is implemented to respond to taps on the name of the pin
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == view.rightCalloutAccessoryView {
            
            let photoController = storyboard!.instantiateViewController(withIdentifier: "photoAlbumView") as! PhotoAlbumView
            photoController.latitude = self.latitude
            photoController.longitude = self.longitude
            photoController.pin = view.annotation as! Pin
            //self.presentViewController(photoController, animated: true, completion: nil)
            self.navigationController!.pushViewController(photoController, animated: true)
            
        }
        
    }
    
    
}

