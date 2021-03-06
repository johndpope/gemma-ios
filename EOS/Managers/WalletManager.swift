//
//  WalletManager.swift
//  EOS
//
//  Created by koofrank on 2018/7/9.
//  Copyright © 2018年 com.nbltrust. All rights reserved.
//

import Foundation
import KeychainAccess
import SwifterSwift
import SwiftyUserDefaults
import Repeat
import SwiftDate
import eos_ios_core_cpp
import seed39_ios_golang

class WalletManager {
    static let shared = WalletManager()

    let keychain = Keychain(service: SwifterSwift.appBundleID ?? "com.nbltrust.gemma")

    var currentPubKey: String = Defaults[.currentWallet]
    var accountNames: [String] = Defaults[.accountNames]

    var priKey: String = ""

    var timer: Repeater?

    private init() {
        //test
        Seed39SignERC20()
    }

    func createPairKey() {
        if let keys = EOSIO.createKey(), let pub = keys[optional: 0], let pri = keys[optional: 1] {
            currentPubKey = pub
            priKey = pri
        }
    }

    func saveWallket(_ account: String,
                     password: String,
                     hint: String,
                     isImport: Bool = false,
                     txID: String? = nil,
                     invitationCode: String? = nil,
                     type: CreateAPPId? = nil,
                     deviceName: String? = nil) {
        if type == .bluetooth {
            savePriKey(priKey, publicKey: currentPubKey, password: password)
            savePasswordHint(currentPubKey, hint: hint)

            addToLocalWallet(isImport, accountName: account, type: type, deviceName: deviceName)
            switchWallet(currentPubKey)
            accountNames = [account]

            switchAccount(0)

            removePriKey()
        } else {
            savePriKey(priKey, publicKey: currentPubKey, password: password)
            savePasswordHint(currentPubKey, hint: hint)

            addToLocalWallet(isImport, accountName: account, type: type, deviceName: deviceName)
            switchWallet(currentPubKey)
            accountNames = [account]

            switchAccount(0)
            removePriKey()

        }
    }

    func updateWalletPassword(_ password: String, hint: String) {
        guard let pubKey = EOSIO.getPublicKey(self.priKey) else { return }
        savePriKey(self.priKey, publicKey: pubKey, password: password)
        savePasswordHint(pubKey, hint: hint)
    }

    func updateWalletName(_  publicKey: String, walletName: String) {
        var wallets = Defaults[.walletList]

        if let walletIndex = wallets.map({ $0.publicKey }).index(of: publicKey) {
            var wallet = wallets[walletIndex]
            wallet.name = walletName
            wallets[walletIndex] = wallet
            Defaults[.walletList] = wallets
        }
    }

    func addToLocalWallet(_ isImport: Bool = false, accountName: String?, type: CreateAPPId? = nil, deviceName: String? = nil) {
        var wallets = Defaults[.walletList]

        if !wallets.map({ $0.publicKey }).contains(currentPubKey) {
            let currentIndex = currentWalletCount() + 1
            var walletName = "EOS-WALLET-\(currentIndex)"
            if let walletType = type, walletType == .bluetooth {
                walletName = "WOOKONG Bio"
            }
            let wallet = WalletList(name: walletName,
                                    accountName: accountName,
                                    created: "",
                                    publicKey: currentPubKey,
                                    isBackUp: isImport ? true : false,
                                    creatStatus: WalletCreatStatus.willGetAccountInfo.rawValue,
                                    getAccountInfoDate: Date(),
                                    isImport: isImport,
                                    type: type,
                                    deviceName: deviceName)
            wallets.append(wallet)
            Defaults[.walletList] = wallets
        }
    }

    func getAccount() -> String {
        removePriKey()//清除私钥

        if let wallet = currentWallet() {
            if accountNames.count == 0 {
                return "--"
            }
            if let walletAccount = wallet.accountName {
                return walletAccount
            }
        }

        return "--"
    }

    func fetchAccount(_ callback: @escaping StringCallback) {
        if let wallet = currentWallet() {
            if let pubKey = wallet.publicKey {
                if accountNames.count == 0 {
                    fetchAccountNames(pubKey) { (success) in
                        if success {
                            callback(self.accountNames[0])
                        } else {
                            callback("--")
                        }
                    }
                    return
                }
                return callback(self.accountNames[0])
            }
        }

        return callback("--")
    }

