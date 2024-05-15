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
        _ = WWWebImage.shared.initDatabase(for: .documents, expiredDays: 90, cacheDelayTime: 600)
        return true
    }
}

