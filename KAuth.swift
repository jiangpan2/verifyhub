//
//  KAuth.swift
//  verifyhub
//
//  卡密认证核心模块
//

import UIKit

/// 卡密认证管理器
class KAuth {

    /// 单例
    static let shared = KAuth()

    private init() {}

    /// 卡密登录 (与Android KauthApiService.kaLogin一致)
    /// - Parameters:
    ///   - cardCode: 卡密
    ///   - completion: 回调
    func login(cardCode: String, completion: @escaping (Bool, String) -> Void) {
        print("卡密登录中: \(cardCode)")
        
        let deviceId = KauthCore.shared.getDeviceId()
        let endpoint =  APIEndpoint.kaLogin(kaPwd: cardCode, captchaCode: "", captchaUuid: "", deviceId: deviceId, platformType: "iOS")
        
        print("📡 发起网络请求: \(endpoint.path)")
        NetworkManager.shared.request(endpoint) { (result: Result<ApiResult<LoginResponse>, Error>) in
            switch result {
            case .success(let response):
                print("✅ 请求成功, code: \(response.code ?? -1), msg: \(response.msg ?? "nil")  traceId:\(response.traceId ?? "nil" )")
                if response.code == 200 {
                    // 保存token和pongInterval
                    if let token = response.data?.token {
                        KauthCore.shared.putVal(key: "token", value: token)
                    }
                    if let pongInterval = response.data?.pongInterval {
                        KauthCore.shared.putVal(key: "pongInterval", value: pongInterval)
                    }
                    completion(true, response.msg ?? "登录成功")
                } else {
                    completion(false, response.msg ?? "登录失败")
                }
            case .failure(let error):
                print("❌ 请求失败: \(error.localizedDescription)")
                completion(false, error.localizedDescription)
            }
        }
    }

    /// 卡密解绑
    /// - Parameters:
    ///   - cardCode: 卡密
    ///   - completion: 回调
    func unbind(cardCode: String, completion: @escaping (Bool, String) -> Void) {
        print("卡密解绑中: \(cardCode)")
        
        let deviceId = KauthCore.shared.getDeviceId()
        let endpoint = APIEndpoint.unbindDeviceKaPwd(kaPwd: cardCode, deviceId: deviceId)
        
        NetworkManager.shared.request(endpoint) { (result: Result<ApiResult<EmptyResponse>, Error>) in
            switch result {
            case .success(let response):
                if response.code == 200 {
                    completion(true, response.msg ?? "解绑成功")
                } else {
                    completion(false, response.msg ?? "解绑失败")
                }
            case .failure(let error):
                completion(false, error.localizedDescription)
            }
        }
    }

    /// 卡密充值 (以卡充卡)
    /// - Parameters:
    ///   - cardCode: 当前卡密（在页面上输入）
    ///   - rechargeCode: 充值卡密（在弹窗输入）
    ///   - completion: 回调
    func recharge(cardCode: String, rechargeCode: String, completion: @escaping (Bool, String) -> Void) {
        print("卡密充值中: \(cardCode) -> \(rechargeCode)")
        
        let endpoint = APIEndpoint.rechargeKa(cardPwd: cardCode, rechargeCardPwd: rechargeCode)
        
        NetworkManager.shared.request(endpoint) { (result: Result<ApiResult<EmptyResponse>, Error>) in
            switch result {
            case .success(let response):
                if response.code == 200 {
                    completion(true, response.msg ?? "充值成功")
                } else {
                    completion(false, response.msg ?? "充值失败")
                }
            case .failure(let error):
                completion(false, error.localizedDescription)
            }
        }
    }
    
    /// 账号密码登录
    /// - Parameters:
    ///   - username: 用户名
    ///   - password: 密码
    ///   - completion: 回调
    func pwdLogin(username: String, password: String, completion: @escaping (Bool, String) -> Void) {
        print("账号密码登录中: \(username)")
        // TODO: 实现登录逻辑
        completion(true, "登录成功")
    }
}
