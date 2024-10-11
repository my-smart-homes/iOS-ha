import PromiseKit
import Shared
import UIKit
import WebKit

protocol OnboardingAuthLoginViewController: UIViewController {
    var promise: Promise<URL> { get }
    init(authDetails: OnboardingAuthDetails)
}

class OnboardingAuthLoginViewControllerImpl: UIViewController, OnboardingAuthLoginViewController, WKNavigationDelegate {
    let authDetails: OnboardingAuthDetails
    let promise: Promise<URL>
    private let resolver: Resolver<URL>
    private let webView: WKWebView = {
        let configuration = WKWebViewConfiguration()
        configuration.applicationNameForUserAgent = HomeAssistantAPI.applicationNameForUserAgent

        return WKWebView(frame: .zero, configuration: configuration)
    }()

    required init(authDetails: OnboardingAuthDetails) {
        (self.promise, self.resolver) = Promise<URL>.pending()
        self.authDetails = authDetails
        super.init(nibName: nil, bundle: nil)

        title = authDetails.url.host

        isModalInPresentation = true

        let appearance = with(UINavigationBarAppearance()) {
            $0.configureWithOpaqueBackground()
        }

        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance
        navigationItem.compactScrollEdgeAppearance = appearance

        navigationItem.leftBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel)),
        ]

        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refresh)),
        ]
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    @objc private func cancel() {
        resolver.reject(PMKError.cancelled)
    }

    @objc private func refresh() {
        webView.load(.init(url: authDetails.url))
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        webView.navigationDelegate = self

        setContentScrollView(webView.scrollView)

        view.backgroundColor = .systemBackground
        edgesForExtendedLayout = []

        view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        refresh()
    }

    func webView(
        _ webView: WKWebView,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        let result = authDetails.exceptions.evaluate(challenge)
        completionHandler(result.0, result.1)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        resolver.reject(error)
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        if let url = navigationAction.request.url, url.scheme?.hasPrefix("mysmarthomes") == true {
            resolver.fulfill(url)
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }
        // inject js on page load
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("Page has finished loading.")
        injectAutoLoginScript()
    }
    
    private func injectAutoLoginScript() {
            // Escape username and password to avoid special character issues
            let escapedUsername = "bulent".replacingOccurrences(of: "\"", with: "\\\"")
            let escapedPassword = "password2024".replacingOccurrences(of: "\"", with: "\\\"")

            // Define the JavaScript for autofilling and triggering login
            let jsScript = """
            (function() {
                let found = false;

                function checkInputElement() {
                    if (found) { return; }

                    var inputElement = document.querySelector('input[name="username"]');
                    if (inputElement) {
                        found = true;
                        console.log("Input element found");
                        doSignIn();
                    } else {
                        console.log("Input element not found");
                    }
                }

                function doSignIn() {
                    var usernameInput = document.querySelector('input[name="username"]');
                    var passwordInput = document.querySelector('input[name="password"]');
                    var loginButton = document.querySelector('mwc-button');

                    usernameInput.value = "\(escapedUsername)";
                    var usernameEvent = new Event('input', { bubbles: true });
                    usernameInput.dispatchEvent(usernameEvent);

                    passwordInput.value = "\(escapedPassword)";
                    var passwordEvent = new Event('input', { bubbles: true });
                    passwordInput.dispatchEvent(passwordEvent);

                    // Add a slight delay before clicking the login button
                    setTimeout(function() {
                        var clickEvent = new MouseEvent('click', {
                            view: window,
                            bubbles: true,
                            cancelable: true
                        });
                        loginButton.dispatchEvent(clickEvent);
                    }, 100); // 100 milliseconds delay
                }

                setInterval(checkInputElement, 1000);
            })();
            """

            // Inject JavaScript into the web view
            webView.evaluateJavaScript(jsScript) { result, error in
                if let error = error {
                    print("JavaScript injection failed: \(error)")
                } else {
                    print("JavaScript executed successfully")
                }
            }
        }

}

#if DEBUG
extension OnboardingAuthLoginViewControllerImpl {
    var webViewForTests: WKWebView {
        webView
    }
}
#endif
