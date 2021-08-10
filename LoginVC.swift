
import UIKit
import GoogleSignIn
import FBSDKLoginKit
import AuthenticationServices

class LoginVC: UIViewController, ASAuthorizationControllerPresentationContextProviding, ASAuthorizationControllerDelegate {

    @IBOutlet weak var userNameLabel: CustomTextField!
    @IBOutlet weak var passwordLabel: CustomTextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var appleFakeButton: UIButton!
    @IBOutlet weak var showPasswordButton: UIButton!
    
    private var signupAppleRequest:LoginRequest?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance()?.presentingViewController = self
        GIDSignIn.sharedInstance()?.restorePreviousSignIn()
        
        
        #if targetEnvironment(simulator)
            userNameLabel.text = "tester@example.com"
            passwordLabel.text = "123123"
        #endif
        
        if #available(iOS 13.0, *) {
            appleFakeButton.isHidden = false
        }
        else {
            appleFakeButton.isHidden = true
        }       
        
    }
    
    @IBAction func showPasswordTapHandler(_ sender: Any) {
        showPasswordButton?.isSelected = !(showPasswordButton?.isSelected ?? false)
        passwordLabel?.isSecureTextEntry = !(showPasswordButton?.isSelected ?? false)
    }
    
    @IBAction func forgotPasswordTapHandler(_ sender: Any) {
        let forgotPasswordVC = Authorization.VC(ViewControllerName.ForgotPassword)
        self.navigationController?.pushViewController(forgotPasswordVC, animated: true)
    }
    
    @IBAction func loginTapHandler(_ sender: Any) {
        login()
    }
    
    @IBAction func signupTapHandler(_ sender: Any) {
        //GIDSignIn.sharedInstance().signIn()
        let signupVC = Authorization.VC(ViewControllerName.Signup) as! SignupVC
        signupVC.actionDelegate = self
        self.navigationController?.pushViewController(signupVC, animated: true)
    }
    
    @IBAction func loginAppleTapHandler(_ sender: Any) {
        if #available(iOS 13.0, *) {
            appleLogin()
        } 
    }
    
    @IBAction func loginGoogleTapHandler(_ sender: Any) {
        GIDSignIn.sharedInstance()?.presentingViewController = self
        GIDSignIn.sharedInstance().signIn()
    }
    
    @IBAction func loginFacebookTapHandler(_ sender: Any) {
        facebookSignup()
    }
    
    private var loginRequest:LoginRequest?
    private var facebookLoginRequest:LoginRequest?
    private var googleLoginRequest:LoginRequest?
    
    private func login() {
        let loginRequest = LoginRequest()
        self.loginRequest = loginRequest
        self.loginRequest?.login(email: userNameLabel.text ?? "",
                                 password: passwordLabel.text ?? "",
                                 completion: {[weak self, weak loginRequest] (loginModel:LoginModel?, message:String?) in
            guard let self = self else {return}
            guard let loginRequest = loginRequest, loginRequest === self.loginRequest else {return}
            
            self.loginRequest = nil
            
            if nil != loginModel {
                LoginModel.current = loginModel
                self.showMain()
            }
            else {
                
                if (message != nil && message!.contains("Validation Error.")){
                    self.showAlert(withMessage: "Validation error".localized)
                }else{
                    self.showAlert(withMessage: message ?? "")
                }
                
            }
        })
    }
    
    private func showMain(){
        if let window = UIApplication.shared.keyWindow {
            let vc = Main.instantiateViewController(withIdentifier: "MainTabBarVC")
            window.rootViewController = vc
            window.makeKeyAndVisible()
        }
    }
}

    //MARK: - Facebook Login

extension LoginVC {
    
    func facebookSignup() {
        let fbmanager = LoginManager()
        fbmanager.logOut()
        fbmanager.logIn(permissions: ["email"], from: self) { (result, error) in
            if error != nil {
                
            }
            else if (result?.isCancelled)! {
                
                
            }
            else {
                if let token = AccessToken.current {
                    print(token.tokenString)
                    
                    let facebookLoginRequest = LoginRequest()
                    self.loginRequest = facebookLoginRequest
                    facebookLoginRequest.facebookLogin(token: token.tokenString,
                                                       completion: {[weak self, weak facebookLoginRequest]
                                                        (loginModel:LoginModel?, message:String?) in
                        guard let self = self else {return}
                        guard let loginRequest = facebookLoginRequest, loginRequest === self.loginRequest else {return}
                        
                        self.facebookLoginRequest = nil
                                                        
                        if nil != loginModel {
                            LoginModel.current = loginModel
                            self.showMain()
                        }
                        else{
                            self.showAlert(withMessage: message ?? "")
                        }
                    })
                    
                } else {
                    print("Access Token not created !!")
                }
            }
        }
    }
    
}

    //MARK: - Google Login

