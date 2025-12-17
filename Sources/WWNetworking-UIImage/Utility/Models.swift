//
//  Models.swift
//  WWNetworking-UIImage
//
//  Created by William.Weng on 2023/3/14.
//

import UIKit
import WWSQLite3Manager

// MARK: - [資料庫欄位](https://blog.techbridge.cc/2017/06/17/cache-introduction/)
public class WebImageInformation: Codable {
    
    let id: Int                 // 編號
    let url: String             // 圖片URL
    let name: String            // 下載圖片的檔案名稱
    let contentLength: Int?     // 從Header取得的檔案大小
    let lastModified: String?   // 從Header取得的檔案最後更新時間
    let eTag: String?           // [從Header取得的檔案Hash值](https://blog.techbridge.cc/2017/06/17/cache-introduction/)
    let createTime: Date        // 建立時間
    let updateTime: Date        // 更新時間
}

// MARK: - SQLite3SchemeDelegate
extension WebImageInformation: SQLite3SchemeDelegate {
    
    /// SQLite資料結構 for WWSQLite3Manager
    /// - Returns: [(key: String, type: SQLite3Condition.DataType)]
    static public func structure() -> [(key: String, type: SQLite3Condition.DataType)] {
        
        let keyTypes: [(key: String, type: SQLite3Condition.DataType)] = [
            (key: "id", type: .INTEGER()),
            (key: "url", type: .TEXT(attribute: (isNotNull: true, isNoCase: true, isUnique: true), defaultValue: nil)),
            (key: "name", type: .TEXT(attribute: (isNotNull: true, isNoCase: false, isUnique: true), defaultValue: nil)),
            (key: "contentLength", type: .INTEGER(attribute: (isNotNull: false, isNoCase: false, isUnique: true), defaultValue: nil)),
            (key: "lastModified", type: .TEXT(attribute: (isNotNull: false, isNoCase: true, isUnique: false), defaultValue: nil)),
            (key: "eTag", type: .TEXT(attribute: (isNotNull: false, isNoCase: false, isUnique: false), defaultValue: nil)),
            (key: "createTime", type: .TIMESTAMP()),
            (key: "updateTime", type: .TIMESTAMP()),
        ]
        
        return keyTypes
    }
}

// MARK: - Model
public extension WWWebImage {
    
    // MARK: - 自定義的錯誤
    struct RemoveImageError: Error {
        let error: Error
        let info: WebImageInformation
    }
    
    // MARK: - 自定義的UIImageView (放GIF用的)
    class GIFImageView: UIImageView {}
}
