//
//  PhotoAlbumView.swift
//  Virtual Tourist
//
//  Created by grace montoya on 7/28/16.
//  Copyright © 2016 grace montoya. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumView: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionViewFlowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var toolBar: UIToolbar!
    @IBOutlet weak var refreshButton: UIBarButtonItem! //(is enabled only if all the photos have been downloaded)
    
    var latitude:Double! = nil
    var longitude:Double! = nil
    let space: CGFloat = 3.0
    var dimension: CGFloat = 0.0
    var downloadedImages = 0
    var canDeleteImages = false
    //access to client
    let flickrClient = FlickrClient.sharedInstance()
    
    //fetched results controller saves photos
    var fetchedResultsController: NSFetchedResultsController!
    //NSFetchedResultsControllerDelegate  variables
    var insertedIndexCells: [NSIndexPath]!
    var deletedIndexCells: [NSIndexPath]!
    //coreDataStack
    var stack:CoreDataStack! = nil
    //pin
    var pin: Pin!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        placeMapPin()
        // Get the stack
        let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
        stack = delegate.stack
        
        if fetchPhotos().isEmpty {
            canDeleteImages = false
            searchPhotos()
        } else {
            canDeleteImages = true //checar esto para cambiar
            
        }
        
        
        // get dimensions for collection cells
        func getDimension()->CGFloat {
            var frameDimension:CGFloat = 0
            switch(UIDeviceOrientationIsLandscape(UIDevice.currentDevice().orientation)){
            case true:  //landsacape mode
                frameDimension = view.frame.size.height
            case false: //portrait mode
                frameDimension = view.frame.size.width
            }
            return (frameDimension - (2 * space)) / 3.0
        }
        
        dimension = getDimension()
        collectionViewFlowLayout.minimumInteritemSpacing = space
        collectionViewFlowLayout.itemSize = CGSizeMake(dimension, dimension)
        
    }//viewDidLoad end
    
    //places the selected pin on the map
    func placeMapPin() {
        mapView.addAnnotation(pin)
        mapView.camera.centerCoordinate = CLLocationCoordinate2DMake(pin.latitude, pin.longitude)
        mapView.camera.altitude = 10000 //zooms in the map
    }
    
    //searches for flickr photos
    func searchPhotos(){
        self.refreshButton.enabled = false
        downloadedImages = 0
        flickrClient.getPhotosURL(1, latitude: pin.latitude, longitude: pin.longitude) { (result, error) in
            if error != nil{
                print("found an error getting photos urls")
            }else{
                self.savePhotosUrlInCoreData(result!)
            }
        }
    }
    
    //checks if there are  that are already stored in the DB
    func fetchPhotos()->[Photo]{
        var photos = [Photo]()
        
        //Create the fetch request
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.sortDescriptors = []
        fetchRequest.predicate = NSPredicate(format: "pin = %@", pin)
        
        //create a fetchedResultsController
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
        
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
            if let results = fetchedResultsController.fetchedObjects as? [Photo] {
                photos = results
            }
        } catch {
            print("Error while trying to fetch photos.")
        }
        
        return photos
        
    }
    
    //saves only the photos URL
    func savePhotosUrlInCoreData(photosUrl: [String]){
        performUIUpdatesOnMain{
            for url in photosUrl{
                let photo = Photo(imageUrl: url, context: self.stack.context)
                photo.pin = self.pin
            }
            
            do{
                try self.stack.saveContext()
            }catch{
                print("error while saving context")
            }
        }
    }
    
    //gets a new set of fotos url's
    @IBAction func refreshPhotos(sender: UIBarButtonItem) {
        //delete photos from context
        canDeleteImages = false
        for photo in fetchedResultsController.fetchedObjects as! [Photo] {
            stack.context.deleteObject(photo)
            
        }
        //delete from core data, which deletes from the collectionView
        do{
            try self.stack.saveContext()
        }catch{
            print("error while saving image data in context")
        }
        
        searchPhotos()
    }
    
}

// MARK: UICollectionViewDataSource
extension PhotoAlbumView : UICollectionViewDataSource {
    
    //number of items
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections![section].numberOfObjects
        
    }
    
    // cell for item
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        //create the cell
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("flickrCell", forIndexPath: indexPath) as! PhotoViewCell
        cell.imageView!.image = UIImage(named: "placeholder")
        cell.activityIndicator.hidden = false
        cell.activityIndicator.startAnimating()
        
        // checks if there are objects
        if (self.fetchedResultsController.fetchedObjects?.count != 0) {
            
            // Find the right photo for this indexpath
            let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
            
            if  let data = photo.imageData {
                //image already downloaded
                performUIUpdatesOnMain{
                    cell.imageView.image = UIImage(data:data)
                    cell.activityIndicator.stopAnimating()
                    cell.activityIndicator.hidden = true
                }
                
            } else {
                //"Downloading image"
                flickrClient.downloadPhotoFromURL(photo.imageURL!) { (data, error) in
                    if let data = data {
                        self.downloadedImages = self.downloadedImages + 1
                        performUIUpdatesOnMain{
                            //if finished downloading all images enable the refresh button
                            if self.downloadedImages == Int(FlickrConstants.FlickrParameterValues.PhotosPerPage)! {
                                self.refreshButton.enabled = true
                                self.canDeleteImages = true
                            }
                            
                            // update the stack with the new imagedata
                            photo.imageData = data
                            do{
                                try self.stack.saveContext()
                            }catch{
                                print("error while saving image data in context")
                            }
                            // update the cell if there was a cell
                            cell.imageView.image = UIImage(data:data)
                            cell.activityIndicator.stopAnimating()
                            cell.activityIndicator.hidden = true
                        }
                    } else {
                        print("Couldn't download image from URL")
                    }
                }
            }
        } else {
            print("image doesnt exist")
        }
        
        return cell
    }
    
}

extension PhotoAlbumView: UICollectionViewDelegate {
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if canDeleteImages {
            // Find the right photo for this indexpath
            let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
            
            //delete from core data, which deletes from the collectionView
            stack.context.deleteObject(photo)
            do{
                try self.stack.saveContext()
            }catch{
                print("error while saving image data in context")
            }
        } else {
            print("can't delete while downloading images")
        }
    }
    
}

// MARK: NSFetchedResultsControllerDelegate

extension PhotoAlbumView: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        //print("controllerWillChangeContent")
        insertedIndexCells = [NSIndexPath]()
        deletedIndexCells = [NSIndexPath]()
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        //print("controllerDidChangeContent")
        collectionView.performBatchUpdates({
            self.collectionView.insertItemsAtIndexPaths(self.insertedIndexCells)
            self.collectionView.deleteItemsAtIndexPaths(self.deletedIndexCells)
            }, completion: nil)
        
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        //print("didChangeObject")
        switch type {
        case .Insert:
            insertedIndexCells.append(newIndexPath!)
        case .Delete:
            deletedIndexCells.append(indexPath!)
        default:
            break
        }
    }
    
}


