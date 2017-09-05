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
    func getPhotosURL(_ numberOfPhotos:Int, latitude: Double, longitude:Double, completionHandlerForGetPhotos:@escaping (_ result:[String]?, _ error:NSError?)->Void){
        
        let parameters = [FlickrConstants.FlickrParameterKeys.BoundingBox: bboxString(latitude, longitude: longitude)]
        
        taskForGet(parameters as [String : AnyObject]) { (result, error) in
            if let error = error{
                completionHandlerForGetPhotos(nil, error)
            } else {
                /* GUARD: Is "photos" key in our result? */
                guard let photosDictionary = result?[FlickrConstants.FlickrResponseKeys.Photos] as? [String:AnyObject] else {
                    let userInfo = [NSLocalizedDescriptionKey: "Could not find photos key in dictionary:"]
                    completionHandlerForGetPhotos(nil, NSError(domain: "convertDataWithCompletionHandlerParse", code: 1, userInfo: userInfo))
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
                    completionHandlerForGetPhotos(nil, error!)
                    return
                }
                
                if photosArray.count == 0 {
                    let userInfo = [NSLocalizedDescriptionKey: "No photos found. Try another search."]
                    completionHandlerForGetPhotos(nil, NSError(domain: "convertDataWithCompletionHandlerParse", code: 1, userInfo: userInfo))
                    return
                } else {
                    
                    var photosData = [String]() //save strings url
                    for photo in photosArray {
                        if let photoURL = photo[FlickrConstants.FlickrResponseKeys.MediumURL] as? String {
                            photosData.append(photoURL)
                            
                        }
                    }
                    
                    completionHandlerForGetPhotos(photosData, nil)
                    
                }
            }
        }
        
        
    }
    
    func downloadPhotoFromURL(_ imageUrl:String, completionHandlerForDownloadPhotoFromUrl:@escaping (_ data:Data?, _ error:NSError?)->Void)->URLSessionTask{
        let url = URL(string: imageUrl)
        let request = URLRequest(url: url!)
        let task = session.dataTask(with: request, completionHandler: {data, response, error in
            guard let data = data else {
                completionHandlerForDownloadPhotoFromUrl(nil, NSError(domain: "downloadPhotoFromURL", code: 1, userInfo: [NSLocalizedDescriptionKey: "Couldn't download image from URL"]))
                return
            }
            completionHandlerForDownloadPhotoFromUrl(data, nil)
        }) 
        
        task.resume()
        return task    
    }
    
    fileprivate func bboxString(_ latitude:Double, longitude:Double) -> String {
        // ensure bbox is bounded by minimum and maximums
        let minimumLon = max(longitude - FlickrConstants.Coordinates.SearchBBoxHalfWidth, FlickrConstants.Coordinates.SearchLonRange.0)
        let minimumLat = max(latitude - FlickrConstants.Coordinates.SearchBBoxHalfHeight, FlickrConstants.Coordinates.SearchLatRange.0)
        let maximumLon = min(longitude + FlickrConstants.Coordinates.SearchBBoxHalfWidth, FlickrConstants.Coordinates.SearchLonRange.1)
        let maximumLat = min(latitude + FlickrConstants.Coordinates.SearchBBoxHalfHeight, FlickrConstants.Coordinates.SearchLatRange.1)
        return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
    }
    
    
}
