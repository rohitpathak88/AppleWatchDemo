//
//  NetworkManager.swift
//  AppleWatchDemo
//
//  Created by Rohit Pathak on 10/06/19.
//  Copyright © 2019 Rohit Pathak. All rights reserved.
//

import Foundation
import Alamofire

class NetworkManager: EventLoop {
    
    var queueType:String?
    var isFileInProcess = false
    
    override init() {
        
        super.init()
        
        reachabilityManager?.listener = { status in
            print("Network Status Changed: \(status)")
        }
        
        reachabilityManager?.startListening()
        
        // -- This will spawn new network thread
        // -- and invoke EventLoop method
        self.start()
    }
    
    let reachabilityManager = NetworkReachabilityManager(host: "www.apple.com")
    
    private let sessionManager: SessionManager = {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = SessionManager.defaultHTTPHeaders
        configuration.timeoutIntervalForRequest = 120
        
        return SessionManager(configuration: configuration)
    }()
    
    /*
     Used to add network request in network run loop
     */
    
    func addNetworkEvent(evobj:RestEngineEvents){
        super.addEvent(evObj: evobj)
    }
    
    override func processQueuedEvent(evobj: Any){
        
        if let restObject = evobj as? RestEngineEvents{
            
            if restObject.fastQueue{
                // process simple rest request
                processRestRequest(apiRequest:restObject.apiRequest)
            }else{
                // Slow Queue
                if let data = restObject.object as? [String:Any] {
                    
                    if restObject.downloadingFile,let url = data["squadPic"] as? URL {
                        
                        if let urlToSave = data["kDownloadFilePath"] as? URL{
                            self.processDownloadFileRequest(serverURL: url, localFileURL: urlToSave)
                        }
                        
                    }else if restObject.uploadMultipart{
                        
                        if let params = restObject.object as? [String:Any],
                            let imageArr = params["imageArr"] as? [Any],
                            let imageNames = params["imageNames"] as? [String],
                            let fileNames = params["fileNames"] as? [String],
                            let urlStr = restObject.apiRequest?.urlRequest?.url{
                            
                            self.uploadMediaService(url: urlStr, data: imageArr, withName: imageNames, fileName: fileNames, mimeType: ["image/jpeg","image/jpeg","image/jpeg"], parameters: params)
                            
                        }
                        
                    }
                    else if let url = data["squadPic"] as? URL{
                        self.processUploadFileRequest(url: url, apiRequest: restObject.apiRequest)
                    }
                    
                }else{
                    print("url not found")
                }
            }
        }else{
            //ERROR
            print("Not handle yet %@",evobj)
        }
    }
    
    fileprivate func processUploadFileRequest(url:URL,apiRequest:URLRequestConvertible?){
        self.isFileInProcess = true
        if let request =  apiRequest{
            sessionManager.upload(url, with: request)
                .uploadProgress { progress in // main queue by default
                    print("Upload Progress: \(progress.fractionCompleted)")
                    self.handleProgress(progress: progress.fractionCompleted, forFile: url)
                    
                }
                .responseData { responseData in
                    self.isFileInProcess = false
                    self.handleRestResponse(response: responseData)
            }
        } else {
            
        }
    }
    
    fileprivate func uploadMediaService(url:URL, data:[Any], withName:[String], fileName:[String], mimeType:[String], parameters:[String:Any]?) {
        
        self.isFileInProcess = true
        sessionManager.upload(multipartFormData: { (multipartFormData) in
            
            for (key,value) in parameters! {
                if let value = value as? String {
                    multipartFormData.append(value.data(using: String.Encoding.utf8)!, withName: key)
                }
            }
            
            for (index,item) in data.enumerated() {
                if let items = item as? UIImage {
                    multipartFormData.append(items.jpegData(compressionQuality: 0.5)!, withName: withName[index], fileName: fileName[index], mimeType: mimeType[index])
                }
            }
            
        }, to:url) { (result) in
            
            switch result {
            case .success(let upload, _, _):
                upload.uploadProgress(closure: { (progress) in
                    self.handleProgress(progress: progress.fractionCompleted, forFile:url)
                })
                upload.responseData { response in
                    self.isFileInProcess = false
                    self.handleRestResponse(response: response)
                }
            case .failure(let error):
                print(error.localizedDescription)
                break
            }
        }
    }
    
    fileprivate func processDownloadFileRequest(serverURL:URL,localFileURL:URL){
        
        self.isFileInProcess = true
        
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            return (localFileURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        Alamofire.download(serverURL, to: destination)
            .downloadProgress { (progress) in
                print("Download Progress: \(progress.fractionCompleted)")
                self.handleProgress(progress: progress.fractionCompleted, forFile: localFileURL)
            }
            .response { response in
                
                self.isFileInProcess = false
                
                if response.error == nil{
                    self.handleRestResponse(response: response)
                }
                
        }
    }
    
    fileprivate func processRestRequest(apiRequest:URLRequestConvertible?){
        
        if let request = try? apiRequest?.asURLRequest(){
            sessionManager.request(request).responseJSON { (response) in
                self.handleRestResponse(response: response.value)
            }
        }
    }
    
    // MARK: Handlers
    fileprivate func handleProgress(progress:Double, forFile url:URL){
        RequestScheduler.shared.notifyProgress(queueType: queueType!, progress: progress, forFile: url)
    }
    
    fileprivate func handleRestResponse(response:DataResponse<Data>){
        // Notify Scheduler to schedule next request
        RequestScheduler.shared.notifyThread(queueType: queueType!,response: response.data as AnyObject)
    }
    
    fileprivate func handleRestResponse(response:Any?){
        // Notify Scheduler to schedule next request
        RequestScheduler.shared.notifyThread(queueType: queueType!,response: response as AnyObject)
    }
    
    fileprivate func handleRestResponse(response:[String:Any]){
        // Notify Scheduler to schedule next request
        RequestScheduler.shared.notifyThread(queueType: queueType!,response: response as AnyObject)
    }
    
    fileprivate func handleRestResponse(response:DefaultDownloadResponse){
        // Notify Scheduler to schedule next request
        RequestScheduler.shared.notifyThread(queueType: queueType!,response: response as AnyObject)
    }
    
}
