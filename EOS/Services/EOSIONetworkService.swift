//
//  EOSIONetworkService.swift
//  EOS
//
//  Created by koofrank on 2018/7/9.
//  Copyright © 2018年 com.nbltrust. All rights reserved.
//

import Foundation
import Moya
import SwifterSwift
import SwiftyJSON
import SwiftyUserDefaults
import MMKV
import Alamofire

enum EOSIOService {
    //chain
    case getCurrencyBalance(account: String)
    case getAccount(account: String, otherNode: Bool)
    case getInfo
    case getBlock(num: String)
    case abiJsonToBin(json: String)
    case abiBinToJson(bin: String, action:EOSAction)
    case pushTransaction(json: String)
    case getTableRows(json:String)

    //history
    case getKeyAccounts(pubKey: String)
    case getTransaction(id: String)
}

struct EOSIONetwork {
    static let provider = MoyaProvider<EOSIOService>(callbackQueue: nil,
                                                     manager: defaultManager(),
                                                     plugins: [NetworkLoggerPlugin(verbose: true), DataCachePlugin()],
                                                     trackInflights: false)

    static func request(
        target: EOSIOService,
        fetchedCache: Bool = false,
        success successCallback: @escaping (JSON) -> Void,
        error errorCallback: @escaping (_ statusCode: Int) -> Void,
        failure failureCallback: @escaping (MoyaError) -> Void
        ) {
        var fetchedCache = fetchedCache
        switch target {
        case .getAccount:
            fetchedCache = true
        case .getCurrencyBalance:
            fetchedCache = true
        default:
            fetchedCache = false
        }

        if fetchedCache, let cache = MMKV.default().object(of: NSString.self, forKey: target.fetchCacheKey()) as? String {
            let json = JSON.init(parseJSON: cache)
            successCallback(json)
        }
        provider.request(target) { (result) in
            switch result {
            case let .success(response):
                do {
                    _ = try response.filterSuccessfulStatusCodes()
                    let json = try JSON(response.mapJSON())
                    if let str = json.rawString() {
                        MMKV.default().set(str, forKey: target.fetchCacheKey())
                    }
                    successCallback(json)
                } catch _ {
                    do {
                        let json = try JSON(response.mapJSON())
                        let error = json["error"]["code"].debugDescription
                        let codeKey = AppConfiguration.EOSErrorCodeBase + error
                        let codeValue = codeKey.localized()
                        if (error == "3080004" || error == "3080005"), WalletManager.shared.currentWallet()?.type == .bluetooth {
                            errorCallback(1)
                        } else {
                            showFailTop(codeValue)
                        }
                    } catch _ {

                    }
                    errorCallback(0)
                }
            case let .failure(error):
                let networkStr = getNetWorkReachability()
                if networkStr != WifiStatus.notReachable.rawValue {
                    showFailTop(R.string.localizable.request_failed.key.localized())
                } else {
                    endProgress()
                }

                failureCallback(error)
            }
        }
    }
}

extension EOSIOService: TargetType {
    var baseURL: URL {
        let configuration = NetworkConfiguration()
        switch self {
        case .getTransaction:
            return NetworkConfiguration.EOSWebAPI!
        default:
            return configuration.EOSIOBaseURL
        }
    }

    var isNeedCache: Bool {
        switch self {
        case .getAccount:
            return false
        default:
            return false
        }
    }

    var path: String {
        switch self {
        case .getCurrencyBalance:
            return "/v1/chain/get_currency_balance"
        case .getAccount:
            return "/v1/chain/get_account"
        case .getInfo:
            return "/v1/chain/get_info"
        case .getBlock:
            return "/api/v1/chain/get_block"
        case .abiJsonToBin:
            return "/v1/chain/abi_json_to_bin"
        case .abiBinToJson:
            return "/v1/chain/abi_bin_to_json"
        case .pushTransaction:
            return "/v1/chain/push_transaction"
        case .getKeyAccounts:
            return "/v1/history/get_key_accounts"
        case let .getTransaction(id):
            return "/api/v1/get_transaction/\(id)"
        case .getTableRows:
            return "/v1/chain/get_table_rows"
        }
    }

    var parameters: [String: Any] {
        switch self {
        case let .getCurrencyBalance(account):
            return ["account": account, "code": EOSIOContract.TokenCode, "symbol": NetworkConfiguration.EOSIODefaultSymbol]
        case let .getAccount(account, _):
            return ["account_name": account]
        case .getInfo:
            return [:]
        case let .getBlock(num):
            return ["block_num_or_id": num]
        case let .abiJsonToBin(json):
            return JSON(parseJSON: json).dictionaryObject ?? [:]
        case let .pushTransaction(json):
            var transaction: [String: Any] = ["compression": "none"]
            var jsonOb = JSON(parseJSON: json).dictionaryObject ?? [:]
            let signatures = jsonOb["signatures"]
            jsonOb.removeValue(forKey: "signatures")
            transaction["signatures"] = signatures
            transaction["transaction"] = jsonOb

            return transaction
        case let .abiBinToJson(bin, action):
            return ["code": EOSIOContract.TokenCode, "action": action.rawValue, "binargs": bin]
        case let .getKeyAccounts(pubKey):
            return ["public_key": pubKey]
        case .getTransaction:
            return [:]
        case let .getTableRows(json):
            return JSON(parseJSON: json).dictionaryObject ?? [:]
        }
    }

    var task: Task {
//        switch self {
//        case .getTransaction:
//            return .requestParameters(parameters: parameters, encoding: URLEncoding.default)
//        default:
            return .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
//        }
    }

    var method: Moya.Method {
        switch self {
        case .getTransaction:
            return .get
        default:
            return .post
        }
    }

    var sampleData: Data {
        guard let data = try? JSON(parameters).rawData() else {
            return Data()
        }
        return data
    }

    var headers: [String: String]? {
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

extension TargetType {
    func fetchCacheKey() -> String {
        return cacheKey
    }

    private var baseCacheKey : String {
        return "[\(self.method)]\(self.baseURL.absoluteString)/\(self.path)"
    }

    private var cacheKey: String {
        let baseKey = baseCacheKey

        if parameterRaw.isEmpty { return baseKey }
        return baseKey + "?" + parameterRaw
    }

    private var parameterRaw: String {
        switch self.task {
        case let .requestParameters(parameters, _):
            return JSON(parameters).rawString() ?? ""
        case let .requestCompositeParameters(bodyParameters, _, urlParameters):
            var parameters = bodyParameters
            for (key, value) in urlParameters { parameters[key] = value }
            return JSON(parameters).rawString() ?? ""
        case let .downloadParameters(parameters, _, _):
            return JSON(parameters).rawString() ?? ""
        case let .uploadCompositeMultipart(_, urlParameters):
            return JSON(urlParameters).rawString() ?? ""
        case let .requestCompositeData(_, urlParameters):
            return JSON(urlParameters).rawString() ?? ""
        default: return  ""
        }
    }
}
