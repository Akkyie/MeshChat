//
//  Chat.swift
//  MeshChat
//
//  Created by Akio Yasui on 11/26/15.
//  Copyright © 2015 Akio Yasui. All rights reserved.
//

import UIKit
import CoreMesh
import RealmSwift
import ObjectMapper

private extension NSDictionary {
	var data: NSData? {
		return try? NSJSONSerialization.dataWithJSONObject(self, options: [])
	}
}

public enum Notification: String {

	private static let prefix = "jp.ad.wide.sfc.aky.CoreMesh."

	case PeerStatusChanged = "PeersChanged"
	case MessagesUpdated = "MessagesUpdated"

	var name: String {
		return self.dynamicType.prefix + self.rawValue
	}

	func post(object: AnyObject? = nil, userInfo: [String: AnyObject]? = nil) {
		NSNotificationCenter.defaultCenter().postNotificationName(self.name, object: object, userInfo: userInfo)
	}

	func addObserver(observer: AnyObject, selector: Selector, object: AnyObject? = nil) {
		NSNotificationCenter.defaultCenter().addObserver(observer, selector: selector, name: self.name, object: object)
	}

}

private enum DataType: String {

	private static let prefix = "jp.ad.wide.sfc.MeshChat."

	case DataType = "DataType"
	case PeerInfoRequest = "PeerInfoRequest"
	case PeerInfoResponse = "PeerInfoResponse"
	case TextMessage = "TextMessage"

	var key: String {
		return self.dynamicType.prefix + self.rawValue
	}

	init?(key: String) {
		switch key.stringByReplacingOccurrencesOfString(self.dynamicType.prefix, withString: "") {
		case DataType.rawValue: self = DataType
		case PeerInfoResponse.rawValue: self = PeerInfoResponse
		case PeerInfoRequest.rawValue: self = PeerInfoRequest
		case TextMessage.rawValue: self = TextMessage
		default: return nil
		}
	}

}

private enum ChatManagerError: ErrorType, CustomStringConvertible {
	case PeerAlreadyExists
	case PeerNotFound
	case InformationIncomplete
	case JSONSerializationFailure

	var description: String {
		switch self {
		case .PeerAlreadyExists: return "Peer to register already exists."
		case .PeerNotFound: return "Peer which has specified UUID was not found."
		case .InformationIncomplete: return "Given information was not sufficient."
		case .JSONSerializationFailure: return "Serialization between JSON and Data was failed."
		}
	}
}

public final class ChatManager {

	static let defaultManager = ChatManager()

	var mesh: DualMeshManager! = nil
	let realm: Realm

	private init() {
		let dictionary = NSBundle.mainBundle().infoDictionary
		let version = dictionary.map { $0["CFBundleVersion"] }.flatMap { $0 as? String }.flatMap { UInt64($0) } ?? 0
		do {
			self.realm = try Realm(configuration: Realm.Configuration(schemaVersion: version))
		} catch let error as NSError {
			fatalError(error.localizedDescription)
		}
	}

	func initializeMesh(selfPeer: Peer) {
		self.mesh = DualMeshManager(name: selfPeer.name, UUID: NSUUID(UUIDString: selfPeer.UUID)!)
		self.mesh.delegate = self
	}

}

extension ChatManager {

	func start(force: Bool = true) {
		do {
			guard let mesh = self.mesh else {
				if force {
					try self.saveSystemMessage("CoreMesh is not initialized.")
				}
				return
			}
			mesh.start()
			try self.saveSystemMessage("Started search of peers.")
		} catch let error {
			self.reportError(error)
		}
	}

	func stop(force: Bool = true) {
		do {
			guard let mesh = self.mesh else {
				if force {
					try self.saveSystemMessage("CoreMesh is not initialized.")
				}
				return
			}
			mesh.stop()
			try self.saveSystemMessage("Stopped search of peers.")
		} catch let error {
			self.reportError(error)
		}
	}

}

extension ChatManager {

	static func myUUID() -> NSUUID? {
		return NSUserDefaults.standardUserDefaults().stringForKey("jp.ad.wide.sfc.MeshChat.myUUID").flatMap { NSUUID(UUIDString: $0) }
	}

	static func setMyUUID(UUID: NSUUID) {
		NSUserDefaults.standardUserDefaults().setObject(UUID.UUIDString, forKey: "jp.ad.wide.sfc.MeshChat.myUUID")
	}

}

extension ChatManager {

	func reportError(error: ErrorType) {
		assertionFailure("\(error)")
		dispatch_async(dispatch_get_main_queue()) {
			switch error {
			case let error as NSError: self.reportError(error)
			case let error as ChatManagerError: self.reportError(error)
			default: fatalError("\(error)")
			}
			NSNotificationCenter.defaultCenter().postNotificationName(Notification.MessagesUpdated.name, object: nil)
		}
	}

	private func reportError(error: ChatManagerError) {
		do {
			if self.realm.inWriteTransaction {
				self.realm.cancelWrite()
			}
			try self.realm.write {
				let message = Message()
				message.type = MessageType.Error.rawValue
				message.UUID = NSUUID().UUIDString
				message.text = error.description
				message.date = NSDate()
				self.realm.add(message)
			}
		} catch let error {
			fatalError("\(error)")
		}
	}

	private func reportError(error: NSError) {
		do {
			try self.realm.write {
				let message = Message()
				message.type = MessageType.Error.rawValue
				message.UUID = NSUUID().UUIDString
				message.text = error.localizedDescription
				message.date = NSDate()
				self.realm.add(message)
			}
		} catch let error {
			fatalError("\(error)")
		}
	}

}

extension ChatManager {

