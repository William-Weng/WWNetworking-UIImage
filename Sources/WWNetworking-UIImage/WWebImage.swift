//
//  WWebImage.swift
//  WWNetworking-UIImage
//
//  Created by William.Weng on 2023/3/15.
//

import UIKit
import WWNetworking
import WWSQLite3Manager

open class WWWebImage {
    
    public struct RemoveImageError: Error {
        let error: Error
        let info: WebImageInformation
    }
    
    public static let shared = WWWebImage()
    
    private(set) var defaultImage: UIImage?
    
    var imageSetUrls: Set<String> = []
    
    private var isDownloading = false
    
    private var downloadProgressBlock: ((WWNetworking.DownloadProgressInformation) -> Void)?
    private var removeExpiredCacheImagesProgressBlock: ((Result<WebImageInformation, RemoveImageError>) -> Void)?
    
    private init() { downloadWebImageWithNotification() }
}

// MARK: - WWNetworking (公開工具)
public extension WWWebImage {
        
    /// [初始化資料表 / 資料庫](https://blog.techbridge.cc/2017/06/17/cache-introduction/)
    /// - Parameters:
    ///   - directoryType: 要存放的資料夾
    ///   - expiredDays: 圖片要清除的過期時間 (for 更新時間)
    ///   - cacheDelayTime: 圖片要更新的快取時間 (for 更新時間 / 避免一直更新)
    ///   - defaultImage: 預設圖片
    /// - Returns: Result<SQLite3Database.ExecuteResult, Error>
    func initDatabase(for directoryType: WWSQLite3Manager.FileDirectoryType = .documents, expiredDays: Int = 90, cacheDelayTime: TimeInterval = 600, defaultImage: UIImage?) -> Result<SQLite3Database.ExecuteResult, Error> {
        
        let result = WWSQLite3Manager.shared.connent(for: directoryType, filename: Constant.databaseName)
        Constant.cacheImageFolderType = directoryType
        Constant.cacheDelayTime = cacheDelayTime
        
        self.defaultImage = defaultImage
        
        defer { removeExpiredCacheImages(expiredDays: expiredDays) }
        
        switch result {
        case .failure(let error): return .failure(error)
        case .success(let database):
            
            let result = createDatabase(database, for: Constant.tableName)
            Constant.database = database
                        
            return .success(result)
        }
    }
    
    /// 移除過期快取圖片 => updateTime
    /// - Parameters:
    ///   - expiredDays: 圖片要清除的過期時間
    /// - Returns: 資料庫資料是否刪除
    func removeExpiredCacheImages(expiredDays: Int) -> Bool {
        
        let expiredCacheImages = API.shared.searchExpiredCacheImageInformation(expiredDays: expiredDays, for: Constant.tableName)
        
        expiredCacheImages.compactMap { dictionary in
            
            dictionary._jsonClass(for: WebImageInformation.self)
            
        }.forEach { info in
            
            let result = removeImage(filename: info.name)
            
            switch result {
            case .failure(let error): removeExpiredCacheImagesProgressBlock?(.failure(RemoveImageError(error: error, info: info)))
            case .success(let isSuccess): if (isSuccess) { removeExpiredCacheImagesProgressBlock?(.success(info)) }
            }
        }
        
        let isSuccess = API.shared.deleteCacheImageInformation(expiredDays: expiredDays, for: Constant.tableName)
        return isSuccess
    }
    
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
    
    /// 圖片下載進度
    /// - Parameter block: WWNetworking.DownloadProgressInformation
    func downloadProgress(block: @escaping (WWNetworking.DownloadProgressInformation) -> Void) {
        downloadProgressBlock = block
    }
    
    /// 刪除過期圖片進度
    /// - Parameter block: Result<WebImageInformation, RemoveImageError>
    func removeExpiredCacheImagesProgress(block: @escaping (Result<WebImageInformation, RemoveImageError>) -> Void) {
        removeExpiredCacheImagesProgressBlock = block
    }
}

// MARK: - WWNetworking (小工具)
private extension WWWebImage {
    
