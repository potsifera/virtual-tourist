//
//  Photo.swift
//  Virtual Tourist
//
//  Created by grace montoya on 7/26/16.
//  Copyright © 2016 grace montoya. All rights reserved.
//

import Foundation
import CoreData


class Photo: NSManagedObject {

// Insert code here to add functionality to your managed object subclass
    convenience init(imageUrl: String,  context: NSManagedObjectContext) {
        if let ent = NSEntityDescription.entity(forEntityName: "Photo", in: context){
            self.init(entity: ent, insertInto: context)
            self.imageURL = imageUrl
            self.imageData = nil
            
        }else {
            fatalError("Unable to Find Photo!")
        }
        
    }
}
