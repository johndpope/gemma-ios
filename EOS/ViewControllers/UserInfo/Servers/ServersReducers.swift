//
//  ServersReducers.swift
//  EOS
//
//  Created DKM on 2018/7/19.
//  Copyright © 2018年 com.nbltrust. All rights reserved.
//

import UIKit
import ReSwift

func gServersReducer(action: Action, state: ServersState?) -> ServersState {
    return ServersState(isLoading: loadingReducer(state?.isLoading, action: action),
                        page: pageReducer(state?.page, action: action),
                        errorMessage: errorMessageReducer(state?.errorMessage, action: action),
                        property: gServersPropertyReducer(state?.property, action: action))
}

func gServersPropertyReducer(_ state: ServersPropertyState?, action: Action) -> ServersPropertyState {
    let state = state ?? ServersPropertyState()

    switch action {
    default:
        break
    }

    return state
}
