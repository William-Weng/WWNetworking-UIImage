//
//  Constant.swift
//  WWNetworking-UIImage
//
//  Created by William.Weng on 2022/12/15.
//

import UIKit
import WWSQLite3Manager

// MARK: - Constant
open class Constant: NSObject {
    
    typealias FileInfomation = (isExist: Bool, isDirectory: Bool)                                           // 檔案相關資訊 (是否存在 / 是否為資料夾)
    typealias CacheHeaderFields = (url: URL?, lastModified: String?, eTag: String?, contentLength: Int?)    // 快取圖片的依據 (URL / 最後更新時間 / ETag / 檔案大小)
    typealias GIFImageInformation = (index: Int, cgImage: CGImage, pointer: UnsafeMutablePointer<Bool>)     // GIF動畫: (第幾張, CGImage, UnsafeMutablePointer<Bool>)

    static let databaseName = "WWWebImage.db"
    static let tableName = "CacheImage"
    
    static var cacheType: Constant.CacheType = .cache()
    static var maxnumDownloadCount: UInt = 10
    static var cacheDelayTime = 60.0
    static var cacheImageFolder = WWSQLite3Manager.FileDirectoryType.caches.url()    
    static var cacheImageFolderType: WWSQLite3Manager.FileDirectoryType = .caches { willSet { Self.cacheImageFolder = newValue.url() }}
    
    static var database: SQLite3Database?
    
    // MARK: - 快取類型 (SQLite / NSCache)
    public enum CacheType {
        case sqlite(_ folder: WWSQLite3Manager.FileDirectoryType = .documents, _ expiredDays: Int = 90, _ cacheDelayTime: TimeInterval = 600)
        case cache(_ countLimit: Int = 100, _ totalCostLimit: Int = 100 * 1024 * 1024, _ delegate: NSCacheDelegate? = nil)
    }
    
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
    
    /// 圖片的Data開頭辨識字元
    enum ImageFormat: CaseIterable {
        
        var header: [UInt8] { return headerMaker() }

        case icon
        case png
        case apng
        case jpeg
        case gif
        case webp
        case bmp
        case heic
        case avif
        case svg
        case pdf
        
        /// 圖片的文件標頭檔 (要看各圖檔的文件)
        /// - Returns: [UInt8]
        private func headerMaker() -> [UInt8] {
            
            switch self {
            case .icon: return [0x00, 0x00, 0x01, 0x00]
            case .png: return [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
            case .apng: return [0x61, 0x63, 0x54, 0x4C]
            case .jpeg: return [0xFF, 0xD8, 0xFF]
            case .gif: return [0x47, 0x49, 0x46]
            case .webp: return [0x52, 0x49, 0x46, 0x46, 0x00, 0x00, 0x00, 0x00, 0x57, 0x45, 0x42, 0x50]
            case .bmp:  return [0x42, 0x4D]
            case .heic: return [0x00, 0x00, 0x00, 0x00, 0x66, 0x74, 0x79, 0x70, 0x68, 0x65, 0x69, 0x63]
            case .avif: return [0x00, 0x00, 0x00, 0x00, 0x66, 0x74, 0x79, 0x70, 0x61, 0x76, 0x69, 0x66]
            case .svg: return []
            case .pdf: return [0x25, 0x50, 0x44, 0x46]
            }
        }
    }
}
