//
//  Recording.swift
//  MiniAudioPlayer
//
//  Created by Ensem on 2018/7/24.
//  Copyright © 2018年 Ensem. All rights reserved.
//

import Foundation

class Recording: Item, Codable {
    override init(name: String, uuid: UUID) {
        super.init(name: name, uuid: uuid)
    }
    
    var fileURL: URL? {
        return store?.fileURL(for: self)
    }
}
