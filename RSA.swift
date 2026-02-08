//
//  RSA.swift
//  verifyhub
//
//  RSA加密工具 - 支持动态传入公钥/私钥
//

import UIKit
import Security
import CryptoKit

/// RSA加密工具类
struct RSATool {

    /// 公钥加密
    /// - Parameters:
    ///   - plaintext: 明文
    ///   - pubKey: 公钥字符串 (PEM格式)
    /// - Returns: 加密后的Base64字符串，失败返回nil
    static func encrypt(plaintext: String, pubKey: String) -> String? {
        print("🔐 RSATool.encrypt 开始, pubKey=\(pubKey)")
        guard let keyData = keyDataFromPEM(pubKey, isPrivate: false) else {
            print("❌ RSA: 无效的公钥格式")
            return nil
        }
        print("🔐 keyData长度: \(keyData.count)")

        guard let inputData = plaintext.data(using: .utf8) else {
            print("❌ RSA: 明文转Data失败")
            return nil
        }
        print("🔐 inputData长度: \(inputData.count)")

        guard let key = createSecKey(keyData, isPrivate: false) else {
            print("❌ RSA: createSecKey失败")
            return nil
        }
        print("🔐 SecKey创建成功, blockSize: \(SecKeyGetBlockSize(key))")
        
        let result = rsaEncrypt(inputData, key: key)
        print("🔐 rsaEncrypt结果: \(result?.count ?? 0) bytes")
        return result
    }

    /// 私钥解密
    /// - Parameters:
    ///   - ciphertext: 密文 (Base64格式)
    ///   - privKey: 私钥字符串 (PEM格式)
    /// - Returns: 解密后的明文，失败返回nil
    static func decrypt(ciphertext: String, privKey: String) -> String? {
        guard let keyData = keyDataFromPEM(privKey, isPrivate: true) else {
            print("RSA: 无效的私钥格式")
            return nil
        }

        guard let inputData = Data(base64Encoded: ciphertext) else {
            print("RSA: 密文Base64解码失败")
            return nil
        }

        guard let resultData = decryptWithPrivateKey(inputData, keyData) else {
            return nil
        }

        return String(data: resultData, encoding: .utf8)
    }

    /// 私钥加密
    /// - Parameters:
    ///   - plaintext: 明文
    ///   - privKey: 私钥字符串 (PEM格式)
    /// - Returns: 加密后的Base64字符串，失败返回nil
    static func encryptByPrivateKey(plaintext: String, privKey: String) -> String? {
        guard let keyData = keyDataFromPEM(privKey, isPrivate: true) else {
            print("RSA: 无效的私钥格式")
            return nil
        }

        guard let inputData = plaintext.data(using: .utf8) else {
            print("RSA: 明文转Data失败")
            return nil
        }

        return encryptWithPrivateKey(inputData, keyData)
    }