    func fetchAccountNames(_ publicKey: String, completion: @escaping (Bool) -> Void) {
        EOSIONetwork.request(target: .getKeyAccounts(pubKey: publicKey), success: { (json) in
            if let names = json["account_names"].arrayObject as? [String] {
                self.accountNames = names
                Defaults[.accountNames] = names

                completion(names.count > 0)
            }
        }, error: { (_) in
            completion(false)
        }) { (_) in
            completion(false)
        }
    }

    func addPrivatekey(_ pri: String) {
        self.priKey = pri
    }

    func removePriKey() {
        self.priKey = ""
    }

    func importPrivateKey(_ password: String, hint: String, completion: @escaping (Bool) -> Void) {
        guard let pubKey = EOSIO.getPublicKey(self.priKey) else { completion(false); return }
        fetchAccountNames(pubKey) { (success) in
            if success {
                self.currentPubKey = pubKey

                self.saveWallket(self.accountNames[0], password: password, hint: hint, isImport: true, txID: nil, type: .gemma, deviceName: nil)
            }
            completion(success)
        }
    }

    func currentWallet() -> WalletList? {
        let pubKey = Defaults[.currentWallet]
        let wallets = wallketList()

        if let index = wallets.map({ $0.publicKey }).index(of: pubKey) {
            return wallets[index]
        }

        return nil
    }

    func isBluetoothWallet() -> Bool {
        if let wallet = currentWallet() {
            return wallet.type == .bluetooth
        }
        return false
    }

    func wallketList() -> [WalletList] {
        return Defaults[.walletList]
    }

    func switchWallet(_ publicKey: String) {
        currentPubKey = publicKey
        Defaults[.currentWallet] = publicKey
    }

    func switchAccount(_ index: Int) {
        var wallets = Defaults[.walletList]
        if let walletIndex = wallets.map({ $0.publicKey }).index(of: currentPubKey) {
            var wallet = wallets[walletIndex]
            wallet.accountName = accountNames[index]
            wallets[walletIndex] = wallet
            Defaults[.walletList] = wallets
        }
    }

    func existWallet() -> Bool {
        return currentWalletCount() != 0
    }

    func registerSuccess(_ pubKey: String) {
        var wallets = wallketList()

        if let index = wallets.map({ $0.publicKey }).index(of: pubKey) {
            var wallet = wallets[index]
            wallet.creatStatus = WalletCreatStatus.creatSuccessed.rawValue
            wallets[index] = wallet

            Defaults[.walletList] = wallets
        }
    }

    func backupSuccess(_ pubKey: String) {
        var wallets = wallketList()

        if let index = wallets.map({ $0.publicKey }).index(of: pubKey) {
            var wallet = wallets[index]
            wallet.isBackUp = true
            wallets[index] = wallet

            Defaults[.walletList] = wallets
        }
    }

    func currentWalletCount() -> Int {
        let wallets = Defaults[.walletList]

        return wallets.count
    }

    func removeAllWallets() {
        Defaults.remove(.walletList)
    }

    func removeWallet(_ publicKey: String) {
        var wallets = Defaults[.walletList]
        if let index = wallets.map({ $0.publicKey }).index(of: publicKey) {
            wallets.remove(at: index)
            Defaults[.walletList] = wallets
        }

        try? keychain.remove("\(publicKey)-passwordHint")
        try? keychain.remove("\(publicKey)-pubKey")
        try? keychain.remove("\(publicKey)-cypher")

        if wallets.count == 0 {
            appCoodinator.curDisplayingCoordinator().rootVC.popToRootViewController(animated: true)
        } else {
            appCoodinator.curDisplayingCoordinator().rootVC.popToRootViewController(animated: true)
        }
    }

    func switchToLastestWallet() -> Bool {
        let wallets = Defaults[.walletList]

        if let wallet = wallets.last {
            if let pubKey = wallet.publicKey {
                switchWallet(pubKey)
                return true
            }
        }

        return false
    }

    func getCurrentSavedPublicKey() -> String {
        return Defaults[.currentWallet]
    }

    private func savePasswordHint(_ publicKey: String, hint: String) {
        guard hint.count > 0 else { return }

        keychain[string: "\(publicKey)-passwordHint"] = hint
    }

    func getPasswordHint(_ publicKey: String) -> String? {
        if let hint = keychain[string: "\(publicKey)-passwordHint"] {
            return hint
        }

        return nil
    }

    private func savePriKey(_ privateKey: String, publicKey: String, password: String) {
        if let cypher = EOSIO.getCypher(privateKey, password: password) {
            keychain[string: "\(publicKey)-cypher"] = cypher
        }
    }

