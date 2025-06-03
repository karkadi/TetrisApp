//
//  NextPieceView.swift
//  TetrisApp
//
//  Created by Arkadiy KAZAZYAN on 01/06/2025.
//
import SwiftUI

struct NextPieceView: View {
    let nextPiece: Tetromino?
    let blockSize: CGFloat
    
    var xOffset: CGFloat {
        switch nextPiece?.type {
        case .i:
            return 1.5
        case  .o:
            return 0.5
        default:
            return 1
        }
    }
    var yOffset: CGFloat {
        switch nextPiece?.type {
        case .i:
            return 0
        default:
            return 0.5
        }
    }
    
    var body: some View {
        VStack {
            Text("Next:")
            if let nextPiece = nextPiece {
                ZStack {
                    ForEach(0..<nextPiece.blocks.count, id: \.self) { index in
                        let block = nextPiece.blocks[index]
                        BlockView(color: nextPiece.type)
                            .offset(
                                x: (CGFloat(block.column) - xOffset) * blockSize,
                                y: (CGFloat(block.row) - yOffset) * blockSize
                            )
                    }
                }
                .frame(width: 4.5 * blockSize, height: 4 * blockSize)
                .background(Color.black.opacity(0.8))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(.leading,16)
        .padding(.trailing,8)
    }
}

#Preview {
    ScrollView {
        VStack {
            ForEach(BlockColor.allCases.dropLast(), id: \.self) { color in
                NextPieceView(nextPiece: Tetromino.create(color), blockSize: 20)
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.3))
    }
}
