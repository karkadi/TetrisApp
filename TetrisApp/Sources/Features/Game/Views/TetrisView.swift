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
                    width: (CGFloat(store.board[0].count)) * blockSize,
                    height: CGFloat(store.board.count) * blockSize
                )
                Spacer()
                rightView

            }
            newLevelView
            Spacer()
            // Controls
            controlsView
        }
        .background(Color.white.opacity(0.3))
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

    private var rightView: some View {
        VStack {
            // Next piece preview
            NextPieceView(nextPiece: store.nextPiece, blockSize: blockSize)

            // Score and controls
            VStack(alignment: .center, spacing: 0) {
                Text("Score")
                    .font(.headline)
                Text("\(store.score)")
                    .font(.headline)
                Text("Level")
                    .font(.headline)
                Text("\(store.level)")
                    .font(.headline)
                Text("Lines")
                    .font(.headline)
                Text("\(store.linesCleared)/\(store.linesToNextLevel)")
                    .font(.headline)
            }
            .frame(width: 90)
            .padding(.vertical,16)
            .background(.black)
            .cornerRadius(8)
            .offset(x: 4)

            Button(action: { store.send(.toggleMute) }) {
                Image(systemName: store.state.isMuted ? "speaker.slash" : "speaker" )
                    .frame(width: 25, height: 25)
                    .foregroundColor(.primary)
            }
            .buttonStyle(.bordered)
            .background(.black)
            .cornerRadius(8)
            .padding(.top,8)

            Group {
                if store.isGameOver {
                    Button(action: {
                        store.send(.startGame)
                    }) {
                        Text("New Game")
                            .foregroundColor(.primary)
                    }
                } else if store.isPaused {
                    Button(action: {
                        store.send(.resumeGame)
                    }) {
                        Text("Resume")
                            .foregroundColor(.primary)
                    }
                } else {
                    Button(action: {
                        store.send(.pauseGame)
                    }) {
                        Text("Pause")
                            .foregroundColor(.primary)
                    }
                }
            }
            .buttonStyle(.bordered)
            .background(.black)
            .cornerRadius(8)
            .padding(.top,8)
        }
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
                        x: (CGFloat(column) - 3.5 ) * blockSize,
                        y: (CGFloat(row) - 8.5) * blockSize
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
                        x: (CGFloat(store.piecePosition.column + block.column) - 3.5) * blockSize,
                        y: (CGFloat(store.piecePosition.row + block.row) - 8.5) * blockSize
                    )
            }
        }
    }

    private var scoreView: some View {
        VStack {
            Text("High Score: \(store.highScore)")
                .font(.headline)
                .foregroundColor(store.score > store.highScore && store.score > 0 ? .yellow : .primary)

        }
        .padding()
    }

    private var newLevelView: some View {
        VStack {
            if store.isLevelTransitioning {
                Text("LEVEL \(store.level)")
                    .font(.title2)
                    .foregroundColor(.yellow)
                    .transition(.scale)
                    .animation(.spring(), value: store.level)
            }
        }
        .padding(.top, 40)
    }

    private var controlsView: some View {
        HStack {
            Button(action: { store.send(.moveLeft) }) {
                Image(systemName: "arrow.left")
                    .frame(width: 60, height: 60)
                    .foregroundColor(.primary)
            }

            VStack {
                Button(action: { store.send(.rotate) }) {
                    Image(systemName: "arrow.clockwise")
                        .frame(width: 60, height: 60)
                        .foregroundColor(.primary)
                }

                Button(action: { store.send(.drop) }) {
                    Image(systemName: "arrow.down")
                        .frame(width: 60, height: 60)
                        .foregroundColor(.primary)
                }
            }

            Button(action: { store.send(.moveRight) }) {
                Image(systemName: "arrow.right")
                    .frame(width: 60, height: 60)
                    .foregroundColor(.primary)
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

