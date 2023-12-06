//
//  TableViewCell.swift
//  Example
//
//  Created by iOS on 2023/4/7.
//

import UIKit
import WWPrint

final class TableViewCell: UITableViewCell {

    @IBOutlet weak var myImageView: UIImageView!
    @IBOutlet weak var myLabel: UILabel!
    
    deinit { wwPrint("deinit => \(Self.self)") }
}
