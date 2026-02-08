//
//  AES.swift
//  verifyhub
//
//  AES ECB ZeroPadding 加密工具 - 支持动态传入密钥
//

import UIKit
import CommonCrypto

/// AES加密工具类 (ECB模式 + ZeroPadding)
class AES {

    /// 单例
    static let shared = AES()

    private init() {}

    // MARK: - Public Methods

    /// AES ECB 加密
    /// - Parameters:
    ///   - plainText: 明文
    ///   - key: 密钥 (16/24/32字节对应AES-128/192/256)
    /// - Returns: 加密后的Base64字符串，失败返回nil
    func encrypt(plainText: String, key: String) -> String? {
        guard let keyData = key.data(using: .utf8) else {
            print("AES: 密钥转Data失败")
            return nil
        }

        guard let data = plainText.data(using: .utf8) else {
            print("AES: 明文转Data失败")
            return nil
        }

        return encrypt(data: data, key: keyData)
    }

    /// AES ECB 解密
    /// - Parameters:
    ///   - ciphertext: 密文 (Base64格式)
    ///   - key: 密钥 (16/24/32字节对应AES-128/192/256)
    /// - Returns: 解密后的明文，失败返回nil
    func decrypt(ciphertext: String, key: String) -> String? {
        guard let keyData = key.data(using: .utf8) else {
            print("AES: 密钥转Data失败")
            return nil
        }

        guard let data = Data(base64Encoded: ciphertext) else {
            print("AES: 密文Base64解码失败")
            return nil
        }

        guard let decryptedData = decrypt(data: data, key: keyData) else {
            return nil
        }

        return String(data: decryptedData, encoding: .utf8)
    }

    /// AES ECB 加密 (Data输入)
    /// - Parameters:
    ///   - data: 明文数据
    ///   - key: 密钥数据
    /// - Returns: 加密后的Base64字符串
    func encrypt(data: Data, key: Data) -> String? {
        guard let encryptedData = crypt(data: data, key: key, operation: kCCEncrypt) else {
            return nil
        }
        return encryptedData.base64EncodedString()
    }

    /// AES ECB 解密 (Data输入)
    /// - Parameters:
    ///   - data: 密文数据
    ///   - key: 密钥数据
    /// - Returns: 解密后的明文数据
    func decrypt(data: Data, key: Data) -> Data? {
        return crypt(data: data, key: key, operation: kCCDecrypt)
    }

    // MARK: - Private Methods

    private func crypt(data: Data, key: Data, operation: Int) -> Data? {
        let keyLength = key.count
        let validKeyLengths = [kCCKeySizeAES128, kCCKeySizeAES192, kCCKeySizeAES256]

        guard validKeyLengths.contains(keyLength) else {
            print("AES: 无效的密钥长度，必须是16/24/32字节，当前: \(keyLength)")
            return nil
        }

        // ZeroPadding: 不足16字节倍数则填充0x00
        var inputData = data
        if operation == kCCEncrypt {
            let blockSize = kCCBlockSizeAES128
            let paddingLength = blockSize - (data.count % blockSize)
            inputData = Data(data)
            inputData.append(Data(repeating: 0, count: paddingLength))
        }

        let dataLength = inputData.count
        let cryptLength = dataLength + kCCBlockSizeAES128

        var cryptData = Data(count: cryptLength)
        var numBytesEncrypted: size_t = 0

        let keyBytes = key.withUnsafeBytes { $0.baseAddress!.assumingMemoryBound(to: UInt8.self) }
        let dataBytes = inputData.withUnsafeBytes { $0.baseAddress!.assumingMemoryBound(to: UInt8.self) }
        let cryptBytes = cryptData.withUnsafeMutableBytes { $0.baseAddress!.assumingMemoryBound(to: UInt8.self) }

        let status = CCCrypt(
            CCOperation(operation),
            CCAlgorithm(kCCAlgorithmAES),
            CCOptions(kCCOptionECBMode),  // ECB模式，无偏移向量
            keyBytes,
            keyLength,
            nil,  // ECB模式无偏移向量
            dataBytes,
            dataLength,
            cryptBytes,
            cryptLength,
            &numBytesEncrypted
        )

        if status != kCCSuccess {
            print("AES: 加解密失败, status: \(status)")
            return nil
        }

        cryptData.count = numBytesEncrypted

        // 解密后移除ZeroPadding (末尾的0x00)
        if operation == kCCDecrypt {
            while cryptData.count > 0 {
                let lastByte = cryptData.last!
                if lastByte == 0 {
                    cryptData.removeLast()
                } else {
                    break
                }
            }
        }

        return cryptData
    }
}
