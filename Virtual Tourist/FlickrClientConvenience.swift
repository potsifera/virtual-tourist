//
//  FlickrClientConvenience.swift
//  Virtual Tourist
//
//  Created by grace montoya on 7/28/16.
//  Copyright © 2016 grace montoya. All rights reserved.
//

import Foundation

extension FlickrClient {
    
    
    // gets photos from flickr depending on the latitude and longitude of the search
    func getPhotosURL(numberOfPhotos:Int, latitude: Double, longitude:Double, completionHandlerForGetPhotos:(result:[String]?, error:NSError?)->Void){
        
        let parameters = [FlickrConstants.FlickrParameterKeys.BoundingBox: bboxString(latitude, longitude: longitude)]
        
        taskForGet(parameters) { (result, error) in
            if let error = error{
                completionHandlerForGetPhotos(result: nil, error: error)
            } else {
                /* GUARD: Is "photos" key in our result? */
                guard let photosDictionary = result[FlickrConstants.FlickrResponseKeys.Photos] as? [String:AnyObject] else {
                    let userInfo = [NSLocalizedDescriptionKey: "Could not find photos key in dictionary:"]
                    completionHandlerForGetPhotos(result: nil, error: NSError(domain: "convertDataWithCompletionHandlerParse", code: 1, userInfo: userInfo))
                    return
                }
                
//                /* GUARD: Is "pages" key in the photosDictionary? */
//                guard let totalPages = photosDictionary[FlickrConstants.FlickrResponseKeys.Pages] as? Int else {
//                    let userInfo = [NSLocalizedDescriptionKey: "Could not find total pages key in dictionary:"]
//                    completionHandlerForGetPhotos(result: nil, error: NSError(domain: "convertDataWithCompletionHandlerParse", code: 1, userInfo: userInfo))
//                    return
//                }
                

                /* GUARD: Is the "photo" key in photosDictionary? */
                guard let photosArray = photosDictionary[FlickrConstants.FlickrResponseKeys.Photo] as? [[String: AnyObject]] else {
                    completionHandlerForGetPhotos(result: nil, error: error!)
                    return
                }
                
                if photosArray.count == 0 {
                    let userInfo = [NSLocalizedDescriptionKey: "No photos found. Try another search."]
                    completionHandlerForGetPhotos(result: nil, error: NSError(domain: "convertDataWithCompletionHandlerParse", code: 1, userInfo: userInfo))
                    return
                } else {
                    
                    var photosData = [String]() //save strings url
                    for photo in photosArray {
                        if let photoURL = photo[FlickrConstants.FlickrResponseKeys.MediumURL] as? String {
                            photosData.append(photoURL)
                            
                        }
                    }
                    
                    completionHandlerForGetPhotos(result: photosData, error: nil)
                    
                }
            }
        }
        
        
    }
    
    func downloadPhotoFromURL(imageUrl:String, completionHandlerForDownloadPhotoFromUrl:(data:NSData?, error:NSError?)->Void)->NSURLSessionTask{
        let url = NSURL(string: imageUrl)
        let request = NSURLRequest(URL: url!)
        let task = session.dataTaskWithRequest(request) {data, response, error in
            guard let data = data else {
                completionHandlerForDownloadPhotoFromUrl(data: nil, error: NSError(domain: "downloadPhotoFromURL", code: 1, userInfo: [NSLocalizedDescriptionKey: "Couldn't download image from URL"]))
                return
            }
            completionHandlerForDownloadPhotoFromUrl(data: data, error: nil)
        }
        
        task.resume()
        return task    
    }
    
    private func bboxString(latitude:Double, longitude:Double) -> String {
        // ensure bbox is bounded by minimum and maximums
        let minimumLon = max(longitude - FlickrConstants.Coordinates.SearchBBoxHalfWidth, FlickrConstants.Coordinates.SearchLonRange.0)
        let minimumLat = max(latitude - FlickrConstants.Coordinates.SearchBBoxHalfHeight, FlickrConstants.Coordinates.SearchLatRange.0)
        let maximumLon = min(longitude + FlickrConstants.Coordinates.SearchBBoxHalfWidth, FlickrConstants.Coordinates.SearchLonRange.1)
        let maximumLat = min(latitude + FlickrConstants.Coordinates.SearchBBoxHalfHeight, FlickrConstants.Coordinates.SearchLatRange.1)
        return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
    }
    
    
}
