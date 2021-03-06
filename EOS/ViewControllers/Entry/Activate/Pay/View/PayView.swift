//
//  PayView.swift
//  EOS
//
//  Created zhusongyu on 2018/9/6.
//  Copyright © 2018年 com.nbltrustdev. All rights reserved.
//

import Foundation

@IBDesignable
class PayView: EOSBaseView {
    @IBOutlet weak var nextButton: Button!
    @IBOutlet weak var cpuLabel: BaseLabel!
    @IBOutlet weak var netLabel: BaseLabel!
    @IBOutlet weak var ramLabel: BaseLabel!
    @IBOutlet weak var rmbPriceLabel: BaseLabel!

    enum Event: String {
        case payViewDidClicked
        case nextClick
    }

    override func setup() {
        super.setup()

        setupUI()
        setupSubViewEvent()
    }

    func setupUI() {

    }

    func setupSubViewEvent() {
        nextButton.button.rx.controlEvent(.touchUpInside).subscribe(onNext: {[weak self] _ in
            guard let `self` = self else { return }
            self.nextButton.next?.sendEventWith(Event.nextClick.rawValue, userinfo: [:])
        }).disposed(by: disposeBag)
    }

    @objc override func didClicked() {
        self.next?.sendEventWith(Event.payViewDidClicked.rawValue, userinfo: ["data": self.data ?? "", "self": self])
    }
}
