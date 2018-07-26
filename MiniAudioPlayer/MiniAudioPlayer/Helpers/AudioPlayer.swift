//
//  AudioPlayer.swift
//  MiniAudioPlayer
//
//  Created by Ensem on 2018/7/26.
//  Copyright © 2018年 Ensem. All rights reserved.
//

import Foundation
import AVFoundation

class AudioPlayer: NSObject {
    private var audioPlayer: AVAudioPlayer
    private var timer: Timer?
    private var update: (TimeInterval?) -> ()
    
    init?(url: URL, update: @escaping (TimeInterval?) -> ()) {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            return nil
        }
        
        if let player = try? AVAudioPlayer(contentsOf: url) {
            audioPlayer = player
            self.update = update
        } else {
            return nil
        }
        
        super.init()
        audioPlayer.delegate = self
    }
    
    func togglePlat() {
        if audioPlayer.isPlaying {
            audioPlayer.pause()
            timer?.invalidate()
            timer = nil
        } else {
            audioPlayer.play()
            if let t = timer {
                t.invalidate()
            }
            
            timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
                guard let s = self else { return }
                s.update(s.audioPlayer.currentTime)
            }
        }
    }
    
    func setProgress(_ time: TimeInterval) {
        audioPlayer.currentTime = time
    }
    
    var duration: TimeInterval {
        return audioPlayer.duration
    }
    
    var isPlaying: Bool {
        return audioPlayer.isPlaying
    }
    
    var isPaused: Bool {
        return !audioPlayer.isPlaying && audioPlayer.currentTime > 0
    }
    
    deinit {
        timer?.invalidate()
    }
}

extension AudioPlayer: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        timer?.invalidate()
        timer = nil
        update(flag ? audioPlayer.currentTime : nil)
    }
}
