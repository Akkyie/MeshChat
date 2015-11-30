//
//  AppDelegate.swift
//  MeshChat
//
//  Created by Akio Yasui on 11/26/15.
//  Copyright © 2015 Akio Yasui. All rights reserved.
//

import UIKit
import RealmSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?

	let manager = ChatManager.defaultManager

	func applicationDidBecomeActive(application: UIApplication) {
		self.manager.start(false)
	}

	func applicationWillResignActive(application: UIApplication) {
		self.manager.stop(false)
	}
	
}

