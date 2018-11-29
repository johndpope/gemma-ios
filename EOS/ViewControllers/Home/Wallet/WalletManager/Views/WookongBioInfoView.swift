//
//  WookongBioInfoView.swift
//  EOS
//
//  Created peng zhu on 2018/11/16.
//  Copyright © 2018 com.nbltrustdev. All rights reserved.
//

import Foundation

@IBDesignable
class WookongBioInfoView: BaseView {
    @IBOutlet weak var titleLabel: UILabel!

    @IBOutlet weak var subTitleLabel: UILabel!

    @IBOutlet weak var moreView: UIImageView!

    @IBOutlet weak var statusView: WookongBioStatusView!
    
    override func setup() {
        super.setup()
        
        setupUI()
        setupSubViewEvent()
    }
    
    func setupUI() {
        if BLTWalletIO.shareInstance()?.isConnection() ?? false {
            self.statusView.data = BLTWalletIO.shareInstance()?.batteryInfo
            moreView.isHidden = false
        } else {
            self.statusView.data = nil
            moreView.isHidden = true
        }
    }
    
    func setupSubViewEvent() {
        BLTWalletIO.shareInstance()?.batteryInfoUpdated = { [weak self] (info) in
            guard let `self` = self else { return }
            if info != nil {
                self.moreView.isHidden = false
            } else {
                self.moreView.isHidden = true
            }
            self.statusView.data = info
        }
    }
}
