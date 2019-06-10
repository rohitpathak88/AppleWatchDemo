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

// identifier: page Interface Controller identifier.
// Context: page context, a string used as the action button title.
//
struct ControllerID {
    static let mainInterfaceController = "MainInterfaceController"
}

class InterfaceController: WKInterfaceController, TestDataProvider, SessionCommands  {

    // Retain the controllers so that we don't have to reload root controllers for every switch.
    //
    static var instances = [InterfaceController]()
    private var command: Command!
    
    @IBOutlet var statusLabel: WKInterfaceLabel!
    @IBOutlet var commandButton: WKInterfaceButton!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
        if let context = context as? CommandStatus {
            command = context.command
            updateUI(with: context)
            type(of: self).instances.append(self)
        } else {
            statusLabel.setText("Activating...")
        }
        
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
        
        guard command != nil else { return } // For first-time loading do nothing.
        
        // For .updateAppContext, retrieve the receieved app context if any and update the UI.
        // For .transferFile and .transferUserInfo, log the outstanding transfers if any.
        //
        if command == .updateAppContext {
            let timedColor = WCSession.default.receivedApplicationContext
            if timedColor.isEmpty == false {
                var commandStatus = CommandStatus(command: command, phrase: .received)
                commandStatus.timedColor = TimedColor(timedColor)
                updateUI(with: commandStatus)
            }
        }
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    // .dataDidFlow notification handler. Update the UI based on the command status.
    //
    @objc
    func dataDidFlow(_ notification: Notification) {
        guard let commandStatus = notification.object as? CommandStatus else { return }
        
        // If the data is from current channel, simple update color and time stamp, then return.
        //
        if commandStatus.command == command {
            updateUI(with: commandStatus, errorMessage: commandStatus.errorMessage)
            return
        }
        
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
    
    // Update the user interface with the command status.
    // Note that there isn't a timed color when the interface controller is initially loaded.
    //
    private func updateUI(with commandStatus: CommandStatus, errorMessage: String? = nil) {
        guard let timedColor = commandStatus.timedColor else {
            statusLabel.setText("")
            commandButton.setTitle(commandStatus.command.rawValue)
            return
        }
    }
    
    // Do the command associated with the current page.
    //
    @IBAction func commandAction() {
        
        updateAppContext(appContext)
        
//        guard let command1 = command else { return }
//
//        switch command1 {
//        case .updateAppContext: updateAppContext(appContext)
//        case .sendMessage: sendMessage(message)
//        case .sendMessageData: sendMessageData(messageData)
//        case .transferUserInfo: transferUserInfo(userInfo)
//        case .transferFile: transferFile(file, metadata: fileMetaData)
//        case .transferCurrentComplicationUserInfo: transferCurrentComplicationUserInfo(currentComplicationInfo)
//        }
    }
}
