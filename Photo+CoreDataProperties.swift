//
//  Photo+CoreDataProperties.swift
//  Virtual Tourist
//
//  Created by grace montoya on 7/26/16.
//  Copyright © 2016 grace montoya. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Photo {

    @NSManaged var imageData: Data?
    @NSManaged var imageURL: String?
    @NSManaged var pin: Pin?

}
