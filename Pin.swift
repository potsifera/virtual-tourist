//
//  Pin.swift
//  Virtual Tourist
//
//  Created by grace montoya on 7/26/16.
//  Copyright © 2016 grace montoya. All rights reserved.
//

import Foundation
import CoreData
import MapKit


class Pin: NSManagedObject, MKAnnotation {
    
  
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

// Insert code here to add functionality to your managed object subclass
    convenience init(latitude:Double,longitude:Double, context: NSManagedObjectContext) {
        if let ent = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context){
            self.init(entity: ent, insertIntoManagedObjectContext: context)
            self.latitude = latitude
            self.longitude = longitude
            self.title = ""
            
        }else {
            fatalError("Unable to Find Pin !")
        }
        
    }

}
