//
//  BaseViewController.swift
//  verifyhub
//
//  基类控制器 - 页面可见时启动心跳，不可见时停止
//

import UIKit

/// 基类控制器
class BaseViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // 子类可重写
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 只有已登录（有token）才启动心跳
        if let token = KauthCore.shared.getVal(key: "token"), !token.isEmpty {
            HeartbeatManager.shared.start() // 页面即将显示时启动心跳
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // 不在这里停止，因为可能是跳转到同级的其他页面
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // 检查是否是真正离开当前导航栈
        if isMovingFromParent {
            HeartbeatManager.shared.stop() // 页面真正离开时停止心跳
        }
    }
    
    deinit {
        print("🗑️ \(self.className) 被释放")
    }
}

// MARK: - UIViewController 扩展

extension UIViewController {
    /// 获取类名
    var className: String {
        return String(describing: type(of: self))
    }
}
