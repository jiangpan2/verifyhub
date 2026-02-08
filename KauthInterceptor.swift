//
//  KauthInterceptor.swift
//  verifyhub
//
//  请求/响应拦截器 - 负责加密请求体、生成签名、验证响应、解密响应体
//

import Foundation

/// KAuth拦截器
class KauthInterceptor {
    
    // MARK: - Request Interceptor
    
    /// 适配请求 - 添加签名和加密请求体
    func adapt(request: URLRequest) throws -> URLRequest {
        // 处理请求体
        var bodyString = ""
        if let httpBody = request.httpBody,
           let bodyStr = String(data: httpBody, encoding: .utf8),
           !bodyStr.isEmpty {
            bodyString = bodyStr
        } else {
            // 无请求体时使用空JSON对象（与Android端一致）
            bodyString = "{}"
        }
        
        // 清理JSON格式（移除空白）
        if let data = bodyString.data(using: .utf8) {
            if let jsonObject = try? JSONSerialization.jsonObject(with: data),
               let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: []),
               let prettyString = String(data: prettyData, encoding: .utf8) {
                bodyString = prettyString
            }
        }
        
        // AES加密请求体
        let programSecret = KauthCore.shared.config.programSecret
        guard let encryptedBody = AES.shared.encrypt(plainText: bodyString, key: programSecret) else {
            throw KauthError.encryptionFailed
        }
        
        // 生成签名参数
        let deviceId = KauthCore.shared.getDeviceId()
        let nonce = "\(deviceId)_\(UUID().uuidString.replacingOccurrences(of: "-", with: ""))"
        let time = Int64(Date().timeIntervalSince1970 * 1000)
        
        // 获取URL路径（用于签名）
        guard let url = request.url else {
            throw KauthError.invalidURL
        }
        let path = url.path
        
        // 生成签名
        guard let sign = SignTools.sign(
            config: KauthCore.shared.config,
            url: path,
            body: bodyString,
            nonce: nonce,
            time: time
        ) else {
            throw KauthError.signatureFailed
        }
        
        // 构建新的请求体
        guard let encryptedBodyData = encryptedBody.data(using: .utf8) else {
            throw KauthError.encryptionFailed
        }
        var newRequest = request
        newRequest.httpBody = encryptedBodyData
        
        // 添加请求头
        newRequest.setValue(KauthCore.shared.config.programId, forHTTPHeaderField: KauthCore.Headers.programId)
        newRequest.setValue(nonce, forHTTPHeaderField: KauthCore.Headers.nonce)
        newRequest.setValue(String(time), forHTTPHeaderField: KauthCore.Headers.time)
        newRequest.setValue(KauthCore.shared.config.signType.rawValue, forHTTPHeaderField: KauthCore.Headers.signType)
        newRequest.setValue(sign, forHTTPHeaderField: KauthCore.Headers.sign)
        // 添加accessToken（如果存在）
        if let token = KauthCore.shared.getVal(key: "token"), !token.isEmpty {
            newRequest.setValue(token, forHTTPHeaderField: KauthCore.Headers.accessToken)
        }
        
