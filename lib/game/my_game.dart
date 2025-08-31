import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/events.dart';

import '../components/ball.dart';
import '../components/bar.dart';


class MyGame extends FlameGame with HasCollisionDetection, DragCallbacks {
  late Ball ball;
  late Bar topBar;
  late Bar bottomBar;

  bool isTwoPlayer = false;
  bool isGameOver = false;
  int score = 0;
  
  // Performance optimization flags
  bool _isEngineOptimized = false;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    
    // Advanced collision detection optimization
    collisionDetection = StandardCollisionDetection();
    
    // Optimize engine settings
    _optimizeEngine();
  }
  
  void _optimizeEngine() {
    if (_isEngineOptimized) return;
    
    // Engine is already optimized by default in newer Flame versions
    // Just mark as optimized to avoid repeated calls
    _isEngineOptimized = true;
  }

  void startGame({required bool isTwoPlayer}) {
    this.isTwoPlayer = isTwoPlayer;
    isGameOver = false;
    score = 0;

    // Efficiently clear previous game objects
    final componentsToRemove = children.toList();
    removeAll(componentsToRemove);

    // Create optimized ball
    ball = Ball();
    ball.position = size / 2;
    ball.size = Vector2.all(20);
    ball.onHitBar = _onBallHitBar;
    ball.onGameOver = gameOver;

    // Create bars with optimized settings
    bottomBar = Bar(isBottom: true, isPlayerControlled: true)
      ..size = Vector2(100, 20)
      ..position = Vector2(size.x / 2 - 50, size.y - 40);

    topBar = Bar(
      isBottom: false,
      isPlayerControlled: isTwoPlayer,
    )..size = Vector2(100, 20)
      ..position = Vector2(size.x / 2 - 50, 20);

    // Add all components at once for better performance
    addAll([ball, topBar, bottomBar]);
    
    // Clear AI caches
    if (!isTwoPlayer) {
      topBar.clearBallCache();
    }
  }
  
  // Inline score increment for better performance
  void _onBallHitBar() {
    score++;
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
