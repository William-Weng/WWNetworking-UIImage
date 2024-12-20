//
//  Extension.swift
//  WWNetworking-UIImage
//
//  Created by William.Weng on 2022/12/15.
//

import UIKit
import CommonCrypto

// MARK: - Collection (override function)
extension Collection {

    /// [為Array加上安全取值特性 => nil](https://stackoverflow.com/questions/25329186/safe-bounds-checked-array-lookup-in-swift-through-optional-bindings)
    subscript(safe index: Index) -> Element? { return indices.contains(index) ? self[index] : nil }
}

// MARK: - Set (function)
extension Set {
 
    /// 彈出開頭第一個
    /// - Returns: Element?
    mutating func _popFirst() -> Element? {
        return popFirst()
    }
    
    /// 彈出開頭的某幾個
    /// - Parameter count: UInt
    /// - Returns: [Element]
    mutating func _popFirst(count: UInt) -> [Element] {
        let elements = (0..<count).compactMap { _ in return _popFirst() }
        return elements
    }
}

// MARK: - DispatchQueue (function)
extension DispatchQueue {
    
    /// 安全非同步執行緒
    /// - Parameter block: () -> ()
    func safeAsync(_ block: @escaping () -> ()) {
        if self === DispatchQueue.main && Thread.isMainThread { block(); return }
        async { block() }
    }
}

// MARK: - Notification (static function)
extension Notification {
    
    /// String => Notification.Name
    /// - Parameter name: key的名字
    /// - Returns: Notification.Name
    static func _name(_ name: String) -> Notification.Name { return Notification.Name(rawValue: name) }
    
    /// NotificationName => Notification.Name
    /// - Parameter name: key的名字 (enum)
    /// - Returns: Notification.Name
    static func _name(_ name: Constant.NotificationName) -> Notification.Name { return name.value }
}

// MARK: - NotificationCenter (function)
extension NotificationCenter {
    
    /// 註冊通知
    /// - Parameters:
    ///   - name: 要註冊的Notification名稱
    ///   - queue: 執行的序列
    ///   - object: 接收的資料
    ///   - handler: 監聽到後要執行的動作
    func _register(name: Notification.Name, queue: OperationQueue = .main, object: Any? = nil, handler: @escaping ((Notification) -> Void)) {
        self.addObserver(forName: name, object: object, queue: queue) { (notification) in handler(notification) }
    }
    
    /// 註冊通知
    /// - Parameters:
    ///   - name: 要註冊的Notification名稱
    ///   - queue: 執行的序列
    ///   - object: 接收的資料
    ///   - handler: 監聽到後要執行的動作
    func _register(name: Constant.NotificationName, queue: OperationQueue = .main, object: Any? = nil, handler: @escaping ((Notification) -> Void)) {
        self._register(name: name.value, handler: handler)
    }
    
    /// 發出通知
    /// - Parameters:
    ///   - name: 要發出的Notification名稱
    ///   - object: 要傳送的資料
    func _post(name: Notification.Name, object: Any? = nil) { self.post(name: name, object: object) }

    /// 發射通知
    /// - Parameters:
    ///   - name: 要發射的Notification名稱
    ///   - object: 要傳送的資料
    func _post(name: Constant.NotificationName, object: Any? = nil) { self._post(name: name.value, object: object) }
    
    /// 移除通知
    /// - Parameters:
    ///   - observer: 要移除的位置
    ///   - name: 要移除的Notification名稱
    ///   - object: 接收的資料
    func _remove(observer: Any, name: Notification.Name, object: Any? = nil) { self.removeObserver(observer, name: name, object: object) }
    
    /// 移除通知
    /// - Parameters:
    ///   - observer: 要移除的位置
    ///   - name: 要移除的Notification名稱
    ///   - object: 接收的資料
    func _remove(observer: Any, name: Constant.NotificationName, object: Any? = nil) { self._remove(observer: observer, name: name.value) }
}

// MARK: - JSONSerialization (static function)
extension JSONSerialization {
    
    /// [JSONObject => JSON Data](https://medium.com/彼得潘的-swift-ios-app-開發問題解答集/利用-jsonserialization-印出美美縮排的-json-308c93b51643)
    /// - ["name":"William"] => {"name":"William"} => 7b226e616d65223a2257696c6c69616d227d
    /// - Parameters:
    ///   - object: Any
    ///   - options: JSONSerialization.WritingOptions
    /// - Returns: Data?
    static func _data(with object: Any, options: JSONSerialization.WritingOptions = JSONSerialization.WritingOptions()) -> Data? {
        
        guard JSONSerialization.isValidJSONObject(object),
              let data = try? JSONSerialization.data(withJSONObject: object, options: options)
        else {
            return nil
        }
        
        return data
    }
}

