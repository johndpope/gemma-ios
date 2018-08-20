//
//  NBLNetworkService.swift
//  EOS
//
//  Created by koofrank on 2018/7/9.
//  Copyright © 2018年 com.nbltrust. All rights reserved.
//

import Foundation
import Moya
import SwifterSwift
import SwiftyJSON
import Alamofire

enum NBLService {
    case createAccount(account:String, pubKey:String, invitationCode:String, hash:String)
    case accountVerify(account:String)
    case accountHistory(account:String, showNum:Int, lastPosition:Int)
    case producer(showNum:Int)
}

func defaultManager() -> Alamofire.SessionManager {
    let configuration = URLSessionConfiguration.default
    configuration.httpAdditionalHeaders = Alamofire.SessionManager.defaultHTTPHeaders
    configuration.timeoutIntervalForRequest = 5
    
    let manager = Alamofire.SessionManager(configuration: configuration)
    manager.startRequestsImmediately = false
    return manager
}

struct NBLNetwork {
    static let provider = MoyaProvider<NBLService>(callbackQueue: nil, manager: defaultManager(), plugins: [NetworkLoggerPlugin(verbose: true)], trackInflights: false)
    
    static func request(
        target: NBLService,
        success successCallback: @escaping (JSON) -> Void,
        error errorCallback: @escaping (_ statusCode: Int) -> Void,
        failure failureCallback: @escaping (MoyaError) -> Void
        ) {
        
        provider.request(target) { (result) in
            switch result {
            case let .success(response):
                do {
                    let response = try response.filterSuccessfulStatusCodes()
                    let json = try JSON(response.mapJSON())
                    if json["code"].intValue == 0 {
                        let result = json["result"]
                        successCallback(result)
                    }
                    else {
                        errorCallback(json["code"].intValue)
                    }
                }
                catch _ {
                    errorCallback(99999)
                }
            case let .failure(error):
                failureCallback(error)
            }
        }
    }

}


extension NBLService : TargetType {
    var baseURL: URL {
        return NetworkConfiguration.NBL_BASE_URL
    }
    
    var path: String {
        switch self {
        case .createAccount(_, _, _, _):
            return "/api/v1/faucet/new"
        case .accountVerify(_):
            return "/account/verify"
        case .accountHistory:
            return "/api/v1/account/history"
        case .producer(_):
            return "/api/v1/producer/fetch"
        }
    }
    
    var method: Moya.Method {
        return .post
    }
    
    var parameters: [String: Any] {
        switch self {
        case let .createAccount(account, pubKey, invitationCode, hash):
            return ["account_name": account, "invitation_code": invitationCode, "public_key": pubKey, "app_id": 1, "hash": hash]
        case let .accountVerify(account):
            return ["account_name": account]
        case let .accountHistory(account, showNum, lastPosition):
            return ["account_name": account, "show_num":showNum, "last_pos": lastPosition]
        case let .producer(showNum):
            return ["show_num": showNum]
        }
    }
    
    var task: Task {
        return .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
    }

    var sampleData: Data {
        return try! JSON(parameters).rawData()
    }

    
    var headers: [String : String]? {
        return ["Content-type": "application/json"]
    }
}

private extension String {
    var urlEscaped: String {
        return addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
    }
    
    var utf8Encoded: Data {
        return data(using: .utf8)!
    }
}
