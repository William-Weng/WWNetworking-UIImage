//
//  TableViewDemoController.swift
//  Example
//
//  Created by William.Weng on 2022/12/15.
//

import UIKit
import WWPrint
import WWNetworking_UIImage

final class TableViewController: UIViewController {

    @IBOutlet weak var myTableView: UITableView!
    
    private let imageUrls = [
        "https://media.tenor.com/98NGqBWbyrcAAAAj/%E3%81%A1%E3%81%84%E3%81%8B%E3%82%8F-chiikawa.gif",
        "https://www.niusnews.com/upload/imgs/default/2020Apr_CHOU/0428Sumikko/A1.jpg",
        "https://cc.tvbs.com.tw/img/upload/2020/05/19/20200519191617-75e42ad2.jpg",
        "https://s.yimg.com/ny/api/res/1.2/MubECS_oug7X7MVtm9v9bg--/YXBwaWQ9aGlnaGxhbmRlcjt3PTY0MA--/https://media.zenfs.com/en/dailyview.tw/26023bd61a23e81bf2c4005d03c881a4",
        "https://www.colorsexplained.com/wp-content/uploads/2021/05/shades-of-green-color-infographic.jpg.webp",
        "https://cf.shopee.tw/file/22b1fc845e5ce92481d08c79ffa29296",
        "https://i2.momoshop.com.tw/1658857094/goodsimg/0009/593/640/9593640_O_m.webp",
        "https://hk.rcmart.com/image/catalog/blog_images/sumiko_gurashi_rcmart_charator2.jpg",
        "https://i3.momoshop.com.tw/1672305576/goodsimg/0008/998/717/8998717_O_m.webp",
        "https://www.eposcard.co.jp/gecard/chiikawa/img-files/chkw_im06.gif",
        "https://i.pinimg.com/originals/bd/bd/4f/bdbd4f6d85fdaf6c8eea6ffc99aeaa1a.jpg",
        "https://www.niusnews.com/upload/imgs/default/2020Apr_CHOU/0428Sumikko/A1.jpg",
        "https://cc.tvbs.com.tw/img/upload/2020/05/19/20200519191617-75e42ad2.jpg",
        "https://png.pngtree.com/png-vector/20221222/ourmid/pngtree-super-cute-cartoon-vector-bear-png-image_6504049.png",
        "https://www.colorsexplained.com/wp-content/uploads/2021/05/shades-of-green-color-infographic.jpg.webp",
        "https://cf.shopee.tw/file/22b1fc845e5ce92481d08c79ffa29296",
        "https://i2.momoshop.com.tw/1658857094/goodsimg/0009/593/640/9593640_O_m.webp",
        "https://www.wenjianbaike.com/wp-content/uploads/2021/04/apng_wenjan.png",
        "https://i3.momoshop.com.tw/1672305576/goodsimg/0008/998/717/8998717_O_m.webp",
        "https://tw.bandisoft.com/honeycam/webp/imgs/overwatch_tr.webp",
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
        
        cell.myLabel?.text = "\(indexPath.row + 1)"
        cell.myImageView.WW.downloadImage(with: imageUrls[indexPath.row])
        
        return cell
    }
}
