//
//  ViewController.swift
//  AppleWatchDemo
//
//  Created by Rohit Pathak on 10/06/19.
//  Copyright © 2019 Rohit Pathak. All rights reserved.
//

import UIKit
import WatchConnectivity

class ViewController: UIViewController,SessionCommands {
 
    var restCallBackID:String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
//        restCallBackID = CoreEngine.shared.registerEventCallBack(cbType: .REST_CALLBACK, cbBlock: { (what
//            , result, response) in
//
//            if let data = response as? [String:Any]{
//                self.updateAppContext(data)
//            }
//        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
//        if let callback = restCallBackID{
//            CoreEngine.shared.unregisterEventForID(cbType: .REST_CALLBACK, regId: callback)
//        }
    }
    
    func addObserver(){
        NotificationCenter.default.addObserver(
            self, selector: #selector(type(of: self).dataDidFlow(_:)),
            name: .dataDidFlow, object: nil
        )
        
        NotificationCenter.default.addObserver(
            self, selector: #selector(type(of: self).activationDidComplete(_:)),
            name: .activationDidComplete, object: nil
        )
        
        NotificationCenter.default.addObserver(
            self, selector: #selector(type(of: self).reachabilityDidChange(_:)),
            name: .reachabilityDidChange, object: nil
        )
    }
    
    // .activationDidComplete notification handler.
    //
    @objc
    func activationDidComplete(_ notification: Notification) {
    }
    
    // .reachabilityDidChange notification handler.
    //
    @objc
    func reachabilityDidChange(_ notification: Notification) {
    }
    
    // .dataDidFlow notification handler.
    // Update the UI based on the userInfo dictionary of the notification.
    //
    @objc
    func dataDidFlow(_ notification: Notification) {
        guard let commandStatus = notification.object as? CommandStatus else { return }
        
        if commandStatus.command == .updateAppContext{
            // Do any additional setup after loading the view.
//            let params = ["timestamp":Date().iso8601]
//            let restEvent  = RestEngineEvents.init(id: .LOGIN, obj: params as AnyObject)
//            CoreEngine.shared.addEvent(evObj: restEvent)
        }
        
    }

}

