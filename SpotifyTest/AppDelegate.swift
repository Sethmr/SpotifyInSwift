//
//  AppDelegate.swift
//  SpotifyTest
//
//  Created by Seth Rininger on 10/27/16.
//  Copyright © 2016 Seth Rininger. All rights reserved.
//

import UIKit

let appDelegate = UIApplication.shared.delegate as! AppDelegate

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, SPTAudioStreamingDelegate {

    var window: UIWindow?
    var session: SPTSession?
    var player: SPTAudioStreamingController?
    let kClientId = "ca5c4490e38f41818a6d32a14a0ad2f3"
    let kCallbackURL = "spotifytest://returnAfterLogin"
    let kTokenSwapURL = "http://localhost:1234/swap"
    let kTokenRefreshServiceURL = "http://localhost:1234/refresh"
    let kSessionUserDefaultsKey = "SpotifySession"
    
    func delay(_ delay:Double, closure:@escaping ()->()) {
        DispatchQueue.main.asyncAfter(
            deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        SPTAuth.defaultInstance().clientID = kClientId
        SPTAuth.defaultInstance().redirectURL = URL(string:kCallbackURL)
        //SPTAuth.defaultInstance().tokenSwapURL = URL(string:kTokenSwapURL)
        SPTAuth.defaultInstance().requestedScopes = [SPTAuthStreamingScope]
        //SPTAuth.defaultInstance().tokenRefreshURL = URL(string: kTokenRefreshServiceURL)!
        SPTAuth.defaultInstance().sessionUserDefaultsKey = kSessionUserDefaultsKey

        return true
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        // Ask SPTAuth if the URL given is a Spotify authentication callback

        print("The URL: \(url)")
        if SPTAuth.defaultInstance().canHandle(url) {
            SPTAuth.defaultInstance().handleAuthCallback(withTriggeredAuthURL: url) { error, session in
                // This is the callback that'll be triggered when auth is completed (or fails).
                if error != nil {
                    print("*** Auth error: \(error)")
                    return
                }
                else {
                    SPTAuth.defaultInstance().session = session
                }
                //NotificationCenter.default.post(name: NSNotification.Name.init(rawValue: "sessionUpdated"), object: self)
            }
            //return true
        }
        return false
    }
}

