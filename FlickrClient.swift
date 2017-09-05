//
//  FlickrClient.swift
//  Virtual Tourist
//
//  Created by grace montoya on 7/28/16.
//  Copyright © 2016 grace montoya. All rights reserved.
//

import Foundation

class FlickrClient:NSObject {
    
    // shared session
    var session = URLSession.shared
    
    func taskForGet( _ parameters:[String:AnyObject], completionHandlerForGet:@escaping (_ result:AnyObject?, _ error:NSError?)->Void) -> URLSessionDataTask{

        /* 1. Set the parameters */
        var completeParameters = parameters
        completeParameters[FlickrConstants.FlickrParameterKeys.Method] = FlickrConstants.FlickrParameterValues.SearchMethod as AnyObject
        completeParameters[FlickrConstants.FlickrParameterKeys.APIKey] = FlickrConstants.FlickrParameterValues.APIKey as AnyObject
        completeParameters[FlickrConstants.FlickrParameterKeys.SafeSearch] = FlickrConstants.FlickrParameterValues.UseSafeSearch as AnyObject
        completeParameters[FlickrConstants.FlickrParameterKeys.Extras] =  FlickrConstants.FlickrParameterValues.MediumURL as AnyObject
        completeParameters[FlickrConstants.FlickrParameterKeys.Format] = FlickrConstants.FlickrParameterValues.ResponseFormat as AnyObject
        completeParameters[FlickrConstants.FlickrParameterKeys.NoJSONCallback] =  FlickrConstants.FlickrParameterValues.DisableJSONCallback as AnyObject
        completeParameters[FlickrConstants.FlickrParameterKeys.Page] = "\(arc4random_uniform(10))" as AnyObject
        completeParameters[FlickrConstants.FlickrParameterKeys.PerPage] = FlickrConstants.FlickrParameterValues.PhotosPerPage as AnyObject

        
        /* 2/3. Build the URL, Configure the request */
        let request = URLRequest(url: urlFromParameters(completeParameters))
        //print(urlFromParameters(completeParameters))

        /* 4. Make the request */

        let session = URLSession.shared
        let task = session.dataTask(with: request, completionHandler: { data, response, error in
            func sendError(_ error: String){
                let userInfo = [NSLocalizedDescriptionKey: error]
                completionHandlerForGet(nil, NSError(domain: "FlickrTaskForGetMethod", code:1, userInfo: userInfo))
            }
            
            /* GUARD: Was there an error? */
            guard (error == nil) else{
                sendError("Failure to connect to parse. Check your Internet settings.")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                sendError("Incorrect Credentials")
                //print("Your request returned a status code other than 2xx!")
                //print(response)
                return
            }
            guard let data = data else {
                sendError("failure to connect to flickr api")
                return
            }
            
            /* 5. Parse the data */
            //print(NSString(data: data!, encoding: NSUTF8StringEncoding))
            self.convertDataWithCompletionHandler(data, completionHandlerForConvertData: completionHandlerForGet)

            
        }) 
        task.resume()
        
        return task
    
    }
    
    
    
    // create a URL from parameters
    fileprivate func urlFromParameters(_ parameters: [String:AnyObject]) -> URL{
        var components = URLComponents()
        components.scheme = FlickrConstants.Components.APIScheme
        components.host = FlickrConstants.Components.APIHost
        components.path = FlickrConstants.Components.APIPath
        
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.url!
        
    }

    // given raw JSON, return a usable Foundation object
    fileprivate func convertDataWithCompletionHandler(_ data: Data, completionHandlerForConvertData: (_ result: AnyObject?, _ error:NSError?)->Void ) {
        
        var parsedResult: AnyObject!
        do {
            parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! AnyObject
            completionHandlerForConvertData(parsedResult, nil)
        } catch {
            let userInfo = [NSLocalizedDescriptionKey: "Could not parse the data as JSON from parse: \(data)"]
            completionHandlerForConvertData(nil, NSError(domain: "convertDataWithCompletionHandlerParse", code: 1, userInfo: userInfo))
        }
        
    }
    
    // MARK: Parse Shared Instance
    class func sharedInstance() -> FlickrClient {
        struct Singleton{
            static let sharedInstance = FlickrClient()
        }
        return Singleton.sharedInstance
    }



}
