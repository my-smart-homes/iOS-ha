import Eureka
import RealmSwift
import Shared
import UIKit
import SwiftUI

class OnboardingWelcomeViewController: UIViewController, OnboardingViewController {
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    var preferredBarAppearance: OnboardingBarAppearance { .hidden }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.black // Mantenha o fundo atual ou ajuste conforme necessário
        
            // Stack view para centralizar os itens
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(stackView)
        
            // Adiciona o logo centralizado
        let logoImageView = UIImageView(image: Asset.SharedAssets.logo.image)
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.setHeight(200)
        logoImageView.setWidth(200) // Ajuste o tamanho conforme necessário
        stackView.addArrangedSubview(logoImageView)
        
            // Título de boas-vindas
        let welcomeLabel = UILabel()
        welcomeLabel.text = L10n.Onboarding.Welcome.title("")
        welcomeLabel.font = UIFont.boldSystemFont(ofSize: 28) // Ajuste o tamanho da fonte
        welcomeLabel.textColor = .white // Ajuste a cor do texto conforme necessário
        welcomeLabel.textAlignment = .center
        stackView.addArrangedSubview(welcomeLabel)
        
            // Adiciona um botão "Continue"
        let continueButton = UIButton(type: .custom)
        continueButton.setTitle(L10n.continueLabel, for: .normal)
        continueButton.setTitleColor(.white, for: .normal)
        continueButton.backgroundColor = UIColor.systemBlue
        continueButton.layer.cornerRadius = 10
        continueButton.setHeight(50)
        continueButton.setWidth(300)
        continueButton.addTarget(self, action: #selector(continueTapped(_:)), for: .touchUpInside)
        stackView.addArrangedSubview(continueButton)
        
            // Centraliza o stack view na tela
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    @objc private func continueTapped(_ sender: UIButton) {
        show(OnboardingLoginViewController(), sender: self)
    }
}
