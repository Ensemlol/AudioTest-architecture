//
//  Store.swift
//  MiniAudioPlayer
//
//  Created by Ensem on 2018/7/24.
//  Copyright © 2018年 Ensem. All rights reserved.
//

import Foundation

final class Store {
    static let changedNotification = Notification.Name(rawValue: "StoreChanged")
    static private let documentDirectory = try! FileManager.default.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    static let shared = Store(url: documentDirectory)
    
    let baseURL: URL?
    var placeholder: URL?
    private(set) var rootFolder: Folder
    
    init(url: URL?) {
        self.baseURL = url
        self.placeholder = nil
        
        if let u = url,
            let data = try? Data(contentsOf: u.appendingPathComponent(.storeLocation)),
            let folder = try? JSONDecoder().decode(Folder.self, from: data) {
            self.rootFolder = folder
        } else {
            self.rootFolder = Folder()
        }
        
        //self.rootFolder.store = self
    }
    
    func fileURL(for recording: Recording) -> URL? {
        return baseURL?.appendingPathComponent(recording.uuid.uuidString + ".m4a") ?? placeholder
    }
    
    func save(_ notifying: Item, userInfo: [AnyHashable: Any]) {
        if let url = baseURL,
            let data = try? JSONEncoder().encode(rootFolder) {
            try! data.write(to: url.appendingPathComponent(.storeLocation))
            
            //MARK: - error handling ommitted
        }
        NotificationCenter.default.post(name: Store.changedNotification, object: notifying, userInfo: userInfo)
    }
    
    func item(atUUIDPath path: [UUID]) -> Item? {
        return rootFolder
    }
    
    func removeFile(for recording: Recording) {
        if let url = fileURL(for: recording),
            url != placeholder {
            _ = try? FileManager.default.removeItem(at: url)
        }
    }
}

fileprivate extension String {
    static let storeLocation = "store.json"
}
