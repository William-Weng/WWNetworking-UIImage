//
//  WWebImage.swift
//  WWNetworking-UIImage
//
//  Created by William.Weng on 2023/3/15.
//

import UIKit
import WWNetworking
import WWSQLite3Manager
import WWCacheManager

// MARK: - WWWebImage
open class WWWebImage {
    
    public struct RemoveImageError: Error {
        let error: Error
        let info: WebImageInformation
    }
    
    static public let shared = WWWebImage()
    
    private(set) var defaultImage: UIImage?
    
    var imageSetUrls: Set<String> = []
    
    private var isDownloading = false
    private var cacheManager = WWCacheManager<NSString, NSData>.build()

    private var downloadProgressBlock: ((WWNetworking.DownloadProgressInformation) -> Void)?
    private var removeExpiredCacheImagesProgressBlock: ((Result<WebImageInformation, RemoveImageError>) -> Void)?
    private var errorBlock: ((Error) -> Void)?
    
    private init() { downloadWebImageWithNotification() }
}

// MARK: - WWNetworking (公開工具)
public extension WWWebImage {
    
    /// [初始化快取類型 - SQLite / NSCache](https://blog.techbridge.cc/2017/06/17/cache-introduction/)
    /// - Parameters:
    ///   - cacheType: 快取類型 (SQLite / NSCache)
    ///   - maxnumDownloadCount: 最大同時下載數量
    ///   - defaultImage: 預設圖片
    /// - Returns: Error?
    func cacheTypeSetting(_ cacheType: Constant.CacheType, maxnumDownloadCount: UInt = 5, defaultImage: UIImage?) -> Error? {
        
        Constant.cacheType = cacheType
        Constant.maxnumDownloadCount = 10
        self.defaultImage = defaultImage
        
        switch cacheType {
        case .cache(let countLimit, let totalCostLimit, let delegate):
            cacheManager = WWCacheManager<NSString, NSData>.build(countLimit: countLimit, totalCostLimit: totalCostLimit, delegate: delegate)
            return nil
        case .sqlite(let folder, let expiredDays, let cacheDelayTime):
            let result = initDatabase(for: folder, expiredDays: expiredDays, cacheDelayTime: cacheDelayTime)
            switch result {
            case .success(let success): return nil
            case .failure(let error): return error
            }
        }
    }
    
    /// 移除過期快取圖片 (SQLite) => updateTime
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
    
    /// 讀取存在手機的快取圖示檔Data
    /// - Parameter urlString: String
    /// - Returns: Data?
    func cacheImageData(with urlString: String) -> Data? {
        
        switch Constant.cacheType {
        case .sqlite(_, _, _): return cacheImageDataWithDatabase(urlString: urlString)
        case .cache: return cacheImageDataWithCache(urlString: urlString)
        }
    }
    
    /// 讀取存在手機的快取圖示檔
    /// - Parameter urlString: String?
    /// - Returns: UIImage?
    func cacheImage(with urlString: String) -> UIImage? {
        
        guard let data = cacheImageData(with: urlString) else { return nil }
        
        let image = UIImage(data: data)
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
    
    /// 相關錯誤訊息輸出
    /// - Parameter block: Result<WebImageInformation, RemoveImageError>
    func errorBlock(block: @escaping (Error) -> Void) {
        errorBlock = block
    }
}

// MARK: - WWNetworking (小工具)
private extension WWWebImage {
    
