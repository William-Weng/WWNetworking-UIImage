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
    
    private let gifImageViewTag = 3939889
    
    private var imageView: T
    private var urlString: String?
    private var pixelSize: Int?
    
    private var gifImageView: UIImageView?
    private var gifImageInformation: Constant.GIFImageInformation?
    private var gifImageAnimationBlock: ((Data) -> Void)?

    public init(_ imageView: T) {
        self.imageView = imageView
        self.refreahImageView()
    }
    
    deinit {
        clearGifSetting()
        NotificationCenter.default._remove(observer: self, name: .refreahImageView)
    }
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
        
        clearGifSetting()
                
        guard let urlString = urlString,
              let cacheImageData = WWWebImage.shared.cacheImageData(with: urlString),
              let imageType = cacheImageData._imageDataFormat()
        else {
            imageView.image = parseCacheImage(with: WWWebImage.shared.defaultImage, pixelSize: pixelSize); return
        }
        
        switch imageType {
        case .gif: cacheGifImageDataSetting(cacheImageData, frame: imageView.frame)
        default: imageView.image = parseCacheImage(with: UIImage(data: cacheImageData), pixelSize: pixelSize)
        }
    }
    
    /// 處理Gif圖片的相關處理 (加上一個ImageView單獨處理)
    /// - Parameters:
    ///   - cacheImageData: Data
    ///   - frame: CGRect
    func cacheGifImageDataSetting(_ cacheImageData: Data, frame: CGRect) {
        
        gifImageView = UIImageView(frame: frame)
        gifImageView?.contentMode = .scaleAspectFit
        gifImageView?.tag = gifImageViewTag
        
        gifImageAnimationBlock = { [weak self] data in
            
            _ = self?.gifImageView?._GIF(data: data) { result in
                
                switch result {
                case .failure(let error): print(error)
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
    func refreahImageView() {
        
        NotificationCenter.default._remove(observer: self, name: .refreahImageView)
        
        NotificationCenter.default._register(name: .refreahImageView) { notification in
            
            let urlString = self.urlString
            
            NotificationCenter.default._post(name: .downloadWebImage, object: urlString)
            DispatchQueue.main.safeAsync { self.cacheImageSetting(urlString: urlString) }
        }
    }
    
    /// 解析快取圖片 (要不要縮圖)
    /// - Parameters:
    ///   - image: UIImage?
    ///   - pixelSize: Int?
    /// - Returns: UIImage?
    func parseCacheImage(with image: UIImage?, pixelSize: Int?) -> UIImage? {
        
        if let pixelSize = self.pixelSize { return image?._thumbnail(max: pixelSize) }
        return image
    }
    
    /// 清除GIF的相關設定
    func clearGifSetting() {
        
        if let _gifView = imageView.viewWithTag(gifImageViewTag) { _gifView.removeFromSuperview() }
        
        gifImageInformation?.pointer.pointee = true
        gifImageAnimationBlock = nil
        gifImageView?.removeFromSuperview()
        gifImageView = nil
    }
}
