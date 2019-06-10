//
//  RestHelper.swift
//  AppleWatchDemo
//
//  Created by Rohit Pathak on 10/06/19.
//  Copyright © 2019 Rohit Pathak. All rights reserved.
//

import Foundation
import Alamofire

let Success = 1
let Failure = 0

enum RequestState:Int {
    case NONE       =   0
    case WAITING
    case PROCESSING
    case COMPLETED
}

class RestEngineEvents:EngineEvents {
    
    var state:RequestState = .NONE
    var fastQueue:Bool = true
    var uploadMultipart = false
    var downloadingFile = true // Check only when fastQueue is false
    var apiRequest:URLRequestConvertible?
    var completionBlock:((_ what:Int, _ result:Int,_ response:AnyObject)->Void)?
    var progressBlock:((_ what:Int, _ progress:Double,_ url:URL)->Void)?
    
    required init(id:RestEvents,obj:AnyObject?) {
        super.init()
        self.eventID = id.rawValue
        self.object = obj
    }
}

class RestHelper: NSObject {
    
    static let shared = RestHelper()
    
    let scheduler = RequestScheduler.shared
    
    let onRestCompletionBlock = {   (what:Int, result:Int,response:AnyObject)-> Void in
        
        var restEvent = RestEngineEvents.init(id: RestEvents(rawValue: what)!, obj: response)
        restEvent.state = .COMPLETED
        CoreEngine.shared.addEvent(evObj: restEvent)
    }
    
    let progressBlock = {(_ what:Int, _ progress:Double,_ url:URL)-> Void in
        
        let progressData = ["kDalProgress":progress,"kDalFilePath":url] as [String : Any]
        
        var restEvent = RestEngineEvents.init(id: RestEvents(rawValue: what)!, obj: progressData as AnyObject)
        restEvent.state = .PROCESSING
        CoreEngine.shared.addEvent(evObj: restEvent)
    }
    
    public func processRestRequest(evObj:RestEngineEvents){
        
        let restEventId = RestEvents(rawValue: evObj.eventID)!
        
        switch restEventId {
        case .LOGIN:
            if let parameters = evObj.object as? [String:Any]{
                evObj.apiRequest = ApiRouter.login(params: parameters)
            }else{
                debugPrint("Parameter missing for login")
            }
        case .NETWORK_ERROR:break
        }

        self.addRequestInScheduler(requestObj: evObj)
    }
    
    fileprivate func addRequestInScheduler(requestObj:RestEngineEvents){
        var request = requestObj
        scheduler.addReqInQueue(reqObj: &request, completionBlock: onRestCompletionBlock , progressBlock: progressBlock)
    }
    
    fileprivate func addBasicParameters(){
        
    }
}
