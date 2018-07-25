//
//  RecordViewController.swift
//  MiniAudioPlayer
//
//  Created by Ensem on 2018/7/25.
//  Copyright © 2018年 Ensem. All rights reserved.
//

import UIKit
import AVFoundation

final class RecordViewController: UIViewController, AVAudioRecorderDelegate {
    
    var folder: Folder? = nil
    var recording = Recording(name: "", uuid: UUID())
    
    
}
