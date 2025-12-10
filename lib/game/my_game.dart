import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/events.dart';
import 'package:flutter/services.dart';

import '../components/ball.dart';
import '../components/bar.dart';

class MyGame extends FlameGame with HasCollisionDetection, DragCallbacks {
  static const double targetFps = 60.0;
  static const double frameTime = 1.0 / targetFps;
  
  late Ball ball;
  late Bar topBar;
  late Bar bottomBar;

  bool isTwoPlayer = false;
  bool isGameOver = false;
  int score = 0;
  
  // Performance optimization: cache game size
  late Vector2 _gameSize;
  
  // Frame rate control
  double _accumulator = 0.0;
  
  @override
  Future<void> onLoad() async {
    super.onLoad();
    
    // Enable performance mode
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    // Cache game size
    _gameSize = size;
  }

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
  void update(double dt) {
    // Frame rate limiting for consistent performance on low-end devices
    _accumulator += dt;
    
    if (_accumulator >= frameTime) {
      super.update(_accumulator);
      _accumulator = 0.0;
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _gameSize = size;
  }

  @override
  Color backgroundColor() => const Color(0x00000000);
}
