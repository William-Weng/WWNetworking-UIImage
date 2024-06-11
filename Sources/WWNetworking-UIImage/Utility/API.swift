//
//  API.swift
//  WWNetworking-UIImage
//
//  Created by William.Weng on 2023/3/14.
//

import UIKit
import WWSQLite3Manager

// MARK: - API (單例)
final class API: NSObject {
    
    static let shared = API()
    private override init() {}
}

// MARK: - 小工具 (Search)
extension API {
    
    /// 圖片資訊搜尋
    /// - Parameters:
    ///   - url: 網址
    ///   - tableName: 資料表名稱
    /// - Returns: [[String : Any]]
    func searchCacheImageInformation(_ url: String, for tableName: String) -> [[String : Any]] {
        
        guard let database = Constant.database,
              let name = Optional.some(url._sha1())
        else {
            return []
        }
        
        let condition = SQLite3Condition.Where().isCompare(type: .equal(key: "name", value: name))
        let orderBy = SQLite3Condition.OrderBy().item(type: .ascending(key: "createTime"))
        let result = database.select(tableName: tableName, type: WebImageInformation.self, where: condition, orderBy: orderBy, limit: nil)
        
        return result.array
    }
    
    /// 過期圖片資訊搜尋
    /// - Parameters:
    ///   - expiredDays: 過期天數
    ///   - tableName: 資料表名稱
    /// - Returns: [[String : Any]]
    func searchExpiredCacheImageInformation(expiredDays: Int, for tableName: String) -> [[String : Any]] {
        
        guard let database = Constant.database,
              let expiredDate = Date()._adding(component: .day, value: expiredDays)
        else {
            return []
        }
        
        let condition = SQLite3Condition.Where().isCompare(type: .greaterThan(key: "updateTime", value: "\(expiredDate)"))
        let result = database.select(tableName: tableName, type: WebImageInformation.self, where: condition, orderBy: nil, limit: nil)
        
        return result.array
    }
}

// MARK: - 小工具 (Insert)
extension API {
    
    /// 新增快取圖片URL相關資訊
    /// - Parameters:
    ///   - url: String
    ///   - tableName: String
    /// - Returns: Bool
    func insertCacheImageUrl(_ url: String, for tableName: String) -> Bool {
        
        let items: [SQLite3Database.InsertItem] = [
            (key: "url", value: url),
            (key: "name", value: url._sha1()),
        ]
        
        guard let database = Constant.database,
              let result = database.insert(tableName: tableName, itemsArray: [items])
        else {
            return false
        }
        
        return result.isSussess
    }
}

// MARK: - 小工具 (Update)
extension API {
    
    /// 更新圖片快取資訊
    /// - Parameters:
    ///   - id: Int
    ///   - fields: CacheHeaderFields
    ///   - tableName: String
    /// - Returns: Bool
    func updateCacheImageInformation(id: Int, fields: Constant.CacheHeaderFields, for tableName: String) -> Bool {
        
        guard let database = Constant.database else { return false }
        
        var items: [SQLite3Database.InsertItem] = []
        
        if let lastModified = fields.lastModified { items.append((key: "lastModified", value: lastModified)) }
        if let eTag = fields.eTag { items.append((key: "eTag", value: eTag)) }
        if let contentLength = fields.contentLength { items.append((key: "contentLength", value: contentLength)) }
        items.append((key: "updateTime", value: Date()._localTime()))

        let condition = SQLite3Condition.Where().isCompare(type: .equal(key: "id", value: id))
        let result = database.update(tableName: tableName, items: items, where: condition)
        
        return result.isSussess
    }
    
    /// 更新圖片更新時間
    /// - Parameters:
    ///   - id: Int
    ///   - tableName: String
    /// - Returns: Bool
    func updateCacheImageUpdateTime(id: Int, for tableName: String) -> Bool {
        
        guard let database = Constant.database else { return false }
        
        var items: [SQLite3Database.InsertItem] = []
        
        items.append((key: "updateTime", value: Date()._localTime()))
        
        let condition = SQLite3Condition.Where().isCompare(type: .equal(key: "id", value: id))
        let result = database.update(tableName: tableName, items: items, where: condition)
        
        return result.isSussess
    }
}

// MARK: - 小工具 (Delete)
extension API {
    
    /// 刪除過期圖片
    /// - Parameters:
    ///   - expiredDays: 過期天數
    ///   - tableName: 資料表名稱
    /// - Returns: [[String : Any]]
    func deleteCacheImageInformation(expiredDays: Int, for tableName: String) -> Bool {
        
        guard let database = Constant.database,
              let expiredDate = Date()._adding(component: .day, value: expiredDays)
        else {
            return false
        }
        
        let condition = SQLite3Condition.Where().isCompare(type: .greaterThan(key: "updateTime", value: "\(expiredDate)"))
        let result = database.delete(tableName: tableName, where: condition)
        
        return result.isSussess
    }
    
    /// 刪除指定URL圖片
    /// - Parameters:
    ///   - urlString: String
    ///   - tableName: String
    /// - Returns: Bool
    func deleteCacheImageInformation(urlString: String, for tableName: String) -> Bool {
        
        guard let database = Constant.database else { return false }
        
        let condition = SQLite3Condition.Where().isCompare(type: .greaterThan(key: "url", value: urlString))
        let result = database.delete(tableName: tableName, where: condition)
        
        return result.isSussess
    }
}

