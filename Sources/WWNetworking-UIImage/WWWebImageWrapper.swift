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
    
    private var gifImageView: WWWebImage.GIFImageView?
    private var gifImageInformation: Constant.GIFImageInformation?
    private var gifImageAnimationBlock: ((Data) -> Void)?

    public init(_ imageView: T) {
        self.imageView = imageView
        self.refreshImageView(pixelSize: pixelSize)
    }
    
    deinit {
        clearGifSetting()
        NotificationCenter.default._remove(observer: self, name: .refreshImageView)
    }
}

// MARK: - 公開函式
public extension WWWebImageWrapper {
    
    /// 下載網路圖片
    /// - Parameters:
    ///   - urlString: 下載的圖片路徑
    ///   - pixelSize: [最大像素](https://zh.wikipedia.org/zh-tw/像素)
    func downloadImage(with urlString: String?, pixelSize: Int? = nil) {
        
        self.pixelSize = pixelSize
        
        defer { cacheImageSetting(urlString: urlString, pixelSize: pixelSize) }
                
        guard let urlString = urlString,
              !WWWebImage.shared.imageOrderedSetUrls.contains(urlString)
        else {
            return
        }
        
        self.urlString = urlString
        
        WWWebImage.shared.imageOrderedSetUrls.add(urlString)
        NotificationCenter.default._post(name: .downloadWebImage, object: urlString)
    }
}

// MARK: - 小工具
private extension WWWebImageWrapper {
    
    /// 設定快取圖片 (設定最大解析度)
    /// - Parameter urlString: String
    func cacheImageSetting(urlString: String?, pixelSize: Int?) {
        
        defer { imageView.setNeedsDisplay() }
        
        clearGifSetting()
        
        guard let urlString = urlString,
              let cacheImageData = WWWebImage.shared.cacheImageData(with: urlString),
              let imageType = cacheImageData._imageDataFormat()
        else {
            
            Task { @MainActor in
                let displayImage = WWWebImage.shared.defaultImage
                let processedImage = self.parseCacheImage(with: displayImage, pixelSize: pixelSize)
                imageView.image = processedImage
            }; return
        }
        
        switch imageType {
        case .gif, .apng:
            self.cacheGifImageDataSetting(cacheImageData, frame: imageView.frame)
        default:
            
            Task { @MainActor in
                let displayImage = UIImage(data: cacheImageData) ?? WWWebImage.shared.defaultImage
                let processedImage = self.parseCacheImage(with: displayImage, pixelSize: pixelSize)
                imageView.image = processedImage
            }
        }
    }
    
    /// 處理Gif圖片的相關處理 (加上一個ImageView單獨處理)
    /// - Parameters:
    ///   - cacheImageData: Data
    ///   - frame: CGRect
    func cacheGifImageDataSetting(_ cacheImageData: Data, frame: CGRect) {
        
        gifImageView = WWWebImage.GIFImageView(frame: frame)
        gifImageView?.contentMode = .scaleAspectFit
        
        gifImageAnimationBlock = { [weak self] data in
                        
            _ = self?.gifImageView?._GIF(data: data) { result in
                switch result {
                case .failure(let error): WWWebImage.shared.errorBlock?(error)
                case .success(let info): self?.gifImageInformation = info
                }
            }
        }
        
        if let gifImageView = gifImageView {
            imageView.image = nil
            imageView.addSubview(gifImageView)
            gifImageAnimationBlock?(cacheImageData)
        }
    }
    
    /// 更新圖片畫面 => NotificationCenter
    func refreshImageView(pixelSize: Int?) {
        
        NotificationCenter.default._remove(observer: self, name: .refreshImageView)
        
        NotificationCenter.default._register(name: .refreshImageView) { notification in
            
            let urlString = self.urlString
            
            NotificationCenter.default._post(name: .downloadWebImage, object: urlString)
            DispatchQueue.main.safeAsync { self.cacheImageSetting(urlString: urlString, pixelSize: pixelSize) }
        }
    }
    
    /// 解析快取圖片 (要不要縮圖)
    /// - Parameters:
    ///   - image: UIImage?
    ///   - pixelSize: Int?
    /// - Returns: UIImage?
    func parseCacheImage(with image: UIImage?, pixelSize: Int?) -> UIImage? {
        
        if let pixelSize = pixelSize { return image?._thumbnail(max: pixelSize) }
        return image
    }
    
    /// 清除GIF的相關設定
    func clearGifSetting() {
        
        if let _gifView = imageView.subviews.first { $0 is WWWebImage.GIFImageView } { _gifView.removeFromSuperview() }
                
        gifImageInformation?.pointer.pointee = true
        gifImageAnimationBlock = nil
        gifImageView?.removeFromSuperview()
        gifImageView = nil
    }
}
