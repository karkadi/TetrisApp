//
//  BlockView.swift
//  TetrisApp
//
//  Created by Arkadiy KAZAZYAN on 31/05/2025.
//
import SwiftUI

struct BlockView: View {
    let color: BlockColor
    
    var body: some View {
        Rectangle()
            .fill(color.color)
            .frame(width: 18, height: 18)
            .overlay(
                Rectangle()
                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
            )
    }
}
