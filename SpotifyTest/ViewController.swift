//
//  ViewController.swift
//  SpotifyTest
//
//  Created by Seth Rininger on 11/11/16.
//  Copyright © 2016 Seth Rininger. All rights reserved.
//

import UIKit
import AudioToolbox
import AVFoundation

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
    let audioSession = AVAudioSession.sharedInstance()
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
        let auth = SPTAuth.defaultInstance()
        if self.player == nil {
            self.player = SPTAudioStreamingController.sharedInstance()
            do {
                try self.player?.start(withClientId: auth!.clientID, audioController: nil, allowCaching: true)
                self.player?.delegate = self
                self.player?.playbackDelegate = self
                self.player?.diskCache = SPTDiskCache() /* capacity: 1024 * 1024 * 64 */
                self.player?.login(withAccessToken: auth?.session.accessToken)
            }
            catch let error {
                self.player = nil
                let alert = UIAlertController(title: "Error init", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(alert, animated: true, completion: { _ in })
                self.closeSession()
            }
        }
    }
    
    func closeSession() {
        do {
            try self.player!.stop()
            SPTAuth.defaultInstance().session = nil
            _ = self.navigationController!.popViewController(animated: true)!
        } catch let error {
            let alert = UIAlertController(title: "Error deinit", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(alert, animated: true, completion: { _ in })
        }
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController, didReceiveMessage message: String) {
        let alert = UIAlertController(title: "Message from Spotify", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        self.present(alert, animated: true, completion: { _ in })
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController, didChangePlaybackStatus isPlaying: Bool) {
        print("is playing = \(isPlaying)")
        if isPlaying {
            self.activateAudioSession()
        }
        else {
            self.deactivateAudioSession()
        }
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController, didChange metadata: SPTPlaybackMetadata) {
        self.updateUI()
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController, didReceive event: SpPlaybackEvent, withName name: String) {
        print("didReceivePlaybackEvent: \(event) \(name)")
        print("isPlaying=\(self.player?.playbackState.isPlaying) isRepeating=\(self.player?.playbackState.isRepeating) isShuffling=\(self.player?.playbackState.isShuffling) isActiveDevice=\(self.player?.playbackState.isActiveDevice) positionMs=\(self.player?.playbackState.position)")
    }
    
    func audioStreamingDidLogout(_ audioStreaming: SPTAudioStreamingController) {
        self.closeSession()
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController, didReceiveError error: Error?) {
        print("didReceiveError: \(error!.localizedDescription)")
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController, didChangePosition position: TimeInterval) {
        if self.isChangingProgress {
            return
        }
        let positionDouble = Double(position)
        let durationDouble = Double(self.player!.metadata.currentTrack!.duration)
        self.progressSlider.value = Float(positionDouble / durationDouble)
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController, didStartPlayingTrack trackUri: String) {
        print("Starting \(trackUri)")
        print("Source \(self.player?.metadata.currentTrack?.playbackSourceUri)")
        // If context is a single track and the uri of the actual track being played is different
        // than we can assume that relink has happended.
        let isRelinked = self.player!.metadata.currentTrack!.playbackSourceUri.contains("spotify:track") && !(self.player!.metadata.currentTrack!.playbackSourceUri == trackUri)
        print("Relinked \(isRelinked)")
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController, didStopPlayingTrack trackUri: String) {
        print("Finishing: \(trackUri)")
    }
    
    func audioStreamingDidLogin(_ audioStreaming: SPTAudioStreamingController) {
        self.updateUI()
        self.player?.playSpotifyURI("spotify:user:spotify:playlist:2yLXxKhhziG2xzy7eyD4TD", startingWith: 0, startingWithPosition: 10) { error in
            if error != nil {
                print("*** failed to play: \(error)")
                return
            }
        }
    }
    
    func activateAudioSession() {
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayback)
            try audioSession.setActive(true)
        }
        catch let error {
            print(error.localizedDescription)
        }
    }
    
    func deactivateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        }
        catch let error {
            print(error.localizedDescription)
        }
    }
}
