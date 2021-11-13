//
//  ViewController.swift
//  Messenger
//
//  Created by Hamed on 6/18/1400 AP.
//

import UIKit
import FirebaseAuth
import JGProgressHUD


class ConversationViewController: UIViewController {
    
    private lazy var spinner = JGProgressHUD(style: .dark)
    private var conversations = [Conversation]()
    
    private lazy var tableView: UITableView = {
        let table = UITableView()
        table.register(ConversationTableViewCell.self, forCellReuseIdentifier: ConversationTableViewCell.identifier)
        table.isHidden = true
        table.delegate = self
        table.dataSource = self
        return table
    }()
    
    private lazy var noConversationLabel: UILabel = {
        let label = UILabel()
        label.text = "No Conversation"
        label.textAlignment = .center
        label.textColor = .gray
        label.font = .systemFont(ofSize: 21, weight: .medium)
        label.isHidden = true
        return label
    } ()
    
    
    private var loginObserver: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(didTapComposeButton))
        navigationController?.navigationBar.tintColor = .themeColor

        
        view.addSubview(tableView)
        view.addSubview(noConversationLabel)
        
        loginObserver = NotificationCenter.default.addObserver(forName: .didLogInNotification, object: nil, queue: .main, using: { [weak self] _ in
            guard let strongSelf = self else { return }
            strongSelf.startListeningForConversations()
        })
        
        updateUI()
        startListeningForConversations()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        noConversationLabel.frame = CGRect(x: view.width/4, y: (view.height-200)/2, width: view.width/2, height: 200)
        tableView.frame = view.bounds
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        vaidateAuth()
    }
   
    private func startListeningForConversations() {
        
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else { return }
        
        if let observer = loginObserver{
            NotificationCenter.default.removeObserver(observer)
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        
        DatabaseManager.shared.getAllConversations(for: safeEmail) { [weak self] result in
            switch result {
            case .success(let conversations):
                guard !conversations.isEmpty else {
                    self?.updateUI()
                    return
                }
                self?.conversations = conversations
                DispatchQueue.main.async {
                    self?.updateUI()
                    self?.tableView.reloadData()
                }
            case .failure(let error):
                print("failed to get conver: \(error)")
            }
        }
    }
    
    private func vaidateAuth(){
        if FirebaseAuth.Auth.auth().currentUser == nil{
            let vc = LoginViewController()
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: false)
            
        }
    }
    
    private func updateUI() {
        
        if conversations.isEmpty {
            noConversationLabel.isHidden = false
            tableView.isHidden = true
        } else {
            tableView.isHidden = false
            noConversationLabel.isHidden = true
        }
    }
    
    @objc func didTapComposeButton() {
        
        let vc = NewConversationViewController()
        vc.completion = { [weak self] result in
            guard let strongSelf = self else { return }
            print("\(result)")
            
            let currentConversations = strongSelf.conversations
            
            if let targetConversation = currentConversations.first(where: {
                $0.otherUserEmail == DatabaseManager.safeEmail(emailAddress: result.email)
            }) {
                let vc = ChatViewController(with: targetConversation.otherUserEmail, id: targetConversation.id)
                vc.isNewConversation = false
                vc.title = targetConversation.name
                vc.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            } else {
                strongSelf.createNewConversation(result: result)
            }
        }
        let navVC = UINavigationController(rootViewController: vc)
        present(navVC, animated: true, completion: nil)
        
    }
    
    private func createNewConversation(result: SearchResult) {
        let name = result.name
        let email = DatabaseManager.safeEmail(emailAddress: result.email)
        
        
        // check in database if conversation with these two users exists
        // if it does, reuse conversation id
        // otherwise use existing code
        DatabaseManager.shared.conversationExists(with: email) { [weak self] result in
            guard let strongSelf = self else { return }
            
            switch result {
            case .success(let conversationID):
                let vc = ChatViewController(with: email, id: conversationID)
                vc.isNewConversation = false
                vc.title = name
                vc.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            case .failure(_):
                let vc = ChatViewController(with: email, id: nil)
                vc.isNewConversation = true
                vc.title = name
                vc.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(vc, animated: true)
                
            }
        }
    }
}

extension ConversationViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = conversations[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ConversationTableViewCell.identifier, for: indexPath) as! ConversationTableViewCell
        cell.configure(with: model)
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = conversations[indexPath.row]
        tableView.deselectRow(at: indexPath, animated: true)
        openConversation(model: model)
       
    }
    func openConversation(model: Conversation){
        let vc = ChatViewController(with: model.otherUserEmail, id: model.id)
        vc.title = model.name
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    // MARK: deleting conversation
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // begin delete
            let conversationID = conversations[indexPath.row].id
            tableView.beginUpdates()
            
            DatabaseManager.shared.deleteConversation(conversationID: conversationID) { [weak self] success in
                if success {
                    self?.conversations.remove(at: indexPath.row)
                    tableView.deleteRows(at: [indexPath], with: .left)
                    self?.updateUI()
                }
            }
            
            
            
            tableView.endUpdates()
        }
    }
}