    func getCachedPriKey(_ publicKey: String, password: String) -> String? {
        if let cypher = keychain[string: "\(publicKey)-cypher"], let pri = EOSIO.getPirvateKey(cypher, password: password), pri.count > 0, pri != "wrong password" {
            self.priKey = pri
            return pri
        }
        return nil
    }

    // MARK: Check Wallet creation
    func checkCurrentWallet() {
        if let wallet = self.currentWallet() {
            if let creatStatus = wallet.creatStatus {
                switch(creatStatus) {
                case WalletCreatStatus.willGetAccountInfo.rawValue:
                    willGetAccountInfo(wallet)
                case WalletCreatStatus.failedGetAccountInfo.rawValue:
                    failedGetAccountInfo()
                case WalletCreatStatus.failedWithReName.rawValue:
                    failedWithReName()
                case WalletCreatStatus.willGetLibInfo.rawValue:
                    willGetLibInfo(wallet)
                case WalletCreatStatus.creatSuccessed.rawValue:
                    if let pubKey = wallet.publicKey {
                        registerSuccess(pubKey)
                    }
                default:
                    return
                }

            }
        }
    }

    func getAccoutInfo(_ accountName: String, completion: @escaping (_ success: Bool, _ created: String) -> Void) {
        EOSIONetwork.request(target: .getAccount(account: accountName, otherNode: true), success: {[weak self] (account) in
            guard let `self` = self else { return }
            if let account = Account.deserialize(from: account.dictionaryObject) {
                self.checkPubKey(account, completion: { (success) in
                    if success {
                        if let created = account.created {
                            completion(true, created)
                            return
                        }
                    }
//                    else {
//                        if var wallet = self.currentWallet() {
//                            wallet.creatStatus = WalletCreatStatus.failedWithReName.rawValue
//                            self.updateWallet(wallet)
//                            self.checkCurrentWallet()
//                            return
//                        }
//                    }
                    completion(false, "")
                })
            }
        }, error: { (_) in
            completion(false, "")
        }, failure: { (_) in
            completion(false, "")
        })
    }

    func getLibInfo(_ created: String, completion: @escaping (Bool) -> Void) {
        EOSIONetwork.request(target: .getInfo, success: { (info) in
            let lib = info["last_irreversible_block_num"].stringValue
            EOSIONetwork.request(target: .getBlock(num: lib), success: { (block) in
                let time = block["timestamp"].stringValue.toDate("yyyy-MM-dd'T'HH:mm:ss.SSSSSS", region: Region.ISO)!
                let createdTime = created.toDate("yyyy-MM-dd'T'HH:mm:ss.SSSSSS", region: Region.ISO)!
                if  time >= createdTime {
                    completion(true)
                } else {
                    completion(false)
                }

            }, error: { (_) in
                completion(false)
            }, failure: { (_) in
                completion(false)
            })
        }, error: { (_) in
            completion(false)
        }, failure: { (_) in
            completion(false)
        })
    }

    func willGetAccountInfo(_ wallet: WalletList) {
        var wallet = wallet
        if wallet.getAccountInfoDate == nil {
            wallet.getAccountInfoDate = Date()
            self.updateWallet(wallet)
        }
        self.timer = Repeater.every(.seconds(10)) {[weak self] _ in
            guard let `self` = self else { return }
            if let account = wallet.accountName {
                self.getAccoutInfo(account) {(success, created) in
                    if success {
                        self.closeTimer()
                        wallet.creatStatus = WalletCreatStatus.willGetLibInfo.rawValue
                        wallet.created = created
                    } else {
                        if let startTime = wallet.getAccountInfoDate {
                            let nowTime = Date()
                            if nowTime.timeIntervalSince(startTime) >= 120 {
                                self.closeTimer()
                                wallet.creatStatus = WalletCreatStatus.failedGetAccountInfo.rawValue
                            }
                        }
                    }
                    self.updateWallet(wallet)
                    self.checkCurrentWallet()
                }
            }
        }

        timer?.start()
    }

    func willGetLibInfo(_ wallet: WalletList) {
        var wallet = wallet
        if let created = wallet.created {
            getLibInfo(created) {[weak self] (success) in
                guard let `self` = self else { return }
                if success {
                    if let account = wallet.accountName {
                        self.getAccoutInfo(account, completion: { (success, _) in
                            if success {
                                wallet.creatStatus = WalletCreatStatus.creatSuccessed.rawValue
                                self.updateWallet(wallet)
                                self.checkCurrentWallet()
                            } else {
                                wallet.creatStatus = WalletCreatStatus.failedGetAccountInfo.rawValue
                                self.updateWallet(wallet)
                                self.checkCurrentWallet()
                            }
                        })
                    }
                } else {
                    self.checkCurrentWallet()
                }
            }
        }
    }

