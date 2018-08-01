//
//  CreatationCompleteCoordinator.swift
//  EOS
//
//  Created peng zhu on 2018/7/12.
//  Copyright © 2018年 com.nbltrust. All rights reserved.
//

import UIKit
import ReSwift

protocol CreatationCompleteCoordinatorProtocol {
    func dismissCurrentNav()
    func pushBackupPrivateKeyVC()
}

protocol CreatationCompleteStateManagerProtocol {
    var state: CreatationCompleteState { get }
    func subscribe<SelectedState, S: StoreSubscriber>(
        _ subscriber: S, transform: ((Subscription<CreatationCompleteState>) -> Subscription<SelectedState>)?
    ) where S.StoreSubscriberStateType == SelectedState
}

class CreatationCompleteCoordinator: EntryRootCoordinator {
    
    lazy var creator = CreatationCompletePropertyActionCreate()
    
    var store = Store<CreatationCompleteState>(
        reducer: CreatationCompleteReducer,
        state: nil,
        middleware:[TrackingMiddleware]
    )
}

extension CreatationCompleteCoordinator: CreatationCompleteCoordinatorProtocol {
    func dismissCurrentNav() {
        if let appdelegate = UIApplication.shared.delegate as? AppDelegate {
            appdelegate.appcoordinator?.endEntry()
        }
    }
    
    func pushBackupPrivateKeyVC() {
        let vc = R.storyboard.entry.backupPrivateKeyViewController()!
        let coor = BackupPrivateKeyCoordinator(rootVC: self.rootVC)
        vc.coordinator = coor
        self.rootVC.pushViewController(vc, animated: true)
    }
}

extension CreatationCompleteCoordinator: CreatationCompleteStateManagerProtocol {
    var state: CreatationCompleteState {
        return store.state
    }
    
    func subscribe<SelectedState, S: StoreSubscriber>(
        _ subscriber: S, transform: ((Subscription<CreatationCompleteState>) -> Subscription<SelectedState>)?
        ) where S.StoreSubscriberStateType == SelectedState {
        store.subscribe(subscriber, transform: transform)
    }
    
}
