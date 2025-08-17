import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:lottie/lottie.dart';
import 'game/my_game.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(
              child: LottieBuilder.asset(
                'assets/bg.json',
                fit: BoxFit.contain,
                frameRate: FrameRate(30.0),
                alignment: Alignment.center,
              ),
            ),
            GameWidget<MyGame>(
              game: MyGame(),
              backgroundBuilder: (context) => const SizedBox.shrink(), // 👈 important!
              overlayBuilderMap: {
                'GameOver': (context, game) => GameOverOverlay(game: game),
                'MainMenu': (context, game) => MainMenuOverlay(game: game),
              },
              initialActiveOverlays: const ['MainMenu'],
            ),
          ],
        ),
      ),
    ),
  );
}

class GameOverOverlay extends StatelessWidget {
  final MyGame game;

  const GameOverOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        elevation: 10,
        color: Colors.black87,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Game Over', style: TextStyle(color: Colors.white, fontSize: 28)),
              const SizedBox(height: 16),
              Text('Score: ${game.score}', style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  game.overlays.remove('GameOver');
                  game.overlays.add('MainMenu');
                },
                child: const Text('Main Menu'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MainMenuOverlay extends StatelessWidget {
  final MyGame game;

  const MainMenuOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        elevation: 10,
        color: Colors.black,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Choose Mode', style: TextStyle(color: Colors.white, fontSize: 28)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  game.startGame(isTwoPlayer: false);
                  game.overlays.remove('MainMenu');
                },
                child: const Text('1 Player'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  game.startGame(isTwoPlayer: true);
                  game.overlays.remove('MainMenu');
                },
                child: const Text('2 Player'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
