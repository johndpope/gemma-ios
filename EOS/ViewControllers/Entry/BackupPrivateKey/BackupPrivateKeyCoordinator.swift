//
//  BackupPrivateKeyCoordinator.swift
//  EOS
//
//  Created zhusongyu on 2018/8/1.
//  Copyright © 2018年 com.nbltrust. All rights reserved.
//

import UIKit
import ReSwift
import Presentr

protocol BackupPrivateKeyCoordinatorProtocol {
    func showPresenterVC()
}

protocol BackupPrivateKeyStateManagerProtocol {
    var state: BackupPrivateKeyState { get }
    func subscribe<SelectedState, S: StoreSubscriber>(
        _ subscriber: S, transform: ((Subscription<BackupPrivateKeyState>) -> Subscription<SelectedState>)?
    ) where S.StoreSubscriberStateType == SelectedState
}

class BackupPrivateKeyCoordinator: EntryRootCoordinator {
    
    lazy var creator = BackupPrivateKeyPropertyActionCreate()
    
    var store = Store<BackupPrivateKeyState>(
        reducer: BackupPrivateKeyReducer,
        state: nil,
        middleware:[TrackingMiddleware]
    )
}

extension BackupPrivateKeyCoordinator: BackupPrivateKeyCoordinatorProtocol {
    func showPresenterVC() {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.appcoordinator?.showPresenterPwd(leftIconType: .dismiss)
        }
    }
}

extension BackupPrivateKeyCoordinator: BackupPrivateKeyStateManagerProtocol {
    var state: BackupPrivateKeyState {
        return store.state
    }
    
    func subscribe<SelectedState, S: StoreSubscriber>(
        _ subscriber: S, transform: ((Subscription<BackupPrivateKeyState>) -> Subscription<SelectedState>)?
        ) where S.StoreSubscriberStateType == SelectedState {
        store.subscribe(subscriber, transform: transform)
    }
    
}
