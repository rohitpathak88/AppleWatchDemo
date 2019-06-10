//
//  RequestScheduler.swift
//  AppleWatchDemo
//
//  Created by Rohit Pathak on 10/06/19.
//  Copyright © 2019 Rohit Pathak. All rights reserved.
//

import Foundation
import UIKit


let Thread_Sleep_Time = 1000
let SLOW_QUEUE = "slowQueue"
let FAST_QUEUE = "fastQueue"
let REQUEST_SCH_THREAD = "requestSchThread"

class RequestScheduler: NSObject {

    // -- Request scheduler lock
    var queueMutex:NSLock // -- Always remember free the lock

    // -- Thread sync semaphore
    var sema : DispatchSemaphore

    // -- Request scheduler event queue
    var fastQueueCache:[RestEngineEvents]
    var slowQueueCache:[RestEngineEvents]

    // -- Request scheduler thread
    var schThread:Thread
    var needToNotify:Bool

    // -- Network request queues
    var slowQueue:NetworkManager?
    var fastQueue:NetworkManager?

    static let shared = RequestScheduler()
    
    override init() {

        self.queueMutex = NSLock()

        self.slowQueue = NetworkManager()
        self.slowQueue?.queueType = SLOW_QUEUE
        
        self.fastQueue = NetworkManager()
        self.fastQueue?.queueType = FAST_QUEUE
        
        self.slowQueueCache = [RestEngineEvents]()
        self.fastQueueCache = [RestEngineEvents]()

        self.sema = DispatchSemaphore.init(value: 0)

        self.needToNotify = true

        self.schThread = Thread.init()

        super.init()

        self.schThread = Thread.init(target: self, selector: #selector(reqScheduleHndl), object: nil)
        self.schThread.name = REQUEST_SCH_THREAD
        self.schThread.start()

    }

    func addReqInQueue( reqObj:inout RestEngineEvents,completionBlock:@escaping (_ evType:Int, _ result:Int,_ response:AnyObject)->Void,progressBlock:@escaping (_ evType:Int, _ result:Double,_ url:URL)->Void){

        // -- Take lock to add request into queue
        queueMutex.lock()

        // update the state of Request Object
        // From None -> Waiting in Queue
        reqObj.state = .WAITING
        reqObj.completionBlock = completionBlock
        reqObj.progressBlock = progressBlock
        
        // -- Add request into cache to process
        if reqObj.fastQueue {
            fastQueueCache.append(reqObj)
        }else{
            slowQueueCache.append(reqObj)
        }

        // -- Release lock here
        queueMutex.unlock()
    }

    /*
     Thread handle to moniter event queue and schedule them
     into network queue.
     */
    @objc func reqScheduleHndl(){

        while true {

            // -- Check event queue and schedule request here
            queueMutex.lock()

            if fastQueueCache.count > 0 || slowQueueCache.count > 0{

                // -- Get and remove object from event queue
                if let request = self.getNxtRequest(){

                    // update the state of Request Object
                    // From Waiting -> Processing in Queue
                    print("processing rest event \(request.eventID)")
                    request.state = .PROCESSING

                    // -- Add event object into network run loop here
                    if request.fastQueue{
                        fastQueue?.addNetworkEvent(evobj: request)
                    }else{
                        slowQueue?.addNetworkEvent(evobj: request)
                    }

                    queueMutex.unlock()

                    // -- Pause scheduler thead with semaphore wait here
                    _ = sema.wait(timeout: .distantFuture)
                    

                }else{
                    // Error no request found
                    queueMutex.unlock()
                }

            }else{
                queueMutex.unlock()
                usleep(useconds_t(Thread_Sleep_Time))
            }
        }

    }


    // -- Do not call this func with mutex lock
    func getNxtRequest() -> RestEngineEvents? {

        var evobj : RestEngineEvents? = nil

        if fastQueueCache.count > 0 {
            evobj = fastQueueCache.first!
        }else if (slowQueueCache.count > 0 && !(slowQueue?.isFileInProcess)!){
            evobj = slowQueueCache.first!
        }

        return evobj
    }

    func notifyProgress(queueType:String,progress:Double, forFile url:URL){
    
        //-- Remove processed request
        queueMutex.lock()
        
        if queueType == SLOW_QUEUE, slowQueueCache.count > 0 {
            
            if let evobj = slowQueueCache.first,evobj.state == .PROCESSING{
                
                // Call callback handler
                if let callback = evobj.progressBlock{
                    callback(evobj.eventID,progress,url)
                }
                
            }else{
                // Ignore waiting request
            }
            
        }
        
        queueMutex.unlock()
    }
    
    func notifyThread(queueType:String,response:AnyObject){
        //-- Remove processed request
        queueMutex.lock()

        if queueType == FAST_QUEUE, fastQueueCache.count > 0{
            // Remove request only if it was in processing state
            // otherwise it will endup removing wrong waiting request

            if let evobj = fastQueueCache.first,evobj.state == .PROCESSING{
                // Call callback handler
                print("completed fast queue rest event \(evobj.eventID)")
                if let callback = evobj.completionBlock{
                    callback(evobj.eventID,Success,response)
                }
                
                self.fastQueueCache.removeFirst()
            }else{
                // Ignore waiting request
            }

        }else if queueType == SLOW_QUEUE, slowQueueCache.count > 0 {

            if let evobj = slowQueueCache.first,evobj.state == .PROCESSING{
                
                // Call callback handler
                print("completed slow queue rest event \(evobj.eventID)")
                if let callback = evobj.completionBlock{
                    callback(evobj.eventID,Success,response)
                }
                
                self.slowQueueCache.removeFirst()
            }else{
                // Ignore waiting request
            }

        }

        queueMutex.unlock()
        // -- Resume thread semaphore here
        sema.signal()
    }

}