    /// 公钥解密（返回十六进制字符串）
    /// 服务器使用私钥直接加密MD5值（原始RSA，无额外填充），我们直接解密即可
    /// - Parameters:
    ///   - ciphertext: 密文 (Base64格式)
    ///   - pubKey: 公钥字符串 (PEM格式)
    /// - Returns: 解密后的十六进制字符串，失败返回nil
    static func decryptByPublicKey(ciphertext: String, pubKey: String) -> String? {
        print("🔍 ========== RSA解密开始 ==========")
        print("🔍 服务器签名(Base64): \(String(ciphertext.prefix(40)))...")
        
        guard let keyData = keyDataFromPEM(pubKey, isPrivate: false) else {
            print("RSA: 无效的公钥格式")
            return nil
        }

        guard let inputData = Data(base64Encoded: ciphertext) else {
            print("RSA: 密文Base64解码失败")
            return nil
        }
        print("🔍 签名长度: \(inputData.count) bytes")

        guard let key = createPublicKey(keyData) else {
            print("RSA: 创建公钥失败")
            return nil
        }
        
        let blockSize = SecKeyGetBlockSize(key)
        print("🔍 公钥blockSize: \(blockSize)")
        
        // 直接使用SecKeyDecrypt解密（原始RSA，无填充）
        var decryptedBytes = [UInt8](repeating: 0, count: blockSize)
        var decryptedLength = blockSize
        
        let status = SecKeyDecrypt(key, .OAEP, inputData.withUnsafeBytes { $0.baseAddress!.assumingMemoryBound(to: UInt8.self) }, inputData.count, &decryptedBytes, &decryptedLength)
        
        if status != errSecSuccess {
            print("❌ SecKeyDecrypt(O AEP)失败: status=\(status)")
            
            // 尝试PKCS1填充
            print("🔄 尝试PKCS1填充...")
            let status2 = SecKeyDecrypt(key, .PKCS1, inputData.withUnsafeBytes { $0.baseAddress!.assumingMemoryBound(to: UInt8.self) }, inputData.count, &decryptedBytes, &decryptedLength)
            if status2 != errSecSuccess {
                print("❌ PKCS1也失败: status=\(status2)")
                return nil
            }
        }
        
        // 服务器用私钥加密MD5
        let resultData = Data(bytes: decryptedBytes, count: decryptedLength)
        print("🔍 解密后原始数据: \(resultData.count) bytes")
        print("🔍 完整hex: \(resultData.map { String(format: "%02x", $0) }.joined())")
        
        // 方法1: 如果是32字节二进制MD5（16字节原始hash转hex是32字符）
        if resultData.count == 16 {
            let hexString = resultData.map { String(format: "%02x", $0) }.joined()
            print("✅ 16字节MD5 raw转hex: \(hexString)")
            return hexString
        }
        
        // 方法2: 如果是32字节（可能是32字符hex字符串的二进制）
        if resultData.count == 32 {
            // 尝试作为UTF-8字符串
            if let md5Str = String(data: resultData, encoding: .utf8) {
                print("✅ 32字节UTF-8解码: \(md5Str)")
                return md5Str
            }
            // 或转hex
            let hexString = resultData.map { String(format: "%02x", $0) }.joined()
            print("✅ 32字节转hex: \(hexString)")
            return hexString
        }
        
        // 方法3: 查找PKCS#1 v1.5填充格式: 00 01 FF...FF 00 || 明文
        for i in 0..<min(resultData.count, 256) {
            if resultData[i] == 0x00 && i + 1 < resultData.count {
                if resultData[i+1] == 0x01 || resultData[i+1] == 0x02 {
                    print("🔍 PKCS#1分隔符: i=\(i)")
                    
                    // 查找数据部分开始位置（下一个00）
                    var dataStart = -1
                    for j in (i+2)..<min(resultData.count, i+100) {
                        if resultData[j] == 0x00 {
                            dataStart = j + 1
                            break
                        }
                    }
                    
                    if dataStart > 0 && dataStart < resultData.count {
                        let md5Part = resultData.subdata(in: dataStart..<resultData.count)
                        print("🔍 MD5部分: \(md5Part.count) bytes")
                        
                        // 尝试UTF-8
                        if let md5Str = String(data: md5Part, encoding: .utf8), md5Str.count == 32 {
                            print("✅ PKCS#1 UTF-8: \(md5Str)")
                            return md5Str
                        }
                        
                        // 尝试转hex
                        let hexString = md5Part.map { String(format: "%02x", $0) }.joined()
                        if hexString.count == 32 {
                            print("✅ PKCS#1 hex: \(hexString)")
                            return hexString
                        }
                        
                        // 尝试取16字节
                        if md5Part.count >= 16 {
                            let md5Hex = md5Part.prefix(16).map { String(format: "%02x", $0) }.joined()
                            print("✅ PKCS#1取16字节: \(md5Hex)")
                            return md5Hex
                        }
                    }
                    break
                }
            }
        }
        
        // 方法4: 直接转hex作为最终结果
        let hexString = resultData.map { String(format: "%02x", $0) }.joined()
        print("⚠️ 直接返回hex: \(hexString)")
        return hexString
    }

    // MARK: - Private Methods

