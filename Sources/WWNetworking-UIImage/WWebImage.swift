//
//  WWebImage.swift
//  Example
//
//  Created by iOS on 2023/3/15.
//

import UIKit
import WWPrint
import WWNetworking
import WWSQLite3Manager

open class WWWebImage {
    
    static let shared = WWWebImage()
    
    var imageSetUrls: Set<String> = []
    
    private var isDownloading = false

    private init() { downloadWebImageWithNotification() }
}

// MARK: - WWNetworking (公開工具)
public extension WWWebImage {
    
    /// [初始化資料表 / 資料庫](https://blog.techbridge.cc/2017/06/17/cache-introduction/)
    /// - Parameters:
    ///   - directoryType: 要存放的資料夾
    ///   - expiredDays: 圖片要清除的過期時間
    /// - Returns: Result<SQLite3Database.ExecuteResult, Error>
    static func initDatabase(for directoryType: WWSQLite3Manager.FileDirectoryType = .documents, expiredDays: Int = 90) -> Result<SQLite3Database.ExecuteResult, Error> {
        
        let result = WWSQLite3Manager.shared.connent(for: directoryType, filename: Constant.databaseName)
        Constant.cacheImageFolderType = directoryType
        
        defer { removeExpiredCacheImages(expiredDays) }
        
        switch result {
        case .failure(let error): return .failure(error)
        case .success(let database):
            
            let result = createDatabase(database, for: Constant.tableName)
            Constant.database = database

            return .success(result)
        }
    }
}

// MARK: - WWNetworking (小工具)
private extension WWWebImage {
    
    /// 建立資料庫
    /// - Parameters:
    ///   - database: SQLite3Database
    ///   - tableName: String
    /// - Returns: SQLite3Database.ExecuteResult
    static func createDatabase(_ database: SQLite3Database, for tableName: String) -> SQLite3Database.ExecuteResult {
        let result = database.create(tableName: tableName, type: WebImageInformation.self, isOverwrite: false)
        return result
    }
    
    /// 刪除快取圖片
    /// - Parameters:
    ///   - filename: String
    /// - Returns: Result<Bool, Error>
    static func removeImage(filename: String) -> Result<Bool, Error> {
        
        guard let imageFolderUrl = Constant.cacheImageFolder else { return .failure(Constant.MyError.notOpenURL) }
        
        let url = imageFolderUrl.appendingPathComponent(filename, isDirectory: false)
        
        defer {
            let isExist = FileManager.default._fileExists(with: url)
            wwPrint("\(filename) => \(isExist)")
        }
        
        return FileManager.default._removeFile(at: url)
    }
    
    /// 移除過期快取圖片 => updateTime
    /// - Parameter expiredDays: 圖片要清除的過期時間
    static func removeExpiredCacheImages(_ expiredDays: Int) {
        
        let expiredCacheImages = API.shared.searchExpiredCacheImageInformation(expiredDays: expiredDays, for: Constant.tableName)
        
        expiredCacheImages.compactMap { dictionary in
            dictionary._jsonClass(for: WebImageInformation.self)
        }.forEach { info in
            let result = removeImage(filename: info.name)
            wwPrint(result)
        }
        
        let isSuccess = API.shared.deleteCacheImageInformation(expiredDays: expiredDays, for: Constant.tableName)
        wwPrint("expiredCacheImages => \(expiredCacheImages.count), delete isSuccess => \(isSuccess)")
    }
}

// MARK: - WWNetworking (公開工具)
extension WWWebImage {
    
    /// 讀取存在手機的快取圖示檔
    /// - Parameter filename: String?
    /// - Returns: UIImage?
    func cacheImage(with urlString: String) -> UIImage? {
        
        guard let imageFolderUrl = Constant.cacheImageFolder else { return nil }
        
        let filename = urlString._sha1()
        let path = imageFolderUrl.appendingPathComponent(filename, isDirectory: false).path
        let image = UIImage(contentsOfFile: path)
        
        return image
    }
}

// MARK: - WWNetworking (小工具)
private extension WWWebImage {
    
    /// 下載網路圖片 => 利用Notification單張單張下載
    func downloadWebImageWithNotification() {
        
        NotificationCenter.default._register(name: .downloadWebImage) { [weak self] _ in
            
            guard let this = self,
                  !this.isDownloading,
                  let urlString = this.imageSetUrls.popFirst()
            else {
                return
            }
            
            this.isDownloading = true
            
            this.downloadImage(with: urlString) { isSuccess in
                
                this.isDownloading = false
                                
                if (isSuccess) { NotificationCenter.default._post(name: .refreahImageView, object: urlString) }
                NotificationCenter.default._post(name: .downloadWebImage)
            }
        }
    }
}

// MARK: - WWNetworking (小工具)
private extension WWWebImage {
    
    /// [下載網路圖片](https://www.appcoda.com.tw/ios-concurrency/)
    /// - Parameter urlString: String
    func downloadImage(with urlString: String, completion: @escaping (Bool) -> Void) {
        let _ = API.shared.insertCacheImageUrl(urlString, for: Constant.tableName)
        self.downloadImageAction(with: urlString) { isSuccess in completion(isSuccess) }
    }
    
