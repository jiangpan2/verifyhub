//
//  HeartbeatManager.swift
//  verifyhub
//
//  心跳管理器 - 每2分钟执行一次心跳，失败计次
//

import Foundation
import UIKit

/// 心跳管理器
class HeartbeatManager {
    
    // MARK: - Singleton
    
    static let shared = HeartbeatManager()
    
    // MARK: - Properties
    
    private var timer: Timer?
    private var isRunning = false
    private var failureCount = 0
    private let maxFailureCount = 3
    private let heartbeatInterval: TimeInterval = 120 // 2分钟
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// 启动心跳
    func start() {
        guard !isRunning else { return }
        isRunning = true
        failureCount = 0 // 重置失败计数
        
        timer = Timer.scheduledTimer(withTimeInterval: heartbeatInterval, repeats: true) { [weak self] _ in
            self?.sendPong()
        }
        print("💓 心跳已启动")
        
        // 立即执行一次心跳
        sendPong()
    }
    
    /// 停止心跳
    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        failureCount = 0
        print("💓 心跳已停止")
    }
    
    // MARK: - Private Methods
    
    /// 发送心跳
    private func sendPong() {
        NetworkManager.shared.request(.pong()) { [weak self] (result: Result<ApiResult<String?>, Error>) in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                if response.code == 200 {
                    self.failureCount = 0 // 重置失败计数
                    print("💓 心跳成功")
                } else {
                    // 其他错误码，计次
                    self.handleFailure(code: response.code ?? -1, msg: response.msg)
                }
                
            case .failure(let error):
                self.failureCount += 1
                print("❌ 心跳请求失败: \(error.localizedDescription), 失败次数: \(self.failureCount)")
                
                if self.failureCount >= self.maxFailureCount {
                    self.handleMaxFailure()
                }
            }
        }
    }
    
    /// 处理失败（特定错误码）
    private func handleFailure(code: Int, msg: String?) {
        failureCount += 1
        print("❌ 心跳失败, code: \(code), msg: \(msg ?? "nil"), 失败次数: \(failureCount)")
        
        // code==1050 或 2000 时直接跳转登录页
        if code == 1050 || code == 2000 {
            self.handleTokenExpired(code: code, msg: msg)
        } else if failureCount >= maxFailureCount {
            // 其他错误码达到最大失败次数
            self.handleMaxFailure()
        }
    }
    
    /// Token 过期或其他需要重新登录的情况
    private func handleTokenExpired(code: Int, msg: String?) {
        DispatchQueue.main.async { [weak self] in
            self?.stop()
            self?.clearTokenAndNavigateToLogin(code: code, msg: msg)
        }
    }
    
    /// 达到最大失败次数
    private func handleMaxFailure() {
        DispatchQueue.main.async { [weak self] in
            self?.stop()
            self?.clearTokenAndNavigateToLogin(code: -1, msg: "心跳已达最大失败次数")
        }
    }
    
    /// 清理 Token 并跳转到登录页
    private func clearTokenAndNavigateToLogin(code: Int, msg: String?) {
        KauthCore.shared.clearAll()
        
        // 显示提示框
        let alertMsg: String
        if code == 1050 || code == 2000 {
            alertMsg = msg ?? "登录已过期，请重新登录"
        } else {
            alertMsg = msg ?? "心跳已达最大失败次数"
        }
        
        showAlert(title: "提示", message: alertMsg) { [weak self] in
            self?.navigateToLogin()
        }
    }
    
    /// 跳转到登录页
    private func navigateToLogin() {
        guard let window = UIApplication.shared.windows.first else { return }
        
        let loginVC = LoginViewController()
        let navController = UINavigationController(rootViewController: loginVC)
        
        // 带动画切换
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
            window.rootViewController = navController
        }, completion: nil)
    }
    
    /// 显示提示框
    private func showAlert(title: String, message: String, completion: @escaping () -> Void) {
        DispatchQueue.main.async {
            guard let rootVC = UIApplication.shared.windows.first?.rootViewController else { return }
            
            // 找到最顶层的 controller
            var topVC = rootVC
            while let presentedVC = topVC.presentedViewController {
                topVC = presentedVC
            }
            
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "确定", style: .default) { _ in
                completion()
            })
            
            topVC.present(alert, animated: true)
        }
    }
}