extension LoginVC: GIDSignInDelegate {
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let error = error {
          if (error as NSError).code == GIDSignInErrorCode.hasNoAuthInKeychain.rawValue {
            print("The user has not signed in before or they have since signed out.")
          } else {
            print("\(error.localizedDescription)")
          }
          return
        }
               
        let userId = user.userID                  
        let idToken = user.authentication.idToken 
        print("access token: \(idToken ?? "")")
        let fullName = user.profile.name
        let givenName = user.profile.givenName
        let familyName = user.profile.familyName
        let email = user.profile.email
        
        
        let googleLoginRequest = LoginRequest()
        self.googleLoginRequest = googleLoginRequest
        googleLoginRequest.googleLogin(token: idToken!,
                                         completion: {[weak self, weak googleLoginRequest]
                                            (loginModel:LoginModel?, message:String?) in
            guard let self = self else {return}
            guard let loginRequest = googleLoginRequest, loginRequest === self.googleLoginRequest else {return}
            
            self.googleLoginRequest = nil
            
            if nil != loginModel {
                LoginModel.current = loginModel
                self.showMain()
            }
            else{
                self.showAlert(withMessage: message?.localized ?? "")
            }
        })
        
        
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!,
              withError error: Error!) {
        NSLog("didDisconnectWith")     
    }
}

extension LoginVC: SignupVCDelegate{
    func signupVCDidAppleLogin(sender: SignupVC) {
        if #available(iOS 13.0, *) {
            appleLogin()
        }
    }
    
    func signupVCDidSignup(sender: SignupVC, loginModel: LoginModel) {
        LoginModel.current = loginModel
        
        if let welcomeVC = Welcome.VC(.Welcome) as? WelcomeVC {
            welcomeVC.actionDelegate = self
            welcomeVC.modalPresentationStyle = .fullScreen
            self.present(welcomeVC, animated: false, completion: {})
        }
    }
}

extension LoginVC: WelcomeVCDelegate{
    func welcomeVCDidClose(sender: WelcomeVC) {
        self.showMain()
    }
}

    // MARK:- Apple Login Methods

extension LoginVC  {
    
