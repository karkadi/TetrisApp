//
//  TetrisApp.swift
//  TetrisApp
//
//  Created by Arkadiy KAZAZYAN on 31/05/2025.
//
import SwiftUI
import ComposableArchitecture

@main
struct TetrisApp: App {
    var body: some Scene {
        WindowGroup {
            TetrisView(store: Store( initialState: GameReducer.State()) {
                GameReducer()
            }
            )
            .preferredColorScheme(.dark)
        }
    }
}
