//
//  NextPieceView.swift
//  TetrisApp
//
//  Created by Arkadiy KAZAZYAN on 01/06/2025.
//
import SwiftUI

/// A SwiftUI view that displays the next upcoming Tetromino piece in a Tetris game.
///
/// This view shows a preview of the next piece the player will receive, positioned within a styled
/// container. It automatically adjusts the piece's positioning in its container based on the Tetromino
/// type for optimal visual alignment.
///
/// - Parameters:
///   - nextPiece: The upcoming Tetromino piece to display, or `nil` when no piece is available.
///   - blockSize: The size (in points) of each individual block that makes up the Tetromino piece.
///     This determines both the visual size and spacing between blocks.
///
/// The view uses internal offset calculations to properly center different Tetromino types:
///   - I-piece: Horizontally centered with a specific x-offset adjustment
///   - O-piece: Requires a different horizontal offset to appear centered
///   - Other pieces: Use standard centering offsets
///
/// The Tetromino is displayed within a rounded rectangle with a dark semi-transparent background.
struct NextPieceView: View {
    let nextPiece: Tetromino?
    let blockSize: CGFloat
    
    var xOffset: CGFloat {
        switch nextPiece?.type {
        case .iBlock:
            return 1.5
        case  .oBlock:
            return 0.5
        default:
            return 1
        }
    }
    var yOffset: CGFloat {
        switch nextPiece?.type {
        case .iBlock:
            return 0
        default:
            return 0.5
        }
    }
    
    var body: some View {
        VStack {
            if let nextPiece = nextPiece {
                ZStack {
                    ForEach(0..<nextPiece.blocks.count, id: \.self) { index in
                        let block = nextPiece.blocks[index]
                        BlockView(color: nextPiece.type,
                                  blockSize: blockSize)
                            .offset(
                                x: (CGFloat(block.column) - xOffset) * blockSize,
                                y: (CGFloat(block.row) - yOffset) * blockSize
                            )
                    }
                }
                .frame(width: 4.5 * blockSize, height: 4 * blockSize)
                .background(Color.black.opacity(0.8))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .frame(width: 4.5 * blockSize, height: 4 * blockSize)
                    .foregroundColor(Color.black.opacity(0.8))
            }
        }
        .padding(.leading, 16)
        .padding(.trailing, 8)
    }
}

#Preview {
    ScrollView {
        VStack {
            ForEach(BlockColor.allCases.dropLast(), id: \.self) { color in
                NextPieceView(nextPiece: Tetromino.create(color), blockSize: 20)
            }
            NextPieceView(nextPiece: nil, blockSize: 20)
        }
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.3))
    }
}
