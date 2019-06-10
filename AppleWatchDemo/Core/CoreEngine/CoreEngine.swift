//
//  CoreEngine.swift
//  AppleWatchDemo
//
//  Created by Rohit Pathak on 10/06/19.
//  Copyright © 2019 Rohit Pathak. All rights reserved.
//

import Foundation

let BASE_REGISTER_ID     =   100

class EngineEvents {
    
    var eventID:Int         =   0
    var object:AnyObject?
    
}

class LocalEngineEvents:EngineEvents {
    
    required init(id:LocalEvents,obj:AnyObject?) {
        super.init()
        self.eventID = id.rawValue
        self.object = obj
    }
    
}

class SocketEngineEvents:EngineEvents {
    
    required init(id:SocketEvents,obj:AnyObject?) {
        super.init()
        self.eventID = id.rawValue
        self.object = obj
    }
    
}

let MIN_REST_EVENT  =   1000
let MAX_REST_EVENT  =   1999

enum RestEvents:Int {
    case    LOGIN  =   1000
    case    NETWORK_ERROR
}

let MIN_LOCAL_EVENT  =   2000
let MAX_LOCAL_EVENT  =   2999

enum LocalEvents:Int{
    case    START_CONTACT_SYNC    =   2000
}

let MIN_SOCKET_EVENT  =   3000
let MAX_SOCKET_EVENT  =   3999

enum SocketEvents:Int{
    case    CONNECT =   3000
}

enum EventCallBack:String{
    case REST_CALLBACK      =   "restEventListenerCallBack"
    case SOCKET_CALLBACK    =   "socketEventListenerCallBack"
    case LOCAL_CALLBACK     =   "localEventListenerCallBack"
}

class CoreEngine: EventLoop {
    
    fileprivate var restHelper = RestHelper.shared
    fileprivate var cbHndler = [String:Any]()
    fileprivate var currentRegIdx = 0
    fileprivate var mutex = NSLock()
    
    static let shared = CoreEngine()
    
    // feature toggle variables
    var autoDownloadImages = true
    var autoDownloadAudio = true
    var autoDownloadVideo = true
    
    
    override init() {
        
        super.init()
        
        //Start Thread here
        self.start()
        self.name = "CoreEngine"
    }
    
    // MARK:- Public Methods
    public override func addEvent(evObj: EngineEvents){
        print("Event added \(evObj.eventID)")
        return super.addEvent(evObj: evObj)
    }
    
    public func addEngineEventsWithOutWait(evObj: EngineEvents){
        self.processQueuedEvent(evobj:evObj)
    }
    
    public func registerEventCallBack(cbType:EventCallBack, cbBlock:@escaping(_ eventID:Int, _ result:Int, _ response:AnyObject?)-> Void) -> String {
        
        mutex.lock()
        
        var cbhndl:[String:Any]?
        
        if self.cbHndler[cbType.rawValue] != nil {
            cbhndl = (self.cbHndler[cbType.rawValue] as! [String : Any])
        } else {
            cbhndl = [String:Any]()
        }
        
        currentRegIdx += 1
        
        let regID = String(format:"%d",currentRegIdx)
        cbhndl?[regID] = cbBlock
        
        self.cbHndler[cbType.rawValue] = cbhndl
        
        mutex.unlock()
        
        return regID
    }
    
    public func unregisterEventForID(cbType:EventCallBack,regId:String){
        mutex.lock()
        if var cbhndl = self.cbHndler[cbType.rawValue] as? [String:Any]{
            cbhndl.removeValue(forKey: regId)
            self.cbHndler[cbType.rawValue] = cbhndl
        }
        mutex.unlock()
    }
    
    // MARK:- Private Methods
    internal override func processQueuedEvent(evobj: Any){
        
        if let events = evobj as? EngineEvents{
            
            switch events.eventID {
            case MIN_REST_EVENT ... MAX_REST_EVENT:
                self.processRestEvents(evobj: events as! RestEngineEvents)
            case MIN_LOCAL_EVENT ... MAX_LOCAL_EVENT:
                self.processLocalEvents(evobj: events)
            case MIN_SOCKET_EVENT ... MAX_SOCKET_EVENT:
                self.processSocketEvents(evobj: events)
            default:
                break
            }
            
        }else{
            print("Event not handle yet %@",evobj)
        }
        
    }
    
    fileprivate func processRestEvents(evobj: RestEngineEvents){
        if evobj.state == .NONE{
            
            restHelper.processRestRequest(evObj: evobj)
            
        } else if evobj.state == .PROCESSING{
            
            //update the progess of uploading / downloading the files
            
        } else if evobj.state == .COMPLETED{
            
            let eventID = RestEvents(rawValue: evobj.eventID)!
            let notifyToGUI = true
            
            switch (eventID) {
                
            case .LOGIN:
                if let responseDict = evobj.object as? [String : Any]{
                    debugPrint(responseDict)
                    
                }
                
            default : debugPrint("Not handle yet")
            }
            
            // notify the response to the GUI
            if notifyToGUI {
                self.notifyToGUI(cbType: EventCallBack.REST_CALLBACK, eventID: evobj.eventID, result: Success, response: evobj.object)
            }
        }
    }
    
    fileprivate func processLocalEvents(evobj: EngineEvents){
        let eventID = LocalEvents(rawValue: evobj.eventID)!
        switch (eventID) {
            
        default:
            break
        }
        
    }
    
    fileprivate func processSocketEvents(evobj: EngineEvents){
        
        let eventID = SocketEvents(rawValue: evobj.eventID)!
        
        switch (eventID) {
        default:
            self.notifyToGUI(cbType: EventCallBack.SOCKET_CALLBACK, eventID: evobj.eventID, result: Success, response: evobj.object)
            break
        }
    }
    
    /*
     Notify the reponses directly to the call back handler attach with the Events associated with eventID
     */
    
    fileprivate func notifyToGUI(cbType:EventCallBack, eventID:Int, result:Int, response:AnyObject?){
        
        mutex.lock()
        
        if let cbhndl = self.cbHndler[cbType.rawValue] as? [String:Any]{
            
            cbhndl.keys.forEach { (key) in
                let completionBlock = cbhndl[key] as! (_ eventID:Int, _ result:Int, _ response:AnyObject?)-> Void
                completionBlock(eventID,result,response)
            }
        } else {
            print("handler not find to notify")
        }
        mutex.unlock()
    }
}
