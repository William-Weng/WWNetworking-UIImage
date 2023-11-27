//
//  WWWebImageWrapper.swift
//  Example
//
//  Created by iOS on 2023/4/12.
//

import UIKit
import WWPrint

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
    private var defaultImage: UIImage?

    public init(_ imageView: T) {
        self.imageView = imageView
        self.refreahImageView()
    }
    
    /// 下載網路圖片
    /// - Parameters:
    ///   - urlString: 下載的圖片路徑
    ///   - defaultImage: 本機預設圖片
    public func downloadImage(with urlString: String?, defaultImage: UIImage? = nil) {
                
        guard let urlString = urlString else { return }
        
        self.urlString = urlString
        self.defaultImage = defaultImage
        
        WWWebImage.shared.imageSetUrls.insert(urlString)
        cacheImageSetting(urlString: urlString)
        
        NotificationCenter.default._post(name: .downloadWebImage, object: urlString)
    }
    
    /// 設定快取圖片
    /// - Parameter urlString: String
    func cacheImageSetting(urlString: String) {
        
        let cacheImage = WWWebImage.shared.cacheImage(with: urlString)
                
        self.imageView.image = cacheImage ?? self.defaultImage
        self.imageView.setNeedsDisplay()
    }
    
    /// 更新圖片畫面 => NotificationCenter
    func refreahImageView() {
        
        NotificationCenter.default._remove(observer: self, name: .refreahImageView)
        NotificationCenter.default._register(name: .refreahImageView) { [weak self] notification in
            
            guard let this = self else { return }
            
            DispatchQueue.main.async { if let urlString = this.urlString { this.cacheImageSetting(urlString: urlString) }}
            NotificationCenter.default._post(name: .downloadWebImage, object: this.urlString)
        }
    }
    
    deinit {
        NotificationCenter.default._remove(observer: self, name: .refreahImageView)
        wwPrint("deinit => \(Self.self)")
    }
}
