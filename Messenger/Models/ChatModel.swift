//
//  ChatModel.swift
//  Messenger
//
//  Created by Hamed on 8/7/1400 AP.
//

import Foundation
import MessageKit


struct Message: MessageType {
    
    public var sender: SenderType
    
    public var messageId: String
    
    public var sentDate: Date
    
    public var kind: MessageKind
}

struct Sender: SenderType {
    
    public  var photoURL: String
    
    public  var senderId: String
    
    public  var displayName: String
    
    
}

struct Media: MediaItem {
    
    var url: URL?
    
    var image: UIImage?
    
    var placeholderImage: UIImage
    
    var size: CGSize
    
}
