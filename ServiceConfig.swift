//
//  ServiceConfig.swift
//  verifyhub
//
//  服务配置
//

import Foundation

/// 签名类型
enum SignType: String {
    case rsa = "RSA"
    case hmacSHA256 = "HMAC_SHA256"
}

/// 服务配置
struct ServiceConfig {
    /// API域名
    var apiDomain: String = "https://api.kauth.cn"
    
    /// 程序ID
    var programId: String = ""
    
    /// 程序密钥（AES加密用）
    var programSecret: String = ""
    
    /// 商户公钥（RSA签名用）
    var merchantPublicKey: String = ""
    
    /// 签名类型
    var signType: SignType = .rsa
    
    /// 验证配置
    func isValid() -> Bool {
        return !apiDomain.isEmpty &&
               !programId.isEmpty &&
               !programSecret.isEmpty &&
               !merchantPublicKey.isEmpty
    }
}
