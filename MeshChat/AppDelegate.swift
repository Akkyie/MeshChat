//
//  AppDelegate.swift
//  MeshChat
//
//  Created by Akio Yasui on 11/26/15.
//  Copyright © 2015 Akio Yasui. All rights reserved.
//

import UIKit
import RealmSwift
import Fabric
import Crashlytics

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?

	let manager = ChatManager.defaultManager

	func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
		Fabric.with([Crashlytics.self])
		return true
	}

	func applicationDidBecomeActive(application: UIApplication) {
		self.manager.start(false)
	}

	func applicationWillResignActive(application: UIApplication) {
		self.manager.stop(false)
	}
	
}

