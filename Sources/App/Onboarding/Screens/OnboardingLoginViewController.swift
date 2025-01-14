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
        guard validateInputs() else { return }
        fetchServerTimeAndLogin()
    }

    private func validateInputs() -> Bool {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            showAlert(title: "Error", message: "Please enter both email and password.")
            return false
        }
        return true
    }

    private func fetchServerTimeAndLogin() {
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

            self.performLogin(serverTime: serverTime)
        }
    }

    private func performLogin(serverTime: Date) {
        activityIndicator.startAnimating()

        guard let email = emailTextField.text,
              let password = passwordTextField.text else { return }

        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self = self else { return }
            
            self.activityIndicator.stopAnimating()

            if let error = error {
                self.showAlert(title: "Login Failed", message: error.localizedDescription)
                return
            }

            print("Login Success")
            if let userId = authResult?.user.uid {
                print("Logged in user ID: \(userId)")
                self.fetchUserData(userId: userId) { userData in
                    self.handleUserData(userId, userData, serverTime)
                }
            }
        }
    }

    private func handleUserData(_ userId: String, _ userData: [String : Any]?, _ serverTime: Date) {
        guard let userData = userData else {
            showAlert(title: "Error", message: "Failed to retrieve user data.")
            return
        }

        guard let subscription = userData["subscription"] as? [String: Any],
              let expirationDateTimestamp = subscription["expiresAt"] as? Timestamp else {
            showAlert(title: "Missing Subscription Info", message: "This id doesnt have scbuscription expiry record.")
            return;
        }

        let expirationDate = expirationDateTimestamp.dateValue()

        if expirationDate < serverTime {
            showAlert(title: "Subscription Expired", message: "Your subscription has expired. Please renew to continue.")
            return
        }
        
        // fetch first server pass
        let serverPassCollection = Firestore.firestore()
            .collection("users").document(userId)
            .collection("serverPasswords")
        
        serverPassCollection.limit(to: 1).getDocuments{snapshot, error in
            guard error == nil, let document = snapshot?.documents.first else {
                self.showAlert(title: "Error", message: "Failed to fetch server password")
                return
            }
            
            let encryptedPass = document.get("encryptedPass") as? String
            let serverPassDocId = document.documentID
            
            guard let encryptedPass = encryptedPass else{
                self.showAlert(title: "Error", message: "Password not found.")
                return
            }
            
            let secret = MshSecret()
            let decryption = AESDecryption(key: secret.MSH_AES_KEY,
                                           iv: secret.MSH_AES_IV,
                                               encryptedText: encryptedPass)
            guard let decrypted = decryption.decrypt() else {
                print("Failed to decrypt the string.")
                self.showAlert(title: "Error", message: "Decryption failed.")
                return
            }
            
            if let email = userData["email"] as? String {
                self.fetchServerUrl(serverPassDocId, decrypted, email)
            }else{
                self.showAlert(title: "Error", message: "Username Missing for user")
            }
            
        }
    }
    
    private func fetchServerUrl(_ serverDocId: String, _ webviewPassword: String,_ email: String){
        let serverRef = Firestore.firestore().collection("servers").document(serverDocId)
        serverRef.getDocument{ document, error in
            if let document = document, document.exists {
                if let data = document.data() {
                    let internalURl = data["internalUrl"] as? String
                    let externalUrl = data["externalUrl"] as? String
                    OnboardingManualURLViewController.externalURL = externalUrl
                    OnboardingAuthLoginViewControllerImpl.webViewUserName = email
                    OnboardingAuthLoginViewControllerImpl.webViewPassword = webviewPassword

                    // Navigate to the next screen
                    self.show(OnboardingManualURLViewController(), sender: self)
                } else {
                    self.showAlert(title: "Error", message: "Document data is nil or invalid.")
                }
                
            }else{
                self.showAlert(title: "Error", message: "Getting Server Doc")
            }
        
        }
        
//        userRef.getDocument { document, error in
//            if let document = document, document.exists {
//                let data = document.data()
//                completion(data)
//            }else{
//                print("No document found or error: \(error?.localizedDescription ?? "Unknown error")")
//                completion(nil)
//            }
//        }
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
        let urlString = "https://getservertime-jrskleaqea-uc.a.run.app"
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL.")
            DispatchQueue.main.async {
                completion(nil, NSError(domain: "ServerTime", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL."]))
            }
            return
        }
        
        print("URL is valid, starting data task.")
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error in data task:", error.localizedDescription)
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            
            guard let data = data else {
                print("No data received from server.")
                DispatchQueue.main.async {
                    completion(nil, NSError(domain: "ServerTime", code: 404, userInfo: [NSLocalizedDescriptionKey: "No data received from server."]))
                }
                return
            }
            
            do {
                let json = try JSONDecoder().decode([String: String].self, from: data)
                print("JSON parsed successfully:", json)
                
                if let timeString = json["time"] {
                    print("Time string received:", timeString)
                    
                    let formatter = ISO8601DateFormatter()
                    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds] // Ensure it parses fractional seconds
                    
                    if let serverTime = formatter.date(from: timeString) {
                        print("Converted server time:", serverTime)
                        DispatchQueue.main.async {
                            completion(serverTime, nil)
                        }
                    } else {
                        print("Failed to convert time string to Date.")
                        DispatchQueue.main.async {
                            completion(nil, NSError(domain: "ServerTime", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to parse server time."]))
                        }
                    }
                } else {
                    print("No 'time' field in JSON response.")
                    DispatchQueue.main.async {
                        completion(nil, NSError(domain: "ServerTime", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to parse server time."]))
                    }
                }
            } catch {
                print("JSON parsing error:", error.localizedDescription)
                DispatchQueue.main.async {
                    completion(nil, NSError(domain: "ServerTime", code: 500, userInfo: [NSLocalizedDescriptionKey: "JSON parsing error: \(error.localizedDescription)"]))
                }
            }
        }
        
        task.resume()
        print("Data task started.")
    }



}