    private static func encryptWithPublicKey(_ inputData: Data, _ keyData: Data) -> String? {
        guard let key = createSecKey(keyData, isPrivate: false) else {
            return nil
        }

        return rsaEncrypt(inputData, key: key)
    }

    private static func decryptWithPrivateKey(_ inputData: Data, _ keyData: Data) -> Data? {
        guard let key = createSecKey(keyData, isPrivate: true) else {
            return nil
        }

        return rsaDecrypt(inputData, key: key)
    }

    private static func encryptWithPrivateKey(_ inputData: Data, _ keyData: Data) -> String? {
        guard let key = createSecKey(keyData, isPrivate: true) else {
            return nil
        }

        return rsaEncrypt(inputData, key: key)
    }

    private static func decryptWithPublicKey(_ inputData: Data, _ keyData: Data) -> Data? {
        guard let key = createSecKey(keyData, isPrivate: false) else {
            return nil
        }

        return rsaDecrypt(inputData, key: key)
    }

    private static func rsaEncrypt(_ inputData: Data, key: SecKey) -> String? {
        let blockSize = SecKeyGetBlockSize(key)
        var outputData = Data()

        var index = 0
        while index < inputData.count {
            let chunkSize = min(blockSize - 11, inputData.count - index)
            let chunkData = inputData.subdata(in: index..<(index + chunkSize))

            var encryptedBytes = [UInt8](repeating: 0, count: blockSize)
            var encryptedLength = blockSize

            let status = SecKeyEncrypt(key, .PKCS1, chunkData.withUnsafeBytes { $0.baseAddress!.assumingMemoryBound(to: UInt8.self) }, chunkSize, &encryptedBytes, &encryptedLength)

            if status != errSecSuccess {
                print("RSA: 加密失败, status: \(status)")
                return nil
            }

            outputData.append(encryptedBytes, count: encryptedLength)
            index += chunkSize
        }

        return outputData.base64EncodedString()
    }

    /// 公钥解密（使用SecKey原生API，增加调试信息）
    private static func decryptWithPublicKeyMath(_ inputData: Data, key: SecKey) -> Data? {
        print("🔍 使用SecKeyDecrypt解密...")
        
        var decryptedBytes = [UInt8](repeating: 0, count: SecKeyGetBlockSize(key))
        var decryptedLength = decryptedBytes.count
        
        let status = SecKeyDecrypt(key, .PKCS1, inputData.withUnsafeBytes { $0.baseAddress!.assumingMemoryBound(to: UInt8.self) }, inputData.count, &decryptedBytes, &decryptedLength)
        
        guard status == errSecSuccess else {
            print("❌ SecKeyDecrypt失败: status=\(status)")
            return nil
        }
        
        var resultData = Data(bytes: decryptedBytes, count: decryptedLength)
        print("🔍 解密后原始数据: \(resultData.count) bytes")
        print("🔍 解密后hex: \(resultData.map { String(format: "%02x", $0) }.joined())")
        
        // 分析数据结构
        print("🔍 前10字节: \(resultData.prefix(10).map { String(format: "%02x", $0) }.joined())")
        
        // PKCS#1 v1.5签名格式: 00 01 FF FF ... FF 00 || DER(Hash)
        // 查找分隔符 00
        if resultData.count > 2 {
            var sepPos = -1
            for i in 2..<min(resultData.count, 100) {
                if resultData[i] == 0x00 {
                    sepPos = i
                    break
                }
            }
            print("🔍 第一个00分隔符位置: \(sepPos)")
            
            if sepPos > 2 {
                let hashPart = resultData.subdata(in: (sepPos + 1)..<resultData.count)
                print("🔍 哈希部分长度: \(hashPart.count) bytes")
                print("🔍 哈希hex: \(hashPart.map { String(format: "%02x", $0) }.joined())")
                return hashPart
            }
        }
        
        return resultData
    }
    
