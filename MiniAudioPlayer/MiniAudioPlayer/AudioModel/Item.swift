//
//  Item.swift
//  MiniAudioPlayer
//
//  Created by Ensem on 2018/7/24.
//  Copyright © 2018年 Ensem. All rights reserved.
//

import Foundation

class Item {
    let uuid: UUID
    
    private(set) var name: String
    weak var store: Store?
    weak var parent: Folder? {
        didSet {
            store = parent?.store
        }
    }
    
    init(name: String, uuid: UUID) {
        self.name = name
        self.uuid = uuid
        self.store = nil
    }
    
    func setName(_ newName: String) {
        name = newName
        if let p = parent {
            
        }
    }
    
    func deleted() {
        parent = nil
    }
    
    var uuidPath: [UUID] {
        var path = parent?.uuidPath ?? []
        path.append(uuid)
        return path
    }
    
    func item(atUUIDPath path: ArraySlice<UUID>) -> Item? {
        guard let first = path.first,
            first == uuid else { return nil }
        return self
    }
}

extension Item {
    static let changeReasonKey = "reason"
    static let newValueKey = "newValue"
    static let oldValueKey = "oldValue"
    static let parentFolderKey = "parentFolder"
    static let renamed = "renamed"
    static let added = "added"
    static let removed = "removed"
}
