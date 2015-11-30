//
//  ChatTableViewController.swift
//  MeshChat
//
//  Created by Akio Yasui on 11/29/15.
//  Copyright © 2015 Akio Yasui. All rights reserved.
//

import UIKit
import RealmSwift

extension NSDate {
	func relativeString(date: NSDate) -> String {
		let interval = date.timeIntervalSinceDate(self)
		switch interval {
		case 0 ..< 60: return "now"
		case 60 ..< 3600: return "\(Int(interval / 60))m"
		case 3600 ..< 86400: return "\(Int(interval / 3600))h"
		default: return "\(Int(interval / 86400))d"
		}
	}
}

class ChatTableViewCell: UITableViewCell {
	@IBOutlet weak var timeLabel: UILabel!
	@IBOutlet weak var peerLabel: UILabel!
	@IBOutlet weak var _textLabel: UILabel!

	override var textLabel: UILabel! {
		return self._textLabel
	}
}

class ChatTableViewController: UITableViewController {

	var messages = ChatManager.defaultManager.realm.objects(Message)
	var notificationToken: NotificationToken!

	func refresh() {
		print(__FUNCTION__)
		dispatch_async(dispatch_get_main_queue()) {
			self.messages = ChatManager.defaultManager.realm.objects(Message)
			self.tableView.reloadData()
			self.refreshControl!.endRefreshing()
		}
	}

	override func viewDidLoad() {
		self.tableView.rowHeight = UITableViewAutomaticDimension
		self.tableView.estimatedRowHeight = 80.0

		self.refreshControl = UIRefreshControl()
		self.refreshControl!.addTarget(self, action: "refresh", forControlEvents: .ValueChanged)
	}

	override func viewWillAppear(animated: Bool) {
		self.refresh()

		Notification.MessagesUpdated.addObserver(self, selector: "refresh")
		self.notificationToken = ChatManager.defaultManager.realm.addNotificationBlock { (notification, realm) -> Void in
			print(notification)
			self.refresh()
		}
	}

	override func viewDidDisappear(animated: Bool) {
		ChatManager.defaultManager.realm.removeNotification(self.notificationToken)
	}

	override func preferredStatusBarStyle() -> UIStatusBarStyle {
		return .LightContent
	}

}

extension ChatTableViewController {

	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.messages.count
	}

	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let message = self.messages[self.messages.count - indexPath.row - 1]
		switch MessageType(rawValue: message.type) {
		case .Some(.Chat):
			guard let cell = tableView.dequeueReusableCellWithIdentifier("MessageCell", forIndexPath: indexPath) as? ChatTableViewCell else {
				return tableView.dequeueReusableCellWithIdentifier("MessageCell", forIndexPath: indexPath)
			}
			cell.peerLabel.text = message.peer.name
			cell.timeLabel.text = message.date.relativeString(NSDate())
			cell.textLabel.text = message.text
			return cell
		case .Some(.System):
			guard let cell = tableView.dequeueReusableCellWithIdentifier("SystemMessageCell", forIndexPath: indexPath) as? ChatTableViewCell else {
				return tableView.dequeueReusableCellWithIdentifier("SystemMessageCell", forIndexPath: indexPath)
			}
			cell.timeLabel.text = message.date.relativeString(NSDate())
			cell.textLabel.text = message.text
			return cell
		case .Some(.Error):
			guard let cell = tableView.dequeueReusableCellWithIdentifier("ErrorMessageCell", forIndexPath: indexPath) as? ChatTableViewCell else {
				return tableView.dequeueReusableCellWithIdentifier("ErrorMessageCell", forIndexPath: indexPath)
			}
			cell.timeLabel.text = message.date.relativeString(NSDate())
			cell.textLabel.text = message.text
			return cell
		default: return tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
		}
	}

	override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		return UITableViewAutomaticDimension
	}

}