    private static func rsaDecrypt(_ inputData: Data, key: SecKey) -> Data? {
        let blockSize = SecKeyGetBlockSize(key)
        print("🔍 RSA解密: inputData=\(inputData.count) bytes, blockSize=\(blockSize)")
        var outputData = Data()

        var index = 0
        while index < inputData.count {
            let chunkSize = min(blockSize, inputData.count - index)
            let chunkData = inputData.subdata(in: index..<(index + chunkSize))

            var decryptedBytes = [UInt8](repeating: 0, count: blockSize)
            var decryptedLength = blockSize

            let status = SecKeyDecrypt(key, .PKCS1, chunkData.withUnsafeBytes { $0.baseAddress!.assumingMemoryBound(to: UInt8.self) }, chunkSize, &decryptedBytes, &decryptedLength)

            if status != errSecSuccess {
                print("❌ RSA: SecKeyDecrypt失败, status=\(status)")
                return nil
            }

            outputData.append(decryptedBytes, count: decryptedLength)
            index += chunkSize
        }

        print("🔍 RSA解密后原始数据: \(outputData.count) bytes, hex=\(outputData.map { String(format: "%02x", $0) }.joined())")
        
        // 尝试标准PKCS#1 v1.5 签名填充格式:
        // 00 01 FF FF ... FF 00 || 32字节MD5
        
        // 方法1: 查找标准00 01 FF...FF 00填充
        var dataStart = -1
        for i in 0..<outputData.count {
            if outputData[i] == 0x00 && i + 1 < outputData.count {
                let nextByte = outputData[i+1]
                if nextByte >= 0x01 && nextByte <= 0xFF {
                    dataStart = i + 1
                    break
                }
            }
        }
        
        if dataStart > 0 && dataStart < outputData.count {
            let result = outputData.subdata(in: dataStart..<outputData.count)
            print("✅ PKCS#1填充格式, 提取的明文: \(result.count) bytes, hex=\(result.map { String(format: "%02x", $0) }.joined())")
            if let str = String(data: result, encoding: .utf8) {
                print("🔍 明文字符串: \(str)")
            }
            return result
        }
        
        // 方法2: Raw RSA签名（服务器无填充）
        // 直接使用解密结果作为MD5
        if outputData.count == 32 {
            print("✅ Raw RSA格式 (32字节MD5), hex=\(outputData.map { String(format: "%02x", $0) }.joined())")
            return outputData
        }
        
        // 方法3: 如果不是32字节，可能是服务器用了其他填充，尝试直接取全部数据
        print("⚠️ 非标准格式，直接使用原始数据: \(outputData.count) bytes")
        return outputData
    }

    private static func keyDataFromPEM(_ pem: String, isPrivate: Bool) -> Data? {
        var pemString = pem

        if isPrivate {
            pemString = pemString.replacingOccurrences(of: "-----BEGIN RSA PRIVATE KEY-----", with: "")
            pemString = pemString.replacingOccurrences(of: "-----BEGIN PRIVATE KEY-----", with: "")
            pemString = pemString.replacingOccurrences(of: "-----END RSA PRIVATE KEY-----", with: "")
            pemString = pemString.replacingOccurrences(of: "-----END PRIVATE KEY-----", with: "")
        } else {
            pemString = pemString.replacingOccurrences(of: "-----BEGIN RSA PUBLIC KEY-----", with: "")
            pemString = pemString.replacingOccurrences(of: "-----BEGIN PUBLIC KEY-----", with: "")
            pemString = pemString.replacingOccurrences(of: "-----END RSA PUBLIC KEY-----", with: "")
            pemString = pemString.replacingOccurrences(of: "-----END PUBLIC KEY-----", with: "")
        }

        pemString = pemString.replacingOccurrences(of: "\n", with: "")
        pemString = pemString.replacingOccurrences(of: "\r", with: "")
        pemString = pemString.replacingOccurrences(of: " ", with: "")

        guard let data = Data(base64Encoded: pemString) else {
            print("RSA: PEM Base64解码失败")
            return nil
        }

        return data
    }

    private static func createSecKey(_ keyData: Data, isPrivate: Bool) -> SecKey? {
        if isPrivate {
            return createPrivateKey(keyData)
        } else {
            return createPublicKey(keyData)
        }
    }
    