	private func sendMessage(type: DataType, var info: [String: AnyObject] = [:], to peers: [NSUUID]) throws {
		print(__FUNCTION__)
		info[DataType.DataType.key] = type.key
		guard let data = try? NSJSONSerialization.dataWithJSONObject(info, options: []) else {
			throw ChatManagerError.JSONSerializationFailure
		}
		try self.mesh.sendData(data, to: peers)
	}

	private func receivedDictionary(type: DataType, dictionary: [String: AnyObject], from peer: NSUUID) {
		print(__FUNCTION__)
		do {
			switch type {
			case .PeerInfoRequest: try self.sendPeerInfo(to: peer)
			case .PeerInfoResponse: try self.registerPeer(dictionary)
			case .TextMessage: try self.receivedTextMessage(dictionary)
			default: break
			}
		} catch let error as ChatManagerError {
			self.reportError(error)
		} catch let error as NSError {
			self.reportError(error)
		}
	}

	private func sendPeerInfo(to peer: NSUUID) throws {
		print(__FUNCTION__)
		guard let this = self.realm.objectForPrimaryKey(Peer.self, key: ChatManager.myUUID()!.UUIDString) else {
			throw ChatManagerError.PeerNotFound
		}
		self.realm.beginWrite()
		var info = Mapper().toJSON(this)
		try self.realm.commitWrite()
		info["UUID"] = this.UUID
		try self.sendMessage(.PeerInfoResponse, info: info, to: [peer])
		Notification.PeerStatusChanged.post()
	}

	private func registerPeer(dictionary: [String: AnyObject]) throws {
		print(__FUNCTION__)
		guard let peer = Mapper<Peer>().map(dictionary) else {
			throw ChatManagerError.JSONSerializationFailure
		}
		guard let UUID = dictionary["UUID"] as? String else {
			throw ChatManagerError.JSONSerializationFailure
		}
		peer.UUID = UUID
		try self.realm.write {
			self.realm.add(peer)
		}
		try self.saveSystemMessage("\(peer.name) joined your network.")
		Notification.PeerStatusChanged.post()
	}

	public func sendTextMessage(text: String, to peers: [NSUUID]? = nil) {
		print(__FUNCTION__)
		guard let this = self.realm.objectForPrimaryKey(Peer.self, key: ChatManager.myUUID()!.UUIDString) else {
			self.reportError(ChatManagerError.PeerNotFound)
			return
		}
		let peers = peers ?? self.mesh.peers
		do {
			self.realm.beginWrite()
			let message = Message()
			message.UUID = NSUUID().UUIDString
			message.type = MessageType.Chat.rawValue
			message.text = text
			message.date = NSDate()
			message.peer = this
			message.peerUUID = this.UUID
			var info = Mapper().toJSON(message)
			info["UUID"] = message.UUID
			self.realm.add(message)
			try self.realm.commitWrite()
			try self.sendMessage(.TextMessage, info: info, to: peers)
			Notification.MessagesUpdated.post()
		} catch let error as ChatManagerError {
			self.reportError(error)
		} catch let error as NSError {
			self.reportError(error)
		}
	}

	private func receivedTextMessage(dictionary: [String: AnyObject]) throws {
		self.realm.beginWrite()
		let message = Message()
		Mapper<Message>().map(dictionary, toObject: message)
		guard let UUID = dictionary["UUID"] as? String else {
			throw ChatManagerError.JSONSerializationFailure
		}
		message.UUID = UUID
		guard let peer = self.realm.objectForPrimaryKey(Peer.self, key: message.peerUUID) else {
			throw ChatManagerError.PeerNotFound
		}
		message.peer = peer
		self.realm.add(message)
		try self.realm.commitWrite()
		Notification.MessagesUpdated.post()
	}

	private func saveSystemMessage(text: String) throws {
		self.realm.beginWrite()
		let message = Message()
		message.UUID = NSUUID().UUIDString
		message.type = MessageType.System.rawValue
		message.text = text
		message.date = NSDate()
		self.realm.add(message)
		try self.realm.commitWrite()
		Notification.MessagesUpdated.post()
	}

}

extension ChatManager: MeshManagerDelegate {

	public func meshManager(manager: MeshManager, receivedData data: NSData, fromPeer peer: NSUUID) {
		print(__FUNCTION__)
		dispatch_async(dispatch_get_main_queue()) {
			guard let
			dictionary = (try? NSJSONSerialization.JSONObjectWithData(data, options: [])).flatMap({ $0 as? [String: AnyObject] }),
				type = dictionary[DataType.DataType.key].flatMap({ $0 as? String }).flatMap({ DataType(key: $0) }) else
			{
				print("Invalid Message Type")
				print(NSString(data: data, encoding: NSUTF8StringEncoding))
				return
			}
			self.receivedDictionary(type, dictionary: dictionary, from: peer)
		}
	}

	public func meshManager(manager: MeshManager, peerStatusDidChange peerID: NSUUID, status: PeerStatus) {
		print(__FUNCTION__)
		dispatch_async(dispatch_get_main_queue()) {
			Notification.PeerStatusChanged.post()
			do {
				guard let peer = self.realm.objectForPrimaryKey(Peer.self, key: peerID.UUIDString) else {
					try self.sendMessage(.PeerInfoRequest, to: [peerID])
					return
				}
				let message: String
				self.realm.beginWrite()
				switch status {
				case .Connected:
					message = "\(peer.name) joined your network."
				case .NotConnected, .Connecting:
					message = "\(peer.name) leaved your network."
				}
				try self.realm.commitWrite()
				try self.saveSystemMessage(message)
			} catch {
				self.reportError(error)
			}
		}
	}
	
}