    /// [初始化資料表 / 資料庫](https://blog.techbridge.cc/2017/06/17/cache-introduction/)
    /// - Parameters:
    ///   - directoryType: 要存放的資料夾
    ///   - expiredDays: 圖片要清除的過期時間 (for 更新時間)
    ///   - cacheDelayTime: 圖片要更新的快取時間 (for 更新時間 / 避免一直更新)
    /// - Returns: Result<SQLite3Database.ExecuteResult, Error>
    func initDatabase(for directoryType: WWSQLite3Manager.FileDirectoryType, expiredDays: Int, cacheDelayTime: TimeInterval) -> Result<SQLite3Database.ExecuteResult, Error> {
        
        let result = WWSQLite3Manager.shared.connent(for: directoryType, filename: Constant.databaseName)
        
        Constant.cacheImageFolderType = directoryType
        Constant.cacheDelayTime = cacheDelayTime
        
        defer { _ = removeExpiredCacheImages(expiredDays: expiredDays) }
        
        switch result {
        case .failure(let error): return .failure(error)
        case .success(let database):
            
            let result = createDatabase(database, for: Constant.tableName)
            Constant.database = database
                        
            return .success(result)
        }
    }
    
    /// 建立資料庫
    /// - Parameters:
    ///   - database: SQLite3Database
    ///   - tableName: String
    /// - Returns: SQLite3Database.ExecuteResult
    func createDatabase(_ database: SQLite3Database, for tableName: String) -> SQLite3Database.ExecuteResult {
        let result = database.create(tableName: tableName, type: WebImageInformation.self, isOverwrite: false)
        return result
    }
    
    /// 儲存快取圖片 (SQLite / NSCache)
    /// - Parameters:
    ///   - data: Data?
    ///   - filename: String
    /// - Returns: Result<Bool, Error>
    func storeImageData(_ data: Data?, filename: String) -> Result<Bool, Error> {
        
        switch Constant.cacheType {
        case .sqlite(_, _, _): return storeImageDataWithDatabase(data, filename: filename)
        case .cache: return storeImageDataWithCache(data, filename: filename)
        }
    }
    
    /// 刪除快取圖片
    /// - Parameters:
    ///   - filename: String
    /// - Returns: Result<Bool, Error>
    func removeImage(filename: String) -> Result<Bool, Error> {
        
        guard let imageFolderUrl = Constant.cacheImageFolder,
              let url = Optional.some(imageFolderUrl.appendingPathComponent(filename, isDirectory: false))
        else {
            return .failure(Constant.MyError.notOpenURL)
        }
        
        return FileManager.default._removeFile(at: url)
    }
    
    /// 讀取存在手機的快取圖示檔路徑
    /// - Parameter urlString: String?
    /// - Returns: String?
    func cacheImageURL(with urlString: String) -> URL? {
        
        guard let imageFolderUrl = Constant.cacheImageFolder else { return nil }
        
        let filename = urlString._sha1()
        let url = imageFolderUrl.appendingPathComponent(filename, isDirectory: false)
        
        return url
    }
    
    /// 下載網路圖片 => 利用Notification多個同時下載
    func downloadWebImageWithNotification() {
        
        NotificationCenter.default._register(name: .downloadWebImage) { [weak self] _ in
            
            guard let this = self,
                  !this.isDownloading,
                  let urlStrings = Optional.some(this.imageSetUrls._popFirst(count: Constant.maxnumDownloadCount)),
                  !urlStrings.isEmpty
            else {
                return
            }
            
            this.isDownloading = true
            
            switch Constant.cacheType {
            case .cache: this.downloadWebImageWithCache(urlStrings: urlStrings)
            case .sqlite(_, _, _): Task { await this.downloadWebImageWithDatabase(urlStrings: urlStrings) }
            }
        }
    }
}

// MARK: - WWNetworking (小工具)
private extension WWWebImage {
    
    /// [取得有關圖片的Header快取資訊 => 最後更新時間 / Etag / 檔案大小](https://zh.wikipedia.org/zh-tw/HTTP头字段)
    /// - Parameters:
    ///   - urlString: 圖片網址
    ///   - result: Result<CacheHeaderFields, Error>
    func imageUrlCacheHeader(urlString: String?, result: @escaping ((Result<Constant.CacheHeaderFields, Error>) -> Void)) {
        
        guard let urlString = urlString?._removeWhiteSpacesAndNewlines() else { return result(.failure(Constant.MyError.notOpenURL)) }
        
        WWNetworking.shared.header(urlString: urlString) { headerResult in
            
            let _result = self.parseHeaderResult(headerResult)
            
            switch _result {
            case .failure(let error): result(.failure(error))
            case .success(let fields): result(.success(fields))
            }
        }
    }
    