    /// 创建RSA公钥（支持PKCS#8和X509格式）
    private static func createPublicKey(_ derData: Data) -> SecKey? {
        print("🔐 createPublicKey: 输入DER长度=\(derData.count)")
        
        // 首先分析DER结构
        if derData.count >= 2 {
            print("🔐 DER头: \(String(format: "%02x", derData[0])) \(String(format: "%02x", derData[1]))")
        }
        
        // 方法1: 直接加载DER（支持PKCS#8 X.509 SubjectPublicKeyInfo）
        var options1: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrIsPermanent as String: false
        ]
        if let key = SecKeyCreateWithData(derData as CFData, options1 as CFDictionary, nil) {
            print("✅ 方法1: 直接加载DER成功, blockSize=\(SecKeyGetBlockSize(key))")
            return key
        }
        
        // 方法2: 提取PKCS#1公钥 (从PKCS#8 SubjectPublicKeyInfo中提取)
        // SubjectPublicKeyInfo结构:
        // SEQUENCE { 
        //   AlgorithmIdentifier { OID, NULL },
        //   BIT STRING { RSA公钥 }
        // }
        
        // 找到SEQUENCE结束位置 (30 81 xx 或 30 82 xx)
        var seqEnd = -1
        if derData.count >= 4 {
            if derData[0] == 0x30 && derData[1] == 0x81 {
                seqEnd = Int(derData[2]) + 3
            } else if derData[0] == 0x30 && derData[1] == 0x82 {
                seqEnd = Int(derData[2]) * 256 + Int(derData[3]) + 4
            }
        }
        print("🔐 PKCS#8 SEQUENCE结束位置: \(seqEnd)")
        
        // 查找BIT STRING (tag=0x03)
        var bitStringPos = -1
        for i in 0..<min(derData.count, 50) {
            if derData[i] == 0x03 {
                bitStringPos = i
                break
            }
        }
        
        print("🔐 BIT STRING at: \(bitStringPos)")
        
        if bitStringPos > 0 && bitStringPos + 2 < derData.count {
            // 跳过BIT STRING length字节和padding字节
            var offset = bitStringPos + 2
            // 跳过长度字段
            if derData[bitStringPos + 1] >= 0x80 {
                let lenBytes = Int(derData[bitStringPos + 1] & 0x7F)
                if lenBytes <= 3 && offset + lenBytes < derData.count {
                    for j in 0..<lenBytes {
                        offset = bitStringPos + 2 + lenBytes + Int(j)
                    }
                }
            }
            
            // 标准BIT STRING后有一个字节的padding (通常是0x00)
            let rsaKeyStart = offset + 1
            print("🔐 计算的RSA密钥起始位置: \(rsaKeyStart)")
            
            if rsaKeyStart < derData.count {
                let rsaKeyData = derData.subdata(in: rsaKeyStart..<derData.count)
                print("🔐 提取RSA密钥数据: \(rsaKeyData.count) bytes")
                print("🔐 RSA密钥数据前16字节: \(rsaKeyData.prefix(16).map { String(format: "%02x", $0) }.joined())")
                
                // 尝试不同options
                var options2: [String: Any] = [
                    kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
                    kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
                    kSecAttrIsPermanent as String: false
                ]
                if let key = SecKeyCreateWithData(rsaKeyData as CFData, options2 as CFDictionary, nil) {
                    print("✅ 方法2: 提取PKCS#1成功, blockSize=\(SecKeyGetBlockSize(key))")
                    return key
                }
                
                // 尝试不带keyClass
                options2.removeValue(forKey: kSecAttrKeyClass as String)
                if let key = SecKeyCreateWithData(rsaKeyData as CFData, options2 as CFDictionary, nil) {
                    print("✅ 方法2b: 提取PKCS#1成功(无keyClass), blockSize=\(SecKeyGetBlockSize(key))")
                    return key
                }
            }
        }
        
        print("❌ 所有方法都无法创建公钥")
        return nil
    }
    
    /// 创建RSA私钥
    private static func createPrivateKey(_ derData: Data) -> SecKey? {
        let options: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrIsPermanent as String: false
        ]
        
        return SecKeyCreateWithData(derData as CFData, options as CFDictionary, nil)
    }
}
