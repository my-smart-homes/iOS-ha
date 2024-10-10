import Eureka
import FirebaseAuth
import Shared
import UIKit
import SwiftUI
import FirebaseFirestore


class OnboardingLoginViewController: UIViewController, OnboardingViewController, UITextFieldDelegate {
    
    let emailTextField = UITextField()
    let passwordTextField = UITextField()
    var activityIndicator = UIActivityIndicatorView(style: .large)
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    var preferredBarAppearance: OnboardingBarAppearance { .hidden }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.black // Definindo fundo preto para a tela
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(stackView)
        
        // Logo (não foi fornecido no exemplo, então adicionei um placeholder)
        let logoLabel = UILabel()
        logoLabel.text = "Log in"
        logoLabel.font = UIFont.boldSystemFont(ofSize: 28)
        logoLabel.textColor = .white
        stackView.addArrangedSubview(logoLabel)
        
        // Email Field
        emailTextField.delegate = self
        emailTextField.backgroundColor = UIColor(white: 1, alpha: 0.1)
        emailTextField.borderStyle = .roundedRect
        emailTextField.placeholder = "Email"
        emailTextField.textColor = .white
        emailTextField.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        emailTextField.setHeight(48)
        emailTextField.setWidth(300)
        emailTextField.tintColor = .white
        emailTextField.keyboardAppearance = .dark
        
        // Adiciona o placeholder com cor cinza claro
        emailTextField.attributedPlaceholder = NSAttributedString(string: "Email", attributes: [
            .foregroundColor: UIColor.lightGray
        ])
        
        stackView.addArrangedSubview(emailTextField)
        
        // Password Field
        passwordTextField.delegate = self
        passwordTextField.backgroundColor = UIColor(white: 1, alpha: 0.1)
        passwordTextField.borderStyle = .roundedRect
        passwordTextField.placeholder = "Password"
        passwordTextField.textColor = .white
        passwordTextField.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        passwordTextField.setHeight(48)
        passwordTextField.setWidth(300)
        passwordTextField.tintColor = .white
        passwordTextField.isSecureTextEntry = true
        passwordTextField.keyboardAppearance = .dark
        
        passwordTextField.attributedPlaceholder = NSAttributedString(string: "Password", attributes: [
            .foregroundColor: UIColor.lightGray
        ])
        
        stackView.addArrangedSubview(passwordTextField)
        
        // Login Button
        let loginButton = UIButton(type: .custom)
        loginButton.setTitle("Log in", for: .normal)
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.backgroundColor = UIColor.systemBlue
        loginButton.layer.cornerRadius = 10
        loginButton.setHeight(50)
        loginButton.setWidth(300)
        loginButton.addTarget(self, action: #selector(loginTapped(_:)), for: .touchUpInside)
        stackView.addArrangedSubview(loginButton)
        
        // Forgot Password Button
        let forgotPasswordButton = UIButton(type: .system)
        forgotPasswordButton.setTitle("Forgot Password?", for: .normal)
        forgotPasswordButton.setTitleColor(.lightGray, for: .normal)
        forgotPasswordButton.addTarget(self, action: #selector(forgotPasswordTapped(_:)), for: .touchUpInside)
        stackView.addArrangedSubview(forgotPasswordButton)
        
        // Sign Up Button
        let signUpButton = UIButton(type: .system)
        signUpButton.setTitle("Sign up", for: .normal)
        signUpButton.setTitleColor(.white, for: .normal)
        signUpButton.layer.borderColor = UIColor.white.cgColor
        signUpButton.layer.borderWidth = 1
        signUpButton.layer.cornerRadius = 10
        signUpButton.setHeight(50)
        signUpButton.setWidth(300)
        signUpButton.addTarget(self, action: #selector(signUpTapped(_:)), for: .touchUpInside)
        stackView.addArrangedSubview(signUpButton)
        
        // Activity Indicator (Loader)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    
    
    @objc private func loginTapped(_ sender: UIButton) {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            showAlert(title: "Error", message: "Please enter both email and password.")
            return
        }
        
        print("Fetching Server Time")
        fetchServerTime { [weak self] serverTime, error in
            guard let self = self else { return }
            
            if let error = error {
                self.showAlert(title: "Error", message: "Failed to fetch server time: \(error.localizedDescription)")
                return
            }
            
            guard let serverTime = serverTime else {
                self.showAlert(title: "Error", message: "Failed to retrieve server time.")
                return
            }
            
            // Mostrar o loader enquanto faz login
            activityIndicator.startAnimating()
            
            // Realizar login com Firebase Authentication
            Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
                guard let self = self else { return }
                
                // Parar o loader após a resposta
                self.activityIndicator.stopAnimating()
                
                if let error = error {
                    // Exibir mensagem de erro
                    self.showAlert(title: "Login Failed", message: error.localizedDescription)
                    return
                }
                
                
                // Login successful, print to the console
                print("Login Success")
                if let userId = authResult?.user.uid {
                    print("Logged in user ID: \(userId)")
                    
                    // Call function to fetch user data from Firestore
                    self.fetchUserData(userId: userId){ userData in
                        guard let userData = userData else{
                            self.showAlert(title: "Error", message: "Failed to retrieve user data.")
                            return
                        }
                        
                        // Perform the checks after fetching the user data
                        guard let webviewUsername = userData["webview_username"] as? String, !webviewUsername.isEmpty,
                              let webviewPassword = userData["webview_password"] as? String, !webviewPassword.isEmpty,
                              let externalUrl = userData["external_url"] as? String, !externalUrl.isEmpty,
                              let expirationDateTimestamp = userData["expirationDate"] as? Timestamp else {
                            self.showAlert(title: "Missing Information", message: "One or more account details are missing.")
                            return
                        }

                        let expirationDate = expirationDateTimestamp.dateValue()

                        if expirationDate < serverTime {
                            self.showAlert(title: "Subscription Expired", message: "Your subscription has expired. Please renew to continue.")
                            return
                        }
                        
                        // If all checks pass, assign the external URL and proceed with navigation
                        OnboardingManualURLViewController.externalURL = externalUrl
                        // Navigate to the next screen
                        self.show(OnboardingManualURLViewController(), sender: self)
                    }
                }
            }
        }
        
    }
    
    @objc private func forgotPasswordTapped(_ sender: UIButton) {
        // Lógica para recuperação de senha
    }
    
    @objc private func signUpTapped(_ sender: UIButton) {
        // Lógica para ir para a tela de cadastro
    }
    
    // Método para exibir alertas
    private func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    // Function to fetch additional user data from Firestore
    private func fetchUserData(userId: String, completion: @escaping ([String: Any]?) -> Void){
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)
        
        userRef.getDocument { document, error in
            if let document = document, document.exists {
                let data = document.data()
                completion(data)
            }else{
                print("No document found or error: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
            }
        }
    }
    
    func fetchServerTime(completion: @escaping (Date?, Error?) -> Void) {
        let docRef = Firestore.firestore().collection("server-time").document("current-time")
        
        docRef.setData(["timestamp": FieldValue.serverTimestamp()]) { error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            docRef.getDocument { (document, error) in
                if let error = error {
                    completion(nil, error)
                    return
                }
                
                guard let document = document, document.exists, let serverTimestamp = document.data()?["timestamp"] as? Timestamp else {
                    completion(nil, NSError(domain: "ServerTime", code: 404, userInfo: [NSLocalizedDescriptionKey: "Failed to retrieve server time."]))
                    return
                }
                
                let serverTime = serverTimestamp.dateValue()
                completion(serverTime, nil)
            }
        }
    }
}
