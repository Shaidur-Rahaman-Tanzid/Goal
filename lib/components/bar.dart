import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/collisions.dart';
import '../components/ball.dart';

class Bar extends RectangleComponent
    with CollisionCallbacks, DragCallbacks, HasGameRef {
  final bool isBottom;
  bool isPlayerControlled;

  Ball? _ballCache;
  double _lastAIUpdate = 0.0;
  static const double _aiUpdateInterval = 1 / 60; // 60 fps

  // AI behavior tuning
  static const double aiSpeed = 450.0; // move speed
  static const double predictionOffset = 0.15; // higher = more prediction
  static const double errorMargin = 20.0; // randomness

  late double _maxX;
  final _random = Random();

  Bar({required this.isBottom, required this.isPlayerControlled})
      : super(priority: 2);

  @override
  Future<void> onLoad() async {
    super.onLoad();
    paint = Paint()..color = const Color(0xFFF457b9d);
    add(RectangleHitbox());
    _maxX = gameRef.size.x - size.x;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (!isPlayerControlled) return;
    final newX = (position.x + event.localDelta.x).clamp(0.0, _maxX);
    position.x = newX;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isPlayerControlled && !isBottom) {
      _updateAI(dt);
    }
  }

  void _updateAI(double dt) {
    _lastAIUpdate += dt;
    if (_lastAIUpdate < _aiUpdateInterval) return;
    _lastAIUpdate = 0.0;

    _ballCache ??= gameRef.children.whereType<Ball>().firstOrNull;
    if (_ballCache == null) return;

    final ball = _ballCache!;
    final ballVelocity = ball.velocity;

    // Predict ball future X when it reaches paddle Y
    final yDistance = (ball.position.y - position.y).abs();
    final timeToReach = yDistance / ballVelocity.y.abs();
    final predictedX = ball.position.x + ballVelocity.x * timeToReach * predictionOffset;

    // Add error margin to make it imperfect
    final error = (_random.nextDouble() * errorMargin) - (errorMargin / 2);
    final targetX = (predictedX + error - size.x / 2).clamp(0.0, _maxX);

    final currentX = position.x;
    final distance = (targetX - currentX).abs();
    if (distance < 2) return;

    final moveDistance = aiSpeed * _aiUpdateInterval;
    final direction = (targetX - currentX).sign;
    final newX = (currentX + direction * moveDistance).clamp(0.0, _maxX);

    // Smooth interpolation
    position.x = _lerp(currentX, newX, 0.85);
  }

  double _lerp(double start, double end, double t) => start + (end - start) * t;

  void clearBallCache() => _ballCache = null;
}