// MARK: - Encodable (function)
extension Encodable {
    
    /// Class => JSON Data
    /// - Returns: Data?
    func _jsonData() -> Data? {
        guard let jsonData = try? JSONEncoder().encode(self) else { return nil }
        return jsonData
    }
    
    /// Class => JSON String
    func _jsonString() -> String? {
        guard let jsonData = self._jsonData() else { return nil }
        return jsonData._string()
    }
    
    /// Class => JSON Object
    /// - Returns: Any?
    func _jsonObject() -> Any? {
        guard let jsonData = self._jsonData() else { return nil }
        return jsonData._jsonObject()
    }
}

// MARK: - Data (function)
extension Data {
    
    /// Data => 字串
    /// - Parameter encoding: 字元編碼
    /// - Returns: String?
    func _string(using encoding: String.Encoding = .utf8) -> String? {
        return String(bytes: self, encoding: encoding)
    }
    
    /// Data => JSON
    /// - 7b2268747470223a2022626f6479227d => {"http": "body"}
    /// - Returns: Any?
    func _jsonObject(options: JSONSerialization.ReadingOptions = .allowFragments) -> Any? {
        let json = try? JSONSerialization.jsonObject(with: self, options: options)
        return json
    }
    
    /// Data => Class
    /// - Parameter type: 要轉型的Type => 符合Decodable
    /// - Returns: T => 泛型
    func _class<T: Decodable>(type: T.Type) -> T? {
        
        let decoder = JSONDecoder()
        let formatter = DateFormatter()
        
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "UTC")
        
        decoder.dateDecodingStrategy = .formatted(formatter)
        
        return try? decoder.decode(type.self, from: self)
    }
    
    /// 根據ImageHeader找出相對應的圖片Type (jpeg / png / gif) => 一個一個試，找到就結束 => 二進位型圖片
    /// - Parameter data: 圖片資料
    /// - Returns: Constant.ImageFormat?
    func _imageDataFormat() -> Constant.ImageFormat? {
        
        let imageDataArray = lazy.map({$0})
        let allCases = Constant.ImageFormat.allCases
        
        var imageType: Constant.ImageFormat? = nil
        
        allCases.forEach { (type) in
            
            let imageHeader = type.header
            
            if (imageDataArray.count < imageHeader.count) { imageType = nil; return }
            if (imageType != nil) { return }
            
            for index in 0..<imageHeader.count {
                
                let headerHexNumber = imageHeader[index]
                
                if (headerHexNumber == 0x00) { continue }
                if (imageDataArray[index] != headerHexNumber) { imageType = nil; return }
                imageType = type
            }
        }
        
        if (imageType != .png) { return imageType }
        return _isAPNG() ? .apng : .png
    }
}

// MARK: - Data (SHA值)
private extension Data {
    
    /// [計算SHA家族的雜湊值](https://zh.wikipedia.org/zh-tw/SHA家族)
    /// - Parameters:
    ///   - digestLength: [雜湊值長度](https://ithelp.ithome.com.tw/articles/10241695)
    ///   - encode: [雜湊函式](https://ithelp.ithome.com.tw/articles/10208884)
    /// - Returns: [String](https://emn178.github.io/online-tools/)
    func _secureHashAlgorithm(digestLength: Int32, encode: (_ data: UnsafeRawPointer?, _ len: CC_LONG, _ md: UnsafeMutablePointer<UInt8>?) -> UnsafeMutablePointer<UInt8>?) -> String {
        
        var hash = [UInt8](repeating: 0, count: Int(digestLength))
        self.withUnsafeBytes { _ = encode($0.baseAddress, CC_LONG(self.count), &hash) }
        
        let hexBytes = hash.map { String(format: "%02hhx", $0) }
        return hexBytes.joined()
    }
    
    /// [測試是不是apng？ => 搜尋acTL區塊](https://www.silencetime.com/index.php/archives/74/)
    /// - Returns: Bool
    func _isAPNG() -> Bool {

        let acTLBytes = Constant.ImageFormat.apng.header
        let acTLBytesSize = acTLBytes.count
        let bytes = lazy.map({$0})
        
        if (bytes.count < acTLBytesSize) { return false }
        
        for index in 0..<(bytes.count - acTLBytesSize) {
            
            if let acTLByte0 = acTLBytes[safe: 0], let byte0 = bytes[safe: index + 0] { if (acTLByte0 != byte0) { continue }}
            if let acTLByte1 = acTLBytes[safe: 1], let byte1 = bytes[safe: index + 1] { if (acTLByte1 != byte1) { continue }}
            if let acTLByte2 = acTLBytes[safe: 2], let byte2 = bytes[safe: index + 2] { if (acTLByte2 != byte2) { continue }}
            if let acTLByte3 = acTLBytes[safe: 3], let byte3 = bytes[safe: index + 3] { if (acTLByte3 != byte3) { continue }}
            
            return true
        }

        return false
    }
}

