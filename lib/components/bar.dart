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

  // Ultra-optimized AI system
  Ball? _ballCache;
  double _lastAIUpdate = 0.0;
  static const double _aiUpdateInterval = 1 / 40; // 40fps AI updates for better performance
  
  // High-performance AI tuning
  static const double aiSpeed = 350.0;
  static const double predictionMultiplier = 0.1;
  static const double errorVariance = 12.0;
  static const double movementThreshold = 2.5;

  // Pre-cached values for maximum performance
  late double _maxX;
  late double _barHalfWidth;
  final _random = Random();
  
  // AI performance optimizations
  double _aiCacheTimer = 0.0;
  double _targetX = 0.0;
  bool _hasValidTarget = false;
  static const double _aiCacheInterval = 0.3; // Cache AI calculations
  
  // Initialization flag
  bool _isInitialized = false;

  Bar({required this.isBottom, required this.isPlayerControlled})
      : super(priority: 2);

  @override
  Future<void> onLoad() async {
    super.onLoad();
    
    // Optimized paint setup
    paint = Paint()
      ..color = const Color(0xFFF457b9d)
      ..style = PaintingStyle.fill;
    
    add(RectangleHitbox());
    
    // Cache all frequently accessed values
    _maxX = gameRef.size.x - size.x;
    _barHalfWidth = size.x * 0.5;
    _isInitialized = true;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (!isPlayerControlled || !_isInitialized) return;
    
    // Ultra-fast drag handling with minimal calculations
    final deltaX = event.localDelta.x;
    final newX = (position.x + deltaX).clamp(0.0, _maxX);
    
    // Direct position update for immediate response
    position.x = newX;
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // Only run AI for non-player controlled top bars
    if (!isPlayerControlled && !isBottom && _isInitialized) {
      _updateAIOptimized(dt);
    }
  }

  void _updateAIOptimized(double dt) {
    _lastAIUpdate += dt;
    _aiCacheTimer += dt;
    
    // Skip if not time for AI update
    if (_lastAIUpdate < _aiUpdateInterval) return;
    
    final updateDt = _lastAIUpdate;
    _lastAIUpdate = 0.0;

    // Cache ball reference and target calculation less frequently
    if (_ballCache == null || _aiCacheTimer >= _aiCacheInterval) {
      _ballCache = gameRef.children.whereType<Ball>().firstOrNull;
      _aiCacheTimer = 0.0;
      _hasValidTarget = false;
      
      if (_ballCache != null) {
        _calculateAITarget();
      }
    }

    if (!_hasValidTarget || _ballCache == null) return;

    // Ultra-fast movement calculation
    final currentX = position.x;
    final distance = (_targetX - currentX).abs();
    
    // Skip micro-movements for better performance
    if (distance < movementThreshold) return;

    // Optimized movement with direct calculation
    final moveDistance = aiSpeed * updateDt;
    final direction = (_targetX - currentX).sign;
    final newX = (currentX + direction * moveDistance).clamp(0.0, _maxX);

    // Apply movement with minimal smoothing
    position.x = _lerpFast(currentX, newX, 0.95);
  }

  @pragma('vm:prefer-inline')
  void _calculateAITarget() {
    final ball = _ballCache!;
    final ballVel = ball.velocity;
    
    // Skip if ball is moving away from this paddle
    if (ballVel.y > 0) return; // Ball moving down, AI doesn't need to react
    
    // Fast prediction calculation
    final yDiff = (ball.position.y - position.y).abs();
    if (yDiff < 40) return; // Too close, don't calculate
    
    final timeToReach = yDiff / ballVel.y.abs();
    final predictedX = ball.position.x + ballVel.x * timeToReach * predictionMultiplier;
    
    // Add controlled randomness for realistic behavior
    final error = (_random.nextDouble() - 0.5) * errorVariance;
    _targetX = (predictedX + error - _barHalfWidth).clamp(0.0, _maxX);
    _hasValidTarget = true;
  }

  @pragma('vm:prefer-inline')
  double _lerpFast(double start, double end, double t) {
    return start + (end - start) * t;
  }

  // Optimized cache clearing
  void clearBallCache() {
    _ballCache = null;
    _aiCacheTimer = 0.0;
    _hasValidTarget = false;
  }

  // Method for immediate position updates (for networking, etc.)
  void setPosition(double x) {
    if (!_isInitialized) return;
    position.x = x.clamp(0.0, _maxX);
  }
}
