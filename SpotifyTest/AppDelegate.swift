//
//  AppDelegate.swift
//  SpotifyTest
//
//  Created by Seth Rininger on 10/27/16.
//  Copyright © 2016 Seth Rininger. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, SPTAudioStreamingDelegate {

    var window: UIWindow?
    var session: SPTSession?
    var player: SPTAudioStreamingController?
    let kClientId = "ca5c4490e38f41818a6d32a14a0ad2f3"
    let kCallbackURL = "SpotifyTest://returnAfterLogin"
    let kTokenSwapURL = "http://localhost:1234/swap"
    let kTokenRefreshServiceURL = "http://localhost:1234/refresh"
    let kSessionUserDefaultsKey = "SpotifySession"
    
    func delay(_ delay:Double, closure:@escaping ()->()) {
        DispatchQueue.main.asyncAfter(
            deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        let auth = SPTAuth.defaultInstance()
        auth?.clientID = kClientId
        auth?.redirectURL = URL(string:kCallbackURL)
        auth?.tokenSwapURL = URL(string:kTokenSwapURL)
        auth?.requestedScopes = [SPTAuthStreamingScope]
        auth?.tokenRefreshURL = URL(string: kTokenRefreshServiceURL)!
        auth?.sessionUserDefaultsKey = kSessionUserDefaultsKey
        let loginURL = auth?.spotifyAppAuthenticationURL()
        
        // Opening a URL in Safari close to application launch may trigger
        // an iOS bug, so we wait a bit before doing so.
        delay(0.1) {
            application.openURL(loginURL!)
            return
        }
        
        return true
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        // Ask SPTAuth if the URL given is a Spotify authentication callback
        
        let auth = SPTAuth.defaultInstance()
        /*
         Handle the callback from the authentication service. -[SPAuth -canHandleURL:]
         helps us filter out URLs that aren't authentication URLs (i.e., URLs you use elsewhere in your application).
         */
        if auth!.canHandle(url) {
            auth?.handleAuthCallback(withTriggeredAuthURL: url, callback: {
                error, session in
                // This is the callback that'll be triggered when auth is completed (or fails).
                if error != nil {
                    print("*** Auth error: \(error)")
                }
                else {
                    auth?.session = session
                }
                NotificationCenter.default.post(name: NSNotification.Name.init(rawValue: "sessionUpdated"), object: self)
            })
            return true
        }
        return false
    }
}

