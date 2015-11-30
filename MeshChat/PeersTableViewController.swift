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
		return ChatManager.myUUID()?.UUIDString == self.UUID || ChatManager.defaultManager.mesh.peers.contains(NSUUID(UUIDString: self.UUID)!)
	}
}

class PeerTableViewCell: UITableViewCell {

	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet weak var descriptionLabel: UILabel!
	@IBOutlet weak var statusLabel: UILabel!

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
		self.tableView.rowHeight = UITableViewAutomaticDimension
		self.tableView.estimatedRowHeight = 80.0
		
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

	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		guard let
			destination = segue.destinationViewController as? NewMessageTableViewController,
			peer = self.tableView.indexPathForSelectedRow.flatMap({ self.peers[$0.row] }) else {
				return
		}
		destination.targetPeer = peer
	}

}

extension PeersTableViewController {
	
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.peers.count
	}

	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		guard let cell = tableView.dequeueReusableCellWithIdentifier("PeerCell", forIndexPath: indexPath) as? PeerTableViewCell else {
			return tableView.dequeueReusableCellWithIdentifier("PeerCell", forIndexPath: indexPath)
		}
		let peer = self.peers[indexPath.row]
		cell.nameLabel.text = peer.name
		cell.descriptionLabel.text = peer.UUID
		cell.statusLabel.textColor = peer.connected ? UIColor.greenColor() : UIColor.lightGrayColor()
		return cell
	}

	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		return self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
	}

}
