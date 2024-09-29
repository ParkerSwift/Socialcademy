//
//  SocialcademyApp.swift
//  Socialcademy
//
//  Created by Parker Joseph Alexander on 4/1/24.
//

import SwiftUI
import Firebase
import FirebaseAuth

@main

struct SocialcademyApp: App {
    init(){
        setupFirebase()
        print("Working.")
    }
    var body: some Scene {
        WindowGroup {
            AuthView()
        }
    }
}
private extension SocialcademyApp {
    func setupFirebase() {
        FirebaseConfiguration.shared.setLoggerLevel(.min)
        FirebaseApp.configure()
    }
}

