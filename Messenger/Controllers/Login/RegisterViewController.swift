//
//  RegisterViewController.swift
//  Messenger
//
//  Created by Hamed on 6/18/1400 AP.
//

import UIKit
import FirebaseAuth

class RegisterViewController: UIViewController {
    
    private lazy var scrollview: UIScrollView = {
        let scroll = UIScrollView()
        scroll.clipsToBounds = true
        scroll.isUserInteractionEnabled = true
        return scroll
    }()
    
    private lazy var imageView: UIImageView = {
        let image = UIImageView()
        image.image = UIImage(systemName: "person.circle")
        image.tintColor = .systemBlue
        image.isUserInteractionEnabled = true
        image.contentMode = .scaleAspectFit
        image.layer.masksToBounds = true
        image.layer.borderWidth = 2
        image.layer.borderColor = UIColor.systemBlue.cgColor
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
        let firstName = UITextField()
        firstName.autocapitalizationType = .none
        firstName.autocorrectionType = .no
        firstName.returnKeyType = .continue
        firstName.layer.cornerRadius = 12
        firstName.layer.borderWidth = 1
        firstName.layer.borderColor = UIColor.lightGray.cgColor
        firstName.placeholder = "First Name..."
        firstName.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 0))
        firstName.leftViewMode = .always
        firstName.backgroundColor = .white
        
        firstName.delegate = self
        
        return firstName
    }()
    
    private lazy var lastNameField: UITextField = {
        let firstName = UITextField()
        firstName.autocapitalizationType = .none
        firstName.autocorrectionType = .no
        firstName.returnKeyType = .continue
        firstName.layer.cornerRadius = 12
        firstName.layer.borderWidth = 1
        firstName.layer.borderColor = UIColor.lightGray.cgColor
        firstName.placeholder = "Last Name..."
        firstName.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 0))
        firstName.leftViewMode = .always
        firstName.backgroundColor = .white
        
        firstName.delegate = self
        
        return firstName
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
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(didTapChangeProfilePic))
        imageView.addGestureRecognizer(gesture)
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollview.frame = view.bounds
        let size = scrollview.width/3
        imageView.frame = CGRect(x: (scrollview.width-size)/2, y: 20, width: size, height: size)
        imageView.layer.cornerRadius = imageView.width/2.0
        
        firstNameField.frame = CGRect(x: 30, y: imageView.bottom+60, width: scrollview.width-60 , height: 52)
        lastNameField.frame = CGRect(x: 30, y: firstNameField.bottom+20, width: scrollview.width-60 , height: 52)
        emailField.frame = CGRect(x: 30, y: lastNameField.bottom+20, width: scrollview.width-60 , height: 52)
        
        passwordField.frame = CGRect(x: 30, y: emailField.bottom+20, width: scrollview.width-60 , height: 52)
        loginButton.frame = CGRect(x: 30, y: passwordField.bottom+20, width: scrollview.width-60 , height: 52)
        
    }
    
    
    @objc private func didTapChangeProfilePic(){
        
        presentPhotoActionSheet()
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
        DatabaseManager.shared.userExists(with: email) { [weak self] exist in
            guard let strongSelf = self else { return }

            if !exist {
                FirebaseAuth.Auth.auth().createUser(withEmail: email, password: password, completion:  {  authResult , error in
                    
                    guard authResult != nil, error == nil else {
                        print(" create user error")
                        return
                    }
                    
                    DatabaseManager.shared.insertUser(with: ChatAppUser(firstName: name, lastName: last, emailAddress: email))
                    
                    
                    strongSelf.navigationController?.dismiss(animated: true, completion: nil)
                })
            } else {
                // User already exist
                strongSelf.alertUserLoginError(message: "Looks like a user account for that email address already exists.")
                return
            }
            
          
        }
        
        
    }
    
    func alertUserLoginError(message: String = "Please enter all information to create a new account") {
        let alert = UIAlertController(title: "Wooops", message: message , preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    @objc private func didTapRegister() {
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

extension RegisterViewController: UIImagePickerControllerDelegate,  UINavigationControllerDelegate {
    
    func presentPhotoActionSheet(){
        let actionSheet = UIAlertController(title: "Profile Picture", message: "How would you like to select a picture", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        actionSheet.addAction(UIAlertAction(title: "Take Photo", style: .default, handler: { [weak self] _ in
            self?.presentCamera()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "choose Photo", style: .default, handler: { [weak self] _ in
            self?.presentPhotoPicker()
        }))
        present(actionSheet, animated: true)
    }
    
    func presentCamera(){
        let vc = UIImagePickerController()
        vc.delegate = self
        vc.sourceType = .camera
        vc.allowsEditing = true
        present(vc, animated: true)
    }
    
    func presentPhotoPicker(){
        let vc = UIImagePickerController()
        vc.delegate = self
        vc.sourceType = .photoLibrary
        vc.allowsEditing = true
        present(vc, animated: true)
    }
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let selectedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage else {return}
        self.imageView.image = selectedImage
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
