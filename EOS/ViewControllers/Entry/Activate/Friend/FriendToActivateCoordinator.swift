//
//  FriendToActivateCoordinator.swift
//  EOS
//
//  Created zhusongyu on 2018/9/6.
//  Copyright © 2018年 com.nbltrustdev. All rights reserved.
//

import UIKit
import ReSwift
import NBLCommonModule

protocol FriendToActivateCoordinatorProtocol {
}

protocol FriendToActivateStateManagerProtocol {
    var state: FriendToActivateState { get }

    func switchPageState(_ state: PageState)
}

class FriendToActivateCoordinator: NavCoordinator {
    var store = Store(
        reducer: gFriendToActivateReducer,
        state: nil,
        middleware: [trackingMiddleware]
    )

    var state: FriendToActivateState {
        return store.state
    }

    override func register() {
        Broadcaster.register(FriendToActivateCoordinatorProtocol.self, observer: self)
        Broadcaster.register(FriendToActivateStateManagerProtocol.self, observer: self)
    }
}

extension FriendToActivateCoordinator: FriendToActivateCoordinatorProtocol {

}

extension FriendToActivateCoordinator: FriendToActivateStateManagerProtocol {
    func switchPageState(_ state: PageState) {
        DispatchQueue.main.async {
            self.store.dispatch(PageStateAction(state: state))
        }
    }
}
