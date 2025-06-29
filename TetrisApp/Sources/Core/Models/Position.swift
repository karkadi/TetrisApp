//
//  Position.swift
//  TetrisApp
//
//  Created by Arkadiy KAZAZYAN on 30/09/2025.
//
import Foundation

/// A structure representing the position of a block in a two-dimensional grid.
///
/// The `Position` type consists of two integer properties: `row` and `column`
/// which indicate the respective coordinates in the grid. This is commonly used
/// to track the location of individual blocks within a tetromino in a Tetris game.
struct Position: Equatable {
    var row: Int
    var column: Int
}
