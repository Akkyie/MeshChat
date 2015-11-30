//
//  Models.swift
//  MeshChat
//
//  Created by Akio Yasui on 11/27/15.
//  Copyright © 2015 Akio Yasui. All rights reserved.
//

import Foundation
import RealmSwift
import ObjectMapper

class Peer: Object, Mappable {

	dynamic var UUID: String! // Don't include in mapping
	dynamic var name: String!

	required convenience init?(_ map: Map) {
		self.init()
	}

	override class func primaryKey() -> String? {
		return "UUID"
	}

	func mapping(map: Map) {
		self.name <- map["name"]
	}

}

enum MessageType: Int {
	case Default
	case Chat
	case System
	case Error
}

class Message: Object, Mappable {

	dynamic var type = 0
	dynamic var UUID: String! // Don't include in mapping
	dynamic var text: String!
	dynamic var date = NSDate()
	dynamic var peerUUID: String!
	dynamic var peer: Peer! // Don't include in mapping

	required convenience init?(_ map: Map) {
		self.init()
	}

	override class func primaryKey() -> String? {
		return "UUID"
	}

	func mapping(map: Map) {
		self.type <- map["type"]
		self.text <- map["text"]
		self.date <- map["date"]
		self.peerUUID <- map["PeerUUID"]
	}
	
}