    /// 解析HTTP-Header (Last-Modified / eTag / Content-Length)
    /// - Parameters:
    ///   - headerResult: Result<WWNetworking.ResponseInformation, Error>
    /// - Returns: Result<Constant.CacheHeaderFields, Error>
    func parseHeaderResult(_ headerResult: Result<WWNetworking.ResponseInformation, Error>) -> Result<Constant.CacheHeaderFields, Error> {
        
        switch headerResult {
            
        case .failure(let error): return .failure(error)
        case .success(let info):
            
            guard let allHeaderFields = info.response?._allHeaderFields() else { return .failure(Constant.MyError.isEmpty) }
            
            let lastModified = allHeaderFields["last-modified"] as? String
            let eTag = allHeaderFields["etag"] as? String
            let contentLength = allHeaderFields["content-length"] as? String
            
            var fields: Constant.CacheHeaderFields = (url: info.response?.url, lastModified: lastModified, eTag: eTag, contentLength: 0)
            if let contentLength = contentLength { fields.contentLength = Int(contentLength) }
            
            return .success(fields)
        }
    }
    
    /// [要不要更新下載圖片的規則](https://juejin.cn/post/6844904037821743112)
    /// => 有沒有下載圖片 (快取) / ETag是否一樣 / 最後更新日期是否有更新 / 檔案大小有變動
    /// - Parameters:
    ///   - fields: CacheHeaderFields
    /// - Returns: Bool
    func updateImageRule(fields: Constant.CacheHeaderFields) -> Bool {
        
        guard let urlString = fields.url?.absoluteString,
              let info = API.shared.searchCacheImageInformation(urlString, for: Constant.tableName).first,
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
    
    /// 儲存快取圖片 (SQLite)
    /// - Parameters:
    ///   - data: Data?
    ///   - filename: String
    /// - Returns: Result<Bool, Error>
    func storeImageDataWithDatabase(_ data: Data?, filename: String) -> Result<Bool, Error> {
        
        guard let data = data else { return .failure(Constant.MyError.isEmpty) }
        guard let imageFolderUrl = Constant.cacheImageFolder else { return .failure(Constant.MyError.notOpenURL) }
        
        let url = imageFolderUrl.appendingPathComponent(filename, isDirectory: false)
        return FileManager.default._writeData(to: url, data: data)
    }
    
    /// 儲存快取圖片 (NSCache)
    /// - Parameters:
    ///   - data: Data?
    ///   - filename: String
    /// - Returns: Result<Bool, Error>
    func storeImageDataWithCache(_ data: Data?, filename: String) -> Result<Bool, Error> {
        
        guard let data = data as? NSData else { return .failure(Constant.MyError.isEmpty) }
        
        cacheManager.setValue(data, forKey: filename as! NSString, cost: 0)
        return .success(true)
    }
    
    /// 讀取存在手機的快取圖示檔Data (SQLite)
    /// - Parameter urlString: String
    /// - Returns: Data?
    func cacheImageDataWithDatabase(urlString: String) -> Data? {
        
        guard let url = cacheImageURL(with: urlString) else { errorBlock?(Constant.MyError.isEmpty); return nil }
        
        let result = FileManager.default._readData(from: url)
        
        switch result {
        case .success(let data): return data
        case .failure(let error): errorBlock?(error); return nil
        }
    }
    
    /// 讀取存在手機的快取圖示檔Data (NSCache)
    /// - Parameter urlString: String
    /// - Returns: Data?
    func cacheImageDataWithCache(urlString: String) -> Data? {
        let filename = urlString._sha1()
        return cacheManager.value(forKey: filename as! NSString) as? Data
    }
    
    /// 下載網路圖片 (SQLite)
    /// - Parameter urlStrings: [String]
    func downloadWebImageWithDatabase(urlStrings: [String]) async {
        
        let types = requestInformationTypesMaker(with: urlStrings)
        let results = await WWNetworking.shared.multipleRequest(types: types)
        
        var updateUrls: [URL] = []
        
        results.forEach { _result in
            
            let result = parseHeaderResult(_result)
                                
            switch result {
            case .failure(let error): errorBlock?(error)
            case .success(let fields): if let neededUpdateUrl = updateUrlActionURL(with: fields) { updateUrls.append(neededUpdateUrl) }
            }
        }
        
        downloadImagesAction(with: updateUrls)
        isDownloading = false
        
        NotificationCenter.default._post(name: .downloadWebImage)
    }
    
    /// 下載網路圖片 (NSCache)
    /// - Parameter urlStrings: [String]
    func downloadWebImageWithCache(urlStrings: [String]) {
        
        var updateUrls: [URL] = []

        for urlString in urlStrings {
            
            if let data = cacheManager.value(forKey: urlString._sha1() as! NSString) { break }
            
            guard let url = URL(string: urlString) else { continue }
            updateUrls.append(url)
        }
        
        downloadImagesAction(with: updateUrls)
        isDownloading = false
        
        NotificationCenter.default._post(name: .downloadWebImage)
    }
    
    /// 產生[WWNetworking.RequestInformationType]
    /// - Parameter urlStrings: [String]
    /// - Returns: [WWNetworking.RequestInformationType]
    func requestInformationTypesMaker(with urlStrings: [String]) -> [WWNetworking.RequestInformationType] {
        
        let types = urlStrings.map { urlString in
            
            let _ = API.shared.insertCacheImageUrl(urlString, for: Constant.tableName)
            let type: WWNetworking.RequestInformationType = (httpMethod: .HEAD, urlString: urlString, contentType: .json, paramaters: nil, headers: nil, httpBodyType: nil)
            
            return type
        }

        return types
    }
    
    /// 處理要需要更新的URL + 相關動作
    /// - Parameter fields: Constant.CacheHeaderFields
    /// - Returns: URL?
    func updateUrlActionURL(with fields: Constant.CacheHeaderFields) -> URL? {
        
        guard let url = fields.url,
              let imageInfo = API.shared.searchCacheImageInformation(url.absoluteString, for: Constant.tableName).first?._jsonClass(for: WebImageInformation.self)
        else {
            return nil
        }
        
        let isNeededUpdate = updateImageRule(fields: fields)
        var updateUrl: URL?

        if (isNeededUpdate) {
            updateUrl = url
        } else {
            _ = API.shared.updateCacheImageUpdateTime(id: imageInfo.id, for: Constant.tableName)
        }
        
        _ = API.shared.updateCacheImageInformation(id: imageInfo.id, fields: fields, for: Constant.tableName)
        
        return updateUrl
    }
    
    /// 下載圖片 (多個同時下載)
    /// - Parameter urls: [URL]
    func downloadImagesAction(with urls: [URL]) {
        
        let updateUrlStrings = urls.map { $0.absoluteString }
        
        WWNetworking.shared.multipleDownload(urlStrings: updateUrlStrings, delegateQueue: .current) { progress in
            
            WWWebImage.shared.downloadProgressBlock?(progress)
            
        } completion: { result in
            
            switch result {
            case .failure(let error): self.errorBlock?(error)
            case .success(let info):
                
                let result = self.storeImageData(info.data, filename: info.urlString._sha1())
                
                switch result {
                case .failure(let error):
                    API.shared.deleteCacheImageInformation(urlString: info.urlString, for: Constant.tableName)
                    self.errorBlock?(error)
                case .success(_):
                    NotificationCenter.default._post(name: .refreahImageView, object: info.urlString)
                }
            }
        }
    }
}
