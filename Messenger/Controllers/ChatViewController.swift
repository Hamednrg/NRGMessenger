//
//  ChatViewController.swift
//  Messenger
//
//  Created by Hamed on 6/27/1400 AP.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import SDWebImage
import AVKit


class ChatViewController: MessagesViewController {
    
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        return formatter
    }()
    
    public var isNewConversation = false
    
    public let otherUserEmail: String
    private let conversationID: String?
    
    private var messages = [Message]()
    
    private var selfSender: Sender? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else { return nil }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        return Sender(photoURL: "", senderId: safeEmail  , displayName: "Me")
    }
    
    init(with email: String, id: String?) {
        self.otherUserEmail = email
        self.conversationID = id
        super.init(nibName: nil, bundle: nil)
        if let conversationID = conversationID {
            listenForMessages(id: conversationID)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.tintColor = .themeColor

        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        messageInputBar.delegate = self
        setupInputButton()
    }
    
    private func setupInputButton() {
        let button = InputBarButtonItem()
        button.setSize(CGSize(width: 35, height: 35), animated: false)
        button.tintColor = UIColor.themeColor
        button.setImage(UIImage(systemName: "paperclip.badge.ellipsis"), for: .normal)
        button.onTouchUpInside { [weak self] _ in
            self?.presentInputActionSheet()
        }
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
    }
    
    private func presentInputActionSheet() {
        
        let actionSheet = UIAlertController(title: "Attach Media", message: "What would you like to attach?", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Photo", style: .default, handler: { [weak self] _ in
            self?.presentPhotoInputActionSheet()
        }))
        actionSheet.addAction(UIAlertAction(title: "Video", style: .default, handler: { [weak self] _ in
            self?.presentVideoInputActionSheet()
        }))
        actionSheet.addAction(UIAlertAction(title: "Audio", style: .default, handler: {  _ in
            
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionSheet, animated: true, completion: nil)
    }
  
    private func presentVideoInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach Video", message: "Where would you like to attach a Video from?", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Library", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionSheet, animated: true, completion: nil)
    }
  
    private func presentPhotoInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach Photo", message: "Where would you like to attach a photo from?", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionSheet, animated: true, completion: nil)
    }
 
    private func listenForMessages(id: String) {
        
        DatabaseManager.shared.getAllMessagesForConversation(with: id) {[weak self] result in
            switch result {
            
            case .success(let messages):
                guard !messages.isEmpty else { return }
                self?.messages = messages
                DispatchQueue.main.async {
                    self?.messagesCollectionView.reloadDataAndKeepOffset()
                }
            case .failure(let error):
                print("failed to get messages: \(error)")
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
    }
    
}

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let messageID = createMessageID(),
              let conversationID = conversationID,
              let name = self.title,
              let selfSender = selfSender else { return }
        
        if let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage,
           let imageData = image.pngData(){
            
            let fileName = "photo_message" + messageID.replacingOccurrences(of: " ", with: "-") + ".png"
            
            // Upload image
            StorageManager.shared.uploadMessagePhoto(with: imageData, fileName: fileName) { [weak self] result in
                
                guard let strongSelf = self else { return }
                
                switch result {
                case .success(let urlString):
                    
                    print("uploaded message photo: \(urlString)")
                    
                    guard let url = URL(string: urlString), let placeholder = UIImage(systemName: "camera.on.rectangle") else { return }
                    
                    let media = Media(url: url, image: nil, placeholderImage: placeholder, size: .zero)
                    
                    let message = Message(sender: selfSender, messageId: messageID, sentDate: Date(), kind: .photo(media))
                    //send message
                    DatabaseManager.shared.sendMessage(to: conversationID, otherUserEmail: strongSelf.otherUserEmail, name: name, newMessage: message) { success in
                        if success {
                            print("sent photo message")
                        } else {
                            print("failed to send photo message")
                        }
                    }
                    
                case .failure(let error):
                    print("failed to get image url: \(error)")
                }
            }
            
        } else if let videoUrl = info[.mediaURL] as? URL {
            let fileName = "video_message" + messageID.replacingOccurrences(of: " ", with: "-") + ".mov"
            StorageManager.shared.uploadMessageVideo(with: videoUrl, fileName: fileName) { [weak self] result in
                
                guard let strongSelf = self else { return }
                
                switch result {
                case .success(let urlString):
                    
                    print("uploaded message Video: \(urlString)")
                    
                    guard let url = URL(string: urlString), let placeholder = UIImage(systemName: "video.bubble.left.fill") else { return }
                    
                    let media = Media(url: url, image: nil, placeholderImage: placeholder, size: .zero)
                    
                    let message = Message(sender: selfSender, messageId: messageID, sentDate: Date(), kind: .video(media))
                    //send message
                    DatabaseManager.shared.sendMessage(to: conversationID, otherUserEmail: strongSelf.otherUserEmail, name: name, newMessage: message) { success in
                        if success {
                            print("sent video message")
                        } else {
                            print("failed to send video message")
                        }
                    }
                    
                case .failure(let error):
                    print("failed to get video url: \(error)")
                }
            }
        }
    }
}

