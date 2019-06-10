//
//  ApiRouter.swift
//  AppleWatchDemo
//
//  Created by Rohit Pathak on 10/06/19.
//  Copyright © 2019 Rohit Pathak. All rights reserved.
//

import Foundation
import Alamofire

enum ApiRouter: URLRequestConvertible {
    
    case login(params:Parameters)
    
    
    var method: HTTPMethod {
        switch self {
        default:return .post
        }
    }
    
    var path: String {
        switch self {
        case .login:
            return "http://yin2.schwarzsoftware.com.au/cgi-bin/hello_world.py"
        }
    }
    
    // MARK: URLRequestConvertible
    
    func asURLRequest() throws -> URLRequest {
        
        var urlRequest = URLRequest(url:try path.asURL())
        urlRequest.httpMethod = method.rawValue
        
        switch self {
        case .login(let parameters):
            urlRequest = try URLEncoding.default.encode(urlRequest, with: parameters)
            
            return urlRequest
        }
    }
}
