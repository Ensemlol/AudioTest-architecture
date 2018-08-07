//
//  DispatchQueue+Extensions.swift
//  MiniAudioPlayer
//
//  Created by Ensem on 2018/8/7.
//  Copyright © 2018年 Ensem. All rights reserved.
//

import Foundation

extension DispatchQueue {
    static var userInteractive: DispatchQueue { return DispatchQueue.global(qos: .userInteractive) }
    
    static var userInitiated: DispatchQueue { return DispatchQueue.global(qos: .userInitiated) }
    
    static var utility: DispatchQueue { return DispatchQueue.global(qos: .utility) }
    
    static var background: DispatchQueue { return DispatchQueue.global(qos: .background) }
    
    func after(_ delay: TimeInterval, execute closure: @escaping () -> Void) {
        asyncAfter(deadline: .now() + delay, execute: closure)
    }
}
