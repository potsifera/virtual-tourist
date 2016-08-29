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
    var session = NSURLSession.sharedSession()
    
    func taskForGet( parameters:[String:AnyObject], completionHandlerForGet:(result:AnyObject!, error:NSError?)->Void) -> NSURLSessionDataTask{

        /* 1. Set the parameters */
        var completeParameters = parameters
        completeParameters[FlickrConstants.FlickrParameterKeys.Method] = FlickrConstants.FlickrParameterValues.SearchMethod
        completeParameters[FlickrConstants.FlickrParameterKeys.APIKey] = FlickrConstants.FlickrParameterValues.APIKey
        completeParameters[FlickrConstants.FlickrParameterKeys.SafeSearch] = FlickrConstants.FlickrParameterValues.UseSafeSearch
        completeParameters[FlickrConstants.FlickrParameterKeys.Extras] =  FlickrConstants.FlickrParameterValues.MediumURL
        completeParameters[FlickrConstants.FlickrParameterKeys.Format] = FlickrConstants.FlickrParameterValues.ResponseFormat
        completeParameters[FlickrConstants.FlickrParameterKeys.NoJSONCallback] =  FlickrConstants.FlickrParameterValues.DisableJSONCallback
        completeParameters[FlickrConstants.FlickrParameterKeys.Page] = "\(arc4random_uniform(10))"
        completeParameters[FlickrConstants.FlickrParameterKeys.PerPage] = FlickrConstants.FlickrParameterValues.PhotosPerPage

        
        /* 2/3. Build the URL, Configure the request */
        let request = NSURLRequest(URL: urlFromParameters(completeParameters))
        //print(urlFromParameters(completeParameters))

        /* 4. Make the request */

        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request) { data, response, error in
            func sendError(error: String){
                let userInfo = [NSLocalizedDescriptionKey: error]
                completionHandlerForGet(result: nil, error: NSError(domain: "FlickrTaskForGetMethod", code:1, userInfo: userInfo))
            }
            
            /* GUARD: Was there an error? */
            guard (error == nil) else{
                sendError("Failure to connect to parse. Check your Internet settings.")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
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

            
        }
        task.resume()
        
        return task
    
    }
    
    
    
    // create a URL from parameters
    private func urlFromParameters(parameters: [String:AnyObject]) -> NSURL{
        let components = NSURLComponents()
        components.scheme = FlickrConstants.Components.APIScheme
        components.host = FlickrConstants.Components.APIHost
        components.path = FlickrConstants.Components.APIPath
        
        components.queryItems = [NSURLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = NSURLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.URL!
        
    }

    // given raw JSON, return a usable Foundation object
    private func convertDataWithCompletionHandler(data: NSData, completionHandlerForConvertData: (result: AnyObject!, error:NSError?)->Void ) {
        
        var parsedResult: AnyObject!
        do {
            parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            completionHandlerForConvertData(result: parsedResult, error: nil)
        } catch {
            let userInfo = [NSLocalizedDescriptionKey: "Could not parse the data as JSON from parse: \(data)"]
            completionHandlerForConvertData(result:nil, error: NSError(domain: "convertDataWithCompletionHandlerParse", code: 1, userInfo: userInfo))
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
