import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/events.dart';

import '../components/ball.dart';
import '../components/bar.dart';


class MyGame extends FlameGame with  HasCollisionDetection, DragCallbacks {
  late Ball ball;
  late Bar topBar;
  late Bar bottomBar;

  bool isTwoPlayer = false;
  bool isGameOver = false;
  int score = 0;

  void startGame({required bool isTwoPlayer}) {
    this.isTwoPlayer = isTwoPlayer;
    isGameOver = false;
    score = 0;

    removeAll(children.toList());

    // Create the ball
    ball = Ball();
    ball.position = size / 2;
    ball.size = Vector2.all(20);
    ball.onHitBar = () => score += 1;
    ball.onGameOver = () => gameOver();

    // Bottom player bar (always draggable)
    bottomBar = Bar(isBottom: true, isPlayerControlled: true)
      ..size = Vector2(100, 20)
      ..position = Vector2(size.x / 2 - 50, size.y - 40);

    // Top bar: AI or player controlled
    topBar = Bar(
      isBottom: false,
      isPlayerControlled: isTwoPlayer,
    )..size = Vector2(100, 20)
      ..position = Vector2(size.x / 2 - 50, 20);

    addAll([ball, topBar, bottomBar]);
  }

  void gameOver() {
    if (!isGameOver) {
      isGameOver = true;
      overlays.add('GameOver');
    }
  }

  void resetGame() {
    startGame(isTwoPlayer: isTwoPlayer);
    overlays.remove('GameOver');
  }

  @override
  Color backgroundColor() => const Color(0x00000000);
}
