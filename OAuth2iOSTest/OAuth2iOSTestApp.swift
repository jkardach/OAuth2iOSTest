//
//  OAuth2iOSTestApp.swift
//  OAuth2iOSTest
//
//  Created by jim kardach on 8/29/23.
//

import SwiftUI
import GoogleSignIn

@main
struct OAuth2iOSTestApp: App {
    
    var body: some Scene {
        WindowGroup {
            ContentView()
            
            // ...
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
                .onAppear {
                    GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
                        // Check if `user` exists; otherwise, do something with `error`

                    }
                }
        }
    }
}


