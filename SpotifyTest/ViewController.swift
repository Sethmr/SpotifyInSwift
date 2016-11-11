//
//  ViewController.swift
//  SpotifyTest
//
//  Created by Seth Rininger on 11/11/16.
//  Copyright © 2016 Seth Rininger. All rights reserved.
//

import UIKit

class ViewController: UIViewController, SPTAudioStreamingDelegate, SPTAudioStreamingPlaybackDelegate {
    
    @IBOutlet weak var trackTitle: UILabel!
    @IBOutlet weak var prevButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var coverView: UIImageView!
    @IBOutlet weak var coverView2: UIImageView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var progressSlider: UISlider!
    @IBOutlet weak var playbackSourceTitle: UILabel!
    @IBOutlet weak var artistTitle: UILabel!

    var player = SPTAudioStreamingController.sharedInstance()
    var isChangingProgress: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.trackTitle.text = "Nothing Playing"
        self.artistTitle.text = ""
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    @IBAction func rewind(_ sender: UIButton) {
        self.player?.skipPrevious(nil)
    }
    
    @IBAction func playPause(_ sender: UIButton) {
        self.player?.setIsPlaying(!self.player!.playbackState.isPlaying, callback: nil)
    }
    
    @IBAction func fastForward(_ sender: UIButton) {
        self.player?.skipNext(nil)
    }

    @IBAction func seekValueChanged(_ sender: UISlider) {
        self.isChangingProgress = false
        let dest = self.player!.metadata!.currentTrack!.duration * Double(self.progressSlider.value)
        self.player?.seek(to: dest, callback: nil)
    }
    
    @IBAction func logoutClicked(_ sender: UIButton) {
        if (self.player != nil) {
            self.player?.logout()
        }
        else {
            _ = self.navigationController!.popViewController(animated: true)
        }

    }
    
    @IBAction func proggressTouchDown(_ sender: UISlider) {
        self.isChangingProgress = true
    }
    
    func applyBlur(on imageToBlur: UIImage, withRadius blurRadius: CGFloat) -> UIImage {
        let originalImage = CIImage(cgImage: imageToBlur.cgImage!)
        let filter = CIFilter(name: "CIGaussianBlur")
        filter?.setValue(originalImage, forKey: "inputImage")
        filter?.setValue(blurRadius, forKey: "inputRadius")
        let outputImage = filter?.outputImage
        let context = CIContext(options: nil)
        let outImage = context.createCGImage(outputImage!, from: outputImage!.extent)
        let ret = UIImage(cgImage: outImage!)
        return ret
    }
    
    
    func updateUI() {
        let auth = SPTAuth.defaultInstance()
        if self.player?.metadata == nil || self.player?.metadata.currentTrack == nil {
            self.coverView.image = nil
            self.coverView2.image = nil
            return
        }
        self.spinner.startAnimating()
        self.nextButton.isEnabled = self.player?.metadata.nextTrack != nil
        self.prevButton.isEnabled = self.player?.metadata.prevTrack != nil
        self.trackTitle.text = self.player?.metadata.currentTrack?.name
        self.artistTitle.text = self.player?.metadata.currentTrack?.artistName
        self.playbackSourceTitle.text = self.player?.metadata.currentTrack?.playbackSourceName


        SPTTrack.track(withURI: URL(string: self.player!.metadata.currentTrack!.uri)!, accessToken: auth!.session.accessToken, market: nil) { error, result in
            
            if let track = result as? SPTTrack {
                let imageURL = track.album.largestCover.imageURL
                if imageURL == nil {
                    print("Album \(track.album) doesn't have any images!")
                    self.coverView.image = nil
                    self.coverView2.image = nil
                    return
                }
                // Pop over to a background queue to load the image over the network.
                
                DispatchQueue.global().async {
                    do {
                        let imageData = try Data(contentsOf: imageURL!, options: [])
                        let image = UIImage(data: imageData)
                        // …and back to the main queue to display the image.
                        DispatchQueue.main.async {
                            self.spinner.stopAnimating()
                            self.coverView.image = image
                            if image == nil {
                                print("Couldn't load cover image with error: \(error)")
                                return
                            }
                        }
                        // Also generate a blurry version for the background
                        let blurred = self.applyBlur(on: image!, withRadius: 10.0)
                        DispatchQueue.main.async {
                            self.coverView2.image = blurred
                        }

                    } catch let error {
                        print(error.localizedDescription)
                    }
                }
            }
        }

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.handleNewSession()
    }
    
    
    func handleNewSession() {
        var auth = SPTAuth.defaultInstance()
        if self.player == nil {
            var error: Error? = nil
            self.player = SPTAudioStreamingController.sharedInstance()
            do {
                try self.player?.start(withClientId: auth!.clientID, audioController: nil, allowCaching: true)
                self.player?.delegate = self
                self.player?.playbackDelegate = self
                self.player?.diskCache = SPTDiskCache() /* capacity: 1024 * 1024 * 64 */
                self.player?.login(withAccessToken: auth?.session.accessToken)
                
                else {
                    self.player = nil
                    var alert = UIAlertController(title: "Error init", message: error!.description, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: { _ in })
                    self.closeSession()
                }
            }
            catch let error {
            }
        }
    }
}
