//
//  PostsRepository.swift
//  Socialcademy
//
//  Created by Parker Joseph Alexander on 4/13/24.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

// MARK: - PostsRepositoryProtocol

protocol PostsRepositoryProtocol {
    var user: User { get }
    func fetchAllPosts() async throws -> [Post]
    func fetchPosts(by author: User) async throws -> [Post]
    func fetchFavoritePosts() async throws -> [Post]
    func create(_ post: Post) async throws
    func delete(_ post: Post) async throws
    func favorite(_ post: Post) async throws
    func unfavorite(_ post: Post) async throws
}

extension PostsRepositoryProtocol {
    func canDelete(_ post: Post) -> Bool {
        post.author.id == user.id
    }
}

// MARK: - PostsRepositoryStub

#if DEBUG
struct PostsRepositoryStub: PostsRepositoryProtocol {
    let state: Loadable<[Post]>
    let user = User.testUser
    
    func fetchAllPosts() async throws -> [Post] {
        return try await state.simulate()
    }
    
    func fetchPosts(by author: User) async throws -> [Post] {
        return try await state.simulate()
    }
    
    func fetchFavoritePosts() async throws -> [Post] {
        return try await state.simulate()
    }
    
    func create(_ post: Post) async throws {}
    
    func delete(_ post: Post) async throws {}
    
    func favorite(_ post: Post) async throws {}
    
    func unfavorite(_ post: Post) async throws {}
}
#endif

// MARK: - PostsRepository

struct PostsRepository: PostsRepositoryProtocol {
    let user: User
    let postsReference = Firestore.firestore().collection("posts_v2")
    let favoritesReference = Firestore.firestore().collection("favorites")
    
    func fetchAllPosts() async throws -> [Post] {
        return try await fetchPosts(from: postsReference)
    }
    
    func fetchPosts(by author: User) async throws -> [Post] {
        return try await fetchPosts(from: postsReference.whereField("author.id", isEqualTo: author.id))
    }
    
    func fetchFavoritePosts() async throws -> [Post] {
        let favorites = try await fetchFavorites()
        guard !favorites.isEmpty else { return [] }
        return try await postsReference
            .whereField("id", in: favorites.map(\.uuidString))
            .order(by: "timestamp", descending: true)
            .getDocuments(as: Post.self)
            .map { post in
                post.setting(\.isFavorite, to: true)
            }
    }
    func create(_ post: Post) async throws {
        var post = post
        if let imageFileURL = post.imageURL {
            do {
                // Check if the file exists
                guard FileManager.default.fileExists(atPath: imageFileURL.path) else {
                    throw NSError(domain: "PostCreation", code: 404, userInfo: [NSLocalizedDescriptionKey: "Image file not found at \(imageFileURL.path)"])
                }
                
                let storageFile = StorageFile.with(namespace: "posts", identifier: post.id.uuidString)
                print("Attempting to upload image from \(imageFileURL.path)")
                
                // Upload the file
                let uploadedFile = try await storageFile.putFile(from: imageFileURL)
                
                // Get the download URL
                let downloadURL = try await uploadedFile.getDownloadURL()
                
                post.imageURL = downloadURL
                print("Successfully uploaded image. Download URL: \(downloadURL)")
            } catch {
                print("Error uploading image: \(error)")
                throw error
            }
        }
        
        let document = postsReference.document(post.id.uuidString)
        do {
            try await document.setData(from: post)
            print("Successfully created post document with ID: \(post.id.uuidString)")
        } catch {
            print("Error creating post document: \(error)")
            throw error
        }
    }

    
    func delete(_ post: Post) async throws {
        precondition(canDelete(post))
        let document = postsReference.document(post.id.uuidString)
        try await document.delete()
        let image = post.imageURL.map(StorageFile.atURL(_:))
        try await image?.delete()
    }
    
    func favorite(_ post: Post) async throws {
        let favorite = Favorite(postID: post.id, userID: user.id)
        let document = favoritesReference.document(favorite.id)
        try await document.setData(from: favorite)
    }
    
    func unfavorite(_ post: Post) async throws {
        let favorite = Favorite(postID: post.id, userID: user.id)
        let document = favoritesReference.document(favorite.id)
        try await document.delete()
    }
}

private extension PostsRepository {
    func fetchPosts(from query: Query) async throws -> [Post] {
        let (posts, favorites) = try await (
            query.order(by: "timestamp", descending: true).getDocuments(as: Post.self),
            fetchFavorites()
        )
        return posts.map { post in
            post.setting(\.isFavorite, to: favorites.contains(post.id))
        }
    }
    
    func fetchFavorites() async throws -> [Post.ID] {
        return try await favoritesReference
            .whereField("userID", isEqualTo: user.id)
            .getDocuments(as: Favorite.self)
            .map(\.postID)
    }
    
    struct Favorite: Identifiable, Codable {
        var id: String {
            postID.uuidString + "-" + userID
        }
        let postID: Post.ID
        let userID: User.ID
    }
}

private extension Post {
    func setting<T>(_ property: WritableKeyPath<Post, T>, to newValue: T) -> Post {
        var post = self
        post[keyPath: property] = newValue
        return post
    }
}
