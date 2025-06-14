//
//  BoardView.swift
//  TetrisApp
//
//  Created by Arkadiy KAZAZYAN on 31/05/2025.
//
import SwiftUI

/// A SwiftUI view that renders a Tetris game board with surrounding borders.
///
/// The board consists of:
///   - Main gameplay area (black background with grid lines)
///   - Surrounding border (static gray blocks on all sides)
///   - Top/bottom borders spanning full width
///   - Left/right borders spanning play area height
///
/// - Parameters:
///   - rows: Number of rows in the main gameplay area (excluding borders)
///   - columns: Number of columns in the main gameplay area (excluding borders)
///   - blockSize: Side length (in points) for each square block
///
/// - Note: Total view size accounts for borders (+2 blocks width/height)
/// - Warning: Board assumes blockSize matches rendering units in parent view
/// - Remark: Grid lines are offset to center gameplay area within borders
struct BoardView: View {
    let rows: Int
    let columns: Int
    let blockSize: CGFloat

    var body: some View {
       // VStack {
        GeometryReader { geometry in
            // Main game area background
            Rectangle()
                .fill(Color.black)
                .frame(width: geometry.size.width + 2 * blockSize, height: geometry.size.height + 2 * blockSize)
                .offset(x: -1, y: -1) // Offset for border

            // Grid lines
            Path { path in
                // Vertical lines
                for column in 0...columns {
                    path.move(to: CGPoint(
                        x: CGFloat(column) * blockSize - blockSize,
                        y: 0
                    ))
                    path.addLine(to: CGPoint(
                        x: CGFloat(column) * blockSize - blockSize,
                        y: CGFloat(rows) * blockSize
                    ))
                }

                // Horizontal lines
                for row in 0...rows {
                    path.move(to: CGPoint(
                        x: 0,
                        y: CGFloat(row) * blockSize - blockSize
                    ))
                    path.addLine(to: CGPoint(
                        x: CGFloat(columns) * blockSize ,
                        y: CGFloat(row) * blockSize - blockSize
                    ))
                }
            }
            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            .offset(x: blockSize, y: blockSize)

            // Left/Right border (grey blocks)
            ForEach(0..<rows, id: \.self) { row in
                BlockView(color: .gray, blockSize: blockSize)
                    .offset(
                        x: CGFloat(columns) * blockSize + blockSize,
                        y: CGFloat(row) * blockSize + blockSize
                    )
                BlockView(color: .gray, blockSize: blockSize)
                    .offset(
                        x: 0,
                        y: CGFloat(row) * blockSize + blockSize
                    )
            }

            // Top/bottom border (grey blocks)
            ForEach(0..<columns + 2, id: \.self) { column in
                BlockView(color: .gray, blockSize: blockSize)
                    .offset(
                        x: CGFloat(column) * blockSize,
                        y: 0
                    )
                BlockView(color: .gray, blockSize: blockSize)
                    .offset(
                        x: CGFloat(column) * blockSize,
                        y: CGFloat(rows) * blockSize + blockSize
                    )
            }
        }
    }
}

#Preview {
    VStack {
        BoardView(rows: 20, columns: 10, blockSize: 40)
            .padding()
    }
    .padding(40)
}
