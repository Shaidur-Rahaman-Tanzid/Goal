import 'dart:ui';
import 'package:flutter/foundation.dart';

import 'package:flame/game.dart';
import 'package:flame/collisions.dart';
import 'package:flame/events.dart';

import '../components/ball.dart';
import '../components/bar.dart';
import '../services/score_service.dart';

enum GameWinner {
  none,
  player1, // Player 1 (Bottom) / You
  player2, // Player 2 (Top) in 2-player mode
  ai,      // AI Bot (Top) in 1-player mode
}

class MyGame extends FlameGame with HasCollisionDetection, DragCallbacks {
  late Ball ball;
  late Bar topBar;
  late Bar bottomBar;

  bool isTwoPlayer = false;
  bool isGameOver = false;

  // Reactive notifiers for live, real-time UI updates
  final ValueNotifier<int> scoreNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> bestScoreNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> p1WinsNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> p2WinsNotifier = ValueNotifier<int>(0);

  int get score => scoreNotifier.value;
  set score(int val) => scoreNotifier.value = val;

  int get bestScore => bestScoreNotifier.value;
  set bestScore(int val) => bestScoreNotifier.value = val;

  int get p1Wins => p1WinsNotifier.value;
  set p1Wins(int val) => p1WinsNotifier.value = val;

  int get p2Wins => p2WinsNotifier.value;
  set p2Wins(int val) => p2WinsNotifier.value = val;

  GameWinner winner = GameWinner.none;
  bool isNewHighScore = false;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    collisionDetection = StandardCollisionDetection();
  }

  // Dynamic playfield offsets to ensure the top bar and goals are never obscured by the HUD
  double get topGoalY => (size.y * 0.13).clamp(58.0, 92.0);
  double get topBarY => topGoalY + 26.0;

  void startGame({required bool isTwoPlayer}) {
    this.isTwoPlayer = isTwoPlayer;
    isGameOver = false;
    score = 0;
    winner = GameWinner.none;
    isNewHighScore = false;

    // Load persistent stats
    bestScore = ScoreService.getBestScore1P();
    p1Wins = ScoreService.getP1Wins();
    p2Wins = ScoreService.getP2Wins();

    // Clear previous components
    final componentsToRemove = children.toList();
    removeAll(componentsToRemove);

    // Create styled ball at center kickoff spot
    ball = Ball();
    ball.position = Vector2(size.x * 0.5, (topGoalY + size.y - 16.0) * 0.5);
    ball.size = Vector2.all(22);
    ball.onHitBar = _onBallHitBar;
    ball.onGameOver = _onBallGameOver;

    // Create styled bars (positioned safely below the header and above bottom gesture bar)
    bottomBar = Bar(isBottom: true, isPlayerControlled: true)
      ..size = Vector2(104, 20)
      ..position = Vector2(size.x / 2 - 52, size.y - 52);

    topBar = Bar(
      isBottom: false,
      isPlayerControlled: isTwoPlayer,
    )
      ..size = Vector2(104, 20)
      ..position = Vector2(size.x / 2 - 52, topBarY);

    addAll([ball, topBar, bottomBar]);

    if (!isTwoPlayer) {
      topBar.clearBallCache();
    }

    _removeOverlay('GameOver');
    _removeOverlay('MainMenu');
    _addOverlay('InGameHUD');
  }

  void _addOverlay(String name) {
    try {
      overlays.add(name);
    } catch (_) {}
  }

  void _removeOverlay(String name) {
    try {
      overlays.remove(name);
    } catch (_) {}
  }

  void _onBallHitBar() {
    score++;
    if (!isTwoPlayer && score > bestScore) {
      bestScore = score;
      isNewHighScore = true;
    }
  }

  Future<void> _onBallGameOver(bool isTopBoundary) async {
    if (isGameOver) return;
    isGameOver = true;

    if (isTopBoundary) {
      // Ball passed top paddle -> Player 1 (bottom) scores / wins!
      winner = GameWinner.player1;
      if (!isTwoPlayer) {
        score += 5; // Goal bonus in 1P
        final isRecord = await ScoreService.saveBestScore1P(score);
        if (isRecord) isNewHighScore = true;
      } else {
        await ScoreService.incrementP1Wins();
      }
    } else {
      // Ball passed bottom paddle -> Player 2 or AI scores / wins!
      winner = isTwoPlayer ? GameWinner.player2 : GameWinner.ai;
      if (!isTwoPlayer) {
        final isRecord = await ScoreService.saveBestScore1P(score);
        if (isRecord) isNewHighScore = true;
      } else {
        await ScoreService.incrementP2Wins();
      }
    }

    // Refresh persistent values
    bestScore = ScoreService.getBestScore1P();
    p1Wins = ScoreService.getP1Wins();
    p2Wins = ScoreService.getP2Wins();

    _removeOverlay('InGameHUD');
    _addOverlay('GameOver');
  }

  void resetGame() {
    _removeOverlay('GameOver');
    _removeOverlay('InGameHUD');
    startGame(isTwoPlayer: isTwoPlayer);
  }

  @override
  void onDispose() {
    scoreNotifier.dispose();
    bestScoreNotifier.dispose();
    p1WinsNotifier.dispose();
    p2WinsNotifier.dispose();
    super.onDispose();
  }

  @override
  Color backgroundColor() => const Color(0x00000000);
}
