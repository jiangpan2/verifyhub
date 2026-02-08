//
//  UserDefaultsStorage.swift
//  verifyhub
//
//  UserDefaults存储 - 简单数据存储
//

import Foundation

/// UserDefaults存储
class UserDefaultsStorage {
    
    private let defaults: UserDefaults
    private let prefix: String
    
    init(suiteName: String? = nil, prefix: String = "") {
        if let name = suiteName {
            self.defaults = UserDefaults(suiteName: name) ?? UserDefaults.standard
        } else {
            self.defaults = UserDefaults.standard
        }
        self.prefix = prefix
    }
    
    /// 保存
    func save(_ key: String, _ value: String) {
        let fullKey = prefix + key
        defaults.set(value, forKey: fullKey)
    }
    
    /// 读取
    func read(_ key: String) -> String? {
        let fullKey = prefix + key
        return defaults.string(forKey: fullKey)
    }
    
    /// 删除
    func delete(_ key: String) {
        let fullKey = prefix + key
        defaults.removeObject(forKey: fullKey)
    }
    
    /// 清空
    func clear() {
        if prefix.isEmpty {
            defaults.removePersistentDomain(forName: Bundle.main.bundleIdentifier ?? "")
        } else {
            // 清除带有prefix的key
            defaults.dictionaryRepresentation().keys.filter { $0.hasPrefix(prefix) }.forEach {
                defaults.removeObject(forKey: $0)
            }
        }
    }
}
