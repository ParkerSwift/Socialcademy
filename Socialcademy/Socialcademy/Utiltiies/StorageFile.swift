//
//  StorageFile.swift
//  Socialcademy
//
//  Created by Parker Joseph Alexander on 6/13/24.
//

import Foundation
import FirebaseStorage

struct StorageFile {
    private let storageReference: StorageReference
    
    func putFile(from fileURL: URL) async throws -> Self {
        _ = try await storageReference.putFileAsync(from: fileURL)
        return self
    }
    
    func getDownloadURL() async throws -> URL {
        return try await storageReference.downloadURL()
    }
    
    func delete() async throws {
        try await storageReference.delete()
    }
}

extension StorageFile {
    private static let storage = Storage.storage()
    
    static func with(namespace: String, identifier: String) -> StorageFile {
        let path = "\(namespace)/\(identifier)"
        let storageReference = storage.reference().child(path)
        return StorageFile(storageReference: storageReference)
    }
    
    static func atURL(_ downloadURL: URL) -> StorageFile {
        let storageReference = storage.reference(forURL: downloadURL.absoluteString)
        return StorageFile(storageReference: storageReference)
    }
}