    /// 建立資料庫
    /// - Parameters:
    ///   - database: SQLite3Database
    ///   - tableName: String
    /// - Returns: SQLite3Database.ExecuteResult
    func createDatabase(_ database: SQLite3Database, for tableName: String) -> SQLite3Database.ExecuteResult {
        let result = database.create(tableName: tableName, type: WebImageInformation.self, isOverwrite: false)
        return result
    }
    
    /// 刪除快取圖片
    /// - Parameters:
    ///   - filename: String
    /// - Returns: Result<Bool, Error>
    func removeImage(filename: String) -> Result<Bool, Error> {
        
        guard let imageFolderUrl = Constant.cacheImageFolder else { return .failure(Constant.MyError.notOpenURL) }
        
        let url = imageFolderUrl.appendingPathComponent(filename, isDirectory: false)
        
        return FileManager.default._removeFile(at: url)
    }
    
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
    
    /// 下載圖片功能 (會避免一直更新)
    /// - Parameters:
    ///   - urlString: String
    ///   - completion: (Bool) -> Void
    func downloadImageAction(with urlString: String, completion: @escaping (Bool) -> Void) {
        
        guard let imageInfo = API.shared.searchCacheImageInformation(urlString, for: Constant.tableName).first?._jsonClass(for: WebImageInformation.self) else { completion(false); return }
        
        let cacheDelayTime = Date().timeIntervalSince1970 - Constant.cacheDelayTime
        let updateTime = imageInfo.updateTime.timeIntervalSince1970
        let contentLength = imageInfo.contentLength ?? 0
        
        if (updateTime > cacheDelayTime && contentLength > 0) { completion(false); return }
        
        self.imageUrlCacheHeader(urlString: urlString) { cacheResult in
            
            switch cacheResult {
            case .failure(_): completion(false)
            case .success(let fields):

                let isNeededUpdate = self.updateImageRule(urlString: urlString, fields: fields)
                
                if (!isNeededUpdate) {
                    let _ = API.shared.updateCacheImageUpdateTime(id: imageInfo.id, for: Constant.tableName)
                    completion(false); return
                }
                
                let _ = API.shared.updateCacheImageInformation(id: imageInfo.id, fields: fields, for: Constant.tableName)

                self.downloadImage(urlString: urlString) { progress in
                    WWWebImage.shared.downloadProgressBlock?(progress)
                } completion: { result in
                    switch result {
                    case .failure(_): completion(false)
                    case .success(let isSuccess): completion(isSuccess)
                    }
                }
            }
        }
    }
    
    /// [取得有關圖片的Header快取資訊 => 最後更新時間 / Etag / 檔案大小](https://zh.wikipedia.org/zh-tw/HTTP头字段)
    /// - Parameters:
    ///   - urlString: 圖片網址
    ///   - result: Result<CacheHeaderFields, Error>
    func imageUrlCacheHeader(urlString: String?, result: @escaping ((Result<Constant.CacheHeaderFields, Error>) -> Void)) {
        
        guard let urlString = urlString?._removeWhiteSpacesAndNewlines() else { return result(.failure(Constant.MyError.notOpenURL)) }
        
        WWNetworking.shared.header(urlString: urlString) { headerResult in
            
            switch headerResult {
            case .failure(let error): result(.failure(error))
            case .success(let info):
                
                guard let allHeaderFields = info.response?._allHeaderFields() else { result(.failure(Constant.MyError.isEmpty)); return }
                
                let lastModified = allHeaderFields["last-modified"] as? String
                let eTag = allHeaderFields["etag"] as? String
                let contentLength = allHeaderFields["content-length"] as? String
                
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
        
        _ = WWNetworking.build().download(urlString: urlString, delegateQueue: nil) { info in
            progress(info)
        
        } completion: { downloadResult in
            
            switch downloadResult {
            case .failure(let error): completion(.failure(error))
            case .success(let info):
                
                let _result = self.storeImageData(info.data, filename: urlString._sha1())

                switch _result {
                case .failure(let error): completion(.failure(error))
                case .success(let isSuccess): completion(.success(isSuccess));
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
        return FileManager.default._writeData(to: url, data: data)
    }
}