// MARK: - Date (function)
extension Date {
    
    /// 將UTC時間 => 該時區的時間
    /// - 2020-07-07 16:08:50 +0800
    /// - Parameters:
    ///   - dateFormat: 時間格式
    ///   - timeZone: 時區辨識
    /// - Returns: String?
    func _localTime(dateFormat: String = "yyyy-MM-dd HH:mm:ss", timeZone: TimeZone? = TimeZone(identifier: "UTC")) -> String {
        
        let dateFormatter = DateFormatter()
        
        dateFormatter.dateFormat = "\(dateFormat)"
        dateFormatter.timeZone = timeZone
        
        return dateFormatter.string(from: self)
    }
}

// MARK: - Dictionary (function)
extension Dictionary {
    
    /// Dictionary => JSON Data
    /// - ["name":"William"] => {"name":"William"} => 7b226e616d65223a2257696c6c69616d227d
    /// - Returns: Data?
    func _jsonData(options: JSONSerialization.WritingOptions = JSONSerialization.WritingOptions()) -> Data? {
        return JSONSerialization._data(with: self, options: options)
    }
    
    /// Dictionary => JSON Data => T
    /// - Parameter type: 要轉換成的Dictionary類型
    /// - Returns: T?
    func _jsonClass<T: Decodable>(for type: T.Type) -> T? {
        let dictionary = self._jsonData()?._class(type: type.self)
        return dictionary
    }
}

// MARK: - String (function)
extension String {
    
    /// [文字 => SHA1](https://stackoverflow.com/questions/25761344/how-to-hash-nsstring-with-sha1-in-swift)
    /// - Returns: [String](https://emn178.github.io/online-tools/sha1.html)
    func _sha1() -> Self { return self._secureHashAlgorithm(digestLength: CC_SHA1_DIGEST_LENGTH, encode: CC_SHA1) }
    
    /// URL編碼 (百分比)
    /// - 是在哈囉 => %E6%98%AF%E5%9C%A8%E5%93%88%E5%9B%89
    /// - Parameter characterSet: 字元的判斷方式
    /// - Returns: String?
    func _encodingURL(characterSet: CharacterSet = .urlQueryAllowed) -> Self? { return addingPercentEncoding(withAllowedCharacters: characterSet) }
    
    /// 去除空白及換行字元
    /// - Returns: Self
    func _removeWhiteSpacesAndNewlines() -> Self { return trimmingCharacters(in: .whitespacesAndNewlines) }
    
    /// 將"2020-07-08 16:36:31 +0800" => Date()
    /// - Parameter dateFormat: 時間格式
    /// - Returns: Date?
    func _date(dateFormat: Constant.DateFormat = .web) -> Date? {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "\(dateFormat)"
        
        switch dateFormat {
        case .meridiem(formatLocale: let locale): dateFormatter.locale = locale
        default: break
        }
        
        return dateFormatter.date(from: self)
    }
}

// MARK: - String (private function)
private extension String {
    
    /// [計算SHA家族的雜湊值](https://zh.wikipedia.org/zh-tw/SHA家族)
    /// - Parameters:
    ///   - digestLength: [雜湊值長度](https://ithelp.ithome.com.tw/articles/10241695)
    ///   - encode: [雜湊函式](https://ithelp.ithome.com.tw/articles/10208884)
    /// - Returns: [String](https://emn178.github.io/online-tools/)
    func _secureHashAlgorithm(digestLength: Int32, encode: (_ data: UnsafeRawPointer?, _ len: CC_LONG, _ md: UnsafeMutablePointer<UInt8>?) -> UnsafeMutablePointer<UInt8>?) -> String {
        
        let data = Data(self.utf8)
        var hash = [UInt8](repeating: 0, count: Int(digestLength))
        
        data.withUnsafeBytes { _ = encode($0.baseAddress, CC_LONG(data.count), &hash) }
        
        let hexBytes = hash.map { String(format: "%02hhx", $0) }
        return hexBytes.joined()
    }
}

// MARK: - FileManager (function)
extension FileManager {
    
    /// [取得User的資料夾](https://cdfq152313.github.io/post/2016-10-11/)
    /// - UIFileSharingEnabled = YES => iOS設置iTunes文件共享
    /// - Parameter directory: User的資料夾名稱
    /// - Returns: [URL]
    func _userDirectory(for directory: FileManager.SearchPathDirectory) -> [URL] { return Self.default.urls(for: directory, in: .userDomainMask) }
    
    /// User的「暫存」資料夾
    /// - => ~/tmp/
    /// - Returns: URL
    func _temporaryDirectory() -> URL { return self.temporaryDirectory }
    
