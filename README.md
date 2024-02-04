# WWNetworking-UIImage

[![Swift-5.6](https://img.shields.io/badge/Swift-5.6-orange.svg?style=flat)](https://developer.apple.com/swift/) [![iOS-14.0](https://img.shields.io/badge/iOS-14.0-pink.svg?style=flat)](https://developer.apple.com/swift/) ![](https://img.shields.io/github/v/tag/William-Weng/WWNetworking-UIImage) [![Swift Package Manager-SUCCESS](https://img.shields.io/badge/Swift_Package_Manager-SUCCESS-blue.svg?style=flat)](https://developer.apple.com/swift/) [![LICENSE](https://img.shields.io/badge/LICENSE-MIT-yellow.svg?style=flat)](https://developer.apple.com/swift/)

This is a simple web image downloader, similar to a simple version of SDWebImage or Kingfisher.

這是一個簡單的網路圖片下載工具，類似SDWebImage或Kingfisher的簡單版本。

使用[WWNetworking](https://github.com/William-Weng/WWNetworking) + [WWSQLite3Manager](https://github.com/William-Weng/WWSQLite3Manager)套件來延伸製作，且利用網路圖片的Header-Tag，[Last-Modified](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Last-Modified) / [ETag](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/ETag)，來實現快取功能…

![WWNetworking-UIImage](./Example.gif)

### [Installation with Swift Package Manager](https://medium.com/彼得潘的-swift-ios-app-開發問題解答集/使用-spm-安裝第三方套件-xcode-11-新功能-2c4ffcf85b4b)
```bash
dependencies: [
    .package(url: "https://github.com/William-Weng/WWNetworking-UIImage.git", .upToNextMajor(from: "1.0.0"))
]
```

### Example
```swift
import UIKit
import WWNetworking_UIImage

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        _ = WWWebImage.initDatabase(for: .caches, expiredDays: 90)
        return true
    }
}
```
```swift
import UIKit
import WWNetworking_UIImage

final class TableViewContrller: UIViewController {

    @IBOutlet weak var myTableView: UITableView!
    
    private let imageUrls = [
        "https://i.pinimg.com/originals/bd/bd/4f/bdbd4f6d85fdaf6c8eea6ffc99aeaa1a.jpg",
        "https://www.niusnews.com/upload/imgs/default/2020Apr_CHOU/0428Sumikko/A1.jpg",
        "https://cc.tvbs.com.tw/img/upload/2020/05/19/20200519191617-75e42ad2.jpg",
        "https://s.yimg.com/ny/api/res/1.2/MubECS_oug7X7MVtm9v9bg--/YXBwaWQ9aGlnaGxhbmRlcjt3PTY0MA--/https://media.zenfs.com/en/dailyview.tw/26023bd61a23e81bf2c4005d03c881a4",
        "https://www.colorsexplained.com/wp-content/uploads/2021/05/shades-of-green-color-infographic.jpg.webp",
        "https://cf.shopee.tw/file/22b1fc845e5ce92481d08c79ffa29296",
        "https://i2.momoshop.com.tw/1658857094/goodsimg/0009/593/640/9593640_O_m.webp",
        "https://hk.rcmart.com/image/catalog/blog_images/sumiko_gurashi_rcmart_charator2.jpg",
        "https://i3.momoshop.com.tw/1672305576/goodsimg/0008/998/717/8998717_O_m.webp",
        "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRmRiFJ6JP4P1rqOcKoIpW9p7UvK8oWmfRcew&usqp=CAU",
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        myTableView.delegate = self
        myTableView.dataSource = self
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension TableViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return imageUrls.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TableViewCell", for: indexPath) as? TableViewCell else { fatalError() }
        
        let defaultImage = UIImage(named: "no-pictures")
        
        cell.myLabel?.text = "\(indexPath.row)"
        cell.myImageView.WW.downloadImage(with: imageUrls[indexPath.row], defaultImage: defaultImage)
        
        return cell
    }
}
```
```swift
import UIKit

final class TableViewCell: UITableViewCell {

    @IBOutlet weak var myImageView: UIImageView!
    @IBOutlet weak var myLabel: UILabel!
}
```


