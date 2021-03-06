//
//  ConversationTableViewCell.swift
//  Messenger
//
//  Created by Hamed on 8/1/1400 AP.
//

import UIKit
import SDWebImage

class ConversationTableViewCell: UITableViewCell {
    static let identifier = "ConversationTableViewCell"
    
    private lazy var userImageView: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFill
        image.layer.cornerRadius = 40
        image.layer.masksToBounds = true
        return image
    }()
    private lazy var userNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 21, weight: .semibold)
        return label
    }()
    private lazy var userMessageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 19, weight: .regular)
        label.numberOfLines = 0
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(userImageView)
        contentView.addSubview(userNameLabel)
        contentView.addSubview(userMessageLabel)
        
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        userImageView.frame = CGRect(x: 10, y: 10, width: 80, height: 80)
        userNameLabel.frame = CGRect(x: userImageView.right+10, y: 10, width: contentView.width-20-userImageView.width, height: 50)
        userMessageLabel.frame = CGRect(x: userImageView.right+10, y: userNameLabel.bottom, width: contentView.width-20-userImageView.width, height: 25)
        
    }
    
    public func configure(with model: Conversation){
        self.userMessageLabel.text = model.latestMessage.text
        self.userNameLabel.text = model.name
        let path = "images/\(model.otherUserEmail)_profile_picture.png"
        StorageManager.shared.downloadURL(for: path) { [weak self] result in
            switch result {
            case .success(let url):
                DispatchQueue.main.async {
                    self?.userImageView.sd_setImage(with: url, completed: nil)
                }
            case .failure(let error):
                print("failed to get image url: \(error)")
            }
        }
    }
}
