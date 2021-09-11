//
//  RegisterViewController.swift
//  Messenger
//
//  Created by Hamed on 6/18/1400 AP.
//

import UIKit

class RegisterViewController: UIViewController {
    
    private lazy var scrollview: UIScrollView = {
        let scroll = UIScrollView()
        scroll.clipsToBounds = true
        scroll.isUserInteractionEnabled = true
        return scroll
    }()
    
    private lazy var imageView: UIImageView = {
        let image = UIImageView()
        image.image = UIImage(systemName: "person")
        image.tintColor = .systemBlue
        image.isUserInteractionEnabled = true
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
        email.backgroundColor = .white
        
        email.delegate = self
        
        return email
    }()
    
    private lazy var firstNameField: UITextField = {
        let email = UITextField()
        email.autocapitalizationType = .none
        email.autocorrectionType = .no
        email.returnKeyType = .continue
        email.layer.cornerRadius = 12
        email.layer.borderWidth = 1
        email.layer.borderColor = UIColor.lightGray.cgColor
        email.placeholder = "First Name..."
        email.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 0))
        email.leftViewMode = .always
        email.backgroundColor = .white
        
        email.delegate = self
        
        return email
    }()
    
    private lazy var lastNameField: UITextField = {
        let email = UITextField()
        email.autocapitalizationType = .none
        email.autocorrectionType = .no
        email.returnKeyType = .continue
        email.layer.cornerRadius = 12
        email.layer.borderWidth = 1
        email.layer.borderColor = UIColor.lightGray.cgColor
        email.placeholder = "Last Name..."
        email.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 0))
        email.leftViewMode = .always
        email.backgroundColor = .white
        
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
        password.backgroundColor = .white
        
        password.delegate = self
        
        return password
    }()
    
    private lazy var loginButton:UIButton = {
        let button = UIButton()
        button.setTitle("Register", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        button.addTarget(self, action: #selector(registerButtonTapped), for: .touchUpInside)
        return button
    }()
    override func viewDidLoad() {
        title = "Create an Account"
        view.backgroundColor = .white
        
        
        
        // add subviews
        
        view.addSubview(scrollview)
        scrollview.addSubview(imageView)
        scrollview.addSubview(firstNameField)
        scrollview.addSubview(lastNameField)
        scrollview.addSubview(emailField)
        scrollview.addSubview(passwordField)
        scrollview.addSubview(loginButton)
        
        let gesture = UIGestureRecognizer(target: self, action: #selector(didTapChangeProfilePic))
        imageView.addGestureRecognizer(gesture)
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollview.frame = view.bounds
        let size = scrollview.width/3
        imageView.frame = CGRect(x: (scrollview.width-size)/2, y: 20, width: size, height: size)
        
        firstNameField.frame = CGRect(x: 30, y: imageView.bottom+60, width: scrollview.width-60 , height: 52)
        lastNameField.frame = CGRect(x: 30, y: firstNameField.bottom+20, width: scrollview.width-60 , height: 52)
        emailField.frame = CGRect(x: 30, y: lastNameField.bottom+20, width: scrollview.width-60 , height: 52)
        
        passwordField.frame = CGRect(x: 30, y: emailField.bottom+20, width: scrollview.width-60 , height: 52)
        loginButton.frame = CGRect(x: 30, y: passwordField.bottom+20, width: scrollview.width-60 , height: 52)
        
    }
    
    
    @objc private func didTapChangeProfilePic(){
        
        print("gesture called")
    }
    
    @objc private func registerButtonTapped(){
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        firstNameField.resignFirstResponder()
        lastNameField.resignFirstResponder()
        
        guard let email = emailField.text,
              let password = passwordField.text,
              let name = firstNameField.text,
              let last = lastNameField.text,
              !email.isEmpty, !password.isEmpty,!name.isEmpty, !last.isEmpty, password.count >= 6 else { alertUserLoginError()
            return }
        // FireBase log in
        
    }
    
    func alertUserLoginError(){
        let alert = UIAlertController(title: "Wooops", message: "Please enter all information to create a new account", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    @objc private func didTapRegister(){
        let vc = RegisterViewController()
        vc.title = "Create Account"
        navigationController?.pushViewController(vc, animated: true)
    }
}


extension RegisterViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField{
            passwordField.becomeFirstResponder()
        } else if textField == passwordField {
            registerButtonTapped()
        }
        return true
    }
}
