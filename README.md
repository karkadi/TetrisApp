# 🚶‍♂️ Tetris

A classic Tetris game for iPhone, built with SwiftUI and The Composable Architecture (TCA) for a modern, responsive, and testable gaming experience.
Featuring an AI-powered Demo Mode driven by a neural network to showcase intelligent gameplay.

## 📸 Screenshots

<div align="center">
  <img src="./ScreenShoots/demo.png" width="30%" />
  <img src="./ScreenShoots/demo.gif" width="30%" />
</div>

## ✨ Features

**Classic Tetris Gameplay:** Stack falling tetrominoes to clear lines, score points, and progress through increasing difficulty levels.

**AI-Powered Demo Mode**: Watch an intelligent neural network play Tetris autonomously, optimizing moves based on learned strategies to maximize line clears and minimize board clutter.

**Responsive Controls:** Intuitive touch and swipe controls optimized for iPhone.

**High Score Tracking:** Save and display your top scores locally.

**Unit Test Coverage:** 83% test coverage for robust and reliable code.

## 🧠 AI and Neural Network

The Demo Mode leverages a neural network to make intelligent move decisions. The AI evaluates the game state using a feature extractor that analyzes key metrics.
The neural network is trained using a genetic algorithm through self-play, optimizing weights to prioritize moves that lead to higher scores and longer games. The `getBestMove` function calculates the optimal position and rotation for each tetromino based on these features, providing a compelling demonstration of AI-driven gameplay.

## 🛠 Tech Stack

- **Swift**: 5.0+ for modern and performant code.
- **SwiftUI**: For declarative UI, smooth animations, and reusable widgets.
- **The Composable Architecture (TCA)**: For modular, scalable, and testable state management.
- **Swift Concurrency (async/await)**: For efficient game loop management and background tasks.
- **Neural Network**: Custom implementation for AI-driven gameplay in Demo Mode, using a genetic algorithm for training.

## 🏗 Project Structure
```bash
TetrisApp/
 Sources/
 ├── App/                       # Main app entry point
 ├── Core/
 │    ├── Models/              # Game state, tetrominoes, score models
 │    ├── Services/            # Game logic, Game Center integration
 │    │   └── NeuralNetwork/   # AI services
 │    └── Utils/               # Helpers and extensions
 │
 ├── Features/
 │    └── Tetris/              # Game board, controls, and UI
 │
 ├── SharedUI/
 │    └── Components/          # Reusable UI components (buttons, score displays)
 │
 ├── Resources/
 │    └── Assets.xcassets      # Image assets for tetrominoes and UI
 │
 └── Tests/
      ├── UnitTests/           # Unit tests for game logic and models
      └── UITests/             # UI tests for game board and controls
```
## 🚀 Installation
Prerequisites

* Xcode 16 or later

* iOS 18 or later

###Steps

1. Clone the repository:

```bash
git clone https://github.com/karkadi/TetrisApp.git
cd TetrisApp
```
2. Open the project in Xcode:

* Launch Xcode and open TetrisApp.xcodeproj.

3. Enable required capabilities:

* In Xcode, navigate to the project settings.

* Enable Game Center under the Capabilities tab for the app target.

4. Build and run:

* Select an iPhone simulator or device as the target.

* Build and run the app (Cmd + R) to install it on your device.

## 📋 Roadmap

* Enhance AI training with more sophisticated algorithms and real-time feedback.

* Integrate Game Center for global leaderboards and achievements.

* Increase unit test coverage to 90%+ for enhanced reliability.

* Add customizable AI parameters for users to tweak Demo Mode behavior.

## 🤝 Contribution

Pull requests are welcome! For major changes, please open an issue first to discuss what you’d like to change.

## 📄 License

This project is licensed under the MIT License.
See [LICENSE](LICENSE) for details.
