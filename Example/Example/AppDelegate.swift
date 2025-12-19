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
        _ = WWWebImage.shared.cacheTypeSetting(defaultImage: UIImage(named: "no-pictures"))
        return true
    }
}