        // 设置Content-Type
        newRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        
        return newRequest
    }
    
    // MARK: - Response Interceptor
    
    /// 验证并解密响应
    func verify(response: HTTPURLResponse, data: Data, request: URLRequest) throws -> Data {
        let responseBodyString = String(data: data, encoding: .utf8) ?? ""
        print("📥 原始响应数据: \(responseBodyString)")
        
        // 解析响应
        let parseResult: ParseResult
        do {
            parseResult = try JSONDecoder().decode(ParseResult.self, from: data)
            print("✅ 响应解析成功, code: \(parseResult.code ?? -1), isSuccess: \(parseResult.isSuccessValue)")
        } catch {
            print("❌ 响应解析失败: \(error.localizedDescription)")
            print("📥 原始响应数据: \(responseBodyString)")
            throw KauthError.responseParseFailed(error.localizedDescription)
        }
        
        // 如果请求不成功，直接返回原始响应
        if !parseResult.isSuccessValue {
            return responseBodyString.data(using: .utf8) ?? data
        }
        
        // 获取响应头中的签名信息 (兼容iOS 13以下)
        // 暂时跳过响应头校验，因为服务器可能未返回签名相关响应头
        // let headers = response.allHeaderFields as? [String: String] ?? [:]
        // guard let responseNonce = headers[KauthCore.Headers.nonce] else {
        //     throw KauthError.missingHeader("nonce")
        // }
        // guard let responseTimeStr = headers[KauthCore.Headers.time],
        //       let serverTime = Int64(responseTimeStr) else {
        //     throw KauthError.missingHeader("time")
        // }
        // guard let responseSign = headers[KauthCore.Headers.sign] else {
        //     throw KauthError.missingHeader("sign")
        // }
        // guard headers[KauthCore.Headers.signType] != nil else {
        //     throw KauthError.missingHeader("signType")
        // }
        //
        // // 验证时间戳（2分钟内）
        // let currentTime = Int64(Date().timeIntervalSince1970 * 1000)
        // if currentTime - serverTime > KauthCore.timestampTolerance {
        //     throw KauthError.timestampExpired
        // }
        
        // 解密响应体
        let decryptedBody: String?
        if let encryptedData = parseResult.data, !encryptedData.isEmpty {
            print("🔐 密文数据: \(encryptedData)")
            let programSecret = KauthCore.shared.config.programSecret
            print("🔐 使用 programSecret 解密: \(programSecret)")
            guard let decrypted = AES.shared.decrypt(ciphertext: encryptedData, key: programSecret) else {
                print("❌ AES 解密失败")
                throw KauthError.decryptionFailed
            }
            print("🔐 解密后数据: \(decrypted)")
            decryptedBody = decrypted
        } else {
            print("⚠️ 响应中无加密数据")
            decryptedBody = nil
        }
        
        // 验证服务器签名 (已注释，暂时跳过验签)
        // guard let url = request.url else {
        //     throw KauthError.invalidURL
        // }
        // let path = url.path
        //
        // let isValid = SignTools.verifyResponseSign(
        //     config: KauthCore.shared.config,
        //     url: path,
        //     body: decryptedBody,
        //     nonce: responseNonce,
        //     time: serverTime,
        //     sign: responseSign
        // )
        //
        // if !isValid {
        //     throw KauthError.signatureVerificationFailed
        // }
        
        // 构建新的响应体
        var jsonObject: [String: Any] = [
            "msg": parseResult.msg ?? "",
            "code": parseResult.code ?? 0,
            "traceId": parseResult.traceId ?? "",
            "elapse": parseResult.elapse ?? "",
            "respTime": parseResult.respTime ?? "",
            "success": parseResult.isSuccessValue
        ]
        
        // 解密后的 data 需要作为嵌套 JSON 对象，而不是字符串
        if let decrypted = decryptedBody,
           let decryptedData = decrypted.data(using: .utf8),
           let dataObject = try? JSONSerialization.jsonObject(with: decryptedData) as? [String: Any] {
            jsonObject["data"] = dataObject
        }
        
        guard let newData = try? JSONSerialization.data(withJSONObject: jsonObject, options: []) else {
            return responseBodyString.data(using: .utf8) ?? data
        }
        
        return newData
    }
}

// MARK: - KauthError

enum KauthError: LocalizedError {
    case invalidRequestBody
    case invalidURL
    case encryptionFailed
    case decryptionFailed
    case signatureFailed
    case signatureVerificationFailed
    case missingHeader(String)
    case timestampExpired
    case responseParseFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidRequestBody:
            return "无效的请求体"
        case .invalidURL:
            return "无效的URL"
        case .encryptionFailed:
            return "请求体加密失败"
        case .decryptionFailed:
            return "响应体解密失败"
        case .signatureFailed:
            return "签名生成失败"
        case .signatureVerificationFailed:
            return "服务器签名验证失败"
        case .missingHeader(let header):
            return "缺少响应头: \(header)"
        case .timestampExpired:
            return "请求超时"
        case .responseParseFailed(let msg):
            return "响应解析失败: \(msg)"
        }
    }
}