    @available(iOS 13.0, *)
    private func appleLogin() {
        
        //request
        let appleIdProvider = ASAuthorizationAppleIDProvider()
        let authoriztionRequest = appleIdProvider.createRequest()
        authoriztionRequest.requestedScopes = [.fullName, .email]
        
        //Apple’s Keychain sign in
        let passwordProvider = ASAuthorizationPasswordProvider()
        let passwordRequest = passwordProvider.createRequest()
        
        //create authorization controller
        let authorizationController = ASAuthorizationController(authorizationRequests: [authoriztionRequest]) //[authoriztionRequest, passwordRequest]
        authorizationController.presentationContextProvider = self
        authorizationController.delegate = self
        authorizationController.performRequests()
    }
    
    
    @available(iOS 13.0, *)
    private func handleAppleIDAuthorization(appleIDCredential: ASAuthorizationAppleIDCredential?, passwordCredential: ASPasswordCredential?) {
        if let appleIDCredential = appleIDCredential {
            
            let userIdentifier = appleIDCredential.user
            if let identityTokenData = appleIDCredential.identityToken,
                let identityTokenString = String(data: identityTokenData, encoding: .utf8) {
                print("Identity Token \(identityTokenString)")
            }
            
            //Check apple credential state
            let authorizationAppleIDProvider = ASAuthorizationAppleIDProvider()
            
            authorizationAppleIDProvider.getCredentialState(forUserID: userIdentifier) { [weak self] (credentialState: ASAuthorizationAppleIDProvider.CredentialState, error: Error?) in
                guard let self = self else { return }
                
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    
                    if let error = error {
                        print(error)
                        // Something went wrong check error state
                        GlobalFunctions.shared.showAlert(message: "Something went wrong!")
                        return
                    }
                    
                    switch (credentialState) {
                    case .authorized:
                        
                        var fullName = "\(appleIDCredential.fullName?.givenName ?? "") \(appleIDCredential.fullName?.familyName ?? "")"
                        if appleIDCredential.fullName?.givenName == "" && appleIDCredential.fullName?.familyName == "" {
                            fullName = ""
                        }
                        
                        let loginRequest = LoginRequest()
                        self.signupAppleRequest = loginRequest
                        self.signupAppleRequest?.appleLogin(email: appleIDCredential.email,
                                                            name: fullName,
                                                            userID: userIdentifier,
                                                   completion: {[weak self, weak loginRequest] (success:Bool, loginModel:LoginModel?, registerErrorModel:RegisterErrorModel?, message:String?) in
                            guard let self = self else {return}
                            guard let loginRequest = loginRequest, loginRequest === self.signupAppleRequest else {return}
                            
                            self.signupAppleRequest = nil
                            self.appleFakeButton.isHidden = true;
                                                    
                            if success {
                                if let loginModel = loginModel {
                                    LoginModel.current = loginModel
                                    self.showMain()
                                    //self.actionDelegate?.signupVCDidSignup(sender: self, loginModel: loginModel)
                                }
                                else {
                                    self.showAlert(withMessage: kDefaultErrorMessage)
                                }
                            }
                            else {
                                
                            }
                        })
                        
                        if let userEmail = appleIDCredential.email {
                            myUserDefault.set(userEmail, forKey: kEmail)
                            myUserDefault.set(appleIDCredential.fullName?.givenName, forKey: kFirstName)
                            myUserDefault.set(appleIDCredential.fullName?.familyName, forKey: kLastName)
                        }
                       
                        var parameter = Dictionary<String,String>()
                        parameter["fname"] = myUserDefault.string(forKey: kFirstName) ?? ""
                        parameter["lname"] = myUserDefault.string(forKey: kLastName) ?? ""
                        parameter["email"] =  myUserDefault.string(forKey: kEmail) ?? ""
                        parameter["id"] = userIdentifier
                        parameter["type"] = "A"
                        parameter["device_type"] = "I"
                       
                        
                    case .revoked:
                        break
                        GlobalFunctions.shared.forceLogout()
                        
                    case .notFound:
                        break
                        GlobalFunctions.shared.showAlert(message: "Something went wrong!")
                        
                    default: break
                    }
                }
            }
            
        } else if let passwordCredential = passwordCredential {
            print("User: \(passwordCredential.user)")
            print("Password: \(passwordCredential.password)")
            
                       
            // Sign in using an existing iCloud Keychain credential.
            let username = passwordCredential.user
            let password = passwordCredential.password
            
            // For the purpose of this demo app, show the password credential as an alert.
            DispatchQueue.main.async {
                let message = "The app has received your selected credential from the keychain. \n\n Username: \(username)\n Password: \(password)"
                let alertController = UIAlertController(title: "Keychain Credential Received",
                                                        message: message,
                                                        preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    @available(iOS 13.0, *)
    func performExistingAccountSetupFlows() {
        let authorizationController = ASAuthorizationController(authorizationRequests: requests)
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    //apple button
    @available(iOS 13.0, *)
    private func createAppleLoginButton() {
        let btnLoginButton = ASAuthorizationAppleIDButton()
       
        self.stackSocialButtons.addArrangedSubview(btnLoginButton)
        self.view.layoutIfNeeded()
        
      
        btnLoginButton.addAction(for: .touchUpInside) { [weak self] in
            guard let self = self else { return }
            
            //request
            let appleIdProvider = ASAuthorizationAppleIDProvider()
            let authoriztionRequest = appleIdProvider.createRequest()
            authoriztionRequest.requestedScopes = [.fullName, .email]
            
            //Apple’s Keychain sign in
            let passwordProvider = ASAuthorizationPasswordProvider()
            let passwordRequest = passwordProvider.createRequest()
            
            
            //create authorization controller
            let authorizationController = ASAuthorizationController(authorizationRequests: [authoriztionRequest]) //[authoriztionRequest, passwordRequest]
            authorizationController.presentationContextProvider = self
            authorizationController.delegate = self
            authorizationController.performRequests()
        }
    }

    
    @available(iOS 13.0, *)
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return view.window!
    }
    
}

@available(iOS 13.0, *)
extension LoginVC {
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        
        switch authorization.credential {
        case let appleIDCredential as ASAuthorizationAppleIDCredential:
            self.handleAppleIDAuthorization(appleIDCredential: appleIDCredential, passwordCredential: nil)
            
        case let passwordCredential as ASPasswordCredential:
            self.handleAppleIDAuthorization(appleIDCredential: nil, passwordCredential: passwordCredential)
            
        default: break
            
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Authorization returned an error: \(error.localizedDescription)")
    }
}
