//
//  PeersTableViewController.swift
//  MeshChat
//
//  Created by Akio Yasui on 11/26/15.
//  Copyright © 2015 Akio Yasui. All rights reserved.
//

import UIKit
import CoreMesh
import RealmSwift

extension Peer {
	var connected: Bool {
		return ChatManager.defaultManager.mesh.peers.contains(NSUUID(UUIDString: self.UUID)!)
	}
}

class PeersTableViewController: UITableViewController {

	var peers = ChatManager.defaultManager.realm.objects(Peer)
	var notificationToken: NotificationToken!

	func refresh() {
		dispatch_async(dispatch_get_main_queue()) {
			self.peers = ChatManager.defaultManager.realm.objects(Peer)
			self.tableView.reloadData()
			self.refreshControl!.endRefreshing()
		}
	}

	override func viewDidLoad() {
		self.refreshControl = UIRefreshControl()
		self.refreshControl!.addTarget(self, action: "refresh", forControlEvents: .ValueChanged)
	}

	override func viewWillAppear(animated: Bool) {
		self.refresh()

		Notification.PeerStatusChanged.addObserver(self, selector: "refresh")
		self.notificationToken = ChatManager.defaultManager.realm.addNotificationBlock { (notification, realm) -> Void in
			self.refresh()
		}
	}

	override func viewDidDisappear(animated: Bool) {
		ChatManager.defaultManager.realm.removeNotification(self.notificationToken)
	}

	override func preferredStatusBarStyle() -> UIStatusBarStyle {
		return .LightContent
	}

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.peers.count
    }

	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("PeerCell", forIndexPath: indexPath)
		let peer = self.peers[indexPath.row]
		cell.textLabel!.text = "\(peer.name) (\(peer.UUID))"
		cell.textLabel?.textColor = peer.connected ? UIColor.blackColor() : UIColor.grayColor()
		return cell
	}

}