extension ChatViewController: InputBarAccessoryViewDelegate {
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty,
              let selfSender = self.selfSender,
              let messageID = createMessageID() else { return }
        // send message
        print(text)
        let message = Message(sender: selfSender, messageId: messageID, sentDate: Date(), kind: .text(text))
        if isNewConversation {
            // crate convo in database
            DatabaseManager.shared.createNewConversation(with: otherUserEmail, name: self.title ?? "",firstMessage: message) { [weak self] success in
                if success {
                    print("message sent")
                    self?.isNewConversation = false
                } else{
                    print("failed to sent message")
                }
            }
        } else {
            // append to existing conversation data
            guard let conversationID = conversationID, let name = self.title else {
                return
            }
            DatabaseManager.shared.sendMessage(to: conversationID, otherUserEmail: otherUserEmail, name: name, newMessage: message) { success in
                if success {
                    print("message sent")
                } else {
                    print("failed to sent message")
                }
            }
        }
    }
    
    private func createMessageID() -> String? {
        // date, otherUserEmail, senderEmail, randomInt
        let dateString = Self.dateFormatter.string(from: Date())
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        let safeCurrentEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
        let newIdentifier = "\(otherUserEmail)_\(safeCurrentEmail)_\(dateString)"
        print("created message id: \(newIdentifier)")
        return newIdentifier
        
    }
}

extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    
    func currentSender() -> SenderType {
        if let sender = selfSender {
            return sender
        }
        return Sender(photoURL: "N/A", senderId: "N/A", displayName: "N/A")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let message = message as? Message else { return }
        switch message.kind {
        case .photo(let media):
            guard let imageUrl = media.url else { return }
            imageView.sd_setImage(with: imageUrl, completed: nil)
        default:
            break
        }
    }
}

extension ChatViewController: MessageCellDelegate {
    
    func didTapImage(in cell: MessageCollectionViewCell) {
        
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else { return }
        let message = messages[indexPath.section]
        
        switch message.kind {
        case .photo(let media):
            
            guard let imageUrl = media.url else { return }
            let vc = PhotoViewerViewController(with: imageUrl)
            self.navigationController?.present(vc, animated: true, completion: nil)
            
        case .video(let media):
            
            guard let videoUrl = media.url else { return }
            let vc = AVPlayerViewController()
            vc.player = AVPlayer(url: videoUrl)
            vc.allowsPictureInPicturePlayback = true
            vc.player?.play()
            present(vc, animated: true, completion: nil)
            
        default:
            break
        }
    }
}

extension MessageKind {
    var messageKindString: String{
        switch self{
        case .text(_):
            return "text"
        case .attributedText(_):
            return "attributed_text"
        case .photo(_):
            return "photo"
        case .video(_):
            return "video"
        case .location(_):
            return "location"
        case .emoji(_):
            return "emoji"
        case .audio(_):
            return "audio"
        case .contact(_):
            return "contact"
        case .custom(_):
            return "unkown"
        }
    }
}

