//
//  AppDelegate.swift
//  verifyhub
//
//  Created by kauth on 2025/12/29.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // 配置密钥参数
        let apiDomain = "https://api.kauth.cn"
        let programId = "2020596546195886081"
        let programSecret = "4mAW0usQTTds8uCF"
        let merchantPublicKey = "MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC8nVraRDfxkSEsGGUuFtd2zaqvsa7Q2dznyBmUgyZD7RGfesVGksP0BHrJlvW33TTrvr6rgqLljeoFAS+2wtMA+2II5dsf4zlm0QN1TSEIcPNdSWYcgQ8AKLI52SlCpomKdAuVm9xSUkQEvqbNGiFNzt2LgxKcVP4ppUoCKIdGHwIDAQAB"
        KauthCore.shared.configure(apiDomain: apiDomain, programId: programId, programSecret: programSecret, merchantPublicKey: merchantPublicKey)
        
        window = UIWindow(frame: UIScreen.main.bounds)
        let loginVC = LoginViewController()
        let navController = UINavigationController(rootViewController: loginVC)
        window?.rootViewController = navController
        window?.makeKeyAndVisible()
        return true
    }
}
