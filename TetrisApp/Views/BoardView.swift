//
//  BoardView.swift
//  TetrisApp
//
//  Created by Arkadiy KAZAZYAN on 31/05/2025.
//
import SwiftUI

struct BoardView: View {
    let rows: Int
    let columns: Int
    
    var body: some View {
        GeometryReader { geometry in
            let blockSize = geometry.size.width / CGFloat(columns)
            
            Path { path in
                // Vertical lines
                for column in 0...columns {
                    path.move(to: CGPoint(x: CGFloat(column) * blockSize, y: 0))
                    path.addLine(to: CGPoint(x: CGFloat(column) * blockSize, y: geometry.size.height))
                }
                
                // Horizontal lines
                for row in 0...rows {
                    path.move(to: CGPoint(x: 0, y: CGFloat(row) * blockSize))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: CGFloat(row) * blockSize))
                }
            }
            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        }
    }
}
