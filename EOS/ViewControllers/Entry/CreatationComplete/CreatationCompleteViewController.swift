//
//  CreatationCompleteViewController.swift
//  EOS
//
//  Created peng zhu on 2018/7/12.
//  Copyright © 2018年 com.nbltrust. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import ReSwift

class CreatationCompleteViewController: BaseViewController {

    @IBOutlet weak var comfirmView: ComfirmView!
    
    var coordinator: (CreatationCompleteCoordinatorProtocol & CreatationCompleteStateManagerProtocol)?

	override func viewDidLoad() {
        super.viewDidLoad()
        self.title = R.string.localizable.back_up_wallet()
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
        
        comfirmView.cancelButton.rx.controlEvent(.touchUpInside).subscribe(onNext: {[weak self] touch in
            guard let `self` = self else { return }
            self.coordinator?.dismissCurrentNav()
            }, onError: nil, onCompleted: nil, onDisposed: nil).disposed(by: disposeBag)
    }
}

extension CreatationCompleteViewController {
    @objc func sure_event(_ data:[String:Any]) {
        self.coordinator?.pushBackupPrivateKeyVC()
    }
}
