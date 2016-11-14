//
//  ViewController.swift
//  SpotifyTest
//
//  Created by Seth Rininger on 10/27/16.
//  Copyright © 2016 Seth Rininger. All rights reserved.
//

import UIKit
import WebKit

class LoginViewController: UIViewController, SPTStoreControllerDelegate, WebViewControllerDelegate {
    
    @IBOutlet weak var statusLabel: UILabel!
    var authViewController: UIViewController?
    var firstLoad: Bool!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(self.sessionUpdatedNotification), name: NSNotification.Name(rawValue: "sessionUpdated"), object: nil)
        self.statusLabel.text = ""
        self.firstLoad = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let auth = SPTAuth.defaultInstance()
        // Uncomment to turn off native/SSO/flip-flop login flow
        //auth.allowNativeLogin = NO;
        // Check if we have a token at all
        if auth!.session == nil {
            self.statusLabel.text = ""
            return
        }
        // Check if it's still valid
        if auth!.session.isValid() && self.firstLoad {
            // It's still valid, show the player.
            self.showPlayer()
            return
        }
        // Oh noes, the token has expired, if we have a token refresh service set up, we'll call tat one.
        self.statusLabel.text = "Token expired."
        if auth!.hasTokenRefreshService {
            self.renewTokenAndShowPlayer()
            return
        }
        // Else, just show login dialog
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    func getAuthViewController(withURL url: URL) -> UIViewController {
        let webView = WebViewController(url: url)
        webView.delegate = self

        return UINavigationController(rootViewController: webView)
    }
    
    func sessionUpdatedNotification(_ notification: Notification) {
        self.statusLabel.text = ""
        let auth = SPTAuth.defaultInstance()
        self.presentedViewController?.dismiss(animated: true, completion: { _ in })
        if auth!.session != nil && auth!.session.isValid() {
            self.statusLabel.text = ""
            self.showPlayer()
        }
        else {
            self.statusLabel.text = "Login failed."
            print("*** Failed to log in")
        }
    }
    
    func showPlayer() {
        self.firstLoad = false
        self.statusLabel.text = "Logged in."
        self.performSegue(withIdentifier: "ShowPlayer", sender: nil)
    }
    
    internal func productViewControllerDidFinish(_ viewController: SPTStoreViewController) {
        self.statusLabel.text = "App Store Dismissed."
        viewController.dismiss(animated: true, completion: { _ in })
    }
    
    func openLoginPage() {
        self.statusLabel.text = "Logging in..."
        let auth = SPTAuth.defaultInstance()
        if SPTAuth.supportsApplicationAuthentication() {
            UIApplication.shared.openURL(auth!.spotifyAppAuthenticationURL())
        } else {
            self.authViewController = self.getAuthViewController(withURL: SPTAuth.defaultInstance().spotifyWebAuthenticationURL())
            self.definesPresentationContext = true
            self.present(self.authViewController!, animated: true, completion: { _ in })
        }
    }
    
    func renewTokenAndShowPlayer() {
        self.statusLabel.text = "Refreshing token..."
        let auth = SPTAuth.defaultInstance()
        auth!.renewSession(auth!.session) { error, session in
            auth!.session = session
            if error != nil {
                self.statusLabel.text = "Refreshing token failed."
                print("*** Error renewing session: \(error)")
                return
            }
            self.showPlayer()
        }
    }
    
    func webViewControllerDidFinish(_ controller: WebViewController) {
        // User tapped the close button. Treat as auth error
    }
  
    @IBAction func loginButtonWasPressed(_ sender: SPTConnectButton) {
        self.openLoginPage()
    }
    
    @IBAction func showSpotifyAppStoreClicked(_ sender: UIButton) {
        self.statusLabel.text = "Presenting App Store..."
        let storeVC = SPTStoreViewController(campaignToken: "your_campaign_token", store: self)
        self.present(storeVC!, animated: true, completion: { _ in })
    }
    
    @IBAction func clearCookiesClicked(_ sender: UIButton) {
        let storage = HTTPCookieStorage.shared
        for cookie: HTTPCookie in storage.cookies! {
            if (cookie.domain as NSString).range(of: "spotify.").length > 0 || (cookie.domain as NSString).range(of: "facebook.").length > 0 {
                storage.deleteCookie(cookie)
            }
        }
        UserDefaults.standard.synchronize()
        self.statusLabel.text! = "Cookies cleared."
    }
}

