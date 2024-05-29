//
//  Constant.swift
//  WWNetworking-UIImage
//
//  Created by William.Weng on 2022/12/15.
//

import UIKit
import WWSQLite3Manager

// MARK: - Constant
final class Constant: NSObject {
    
    typealias FileInfomation = (isExist: Bool, isDirectory: Bool)                                           // 檔案相關資訊 (是否存在 / 是否為資料夾)
    typealias CacheHeaderFields = (url: URL?, lastModified: String?, eTag: String?, contentLength: Int?)    // 快取圖片的依據 (URL / 最後更新時間 / ETag / 檔案大小)
    
    static let databaseName = "WWWebImage.db"
    static let tableName = "CacheImage"
    static let maxnumDownloadCount: UInt = 5
    
    static var cacheDelayTime = 60.0
    static var cacheImageFolder = WWSQLite3Manager.FileDirectoryType.caches.url()    
    static var cacheImageFolderType: WWSQLite3Manager.FileDirectoryType = .caches {
        willSet { Self.cacheImageFolder = newValue.url() }
    }
    
    static var database: SQLite3Database?
    
    // MARK: - 自定義錯誤
    enum MyError: Error, LocalizedError {
        
        var errorDescription: String { errorMessage() }
        
        case notOpenURL
        case notImage
        case notInsert
        case isEmpty
        case removeImage(_ url: URL)
        
        /// 顯示錯誤說明
        /// - Returns: String
        private func errorMessage() -> String {
            switch self {
            case .notOpenURL: return "打開URL錯誤"
            case .notImage: return "不是圖片檔"
            case .notInsert:  return "加入資料庫錯誤"
            case .isEmpty: return "空資料"
            case .removeImage(_): return "刪除圖片失敗"
            }
        }
    }
    
    /// [時間的格式](https://nsdateformatter.com)
    enum DateFormat: CustomStringConvertible {
        
        var description: String { return toString() }
        
        case full
        case long
        case middle
        case meridiem(formatLocale: Locale)
        case short
        case timeZone
        case time
        case yearMonth
        case monthDay
        case day
        case web
        case custom(format: String)
        
        /// [轉成對應的字串](https://medium.com/彼得潘的-swift-ios-app-開發問題解答集/dateformatter-的-am-pm-問題-5e0d301e8998)
        private func toString() -> String {
            
            switch self {
            case .full: return "yyyy-MM-dd HH:mm:ss ZZZ"
            case .long: return "yyyy-MM-dd HH:mm:ss"
            case .middle: return "yyyy-MM-dd HH:mm"
            case .meridiem: return "yyyy-MM-dd hh:mm a"
            case .short: return "yyyy-MM-dd"
            case .timeZone: return "ZZZ"
            case .time: return "HH:mm:ss"
            case .yearMonth: return "yyyy-MM"
            case .monthDay: return "MM-dd"
            case .day: return "dd"
            case .web: return "E, dd MM yyyy hh:mm:ss ZZZ"
            case .custom(let format): return format
            }
        }
    }
    
    /// NotificationName
    enum NotificationName {
        
        /// 顯示真實的值
        var value: Notification.Name { return notificationName() }
        
        case downloadWebImage   // 下載網路圖片
        case refreahImageView   // 更新UIImageBiew

        /// 顯示真實的值 => Notification.Name
        func notificationName() -> Notification.Name {
            
            switch self {
            case .downloadWebImage: return Notification._name("WWWebImage_DownloadWebImage")
            case .refreahImageView: return Notification._name("WWWebImage_RefreahImageView")
            }
        }
    }
}
