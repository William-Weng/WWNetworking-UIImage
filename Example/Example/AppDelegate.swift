//
//  AppDelegate.swift
//  Example
//
//  Created by William.Weng on 2022/12/15.
//
/// file:///Users/ios/Desktop/@WWNetworking-UIImage

import UIKit
import WWPrint
import WWNetworking_UIImage

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let defaultImage = UIImage(named: "no-pictures")
        // let error = WWWebImage.shared.initCacheType(.database(.documents, 90, 600), defaultImage: defaultImage)
        let error = WWWebImage.shared.initCacheType(.cache, defaultImage: defaultImage)
        wwPrint(error)
        
        WWWebImage.shared.downloadProgress { info in
            wwPrint(info)
        }
        
        return true
    }
}

