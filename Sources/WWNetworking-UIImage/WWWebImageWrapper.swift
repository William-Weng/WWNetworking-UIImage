//
//  WWWebImageWrapper.swift
//  WWNetworking-UIImage
//
//  Created by William.Weng on 2023/4/12.
//

import UIKit

// MARK: - WWWebImageProtocol
public protocol WWWebImageProtocol: UIImageView {}

// MARK: - WWWebImageProtocol
extension WWWebImageProtocol {
    public var WW: WWWebImageWrapper<Self> { return WWWebImageWrapper(self) }
}

// MARK: - UIImageView + WWWebImageProtocol
extension UIImageView: WWWebImageProtocol {}

// MARK: - WWWebImageWrapper
open class WWWebImageWrapper<T: UIImageView> {
    
    private var imageView: T
    private var urlString: String?
    private var pixelSize: Int?
    
    public init(_ imageView: T) {
        self.imageView = imageView
        self.refreahImageView()
    }
    
    deinit { NotificationCenter.default._remove(observer: self, name: .refreahImageView) }
}

// MARK: - 公開函式
public extension WWWebImageWrapper {
    
    /// 下載網路圖片
    /// - Parameters:
    ///   - urlString: 下載的圖片路徑
    ///   - pixelSize: [最大像素](https://zh.wikipedia.org/zh-tw/像素 )
    func downloadImage(with urlString: String?, pixelSize: Int? = nil) {
        
        self.pixelSize = pixelSize
        
        defer { cacheImageSetting(urlString: urlString) }
        
        guard let urlString = urlString,
              !WWWebImage.shared.imageSetUrls.contains(urlString)
        else {
            return
        }
        
        self.urlString = urlString
        
        WWWebImage.shared.imageSetUrls.insert(urlString)
        NotificationCenter.default._post(name: .downloadWebImage, object: urlString)
    }
}

// MARK: - 小工具
private extension WWWebImageWrapper {
    
    /// 設定快取圖片 (設定最大解析度)
    /// - Parameter urlString: String
    func cacheImageSetting(urlString: String?) {
        
        defer { imageView.setNeedsDisplay() }
        
        guard let urlString = urlString,
              let cacheImage = WWWebImage.shared.cacheImage(with: urlString)
        else {
            if let pixelSize = self.pixelSize { imageView.image = WWWebImage.shared.defaultImage?._thumbnail(max: pixelSize); return }
            imageView.image = WWWebImage.shared.defaultImage; return
        }
        
        if let pixelSize = self.pixelSize { imageView.image = cacheImage._thumbnail(max: pixelSize); return }
        imageView.image = cacheImage
    }
    
    /// 更新圖片畫面 => NotificationCenter
    func refreahImageView() {
        
        NotificationCenter.default._remove(observer: self, name: .refreahImageView)
        
        NotificationCenter.default._register(name: .refreahImageView) { notification in
            
            let urlString = self.urlString
            
            NotificationCenter.default._post(name: .downloadWebImage, object: urlString)
            DispatchQueue.main.safeAsync { self.cacheImageSetting(urlString: urlString) }
        }
    }
}
