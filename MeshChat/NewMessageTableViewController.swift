//
//  NewMessageTableViewController.swift
//  MeshChat
//
//  Created by Akio Yasui on 12/1/15.
//  Copyright © 2015 Akio Yasui. All rights reserved.
//

import UIKit
import RealmSwift

class NewMessageTableViewController: UITableViewController {

	var targetPeer: Peer? = nil

	@IBOutlet weak var placeholderLabel: UILabel!
	@IBOutlet weak var textView: UITextView!
	@IBOutlet weak var sendButtonItem: UIBarButtonItem!

	@IBAction func sendMessage(sender: UIBarButtonItem) {
		if let
			peer = self.targetPeer,
			UUID = NSUUID(UUIDString: peer.UUID)
		{
			ChatManager.defaultManager.sendTextMessage(self.textView.text, to: [UUID])

		} else {
			ChatManager.defaultManager.sendTextMessage(self.textView.text)
		}
		self.textView.endEditing(true)
		self.dismissViewControllerAnimated(true, completion: nil)
	}

	@IBAction func cancel(sender: UIBarButtonItem) {
		self.textView.endEditing(true)
		self.dismissViewControllerAnimated(true, completion: nil)
	}

	override func preferredStatusBarStyle() -> UIStatusBarStyle {
		return .LightContent
	}

}

extension NewMessageTableViewController: UITextViewDelegate {

	func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
		let string = (textView.text as NSString?)?.stringByReplacingCharactersInRange(range, withString: text) ?? self.textView.text ?? ""
		self.sendButtonItem.enabled = string.utf16.count > 0
		self.placeholderLabel.hidden = string.utf16.count > 0
		return text != "\n"
	}
	
}
