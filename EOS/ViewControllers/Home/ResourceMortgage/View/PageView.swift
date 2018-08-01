//
//  PageView.swift
//  EOS
//
//  Created by zhusongyu on 2018/7/25.
//  Copyright © 2018年 com.nbltrust. All rights reserved.
//

import Foundation


@IBDesignable
class PageView: UIView {

    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var leftLabel: UILabel!
    @IBOutlet weak var rightLabel: UILabel!
    @IBOutlet weak var lineView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var leftView: OperationLeftView!
    @IBOutlet weak var rightView: OperationRightView!
    
    var data: Any? {
        didSet {
            if let data = data as? PageViewModel {
                balanceLabel.text = data.balance
                leftLabel.text = data.leftText
                rightLabel.text = data.rightText
                leftView.data = data.operationLeft
                rightView.data = data.operationRight
                updateHeight()
            }
        }
    }
    
    enum event: String {
        case left
        case right
    }
    
    enum page: Int {
        case left = 0
        case right = 1
    }
    
    var index = page.left
    
    var balance = "" {
        didSet {
            balanceLabel.text = balance
        }
    }
    
    func setUp() {
        updateLabelStatus()
        setupEvent()
        updateHeight()
    }
    
    func updateLabelStatus() {
        if index == page.left {
            leftLabel.textColor = UIColor.darkSlateBlue
            rightLabel.textColor = UIColor.blueyGrey
        } else {
            leftLabel.textColor = UIColor.blueyGrey
            rightLabel.textColor = UIColor.darkSlateBlue
        }
    }
    
    func setupEvent() {
        leftLabel.rx.tapGesture().when(.recognized).subscribe(onNext: {[weak self] tap in
            guard let `self` = self else { return }
            self.leftLabel.next?.sendEventWith(event.left.rawValue, userinfo: [:])
        }).disposed(by: disposeBag)
        
        rightLabel.rx.tapGesture().when(.recognized).subscribe(onNext: {[weak self] tap in
            guard let `self` = self else { return }
            self.rightLabel.next?.sendEventWith(event.right.rawValue, userinfo: [:])
        }).disposed(by: disposeBag)
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize.init(width: UIViewNoIntrinsicMetric,height: dynamicHeight())
    }
    
    fileprivate func updateHeight() {
        layoutIfNeeded()
        self.height = dynamicHeight()
        invalidateIntrinsicContentSize()
    }
    
    fileprivate func dynamicHeight() -> CGFloat {
        let lastView = self.subviews.last?.subviews.last
        return lastView?.bottom ?? 0
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layoutIfNeeded()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadViewFromNib()
        setUp()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadViewFromNib()
        setUp()
    }
    
    fileprivate func loadViewFromNib() {
        let bundle = Bundle(for: type(of: self))
        let nibName = String(describing: type(of: self))
        let nib = UINib.init(nibName: nibName, bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil).first as! UIView
//                self.insertSubview(view, at: 0)
        
        addSubview(view)
        view.frame = self.bounds
        view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
}

extension PageView {
    @objc func left(_ data: [String: Any]) {
        lineView.centerX = leftLabel.centerX
        scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
        index = page.left
        updateLabelStatus()
        self.next?.sendEventWith(event.left.rawValue, userinfo: [:])
    }
    @objc func right(_ data: [String: Any]) {
        lineView.centerX = rightLabel.centerX
        scrollView.setContentOffset(CGPoint(x: self.width, y: 0), animated: true)
        index = page.right
        updateLabelStatus()
        self.next?.sendEventWith(event.right.rawValue, userinfo: [:])
    }
}
