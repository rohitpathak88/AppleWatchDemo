//
//  EventLoop.swift
//  AppleWatchDemo
//
//  Created by Rohit Pathak on 10/06/19.
//  Copyright © 2019 Rohit Pathak. All rights reserved.
//

import Foundation

class EventLoop: Thread {

    override func main() {
        let runloop = RunLoop.current
        runloop.add(NSMachPort(), forMode: .default)
        runloop.run()
    }

    func addEvent(evObj:EngineEvents){
        self.perform(#selector(processQueuedEvent(evobj:)), on: self, with: evObj, waitUntilDone: false)
    }

    @objc func processQueuedEvent(evobj:Any){
        
    }


    func cancelEvent(){
        RunLoop .cancelPreviousPerformRequests(withTarget: self)
    }

}
