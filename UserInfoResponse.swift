//
//  UserInfoResponse.swift
//  verifyhub
//
//  用户信息响应模型（服务器实际返回的格式）
//

import Foundation

/// 用户信息响应
struct UserInfoResponse: Codable {
    let trial: Bool?           // 是否试用
    let serverExpireTime: String?  // 到期时间（时卡）
    let serverRemainNum: Int?      // 剩余次数（次卡）
    let serverType: String?        // "time" 时卡, "ci" 次卡
    let userId: String?            // 用户ID
    
    enum CodingKeys: String, CodingKey {
        case trial
        case serverExpireTime
        case serverRemainNum
        case serverType
        case userId
    }
    
    /// 用户ID显示
    var userIdDescription: String {
        return userId ?? "未知"
    }
    
    /// 是否试用显示
    var trialDescription: String {
        return trial == true ? "是" : "否"
    }
    
    /// 卡类型显示
    var cardTypeDescription: String {
        switch serverType {
        case "time":
            return "时卡"
        case "ci":
            return "次卡"
        default:
            return "未知"
        }
    }
    
    /// 到期时间/剩余次数显示
    var expireInfoDescription: String {
        if serverType == "time", let expireTime = serverExpireTime {
            // 格式化时间显示
            let formatted = formatExpireTime(expireTime)
            return "到期时间: \(formatted)"
        } else if serverType == "ci", let remainNum = serverRemainNum {
            return "剩余次数: \(remainNum)"
        }
        return "无"
    }
    
    /// 格式化到期时间
    private func formatExpireTime(_ time: String) -> String {
        // 处理 ISO 8601 格式: "2025-12-31T18:28:23" 或带毫秒 "2019-08-24T14:15:22.123Z"
        
        // 移除毫秒部分（如果有）
        var cleanTime = time
        if time.contains(".") {
            // 去掉毫秒和可能的 Z
            let components = time.components(separatedBy: ".")
            if components.count > 0 {
                cleanTime = components[0]
                if cleanTime.hasSuffix("Z") {
                    cleanTime = String(cleanTime.dropLast())
                }
            }
        }
        
        // 格式化
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        
        if let date = formatter.date(from: cleanTime) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "yyyy年M月d日 HH:mm:ss"
            return displayFormatter.string(from: date)
        }
        
        // 如果还是解析失败，尝试直接解析原始字符串
        if let date = formatter.date(from: time) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "yyyy年M月d日 HH:mm:ss"
            return displayFormatter.string(from: date)
        }
        
        // 直接返回原始字符串
        return time
    }
}
