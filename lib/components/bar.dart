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
  static const double _aiUpdateInterval = 1 / 30; // Reduced to 30 fps for AI

  // AI behavior tuning - optimized for performance
  static const double aiSpeed = 350.0; // Reduced move speed
  static const double predictionOffset = 0.12; // Reduced prediction
  static const double errorMargin = 15.0; // Reduced randomness

  late double _maxX;
  final _random = Random();
  
  // Performance caching
  Vector2? _cachedGameSize;
  double? _cachedBarCenterY;

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
    
    // Skip AI update if ball is moving away (optimization)
    if ((isBottom && ballVelocity.y < 0) || (!isBottom && ballVelocity.y > 0)) {
      return;
    }

    // Cache bar center Y position
    _cachedBarCenterY ??= position.y + size.y / 2;

    // Simplified prediction calculation
    final yDistance = (ball.position.y - _cachedBarCenterY!).abs();
    if (yDistance < 50) return; // Don't update if ball is very close
    
    final timeToReach = yDistance / ballVelocity.y.abs();
    final predictedX = ball.position.x + ballVelocity.x * timeToReach * predictionOffset;

    // Reduced error calculation frequency
    final error = (_random.nextDouble() * errorMargin) - (errorMargin / 2);
    final targetX = (predictedX + error - size.x / 2).clamp(0.0, _maxX);

    final currentX = position.x;
    final distance = (targetX - currentX).abs();
    if (distance < 3) return; // Increased threshold to reduce micro-movements

    final moveDistance = aiSpeed * _aiUpdateInterval;
    final direction = (targetX - currentX).sign;
    final newX = (currentX + direction * moveDistance).clamp(0.0, _maxX);

    // Reduced interpolation for snappier movement
    position.x = _lerp(currentX, newX, 0.7);
  }
  
  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _cachedGameSize = size;
    _maxX = size.x - this.size.x;
    _cachedBarCenterY = null; // Recalculate bar center
  }

  double _lerp(double start, double end, double t) => start + (end - start) * t;

  void clearBallCache() => _ballCache = null;
}
