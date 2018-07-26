//
//  Recorder.swift
//  MiniAudioPlayer
//
//  Created by Ensem on 2018/7/26.
//  Copyright © 2018年 Ensem. All rights reserved.
//

import Foundation
import AVFoundation

final class Recorder: NSObject {
    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?
    private var update: (TimeInterval?) -> ()
    
    let url: URL
    
    init?(url: URL, update: @escaping (TimeInterval?) -> ()) {
        self.update = update
        self.url = url
        
        super.init()
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord)
            try AVAudioSession.sharedInstance().setActive(true)
            
            AVAudioSession.sharedInstance().requestRecordPermission { allowed in
                if allowed {
                    self.start(url)
                } else {
                    self.update(nil)
                }
            }
        } catch {
            return nil
        }
    }
    
    private func start(_ url: URL) {
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44100.0 as Float,
            AVNumberOfChannelsKey: 1
        ]
        
        if let recorder = try? AVAudioRecorder(url: url, settings: settings) {
            recorder.delegate = self
            audioRecorder = recorder
            recorder.record()
            
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                guard let s = self else { return }
                s.update(s.audioRecorder?.currentTime)
            }
        } else {
            update(nil)
        }
    }
    
    func stop() {
        audioRecorder?.stop()
        timer?.invalidate()
    }
}

extension Recorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            stop()
        } else {
            update(nil)
        }
    }
}
