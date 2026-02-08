//
//  NetworkManager.swift
//  verifyhub
//
//  网络管理器 - 基于URLSession封装
//

import Foundation

/// 网络管理器
class NetworkManager {
    
    // MARK: - Singleton
    
    static let shared = NetworkManager()
    
    // MARK: - Properties
    
    private let session: URLSession
    private let interceptor = KauthInterceptor()
    
    // MARK: - Configuration
    
    private var baseURL: String {
        return KauthCore.shared.getBaseURL()
    }
    
    // MARK: - Initialization
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        session = URLSession(configuration: config)
    }
    
    // MARK: - Public Methods
    
    /// 发起请求（兼容iOS 10+）
    func request<T: Decodable>(_ endpoint: APIEndpoint, completion: @escaping (Result<T, Error>) -> Void) {
        let url = try? buildURL(path: endpoint.path)
        guard let validURL = url else {
            completion(.failure(KauthError.invalidURL))
            return
        }
        
        var request = URLRequest(url: validURL)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        
        // 编码请求体 (保持驼峰格式，与服务端和Android端一致)
        if let body = endpoint.body {
            let encoder = JSONEncoder()
            request.httpBody = try? encoder.encode(body)
        }
        
        // 请求拦截
        guard let signedRequest = try? interceptor.adapt(request: request) else {
            completion(.failure(KauthError.signatureFailed))
            return
        }
        
        // 发起请求
        session.dataTask(with: signedRequest) { data, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  let validData = data else {
                DispatchQueue.main.async { completion(.failure(KauthError.invalidURL)) }
                return
            }
            
            // 响应拦截
            do {
                let verifiedData = try self.interceptor.verify(response: httpResponse, data: validData, request: signedRequest)
                print("📥 拦截器返回数据: \(String(data: verifiedData, encoding: .utf8) ?? "nil")")
                
                // 解码响应
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let result = try decoder.decode(T.self, from: verifiedData)
                DispatchQueue.main.async { completion(.success(result)) }
            } catch {
                print("❌ 解码响应失败: \(error.localizedDescription)")
                if let verifiedData = try? self.interceptor.verify(response: httpResponse, data: validData, request: signedRequest) {
                    print("📥 拦截器返回数据: \(String(data: verifiedData, encoding: .utf8) ?? "nil")")
                }
                DispatchQueue.main.async { completion(.failure(KauthError.responseParseFailed(error.localizedDescription))) }
            }
        }.resume()
    }
    
    /// 发起请求（无响应数据）
    func requestVoid(_ endpoint: APIEndpoint, completion: @escaping (Result<Void, Error>) -> Void) {
        request(endpoint) { (result: Result<EmptyResponse, Error>) in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func buildURL(path: String) throws -> URL {
        let urlString = baseURL + path
        guard let url = URL(string: urlString) else {
            throw KauthError.invalidURL
        }
        return url
    }
}

// MARK: - EmptyResponse

struct EmptyResponse: Codable {}

// MARK: - APIEndpoint

/// API端点
struct APIEndpoint {
    let path: String
    let method: HTTPMethod
    let body: Encodable?
    
    init(path: String, method: HTTPMethod = .post, body: Encodable? = nil) {
        self.path = path
        self.method = method
        self.body = body
    }
    
    // MARK: - Factory Methods (用户认证模块)
    
    static func getCaptcha(captchaKey: String?) -> APIEndpoint {
        let body = CaptchaRequest(captchaKey: captchaKey)
        return APIEndpoint(path: "/api/consumer/user/captcha", body: body)
    }
    
    /// 用户密码登录 (与Android KauthApiService.pwdLogin一致)
    static func pwdLogin(loginName: String, password: String, captchaCode: String? = nil, captchaUuid: String? = nil, deviceId: String) -> APIEndpoint {
        let body = PwdLoginRequest(loginName: loginName, password: password, captchaCode: captchaCode, captchaUuid: captchaUuid, deviceId: deviceId)
        return APIEndpoint(path: "/api/consumer/user/pwdlogin", body: body)
    }
    
    /// 卡密登录 (与Android KauthApiService.kaLogin一致)
    static func kaLogin(kaPwd: String, captchaCode: String? = nil, captchaUuid: String? = nil, deviceId: String, platformType: String = "iOS") -> APIEndpoint {
        let body = KaLoginRequest(kaPwd: kaPwd, captchaCode: captchaCode, captchaUuid: captchaUuid, deviceId: deviceId, platformType: platformType)
        return APIEndpoint(path: "/api/consumer/user/kaLogin", body: body)
    }
    
    static func loginOut() -> APIEndpoint {
        return APIEndpoint(path: "/api/consumer/user/loginOut")
    }
    
    static func trialLogin(captchaKey: String? = nil, captchaCode: String? = nil) -> APIEndpoint {
        let body = TrialLoginReq(captchaKey: captchaKey, captchaCode: captchaCode)
        return APIEndpoint(path: "/api/consumer/user/trialLogin", body: body)
    }
    
    /// 用户注册 (与Android KauthApiService.register一致)
    static func register(loginName: String, password: String, kaPassword: String, captchaCode: String? = nil, captchaUuid: String? = nil, nickName: String? = nil, deviceId: String) -> APIEndpoint {
        let body = RegisterRequest(loginName: loginName, password: password, kaPassword: kaPassword, captchaCode: captchaCode, captchaUuid: captchaUuid, nickName: nickName, deviceId: deviceId)
        return APIEndpoint(path: "/api/consumer/user/register", body: body)
    }
    
    /// 账号充值 (与Android KauthApiService.recharge一致)
    static func recharge(loginName: String, kaPassword: String, deviceId: String, captchaCode: String? = nil, captchaUuid: String? = nil) -> APIEndpoint {
        let body = RechargeRequest(loginName: loginName, kaPassword: kaPassword, deviceId: deviceId, captchaCode: captchaCode, captchaUuid: captchaUuid)
        return APIEndpoint(path: "/api/consumer/user/recharge", body: body)
    }
    
    /// 以卡充卡 (与Android KauthApiService.rechargeKa一致)
    static func rechargeKa(cardPwd: String, rechargeCardPwd: String) -> APIEndpoint {
        let body = KaRechargeKaReq(cardPwd: cardPwd, rechargeCardPwd: rechargeCardPwd)
        return APIEndpoint(path: "/api/consumer/user/rechargeKa", body: body)
    }
    
    static func changePassword(username: String, newPassword: String, captchaKey: String? = nil, captchaCode: String? = nil) -> APIEndpoint {
        let body = ResetPwdRequest(username: username, newPassword: newPassword, captchaKey: captchaKey, captchaCode: captchaCode)
        return APIEndpoint(path: "/api/consumer/user/changePassword", body: body)
    }
    
    static func unbindDevice(deviceId: String? = nil) -> APIEndpoint {
        let body = UnbindDeviceRequest(deviceId: deviceId)
        return APIEndpoint(path: "/api/consumer/user/unbindDevice", body: body)
    }
    
    /// 未登录状态下，卡密解绑设备 (与Android KauthApiService.unbindDeviceKaPwd一致)
    static func unbindDeviceKaPwd(kaPwd: String, deviceId: String) -> APIEndpoint {
        let body = UnbindDeviceKaPwdRequest(kaPwd: kaPwd, deviceId: deviceId)
        return APIEndpoint(path: "/api/consumer/user/unbindDeviceKaPwd", body: body)
    }
    
    static func userInfo() -> APIEndpoint {
        return APIEndpoint(path: "/api/consumer/user/userInfo")
    }
    
    static func pong() -> APIEndpoint {
        return APIEndpoint(path: "/api/consumer/user/pong")
    }
    
    // MARK: - Factory Methods (配置管理模块)
    
    static func updateUserConfig(configData: String) -> APIEndpoint {
        let body = UpdateCustomConfigReq(configData: configData)
        return APIEndpoint(path: "/api/consumer/custom/config/updateUserConfig", body: body)
    }
    
    static func getUserConfig() -> APIEndpoint {
        return APIEndpoint(path: "/api/consumer/custom/config/getUserConfig")
    }
    
    static func updateKaConfig(configData: String) -> APIEndpoint {
        let body = UpdateCustomConfigReq(configData: configData)
        return APIEndpoint(path: "/api/consumer/custom/config/updateKaConfig", body: body)
    }
    
    static func getKaConfig() -> APIEndpoint {
        return APIEndpoint(path: "/api/consumer/custom/config/getKaConfig")
    }
    
    // MARK: - Factory Methods (程序管理模块)
    
    static func getProgramDetail() -> APIEndpoint {
        return APIEndpoint(path: "/api/consumer/program/detail")
    }
    
    static func getServerTime() -> APIEndpoint {
        return APIEndpoint(path: "/api/consumer/program/serverTime")
    }
    
    // MARK: - Factory Methods (脚本错误模块)
    
    static func reportScriptError(errorType: String, errorMsg: String, stackTrace: String? = nil, scriptName: String? = nil, scriptVersion: String? = nil) -> APIEndpoint {
        let body = ConsumerProgramScriptErrorReportReq(errorType: errorType, errorMsg: errorMsg, stackTrace: stackTrace, scriptName: scriptName, scriptVersion: scriptVersion)
        return APIEndpoint(path: "/api/consumer/scriptError/report", body: body)
    }
    
    // MARK: - Factory Methods (设备管理模块)
    
    static func cardUnBindDevice() -> APIEndpoint {
        return APIEndpoint(path: "/api/consumer/device/cardUnBindDevice")
    }
    
    // MARK: - Factory Methods (远程控制模块)
    
    static func getRemoteVar(varKey: String, defaultValue: String? = nil) -> APIEndpoint {
        let body = GetRemoteVarReq(varKey: varKey, defaultValue: defaultValue)
        return APIEndpoint(path: "/api/remote/getRemoteVar", body: body)
    }
    
    static func getRemoteData(varKey: String, defaultValue: String? = nil) -> APIEndpoint {
        let body = GetRemoteVarReq(varKey: varKey, defaultValue: defaultValue)
        return APIEndpoint(path: "/api/remote/getRemoteData", body: body)
    }
    
    static func addRemoteData(varKey: String, data: String, expireTime: Int64? = nil) -> APIEndpoint {
        let body = RemoteDataAddReq(varKey: varKey, data: data, expireTime: expireTime)
        return APIEndpoint(path: "/api/remote/addRemoteData", body: body)
    }
    
    static func updateRemoteData(id: Int64, data: String? = nil, expireTime: Int64? = nil) -> APIEndpoint {
        let body = RemoteDataUpdateReq(id: id, data: data, expireTime: expireTime)
        return APIEndpoint(path: "/api/remote/updateRemoteData", body: body)
    }
    
    static func deleteRemoteData(id: Int64) -> APIEndpoint {
        let body = RemoteDataDeleteReq(id: id)
        return APIEndpoint(path: "/api/remote/deleteRemoteData", body: body)
    }
    
    static func callFunction(functionName: String, params: String? = nil) -> APIEndpoint {
        let body = CallFunctionReq(functionName: functionName, params: params)
        return APIEndpoint(path: "/api/remote/callFunction", body: body)
    }
    
    static func getNewestScript(version: String? = nil) -> APIEndpoint {
        let body = GetNewestScriptReq(version: version)
        return APIEndpoint(path: "/api/remote/getNewestScript", body: body)
    }
    
    static func scriptDownloadV2(version: String? = nil, scriptMd5: String? = nil) -> APIEndpoint {
        let body = ScriptDownloadReq(version: version, scriptMd5: scriptMd5)
        return APIEndpoint(path: "/api/remote/scriptDownloadV2", body: body)
    }
}

// MARK: - HTTPMethod

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}
