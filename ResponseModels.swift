//
//  ResponseModels.swift
//  verifyhub
//
//  响应模型
//

import Foundation

/// 解析结果（拦截器用）
struct ParseResult: Codable {
    let msg: String?
    let data: String?  // 加密的响应数据
    let code: Int?
    let traceId: String?
    let elapse: String?
    let respTime: String?
    let isSuccess: Bool?  // 服务器返回的是 isSuccess
    
    enum CodingKeys: String, CodingKey {
        case msg
        case data
        case code
        case traceId
        case elapse
        case respTime
        case isSuccess
    }
    
    var success: Bool? {
        return isSuccess
    }
    
    var isSuccessValue: Bool {
        return code == 200 || isSuccess == true
    }
}

/// API响应结果
struct ApiResult<T: Codable>: Codable {
    let msg: String?
    let data: T?
    let code: Int?
    let traceId: String?
    let elapse: String?
    let respTime: String?
    
    var isSuccess: Bool {
        return code == 200
    }
}

// MARK: - 用户认证模块

/// 图形验证码响应
struct CaptchaResponse: Codable {
    let captchaBase64: String?
    let captchaKey: String?
}

/// 用户信息
struct UserInfo: Codable {
    let id: Int?
    let username: String?
    let nickname: String?
    let avatar: String?
    let balance: Double?
    let expireTime: String?
    let deviceBindCount: Int?
    let maxDeviceBindCount: Int?
}

/// 登录响应
struct LoginResponse: Codable {
    let token: String?
    let pongInterval: String?  // 服务器返回的是字符串
    let userInfo: UserInfo?
}

/// 注册响应
struct RegisterResponse: Codable {
    let token: String?
    let userInfo: UserInfo?
}

// MARK: - 配置管理模块

/// 自定义配置响应
struct GetCustomConfigResp: Codable {
    let configData: String?
}

// MARK: - 程序管理模块

/// 程序详情响应
struct ProgramDetailResponse: Codable {
    let id: Int?
    let name: String?
    let icon: String?
    let description: String?
    let version: String?
    let scriptMd5: String?
    let downloadUrl: String?
}

/// 服务器时间响应
struct ServerTimeResp: Codable {
    let serverTime: Int64?
}

// MARK: - 远程控制模块

/// 远程变量响应
struct RemoteNormalVarResp: Codable {
    let data: String?
    let varKey: String?
    let varType: String?
}

/// 远程数据响应
struct RemoteDataAddResp: Codable {
    let id: Int64?
}

/// 调用函数响应
struct CallFunctionResp: Codable {
    let result: String?
    let error: String?
}

/// 最新脚本响应
struct GetNewestScriptResp: Codable {
    let scriptContent: String?
    let scriptMd5: String?
    let version: String?
}

/// 脚本下载响应
struct RemoteScriptDownloadResp: Codable {
    let scriptContent: String?
    let scriptMd5: String?
    let version: String?
    let downloadUrl: String?
}

// MARK: - 脚本错误报告

/// 脚本错误报告响应（无数据）
