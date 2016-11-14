//
//  AlternativeLoginViewController.swift
//  SpotifyTest
//
//  Created by Seth Rininger on 11/14/16.
//  Copyright © 2016 Seth Rininger. All rights reserved.
//

import UIKit

class AlternativeLoginViewController: UIViewController {

    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    var username: String?
    var password: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        submitButton.layer.cornerRadius = submitButton.bounds.height / 2
        usernameTextField.delegate = self
        passwordTextField.delegate = self
        // Do any additional setup after loading the view.
    }
    
    @IBAction func submitButtonWasPressed(_ sender: UIButton) {
        print("submitButtonWasPressed")
        
        if username != nil && password != nil {
            print("username: \(username!), password: \(password!)")
            view.endEditing(true)
            var urlString: String = "https://accounts.spotify.com/authorize/?client_id=\(appDelegate.kClientId)"
            urlString.append("&response_type=code")
            urlString.append("&redirect_uri=\(appDelegate.kCallbackURL)")
            //urlString.append("&scope=")
            //urlString.append("&state=")
            //urlString.append("&show_dialog=")
            print("url: \(urlString)")
            let url = URL(string: urlString)!
            UIApplication.shared.openURL(url)
//            performAPICall(url) {
//                response, data in
//                if response == 200 {
//                    print("Spotify Response: 200")
//                    do {
//                        let json = try JSONSerialization.data(withJSONObject: data!, options: .prettyPrinted)
//                        print(json)
//                    } catch let error {
//                        print(error.localizedDescription)
//                    }
//                } else {
//                    print("Spotify Response: \(response)")
//                }
//            }
        } else {
            print("username: \(username), password: \(password)")
        }
    }

    internal func performAPICall(_ url: URL, resultHandler: @escaping ((Int, Data?) -> Void)) {
        
        //let session = URLSession(configuration: .default, delegate: nil, delegateQueue: nil)
        let session = URLSession(configuration: .default)
        
        let tokenRequest = NSMutableURLRequest(url: url)
        tokenRequest.httpMethod = "GET"
        
        let dataTask = session.dataTask(with: tokenRequest as URLRequest) {
            data, response, error in
            
            if let httpResponse = response as? HTTPURLResponse {
                if error == nil {
                    resultHandler(httpResponse.statusCode, data)
                } else {
                    print("Error during GET Request to the endpoint \(url).\nError: \(error)")
                }
            }
        }
        dataTask.resume()
    }
}

extension AlternativeLoginViewController: UITextFieldDelegate {
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.text != nil && textField.text! != "" {
            if textField.restorationIdentifier == "passwordTextField" {
                password = textField.text!
            }
            if textField.restorationIdentifier == "usernameTextField" {
                username = textField.text!
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return false
    }
}
