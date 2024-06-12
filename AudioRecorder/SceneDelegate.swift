//
//  SceneDelegate.swift
//  AudioRecorder
//
//  Created by Afsal on 11/06/2024.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

  var window: UIWindow?

  func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    guard let scene = (scene as? UIWindowScene) else { return }
    
    window = UIWindow(windowScene: scene)
    let vc = AudioRecorderController()
    let navigationController = UINavigationController(rootViewController: vc)
    window?.rootViewController = navigationController
    window?.makeKeyAndVisible()
  }
}

