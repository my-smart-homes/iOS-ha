import Foundation
import UIKit

class VersionChecker {
    
    static let shared = VersionChecker()
    
    private let currentVersionCode = 1 // Define the current version code here
    
    private init() {}
    
    func checkForUpdate(from viewController: UIViewController) {
        guard let url = URL(string: "https://my-smart-homes.github.io/app-landing/version.json") else {
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching version data: \(error)")
                return
            }
            
            guard let data = data else {
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let latestVersionCode = json["latest_version_code"] as? Int,
                   let latestVersion = json["latest_version"] as? String {
                    
                    // Check if the latest version code is greater than current version code
                    if latestVersionCode > self.currentVersionCode {
                        DispatchQueue.main.async {
                            self.showUpdateAlert(from: viewController, latestVersion: latestVersion)
                        }
                    }
                }
            } catch {
                print("Error parsing JSON: \(error)")
            }
        }
        
        task.resume()
    }
    
    private func showUpdateAlert(from viewController: UIViewController, latestVersion: String) {
        let alert = UIAlertController(title: "Update Available", message: "A new version \(latestVersion) is available. Please update to continue.", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Update", style: .default) { _ in
            if let url = URL(string: "https://my-smart-homes.github.io/app-landing/") {
                UIApplication.shared.open(url)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        viewController.present(alert, animated: true)
    }
}
