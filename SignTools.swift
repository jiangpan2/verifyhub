//
//  SignTools.swift
//  verifyhub
//
//  签名工具
//

import Foundation
import CommonCrypto

/// 签名工具
struct SignTools {
    
    /// 生成签名
    /// - Parameters:
    ///   - config: 服务配置
    ///   - url: 请求路径
    ///   - body: 请求体
    ///   - nonce: 随机数
    ///   - time: 时间戳
    /// - Returns: 签名后的Base64字符串
    static func sign(config: ServiceConfig, url: String, body: String?, nonce: String, time: Int64) -> String? {
        let bodyStr = body ?? ""
        let signTemplate = "url:\(url)\nbody:\(bodyStr)\nnonce:\(nonce)\ntime:\(time)"
        let md5 = md5Hash(signTemplate)
        
        switch config.signType {
        case .rsa:
            // RSA签名：使用商户公钥对MD5值进行加密（与Android端RsaTools.encryptByPublicKey一致）
            print("🔐 SignTools.RSA签名: md5=\(md5)")
            print("🔐 公钥长度: \(config.merchantPublicKey.count)")
            guard let sign = RSATool.encrypt(plaintext: md5, pubKey: config.merchantPublicKey) else {
                print("❌ RSATool.encrypt返回nil")
                return nil
            }
            print("✅ RSA签名成功: \(sign.prefix(50))...")
            return sign
        case .hmacSHA256:
            // HMAC签名
            return hmacSHA256Sign(md5, key: config.merchantPublicKey)
        }
    }
    
    /// 验证服务器响应签名
    static func verifyResponseSign(config: ServiceConfig, url: String, body: String?, nonce: String, time: Int64, sign: String) -> Bool {
        let bodyStr = body ?? ""
        let signTemplate = "url:\(url)\nbody:\(bodyStr)\nnonce:\(nonce)\ntime:\(time)"
        let md5 = md5Hash(signTemplate)
        
        print("🔍 响应签名验证:")
        print("   signTemplate: \(signTemplate)")
        print("   本地计算的md5: \(md5)")
        print("   服务器签名: \(sign.prefix(100))...")
        
        switch config.signType {
        case .rsa:
            // RSA验签：使用商户公钥解密签名，与MD5值比对
            guard let decryptedSign = RSATool.decryptByPublicKey(ciphertext: sign, pubKey: config.merchantPublicKey) else {
                print("❌ RSA解密失败")
                return false
            }
            print("   解密后的值: \(decryptedSign)")
            let isValid = decryptedSign == md5
            print("   验签结果: \(isValid ? "✅ 通过" : "❌ 失败")")
            return isValid
        case .hmacSHA256:
            return hmacSHA256Verify(md5, key: config.merchantPublicKey, sign: sign)
        }
    }
    
    // MARK: - Private Methods
    
    /// MD5哈希
    private static func md5Hash(_ string: String) -> String {
        let data = Data(string.utf8)
        var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        
        data.withUnsafeBytes { bytes in
            _ = CC_MD5(bytes.baseAddress, CC_LONG(data.count), &digest)
        }
        
        return digest.map { String(format: "%02x", $0) }.joined()
    }
    
    /// HMAC-SHA256签名
    private static func hmacSHA256Sign(_ data: String, key: String) -> String {
        let keyData = Data(key.utf8)
        let dataData = Data(data.utf8)
        
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        
        keyData.withUnsafeBytes { keyBytes in
            dataData.withUnsafeBytes { dataBytes in
                CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA256),
                       keyBytes.baseAddress,
                       keyData.count,
                       dataBytes.baseAddress,
                       dataData.count,
                       &digest)
            }
        }
        
        return Data(digest).base64EncodedString()
    }
    
    /// HMAC-SHA256验签
    private static func hmacSHA256Verify(_ data: String, key: String, sign: String) -> Bool {
        guard let signData = Data(base64Encoded: sign) else {
            return false
        }
        
        let computedSign = hmacSHA256Sign(data, key: key)
        guard let computedSignData = Data(base64Encoded: computedSign) else {
            return false
        }
        
        return signData == computedSignData
    }
}