    /// 下載圖片功能
    /// - Parameters:
    ///   - urlString: String
    ///   - completion: (Bool) -> Void
    func downloadImageAction(with urlString: String, completion: @escaping (Bool) -> Void) {
        
        guard let imageInfo = API.shared.searchCacheImageInformation(urlString, for: Constant.tableName).first?._jsonClass(for: WebImageInformation.self) else { completion(true); return }
        
        self.imageUrlCacheHeader(urlString: urlString) { cacheResult in
            
            switch cacheResult {
            case .failure(let error): wwPrint(error)
            case .success(let fields):

                let isNeededUpdate = self.updateImageRule(urlString: urlString, fields: fields)
                if (!isNeededUpdate) { completion(false); return }
                
                let _ = API.shared.updateCacheImageInformation(id: imageInfo.id, fields: fields, for: Constant.tableName)

                self.downloadImage(urlString: urlString) { progress in
                    wwPrint(progress)
                } completion: { result in
                    switch result {
                    case .failure(_): completion(false)
                    case .success(let isSuccess): completion(isSuccess)
                    }
                }
            }
        }
    }
    
    /// 取得有關圖片的Header快取資訊 => 最後更新時間 / Etag / 檔案大小
    /// - Parameters:
    ///   - urlString: 圖片網址
    ///   - result: Result<CacheHeaderFields, Error>
    func imageUrlCacheHeader(urlString: String?, result: @escaping ((Result<Constant.CacheHeaderFields, Error>) -> Void)) {
        
        guard let urlString = urlString?._removeWhiteSpacesAndNewlines() else { return result(.failure(Constant.MyError.notOpenURL)) }
        
        WWNetworking.shared.header(urlString: urlString) { headerResult in
            
            switch headerResult {
            case .failure(let error): result(.failure(error))
            case .success(let info):
                
                guard let allHeaderFields = info.response?.allHeaderFields else { result(.failure(Constant.MyError.isEmpty)); return }
                
                let lastModified = allHeaderFields["Last-Modified"] as? String
                let eTag = allHeaderFields["Etag"] as? String
                let contentLength = allHeaderFields["Content-Length"] as? String
                
                var fields: Constant.CacheHeaderFields = (lastModified: lastModified, eTag: eTag, contentLength: 0)
                if let contentLength = contentLength { fields.contentLength = Int(contentLength) }
                
                result(.success(fields))
            }
        }
    }
    
    /// 下載網路圖片
    /// - Parameters:
    ///   - urlString: 圖片網址
    ///   - progress: 下載進度資訊
    ///   - completion: Result<Bool, Error>
    func downloadImage(urlString: String?, progress: @escaping (WWNetworking.DownloadProgressInformation) -> Void, completion: @escaping ((Result<Bool, Error>) -> Void)) {
        
        guard let urlString = urlString else { completion(.failure(Constant.MyError.notOpenURL)); return }
        
        _ = WWNetworking().download(urlString: urlString, delegateQueue: nil) { info in
            progress(info)
        
        } completion: { downloadResult in
            
            switch downloadResult {
            case .failure(let error): completion(.failure(error)); wwPrint(error)
            case .success(let info):
                
                let _result = self.storeImageData(info.data, filename: urlString._sha1())

                switch _result {
                case .failure(let error): wwPrint(error); completion(.failure(error))
                case .success(let isSuccess): wwPrint("[下載完成] => \(urlString)"); completion(.success(isSuccess));
                }
            }
        }
    }
    
    /// [要不要更新下載圖片的規則](https://juejin.cn/post/6844904037821743112)
    /// => 有沒有下載圖片 (快取) / ETag是否一樣 / 最後更新日期是否有更新 / 檔案大小有變動
    /// - Parameters:
    ///   - urlString: String
    ///   - fields: CacheHeaderFields
    /// - Returns: Bool
    func updateImageRule(urlString: String, fields: Constant.CacheHeaderFields) -> Bool {
        
        guard let info = API.shared.searchCacheImageInformation(urlString, for: Constant.tableName).first,
              let imageCacheInfo = info._jsonClass(for: WebImageInformation.self)
        else {
            return true
        }
        
        var isNeededUpdateCache = false
        var isNeededUpdateETag = false
        var isNeededUpdateLastModified = false
        var isNeededUpdateContentLength = false

        if cacheImage(with: urlString) == nil {
            isNeededUpdateCache = true
        }
        
        if let _eTag = fields.eTag {
            if let eTag = imageCacheInfo.eTag { isNeededUpdateETag = (_eTag != eTag) }
        }
        
        if let _lastModified = fields.lastModified?._date() {
            if let lastModified = imageCacheInfo.lastModified?._date() { isNeededUpdateLastModified = (_lastModified > lastModified) }
        }
        
        if let _contentLength = fields.contentLength {
            if let contentLength = imageCacheInfo.contentLength { isNeededUpdateContentLength = (_contentLength != contentLength) }
        }
        
        return isNeededUpdateCache || isNeededUpdateETag || isNeededUpdateLastModified || isNeededUpdateContentLength
    }
}

// MARK: - 小工具
private extension WWWebImage {
    
    /// 儲存快取圖片
    /// - Parameters:
    ///   - data: Data?
    ///   - filename: String
    /// - Returns: Result<Bool, Error>
    func storeImageData(_ data: Data?, filename: String) -> Result<Bool, Error> {
        
        guard let data = data,
              let imageFolderUrl = Constant.cacheImageFolder
        else {
            return .failure(Constant.MyError.notOpenURL)
        }
        
        let url = imageFolderUrl.appendingPathComponent(filename, isDirectory: false)
        
        defer {
            let isExist = FileManager.default._fileExists(with: url)
            wwPrint("\(filename) => \(isExist)")
        }
        
        return FileManager.default._writeData(to: url, data: data)
    }
}

