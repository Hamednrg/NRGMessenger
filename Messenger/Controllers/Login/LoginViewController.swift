//
//  LoginViewController.swift
//  Messenger
//
//  Created by Hamed on 6/18/1400 AP.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn
import JGProgressHUD

class LoginViewController: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private lazy var scrollview: UIScrollView = {
        let scroll = UIScrollView()
        scroll.clipsToBounds = true
        return scroll
    }()
    
    private lazy var imageView: UIImageView = {
        let image = UIImageView()
        image.image = UIImage(named: "logo")
        image.contentMode = .scaleAspectFit
        return image
    }()
    
    private lazy var emailField: UITextField = {
        let email = UITextField()
        email.autocapitalizationType = .none
        email.autocorrectionType = .no
        email.returnKeyType = .continue
        email.layer.cornerRadius = 12
        email.layer.borderWidth = 1
        email.layer.borderColor = UIColor.lightGray.cgColor
        email.placeholder = "Email Address..."
        email.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 0))
        email.leftViewMode = .always
        email.backgroundColor = .systemBackground
        
        email.delegate = self
        
        return email
    }()
    private lazy var passwordField: UITextField = {
        let password = UITextField()
        password.autocapitalizationType = .none
        password.autocorrectionType = .no
        password.returnKeyType = .done
        password.isSecureTextEntry = true
        password.layer.cornerRadius = 12
        password.layer.borderWidth = 1
        password.layer.borderColor = UIColor.lightGray.cgColor
        password.placeholder = "Password"
        password.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 0))
        password.leftViewMode = .always
        password.backgroundColor = .systemBackground
        
        password.delegate = self
        
        return password
    }()
    
    private lazy var loginButton:UIButton = {
        let button = UIButton()
        button.setTitle("Log In", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        button.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        return button
    }()
    private lazy var fbLoginButton: FBLoginButton = {
        let button = FBLoginButton()
        //        fbLoginButton.delegate = self
        button.permissions = ["public_profile", "email"]
        return button
    }()
    
    private lazy var googleLoginButton: GIDSignInButton = {
        let button = GIDSignInButton()
        //        fbLoginButton.delegate = self
        
        return button
    }()
    
    private var loginObserver: NSObjectProtocol?
    
    
    override func viewDidLoad() {
        
        
        loginObserver = NotificationCenter.default.addObserver(forName: .didLogInNotification, object: nil, queue: .main, using: { [weak self] _ in
            guard let strongSelf = self else { return }
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
        })
        
        GIDSignIn.sharedInstance().presentingViewController = self
        
        title = "Log In"
        view.backgroundColor = .systemBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register", style: .done, target: self, action: #selector(didTapRegister))
        
        
        // add subviews
        
        view.addSubview(scrollview)
        scrollview.addSubview(imageView)
        scrollview.addSubview(emailField)
        scrollview.addSubview(passwordField)
        scrollview.addSubview(loginButton)
        scrollview.addSubview(fbLoginButton)
        scrollview.addSubview(googleLoginButton)
    }
    deinit {
        if let observer = loginObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollview.frame = view.bounds
        let size = scrollview.width/3
        imageView.frame = CGRect(x: (scrollview.width-size)/2, y: 20, width: size, height: size)
        
        emailField.frame = CGRect(x: 30, y: imageView.bottom+60, width: scrollview.width-60 , height: 52)
        
        passwordField.frame = CGRect(x: 30, y: emailField.bottom+20, width: scrollview.width-60 , height: 52)
        loginButton.frame = CGRect(x: 30, y: passwordField.bottom+20, width: scrollview.width-60 , height: 52)
        googleLoginButton.frame = CGRect(x: 30, y: loginButton.bottom+20, width: scrollview.width-60, height: 60)
        fbLoginButton.frame = CGRect(x: 30, y: googleLoginButton.bottom+20, width: scrollview.width-60, height: 52)
        
    }
    @objc private func loginButtonTapped(){
        
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        guard let email = emailField.text, let password = passwordField.text, !email.isEmpty, !password.isEmpty, password.count >= 6 else { alertUserLoginError()
            return }
        // FireBase log in
        
        spinner.show(in: view)
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            guard let strongSelf = self else{ return }
            
            DispatchQueue.main.async {
                strongSelf.spinner.dismiss()
            }
            
            guard let result = authResult, error == nil else {
                print("error")
                return
            }
            let user = result.user
            
            UserDefaults.standard.set(email, forKey: "email")
            
            print("logged in user: \(user)")
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
        }
    }
    
    func alertUserLoginError(){
        let alert = UIAlertController(title: "Wooops", message: "Please enter all information to log in", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    @objc private func didTapRegister(){
        let vc = RegisterViewController()
        vc.title = "Create Account"
        navigationController?.pushViewController(vc, animated: true)
    }
}


extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField{
            passwordField.becomeFirstResponder()
        } else if textField == passwordField {
            loginButtonTapped()
        }
        return true
    }
}
extension LoginViewController: LoginButtonDelegate {
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        // no operation
    }
    
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        
        guard let token = result?.token?.tokenString else {
            print("User failed to log in with facebook")
            return
        }
        
        let facebookRequest = FBSDKLoginKit.GraphRequest(graphPath: "me", parameters: ["fields" : "email, first_name, last_name, picture.type(large)"], tokenString: token, version: nil, httpMethod: .get )
        facebookRequest.start { connection, result, error in
            guard let result = result as? [String: Any], error == nil else {
                print("Failed to make facebook graph request")
                return
            }
            print("\(result)")
            
            guard let firstName = result["first_name"] as? String,
                  let lastName = result["last_name"] as? String,
                  let email = result["email"] as? String,
                  let picture = result["picture"] as? [String: Any],
                  let data = picture["data"] as? [String: Any],
                  let pictureUrl = data["url"] as? String else {
                print("Failed to get email and name from fb result")
                return
            }
            UserDefaults.standard.set(email, forKey: "email")
            
            DatabaseManager.shared.userExists(with: email) { exist in
                if !exist {
                    let chatUser = ChatAppUser(firstName: firstName, lastName: lastName, emailAddress: email)
                    DatabaseManager.shared.insertUser(with: chatUser) { success in
                        if success {
                            guard let url = URL(string: pictureUrl) else {
                                return
                            }
                            print("Downloading data from facebook image")
                            
                            URLSession.shared.dataTask(with: url) { data, _, _ in
                                guard let data = data else{
                                    print("failed to get data from facebook")
                                    return
                                    
                                }
                                
                                print("got data from FB, uploading...")
                                // Upload image
                                let fileName = chatUser.profilePictureFileName
                                StorageManager.shared.uploadProfilePicture(with: data, fileName: fileName) { result in
                                    switch result {
                                    case .success(let downloadUrl):
                                        UserDefaults.standard.set(downloadUrl, forKey: "profile_picture_url")
                                        print(downloadUrl)
                                    case .failure(let error):
                                        print("storage manager error: \(error)")
                                    }
                                }
                            }.resume()
                        }
                    }
                }
            }
            
            let credential = FacebookAuthProvider.credential(withAccessToken: token)
            FirebaseAuth.Auth.auth().signIn(with: credential) { [weak self] authResult, error in
                guard let strongSelf = self else { return }
                guard authResult != nil , error == nil else {
                    print("Facebook credential login failed")
                    return
                }
                print("Successfully logged user in")
                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
            }
        }
        
        
    }
    
}
