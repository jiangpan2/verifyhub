//
//  RequestModels.swift
//  verifyhub
//
//  请求模型
//

import Foundation

// MARK: - 用户认证模块

/// 图形验证码请求
struct CaptchaRequest: Codable {
    let captchaKey: String?
}

/// 密码登录请求 (与Android PwdLoginRequest一致)
struct PwdLoginRequest: Codable {
    /// 登录账号
    let loginName: String
    /// 登录密码
    let password: String
    /// 图形验证码(可选)
    let captchaCode: String?
    /// 图形验证码UUID(可选)
    let captchaUuid: String?
    /// 设备ID
    let deviceId: String
}

/// 卡密登录请求 (与Android KauthApiService.KaLoginRequest一致)
struct KaLoginRequest: Codable {
    /// 卡密
    let kaPwd: String
    /// 图形验证码(可选)
    let captchaCode: String?
    /// 图形验证码UUID(可选)
    let captchaUuid: String?
    /// 设备ID
    let deviceId: String
    /// 平台类型
    let platformType: String
}

/// 试用登录请求
struct TrialLoginReq: Codable {
    let captchaKey: String?
    let captchaCode: String?
}

/// 用户注册请求 (与Android RegisterRequest一致)
struct RegisterRequest: Codable {
    /// 登录账号
    let loginName: String
    /// 登录密码
    let password: String
    /// 卡密
    let kaPassword: String
    /// 图形验证码(可选)
    let captchaCode: String?
    /// 图形验证码UUID(可选)
    let captchaUuid: String?
    /// 用户昵称
    let nickName: String?
    /// 设备ID
    let deviceId: String
}

/// 账号充值请求 (与Android RechargeRequest一致)
struct RechargeRequest: Codable {
    /// 登录账号
    let loginName: String
    /// 充值卡密
    let kaPassword: String
    /// 设备ID
    let deviceId: String
    /// 图形验证码(可选)
    let captchaCode: String?
    /// 图形验证码UUID(可选)
    let captchaUuid: String?
}

/// 以卡充卡请求 (与Android KaRechargeKaReq一致)
struct KaRechargeKaReq: Codable {
    /// 被充值的卡密
    let cardPwd: String
    /// 充值卡密
    let rechargeCardPwd: String
}

/// 重置密码请求
struct ResetPwdRequest: Codable {
    let username: String
    let newPassword: String
    let captchaKey: String?
    let captchaCode: String?
}

/// 解绑设备请求
struct UnbindDeviceRequest: Codable {
    let deviceId: String?
}

/// 未登录卡密解绑设备请求 (与Android UnbindDeviceKaPwdRequest一致)
struct UnbindDeviceKaPwdRequest: Codable {
    /// 卡密
    let kaPwd: String
    /// 设备ID
    let deviceId: String
}

// MARK: - 配置管理模块

/// 更新自定义配置请求
struct UpdateCustomConfigReq: Codable {
    let configData: String
}

// MARK: - 脚本错误模块

/// 脚本错误报告请求
struct ConsumerProgramScriptErrorReportReq: Codable {
    let errorType: String
    let errorMsg: String
    let stackTrace: String?
    let scriptName: String?
    let scriptVersion: String?
}

// MARK: - 远程控制模块

/// 获取远程变量请求
struct GetRemoteVarReq: Codable {
    let varKey: String
    let defaultValue: String?
}

/// 添加远程数据请求
struct RemoteDataAddReq: Codable {
    let varKey: String
    let data: String
    let expireTime: Int64?
}

/// 更新远程数据请求
struct RemoteDataUpdateReq: Codable {
    let id: Int64
    let data: String?
    let expireTime: Int64?
}

/// 删除远程数据请求
struct RemoteDataDeleteReq: Codable {
    let id: Int64
}

/// 调用函数请求
struct CallFunctionReq: Codable {
    let functionName: String
    let params: String?
}

/// 获取最新脚本请求
struct GetNewestScriptReq: Codable {
    let version: String?
}

/// 脚本下载请求
struct ScriptDownloadReq: Codable {
    let version: String?
    let scriptMd5: String?
}
