
import UIKit

class InternetConnection: NSObject {

    static var reachability: Reachability?
    static var offlineLabel: UILabel?
    static var message = "OFFLINE MODE - NO INTERNET CONNECTION"
    
    var internetAppear: ((Reachability) -> Void)?
    var internetDisappear: ((Reachability) -> Void)?
    
    static func start() {
        do {
            reachability = try Reachability()
        } catch { }

        reachability!.whenReachable = { reachability in

            InternetConnection.configureInternetConnectionLabel()

            if let label = offlineLabel {
                label.isHidden = true
            }

            if reachability.connection == .wifi {
                print("Reachable via WiFi")
            } else {
                print("Reachable via Cellular")
            }
            
            UserManager.current.start()
        }
        reachability!.whenUnreachable = { _ in
            print("Not reachable")

            InternetConnection.configureInternetConnectionLabel()

            if let label = offlineLabel {
                label.isHidden = false
            }
        }

        do {
            try reachability!.startNotifier()
        } catch {
            print("Unable to start notifier")
        }
    }
    static func stop() {
        reachability!.stopNotifier()
    }

    static func isOnline() -> Bool {
        return reachability?.connection != .unavailable
    }

    static func configureInternetConnectionLabel() {
        
        if offlineLabel == nil, let delegate = UIApplication.shared.delegate as? AppDelegate, let window = delegate.window {
            offlineLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 30))
            offlineLabel!.isHidden = true
            offlineLabel!.backgroundColor = UIColor.red
            offlineLabel!.text = message
            offlineLabel!.textColor = UIColor.white
            offlineLabel!.textAlignment = .center

            window.addSubview(offlineLabel!)

            offlineLabel!.translatesAutoresizingMaskIntoConstraints = false
            offlineLabel!.rightAnchor.constraint(equalTo: window.rightAnchor, constant: 0).isActive = true
            offlineLabel!.leftAnchor.constraint(equalTo: window.leftAnchor, constant: 0).isActive = true
            offlineLabel!.bottomAnchor.constraint(equalTo: window.bottomAnchor, constant: 0).isActive = true
            offlineLabel!.heightAnchor.constraint(equalToConstant: 18).isActive = true
        }
        
    }
}
