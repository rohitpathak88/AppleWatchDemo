//
//  InterfaceController.swift
//  AppleWatchDemo WatchKit Extension
//
//  Created by Rohit Pathak on 10/06/19.
//  Copyright © 2019 Rohit Pathak. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity

class InterfaceController: WKInterfaceController{

    @IBOutlet var statusLabel: WKInterfaceLabel!
    @IBOutlet var commandButton: WKInterfaceButton!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Install notification observer.
        //
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
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    // .dataDidFlow notification handler. Update the UI based on the command status.
    //
    @objc
    func dataDidFlow(_ notification: Notification) {
    
    }
    
    // .activationDidComplete notification handler.
    //
    @objc
    func activationDidComplete(_ notification: Notification) {
        print("\(#function): activationState:\(WCSession.default.activationState.rawValue)")
    }
    
    // .reachabilityDidChange notification handler.
    //
    @objc
    func reachabilityDidChange(_ notification: Notification) {
        print("\(#function): isReachable:\(WCSession.default.isReachable)")
    }
    
    private func updateUI(success:Bool,message:String){
        
        self.statusLabel.setText(message)

        let color:UIColor = success ? .white : .red
        
        self.statusLabel.setTextColor(color)
    }
    
    // Do the command associated with the current page.
    //
    @IBAction func commandAction() {
        
        let urlStr = URL(string: "http://yin2.schwarzsoftware.com.au/cgi-bin/hello_world.py")
        
        let stringPost="timestamp=\(Date().iso8601)" // Key and Value

        var request = URLRequest(url: urlStr! , cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 60)
        
        request.httpBody = stringPost.data(using: .utf8)
        request.httpMethod = "POST" // POST ,GET, PUT What you want
        
        let session = URLSession.shared
        
        let dataTask = session.dataTask(with: request as URLRequest) {data,response,error in
            
            do {
                
                if let respdata = data, let jsonResult = try JSONSerialization.jsonObject(with: respdata, options: .mutableContainers) as? [String:Any]{
                    
                    if let sucess = jsonResult["success"] as? Bool,
                        let msg = jsonResult["message"] as? String{
                        self.updateUI(success: sucess, message: msg)
                    }
                    
                }
                
            } catch let error as NSError {
                print(error.localizedDescription)
            }
            
        }
        dataTask.resume()

    }
    
}
