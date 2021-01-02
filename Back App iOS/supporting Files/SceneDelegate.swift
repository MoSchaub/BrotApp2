//
//  SceneDelegate.swift
//  Back App iOS
//
//  Created by Franka Schaub on 26.06.20.
//  Copyright © 2020 Franka Schaub. All rights reserved.
//

import UIKit
import BackAppCore
import BakingRecipeStrings
import BakingRecipeUIFoundation

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    
    let appData = BackAppData()
    lazy var compactHomeVC = CompactHomeViewController(appData: appData)
    
    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(reloadWindows), name: .sceneShouldReload, object: nil)
    }

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let windowScene = (scene as? UIWindowScene) else { return }
        let window = UIWindow(windowScene: windowScene)
        let splitViewController = UISplitViewController()
        
        let navigationViewController = UINavigationController(rootViewController: compactHomeVC)
        splitViewController.viewControllers = [navigationViewController]
        splitViewController.preferredDisplayMode = .allVisible
        window.rootViewController = splitViewController
        window.makeKeyAndVisible()
        self.window = window
        self.window!.tintColor = UIColor.tintColor
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        // open file in app
        let _ = URLContexts.map({ self.appData.open($0.url)})
        compactHomeVC.dataSource.update(animated: true)
        
        let alert = UIAlertController(title: appData.inputAlertTitle, message: appData.inputAlertMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            alert.dismiss(animated: true, completion: nil)
        }))
        
        compactHomeVC.present(alert, animated: true)
    }
    
    @objc private func reloadWindows() {
        window?.rootViewController?.setNeedsStatusBarAppearanceUpdate()
        window?.rootViewController?.children.forEach({
            $0.setNeedsStatusBarAppearanceUpdate()
        })
        
        window?.subviews.forEach({ view in
            view.removeFromSuperview()
            window?.addSubview(view)
        })
    }

}

