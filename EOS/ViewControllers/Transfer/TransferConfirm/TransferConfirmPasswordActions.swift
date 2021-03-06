//
//  TransferConfirmPasswordActions.swift
//  EOS
//
//  Created 朱宋宇 on 2018/7/12.
//  Copyright © 2018年 com.nbltrust. All rights reserved.
//

import Foundation
import ReSwift
import RxCocoa
import HandyJSON

struct TransferConfirmPasswordContext: RouteContext, HandyJSON {
    init() {

    }

    var publicKey = WalletManager.shared.currentPubKey
    var iconType = ""
    var producers: [String] = []
    var type = ""
    var receiver = ""
    var amount = ""
    var remark = ""
    var callback: ((_ priKey: String, _ vc: UIViewController) -> Void)?
}

// MARK: - State
struct TransferConfirmPasswordState: BaseState {
    var pageState: BehaviorRelay<PageState> = BehaviorRelay(value: .initial)

    var context: BehaviorRelay<RouteContext?> = BehaviorRelay(value: nil)
}

// MARK: - Action Creator
class TransferConfirmPasswordPropertyActionCreate {
    public typealias ActionCreator = (_ state: TransferConfirmPasswordState, _ store: Store<TransferConfirmPasswordState>) -> Action?

    public typealias AsyncActionCreator = (
        _ state: TransferConfirmPasswordState,
        _ store: Store <TransferConfirmPasswordState>,
        _ actionCreatorCallback: @escaping ((ActionCreator) -> Void)
        ) -> Void
}
