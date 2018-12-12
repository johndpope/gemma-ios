//
//  VerifyMnemonicWordCoordinator.swift
//  EOS
//
//  Created zhusongyu on 2018/9/13.
//  Copyright © 2018年 com.nbltrustdev. All rights reserved.
//

import UIKit
import ReSwift
import NBLCommonModule
import SwiftyUserDefaults

protocol VerifyMnemonicWordCoordinatorProtocol {
    func popToVC(_ vc: UIViewController)

    func dismissNav()

    func presentSetFingerPrinterVC()
}

protocol VerifyMnemonicWordStateManagerProtocol {
    var state: VerifyMnemonicWordState { get }

    func switchPageState(_ state: PageState)

    func validSequence(_ datas: [String], compairDatas: [String]) -> Bool

    func checkSeed(_ seed: String, success: @escaping () -> Void, failed: @escaping (String?) -> Void)

    func checkFeedSuccessed()

    func verifyMnemonicWord(_ data: [String: Any], seeds: [String], checkStr: String, isWookong: Bool, callback:@escaping (Bool) -> Void)

    func createWookongBioWallet(_ hint: String,
                                success: @escaping SuccessedComplication,
                                failed: @escaping FailedComplication)
}

class VerifyMnemonicWordCoordinator: NavCoordinator {
    var store = Store(
        reducer: gVerifyMnemonicWordReducer,
        state: nil,
        middleware: [trackingMiddleware]
    )

    var state: VerifyMnemonicWordState {
        return store.state
    }

    override func register() {
        Broadcaster.register(VerifyMnemonicWordCoordinatorProtocol.self, observer: self)
        Broadcaster.register(VerifyMnemonicWordStateManagerProtocol.self, observer: self)
    }
}

extension VerifyMnemonicWordCoordinator: VerifyMnemonicWordCoordinatorProtocol {
    func popToVC(_ vc: UIViewController) {
        self.rootVC.popToViewController(vc, animated: true)
    }

    func dismissNav() {
        self.rootVC.dismiss(animated: false) {
            self.presentSetFingerPrinterVC()
        }
    }

    func presentSetFingerPrinterVC() {
        let newHomeNav = appCoodinator.newHomeCoordinator.rootVC
        let printerVC = R.storyboard.bltCard.bltCardSetFingerPrinterViewController()!
        let nav = BaseNavigationController.init(rootViewController: printerVC)
        let coor = BLTCardSetFingerPrinterCoordinator(rootVC: nav)
        printerVC.coordinator = coor
        newHomeNav?.present(nav, animated: true, completion: nil)
    }

    func popRootVC() {
        appCoodinator.endEntry()
    }
}

extension VerifyMnemonicWordCoordinator: VerifyMnemonicWordStateManagerProtocol {
    func switchPageState(_ state: PageState) {
        DispatchQueue.main.async {
            self.store.dispatch(PageStateAction(state: state))
        }
    }

    func validSequence(_ datas: [String], compairDatas: [String]) -> Bool {
        if datas.count != compairDatas.count {
            return false
        } else {
            for index in 0..<datas.count {
                if datas[index] != compairDatas[index] {
                    return false
                }
            }
        }
        return true
    }

    func checkSeed(_ seed: String, success: @escaping () -> Void, failed: @escaping (String?) -> Void) {
        BLTWalletIO.shareInstance().checkSeed(seed, success: success, failed: failed)
    }

    func checkFeedSuccessed() {
        var hint = ""
        self.rootVC.viewControllers.forEach { (vc) in
            if let setWalletVC = vc as? SetWalletViewController {
                hint = setWalletVC.fieldView.hintView.textField.text ?? ""
            }
        }
        self.createWookongBioWallet(hint, success: { [weak self] in
            guard let `self` = self else {return}
            self.rootVC.topViewController?.endLoading()
            self.dismissNav()
            }, failed: { (reason) in
                self.rootVC.topViewController?.endLoading()
                if let failedReason = reason {
                    showFailTop(failedReason)
                }
        })
    }

    func createWookongBioWallet(_ hint: String,
                                success: @escaping SuccessedComplication,
                                failed: @escaping FailedComplication) {
        importWookongBioWallet(self.rootVC, hint: hint, success: success, failed: failed)
    }

    func verifyMnemonicWord(_ data: [String: Any], seeds: [String], checkStr: String, isWookong: Bool, callback:@escaping (Bool) -> Void) {
        if let selectValues = data["data"] as? [String]  {
            if selectValues.count == seeds.count {
                let isValid = validSequence(seeds, compairDatas: selectValues)
                if isValid == true {
                    if isWookong {
                        self.rootVC.topViewController?.startLoadingOnSelf(false, message: "")
                        checkSeed(checkStr, success: { [weak self] in
                            guard let `self` = self else { return }
                            self.checkFeedSuccessed()
                            callback(true)
                            }, failed: { [weak self] (reason) in
                                guard let `self` = self else { return }
                                self.rootVC.topViewController?.endLoading()
                                if let failedReason = reason {
                                    showFailTop(failedReason)
                                }
                                callback(false)
                        })
                    } else {
                        var isWalletManager = false
                        for subVC in self.rootVC.viewControllers {
                            if subVC is WalletManagerViewController {
                                isWalletManager = true
                                break
                            }
                        }
                        var wallet = WalletManager.shared.currentWallet()
                        if isWalletManager == true {
                            wallet = WalletManager.shared.getManagerWallet()
                        }
                        if let wallet = wallet {
                            WalletManager.shared.backupSuccess(wallet)
                            if wallet.type == .HD {
                                self.popRootVC()
                            }
                        }
                        callback(true)
                    }
                } else {
                    showFailTop(R.string.localizable.wookong_mnemonic_ver_failed.key.localized())
                    callback(false)
                }
            }
        }
    }
}