    /// 讀取檔案
    /// - Parameter url: 要讀取的檔案位置
    /// - Returns: Data?
    func _readData(from url: URL?) -> Result<Data?, Error> {
        
        guard let url = url else { return .success(nil) }
        
        do {
            let data = try Data(contentsOf: url)
            return .success(data)
        } catch {
            return .failure(error)
        }
    }
    
    /// 寫入Data - 二進制資料
    /// - Parameters:
    ///   - url: 寫入Data的文件URL
    ///   - data: 要寫入的資料
    /// - Returns: Result<Bool, Error>
    func _writeData(to url: URL?, data: Data?) -> Result<Bool, Error> {
        
        guard let url = url,
              let data = data
        else {
            return .success(false)
        }
        
        do {
            try data.write(to: url)
            return .success(true)
        } catch {
            return .failure(error)
        }
    }
    
    /// 測試該檔案是否存在 / 是否為資料夾
    /// - Parameter url: 檔案的URL路徑
    /// - Returns: Constant.FileInfomation
    func _fileExists(with url: URL?) -> Constant.FileInfomation {

        guard let url = url else { return (false, false) }
        
        var isDirectory: ObjCBool = false
        let isExist = fileExists(atPath: url.path, isDirectory: &isDirectory)
        
        return (isExist, isDirectory.boolValue)
    }
    
    /// 移除檔案
    /// - Parameter atURL: URL
    /// - Returns: Result<Bool, Error>
    func _removeFile(at atURL: URL?) -> Result<Bool, Error> {
        
        guard let atURL = atURL else { return .success(false) }
        
        do {
            try removeItem(at: atURL)
            return .success(true)
        } catch  {
            return .failure(error)
        }
    }
}

// MARK: - Date (function)
extension Date {
    
    /// [增加日期 => 年 / 月 / 日](https://areckkimo.medium.com/用uipageviewcontroller實作萬年曆-76edaac841e1)
    /// - Parameters:
    ///   - component:
    ///   - value: 年(.year) / 月(.month) / 日(.day)
    ///   - calendar: 當地的日曆基準
    /// - Returns: Date?
    func _adding(component: Calendar.Component = .day, value: Int, for calendar: Calendar = .current) -> Date? {
        return calendar.date(byAdding: component, value: value, to: self)
    }
}

// MARK: - HTTPURLResponse (function)
extension HTTPURLResponse {
        
    /// [取得header的欄位數值 (轉全大寫或小寫) => HTML Tag 沒分大小寫](https://zh.wikipedia.org/zh-tw/HTTP头字段)
    /// - Parameter isLowercased: 轉成小寫？
    /// - Returns: [AnyHashable : Any]
    func _allHeaderFields(isLowercased: Bool = true) -> [AnyHashable : Any] {
        
        var headerFields: [AnyHashable : Any]  = [:]
        
        allHeaderFields.forEach() { key, value in
            
            var field = key
            
            if let key = key as? String {
                field = (!isLowercased) ? key.uppercased() : key.lowercased()
            }
            
            headerFields[field] = value
        }
        
        return headerFields
    }
}

// MARK: - UIImage (function)
extension UIImage {
    
    /// [建立縮圖](https://stackoverflow.com/questions/40675640/creating-a-thumbnail-from-uiimage-using-cgimagesourcecreatethumbnailatindex)
    /// - Parameter pixelSize: 最大的像素大小 => 解析度
    /// - Returns: UIImage?
    func _thumbnail(max pixelSize: Int = 300) -> UIImage? {

        guard let imageData = self.pngData() else { return nil }
        
        let options: [CFString : Any] = [
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: pixelSize
        ]
        
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil) else { return nil }
        guard let imageReference = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
        
        return UIImage(cgImage: imageReference)
    }
}

// MARK: - UIImageView (function)
extension UIImageView {
    
    /// [播放GIF圖片](https://augmentedcode.io/2019/09/01/animating-gifs-and-apngs-with-cganimateimageaturlwithblock-in-swift/)
    /// - Parameters:
    ///   - data: [Data](https://developer.apple.com/documentation/imageio/3333272-cganimateimagedatawithblock)
    ///   - options: CFDictionary?
    ///   - result: Result<Bool, Error>
    /// - Returns: [OSStatus?](https://www.osstatus.com/)
    func _GIF(data: Data, options: CFDictionary? = nil, result: @escaping ((Result<Constant.GIFImageInformation, Error>) -> Void)) -> OSStatus {
        
        let cfData = data as CFData
        
        let status = CGAnimateImageDataWithBlock(cfData, options) { (index, cgImage, pointer) in
            self.image = UIImage(cgImage: cgImage)
            result(.success((index, cgImage, pointer)))
        }
        
        return status
    }
}
