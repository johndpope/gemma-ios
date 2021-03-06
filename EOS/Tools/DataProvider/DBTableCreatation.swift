//
//  DBTableCreatation.swift
//  EOS
//
//  Created by peng zhu on 2018/9/10.
//  Copyright © 2018年 com.nbltrustdev. All rights reserved.
//

import Foundation
import SwiftyJSON

extension DBManager {
    func checkDB() throws {
        var accountModel = AccountModel()
        try handleTableCreation(accountModel, primaryKey: accountModel.primaryKey())
    }
}
