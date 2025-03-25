//
//  AppDelegate.swift
//  Example
//
//  Created by William.Weng on 2022/12/15.
//
//

import UIKit
import WWNetworking_UIImage

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        initSetting()
        return true
    }
}

// MARK: - 小工具
private extension AppDelegate {
    
    /// 基本設定
    func initSetting() {
        
        let defaultImage = UIImage(named: "no-pictures")
        let error = WWWebImage.shared.cacheTypeSetting(.cache(), defaultImage: defaultImage)
        
        print(error.debugDescription)
    }
}
