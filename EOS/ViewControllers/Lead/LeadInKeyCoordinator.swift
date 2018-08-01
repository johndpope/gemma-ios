//
//  LeadInKeyCoordinator.swift
//  EOS
//
//  Created DKM on 2018/7/31.
//  Copyright © 2018年 com.nbltrust. All rights reserved.
//

import UIKit
import ReSwift

protocol LeadInKeyCoordinatorProtocol {
    func openScan()

    func openSetWallet()
}

protocol LeadInKeyStateManagerProtocol {
    var state: LeadInKeyState { get }
    func subscribe<SelectedState, S: StoreSubscriber>(
        _ subscriber: S, transform: ((Subscription<LeadInKeyState>) -> Subscription<SelectedState>)?
    ) where S.StoreSubscriberStateType == SelectedState
}

class LeadInKeyCoordinator: HomeRootCoordinator {
    
    lazy var creator = LeadInKeyPropertyActionCreate()
    
    var store = Store<LeadInKeyState>(
        reducer: LeadInKeyReducer,
        state: nil,
        middleware:[TrackingMiddleware]
    )
}

extension LeadInKeyCoordinator: LeadInKeyCoordinatorProtocol {
    func openScan() {
        let vc = BaseNavigationController()
        let scanCoordinator = ScanRootCoordinator(rootVC: vc)
        scanCoordinator.start()
        self.rootVC.present(vc, animated: true, completion: nil)
    }
    
    func openSetWallet() {
        if let vc = R.storyboard.leadIn.setWalletViewController() {
            vc.coordinator = SetWalletCoordinator(rootVC: self.rootVC)
            self.rootVC.pushViewController(vc, animated: true)
        }
    }
}

extension LeadInKeyCoordinator: LeadInKeyStateManagerProtocol {
    var state: LeadInKeyState {
        return store.state
    }
    
    func subscribe<SelectedState, S: StoreSubscriber>(
        _ subscriber: S, transform: ((Subscription<LeadInKeyState>) -> Subscription<SelectedState>)?
        ) where S.StoreSubscriberStateType == SelectedState {
        store.subscribe(subscriber, transform: transform)
    }
    
}
