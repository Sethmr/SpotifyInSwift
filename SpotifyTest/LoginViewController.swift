//
//  ViewController.swift
//  SpotifyTest
//
//  Created by Seth Rininger on 10/27/16.
//  Copyright © 2016 Seth Rininger. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {
    
    @IBOutlet weak var statusLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func loginButtonWasPressed(_ sender: SPTConnectButton) {
        login()
    }

    func login() {
        self.statusLabel.text! = "Logging in..."
        let auth = SPTAuth.defaultInstance()
        if SPTAuth.supportsApplicationAuthentication() {
            UIApplication.shared.openURL(auth!.spotifyAppAuthenticationURL())
        } else {
            let loginURL = auth?.spotifyAppAuthenticationURL()
            
            UIApplication.shared.openURL(loginURL!)
        }

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

