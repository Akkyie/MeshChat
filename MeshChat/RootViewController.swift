//
//  RootViewController.swift
//  MeshChat
//
//  Created by Akio Yasui on 11/27/15.
//  Copyright © 2015 Akio Yasui. All rights reserved.
//

import UIKit

class RootViewController: UIViewController {

	@IBOutlet weak var scrollView: UIScrollView!
	@IBOutlet weak var textField: UITextField!
	@IBOutlet weak var hairlineView: UIView!
	@IBOutlet weak var startButton: UIButton!

	func performSegue() {
		switch self.traitCollection.horizontalSizeClass {
		case .Compact: self.performSegueWithIdentifier("RootCompactSegue", sender: self)
		default: self.performSegueWithIdentifier("RootRegularSegue", sender: self)
		}
	}

	@IBAction func start(sender: AnyObject) {
		let myUUID = UIDevice.currentDevice().identifierForVendor ?? NSUUID()
		ChatManager.setMyUUID(myUUID)
		dispatch_async(dispatch_get_main_queue()) {
			do {
				try ChatManager.defaultManager.realm.write {
					let peer = Peer()
					peer.name = self.textField.text ?? ""
					peer.UUID = myUUID.UUIDString
					ChatManager.defaultManager.initializeMesh(peer)
					ChatManager.defaultManager.realm.add(peer)
				}
				ChatManager.defaultManager.start()
				self.performSegue()
			} catch let error as NSError {
				fatalError(error.localizedDescription)
			}
		}
	}

	override func viewDidLoad() {
		self.textField.delegate = self
	}

	override func viewWillAppear(animated: Bool) {
		self.textField.alpha = 0.0
		self.hairlineView.alpha = 0.0
		self.startButton.alpha = 0.0
	}

	override func viewDidAppear(animated: Bool) {
		if let
			UUID = ChatManager.myUUID(),
			peer = ChatManager.defaultManager.realm.objectForPrimaryKey(Peer.self, key: UUID.UUIDString)
		{
			ChatManager.defaultManager.initializeMesh(peer)
			ChatManager.defaultManager.start()
			self.performSegue()
		} else {
			UIView.animateWithDuration(0.25) {
				self.textField.alpha = 1.0
				self.hairlineView.alpha = 1.0
				self.startButton.alpha = 1.0
			}
		}
	}

	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if let splitViewController = segue.destinationViewController as? UISplitViewController {
			splitViewController.preferredDisplayMode = .AllVisible
		}
	}

	override func preferredStatusBarStyle() -> UIStatusBarStyle {
		return .LightContent
	}

}

extension RootViewController: UITextFieldDelegate {

	func textFieldDidBeginEditing(textField: UITextField) {
		UIView.animateWithDuration(1.0,
			delay: 0.0,
			usingSpringWithDamping: 0.75,
			initialSpringVelocity: 1.0,
			options: [],
			animations: {
				let offset = self.textField.frame.minY - 200
				self.scrollView.contentOffset = CGPoint(x: 0, y: offset)
			},
			completion: nil
		)
	}

	func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
		let string = (textField.text ?? "" as NSString).stringByReplacingCharactersInRange(range, withString: string)
		self.startButton.enabled = !string.isEmpty
		let set = NSCharacterSet.alphanumericCharacterSet()
		return string.utf16.reduce(true, combine: { $0 && set.characterIsMember($1) })
	}

	func textFieldShouldReturn(textField: UITextField) -> Bool {
		UIView.animateWithDuration(1.0,
			delay: 0.0,
			usingSpringWithDamping: 0.75,
			initialSpringVelocity: 1.0,
			options: [],
			animations: {
				self.scrollView.contentOffset = CGPoint(x: 0, y: 0)
			},
			completion: { _ in
				self.start(self)
			}
		)
		return true
	}

}

class SplitViewController: UISplitViewController {

	override func preferredStatusBarStyle() -> UIStatusBarStyle {
		return .LightContent
	}

}

class TabBarController: UITabBarController {

	override func preferredStatusBarStyle() -> UIStatusBarStyle {
		return .LightContent
	}

}

class NavigationController: UINavigationController {

	override func preferredStatusBarStyle() -> UIStatusBarStyle {
		return self.visibleViewController?.preferredStatusBarStyle() ?? .LightContent
	}

}
