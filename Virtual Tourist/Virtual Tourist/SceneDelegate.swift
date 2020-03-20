//
//  SceneDelegate.swift
//  Virtual Tourist
//
//  Created by Anna Zislina on 28/10/2019.
//  Copyright © 2019 Anna Zislina. All rights reserved.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    let dataController = DataController(modelName: "Virtual_Tourist")

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        dataController.load()
        guard let _ = (scene as? UIWindowScene) else { return }
        
        let navVC = window?.rootViewController as! UINavigationController
        let mapVC = navVC.topViewController as! TravelLocationsMapViewController
        mapVC.dataController = dataController
        window?.makeKeyAndVisible()
        
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }
}