    func failedGetAccountInfo() {
        showWarning(R.string.localizable.error_createAccount_failed.key.localized())
        let networkStr = getNetWorkReachability()
        if networkStr != WifiStatus.notReachable.rawValue {
            self.removeWallet(self.currentPubKey)
        }
    }

    func failedWithReName() {
        showWarning(R.string.localizable.error_account_registered.key.localized())
    }

    func checkPubKey(_ account: Account, completion:@escaping ResultCallback) {
        for permission in account.permissions {
            for authKey in permission.requiredAuth.keys {
                if authKey.key == self.currentPubKey {
                    completion(true)
                    return
                }
            }
        }
        completion(false)
    }

    func updateWallet(_ wallet: WalletList) {
        var wallets = wallketList()
        if let index = wallets.map({ $0.publicKey }).index(of: currentPubKey) {
            wallets[index] = wallet
            Defaults[.walletList] = wallets
        }
    }

    func closeTimer() {
        if self.timer != nil {
            self.timer?.pause()
            self.timer = nil
        }
    }

    // MARK: Format Check
    func isValidPassword(_ password: String) -> Bool {
        return password.count >= 8
    }

    func isValidComfirmPassword(_ password: String, comfirmPassword: String) -> Bool {
        return password == comfirmPassword
    }

    func isValidWalletName(_ name: String) -> Bool {
        let regex = "^[1-5a-z]{12}+$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
        return predicate.evaluate(with: name)
    }

}

extension WalletManager {
    // MARK: Account DB
    func getAccountModelsWithAccountName(name: String) -> AccountModel? {
        var condition = DataFetchCondition()
        condition.key = "account_name"
        condition.value = name
        condition.check = .equal
        do {
            let data = try DataProvider.shared.selectData("AccountModel", valueConditon: condition)
            if data.count > 0 {
                let dict = data[0]
                var accountModel = AccountModel()
                accountModel.accountName = dict["account_name"] as? String
                accountModel.netWeight = dict["net_weight"] as? String
                accountModel.cpuWeight = dict["cpu_weight"] as? String
                accountModel.ramBytes = dict["ram_bytes"] as? Int64
                accountModel.from = dict["from"] as? String
                accountModel.to = dict["to"] as? String
                accountModel.delegateNetWeight = dict["delegate_net_weight"] as? String
                accountModel.delegateCpuWeight = dict["delegate_cpu_weight"] as? String
                accountModel.requestTime = dict["request_time"] as? Date
                accountModel.netAmount = dict["net_amount"] as? String
                accountModel.cpuAmount = dict["cpu_amount"] as? String
                accountModel.netUsed = dict["net_used"] as? Int64
                accountModel.netAvailable = dict["net_available"] as? Int64
                accountModel.netMax = dict["net_max"] as? Int64
                accountModel.cpuUsed = dict["cpu_used"] as? Int64
                accountModel.cpuAvailable = dict["cpu_available"] as? Int64
                accountModel.cpuMax = dict["cpu_max"] as? Int64
                accountModel.ramQuota = dict["ram_quota"] as? Int64
                accountModel.ramUsage = dict["ram_usage"]  as? Int64
                accountModel.created = dict["created"] as? String
                return accountModel
            }
            
        } catch {
            
        }
        return nil
    }
    
    //FingerName Manage
    func updateFingerName(_ model: WalletManagerModel, index: Int, fingerName: String) {
        Defaults[fingerKey(model, index: index)] = fingerName
    }
    
    func deleteFingerName(_ model: WalletManagerModel, index: Int) {
        updateFingerName(model, index: index, fingerName: "")
    }
    
    func fingerKey(_ model: WalletManagerModel, index: Int) -> String {
        return model.address + "\(index)"
    }
    
    func fingerName(_ model: WalletManagerModel, index: Int) -> String {
        if let name: String = Defaults[fingerKey(model, index: index)] as? String, !name.isEmpty {
            return name
        } else {
            return R.string.localizable.finger.key.localized() + fingerIndexStr(index)
        }
    }
    
    func fingerIndexStr(_ index: Int) -> String {
        switch index {
        case 0:
            return "一"
        case 1:
            return "二"
        case 2:
            return "三"
        default:
            return ""
        }
    }
}
