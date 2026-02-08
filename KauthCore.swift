//
//  KauthCore.swift
//  verifyhub
//
//  核心管理类
//

import Foundation

/// KAuth核心管理类
class KauthCore {
    
    // MARK: - Singleton
    
    static let shared = KauthCore()
    
    // MARK: - Properties
    
    /// 配置
    private(set) var config: ServiceConfig = ServiceConfig()
    
    /// 存储
    private var storage: UserDefaultsStorage?
    private var keychain: KeychainStorage?
    
    /// 设备ID Key
    private let kDeviceIdKey = "device_id"
    
    // MARK: - Constants
    
    /// 时间戳容差（毫秒）
    static let timestampTolerance: Int64 = 120000
    
    /// 请求头Key
    struct Headers {
        static let programId = "Program-Id"
        static let nonce = "ka-nonce"
        static let time = "ka-time"
        static let signType = "ka-sign-type"
        static let sign = "ka-sign"
        static let accessToken = "accesstoken"
    }
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// 配置初始化
    /// - Parameter config: 配置参数
    /// - Returns: 成功返回"ok"，失败返回错误信息
    @discardableResult
    func configure(apiDomain: String,
                   programId: String,
                   programSecret: String,
                   merchantPublicKey: String,
                   signType: String = "RSA") -> String {
        
        // 设置配置
        config.apiDomain = apiDomain.isEmpty ? "https://api.kauth.cn" : apiDomain
        config.programId = programId
        config.programSecret = programSecret
        config.merchantPublicKey = merchantPublicKey
        
        // 解析签名类型
        if signType.uppercased() == "HMAC_SHA256" {
            config.signType = .hmacSHA256
        } else {
            config.signType = .rsa
        }
        
        // 验证必填参数
        if config.programId.isEmpty {
            return "fail:programId 不能为空"
        }
        if config.programSecret.isEmpty {
            return "fail:programSecret 程序密钥不能为空"
        }
        if config.merchantPublicKey.isEmpty {
            return "fail:merchantPublicKey 不能为空"
        }
        
        // 初始化存储
        storage = UserDefaultsStorage(prefix: "\(config.programId)_")
        keychain = KeychainStorage(service: config.programId)
        
        return "ok"
    }
    
    /// 获取设备ID
    /// - Returns: 设备ID
    func getDeviceId() -> String {
        guard let storage = storage else {
            return "unknown"
        }
        
        if let deviceId = storage.read(kDeviceIdKey), !deviceId.isEmpty {
            return deviceId
        }
        
        // 生成新设备ID
        let deviceId = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        storage.save(kDeviceIdKey, deviceId)
        return deviceId
    }
    
    /// 保存值
    func putVal(key: String, value: String) {
        storage?.save(key, value)
    }
    
    /// 获取值
    func getVal(key: String) -> String? {
        return storage?.read(key)
    }
    
    /// 获取值（带标签）
    func getVal(key: String, defaultValue: String? = nil) -> String? {
        return storage?.read(key) ?? defaultValue
    }
    
    /// 获取API基础URL
    func getBaseURL() -> String {
        return config.apiDomain
    }
    
    /// 获取完整URL
    func getFullURL(path: String) -> String {
        return config.apiDomain + path
    }
    
    /// 清理所有本地存储的认证信息（token等）
    func clearAll() {
        // 清理 UserDefaults 存储
        if let storage = storage {
            // 获取所有存储的 key
            let keys = ["token", "ka_pwd"]
            for key in keys {
                storage.save(key, "")
            }
        }
        
        // 清理 Keychain 存储
        if let keychain = keychain {
            keychain.clear()
        }
        
        print("🧹 已清理所有认证信息")
    }
}
