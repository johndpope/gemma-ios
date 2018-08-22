//
//  NormalViewController.swift
//  EOS
//
//  Created DKM on 2018/7/19.
//  Copyright © 2018年 com.nbltrust. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import ReSwift

class NormalViewController: BaseViewController {
    @IBOutlet weak var languageCell: NormalCellView!
    
    @IBOutlet weak var coinUnitCell: NormalCellView!
    
    @IBOutlet weak var nodeCell: NormalCellView!
    
    var coordinator: (NormalCoordinatorProtocol & NormalStateManagerProtocol)?

	override func viewDidLoad() {
        super.viewDidLoad()
        self.title = R.string.localizable.mine_normal.key.localized()
    }
    
    override func languageChanged() {
        self.relload()
    }
    
    func relload() {
        self.title = R.string.localizable.mine_normal.key.localized()
        languageCell.reload()
        coinUnitCell.reload()
        nodeCell.reload()
    }
    
    func commonObserveState() {
        coordinator?.subscribe(errorSubscriber) { sub in
            return sub.select { state in state.errorMessage }.skipRepeats({ (old, new) -> Bool in
                return false
            })
        }
        
        coordinator?.subscribe(loadingSubscriber) { sub in
            return sub.select { state in state.isLoading }.skipRepeats({ (old, new) -> Bool in
                return false
            })
        }
    }
    
    override func configureObserveState() {
        commonObserveState()
        
    }
}

extension NormalViewController {
    @objc func clickCellView(_ sender:[String:Any]) {
        let index = sender["index"] as! Int
        self.coordinator?.openContent(index)
    }
}

