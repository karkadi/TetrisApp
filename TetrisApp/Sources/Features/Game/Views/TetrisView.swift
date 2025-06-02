//
//  TetrisView.swift
//  TetrisApp
//
//  Created by Arkadiy KAZAZYAN on 31/05/2025.
//

import SwiftUI
import ComposableArchitecture

struct TetrisView: View {
    let store: StoreOf<GameReducer>
    
    // MARK: - Drawing Constants
    private let blockSize: CGFloat = 20
    
    var body: some View {
        VStack {
            // Score and controls
            scoreView
            
            HStack {
                Spacer()
                // Game board
                ZStack {
                    // Grid background
                    BoardView(rows: store.board.count, columns: store.board[0].count)
                    
                    // Placed blocks
                    placedBlocksView
                    
                    // Current piece
                    currentPieceView
                }
                .frame(
                    width: CGFloat(store.board[0].count) * blockSize,
                    height: CGFloat(store.board.count) * blockSize
                )
                .background(Color.black)
                
                // Next piece preview
                NextPieceView(nextPiece: store.nextPiece, blockSize: blockSize)
                
            }
            Spacer()
            // Controls
            controlsView
        }
        .onAppear {
            store.send(.startGame)
        }
        .gesture(
            DragGesture()
                .onEnded { gesture in
                    let horizontal = gesture.translation.width
                    if abs(horizontal) > 20 {
                        if horizontal > 0 {
                            store.send(.moveRight)
                        } else {
                            store.send(.moveLeft)
                        }
                    }
                    
                    let vertical = gesture.translation.height
                    if vertical > 20 {
                        store.send(.moveDown)
                    } else if vertical < -20 {
                        store.send(.rotate)
                    }
                }
        )
    }
    
    private var placedBlocksView: some View {
        ForEach(0..<store.board.count, id: \.self) { row in
            ForEach(0..<store.board[0].count, id: \.self) { column in
                if let color = store.board[row][column] {
                    BlockView(
                        color: color,
                        isClearing: store.clearingLines.contains(row),
                        animationProgress: store.animationProgress
                    )
                    .offset(
                        x: (CGFloat(column) - 4.5 ) * blockSize,
                        y: (CGFloat(row) - 9.5) * blockSize
                    )
                }
            }
        }
    }
    
    @ViewBuilder
    private var currentPieceView: some View {
        if let piece = store.currentPiece {
            ForEach(0..<piece.blocks.count, id: \.self) { index in
                let block = piece.blocks[index]
                BlockView(color: piece.type)
                    .offset(
                        x: (CGFloat(store.piecePosition.column + block.column) - 4.5) * blockSize,
                        y: (CGFloat(store.piecePosition.row + block.row) - 9.5) * blockSize
                    )
            }
        }
    }
    
    private var scoreView: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Score: \(store.score)")
                    .font(.headline)
                Text("Level: \(store.level)")
                    .font(.headline)
                Text("Lines: \(store.linesCleared)/\(store.linesToNextLevel)")
                    .font(.subheadline)
            }
            
            Spacer()
            
            VStack {
                Text("High Score: \(store.highScore)")
                    .font(.headline)
                    .foregroundColor(store.score > store.highScore && store.score > 0 ? .yellow : .primary)
                if store.isLevelTransitioning {
                    Text("LEVEL \(store.level)!")
                        .font(.title)
                        .foregroundColor(.yellow)
                        .transition(.scale)
                        .animation(.spring(), value: store.level)
                }
            }
            
            Spacer()
            
            VStack {
                if store.isGameOver {
                    Button("New Game") {
                        store.send(.startGame)
                    }
                } else if store.isPaused {
                    Button("Resume") {
                        store.send(.resumeGame)
                    }
                } else {
                    Button("Pause") {
                        store.send(.pauseGame)
                    }
                }
                
                Button(action: { store.send(.toggleMute) }) {
                    Image(systemName: store.state.isMuted ? "speaker.slash" : "speaker" )
                        .frame(width: 60, height: 60)
                }
            }
        }
        .padding()
    }
    
    private var controlsView: some View {
        HStack {
            Button(action: { store.send(.moveLeft) }) {
                Image(systemName: "arrow.left")
                    .frame(width: 60, height: 60)
            }
            
            VStack {
                Button(action: { store.send(.rotate) }) {
                    Image(systemName: "arrow.clockwise")
                        .frame(width: 60, height: 60)
                }
                
                Button(action: { store.send(.drop) }) {
                    Image(systemName: "arrow.down")
                        .frame(width: 60, height: 60)
                }
            }
            
            Button(action: { store.send(.moveRight) }) {
                Image(systemName: "arrow.right")
                    .frame(width: 60, height: 60)
            }
        }
        .font(.title)
        .disabled(store.isGameOver || store.isPaused)
    }
}

#Preview {
    TetrisView(store: Store( initialState: GameReducer.State()) {
        GameReducer()
    })
}

