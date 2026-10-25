import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import '../components/bar.dart';
import '../game/my_game.dart';

class Ball extends CircleComponent with HasGameReference<MyGame>, CollisionCallbacks {
  Vector2 velocity = Vector2(150, 200);
  Function()? onHitBar;
  void Function(bool isTopBoundary)? onGameOver;

  // Ultra-optimized cached values
  late double ballRadius;
  late Vector2 gameSize;
  late double gameSizeX;
  late double gameSizeY;
  
  // Highly optimized collision detection
  double _collisionCooldown = 0.0;
  static const double _cooldownDuration = 0.06; // Optimized cooldown
  
  // Performance: reduce frequency of expensive operations
  double _speedUpdateTimer = 0.0;
  double _positionCheckTimer = 0.0;
  static const double _speedUpdateInterval = 0.15; // Less frequent speed updates
  static const double _positionCheckInterval = 0.02; // 50fps position checks
  
  // Pre-calculated constants for maximum performance
  static const double speedIncrement = 2.5;
  static const double maxSpeed = 750.0;
  static const double minVerticalSpeed = 70.0;
  static const double maxHorizontalSpeed = 320.0;
  static const double wallBounceMultiplier = 0.98;

  // Pre-cached rendering objects
  late Paint _shadowPaint;
  late Paint _corePaint;
  late Paint _patchPaint;
  late Paint _seamPaint;
  late Paint _borderPaint;
  late Paint _highlightPaint;
  late Path _centerPatchPath;
  final List<Offset> _seamStarts = [];
  final List<Offset> _seamEnds = [];
  bool _isPaintsReady = false;

  Ball() : super(priority: 1);

  @override
  Future<void> onLoad() async {
    super.onLoad();
    anchor = Anchor.center;
    add(CircleHitbox());

    _updateDimensions(game.size);
    _initPaints();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _updateDimensions(size);
    _initPaints();
  }

  void _updateDimensions(Vector2 size) {
    ballRadius = this.size.x * 0.5;
    gameSize = size;
    gameSizeX = gameSize.x;
    gameSizeY = gameSize.y;
  }

  void _initPaints() {
    _shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);

    _corePaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(-ballRadius * 0.3, -ballRadius * 0.3),
        ballRadius * 1.35,
        const [
          Colors.white,
          Color(0xFFF1F5F9),
          Color(0xFFCBD5E1),
        ],
        const [0.0, 0.65, 1.0],
      )
      ..style = PaintingStyle.fill;

    _patchPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;

    _seamPaint = Paint()
      ..color = const Color(0xFF334155).withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    _borderPaint = Paint()
      ..color = const Color(0xFF64748B).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    _highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;

    // Build authentic soccer ball center pentagon & radiating seam vectors
    _centerPatchPath = Path();
    _seamStarts.clear();
    _seamEnds.clear();

    const int sides = 5;
    final double patchRadius = ballRadius * 0.42;
    for (int i = 0; i < sides; i++) {
      // standard pentagon trigonometry
      final double cosA = (i == 0) ? 0.0 : ((i == 1) ? 0.9510565 : ((i == 2) ? 0.5877852 : ((i == 3) ? -0.5877852 : -0.9510565)));
      final double sinA = (i == 0) ? -1.0 : ((i == 1) ? -0.309017 : ((i == 2) ? 0.809017 : ((i == 3) ? 0.809017 : -0.309017)));

      final double pX = patchRadius * cosA;
      final double pY = patchRadius * sinA;

      if (i == 0) {
        _centerPatchPath.moveTo(pX, pY);
      } else {
        _centerPatchPath.lineTo(pX, pY);
      }

      _seamStarts.add(Offset(pX, pY));
      _seamEnds.add(Offset(ballRadius * cosA * 0.95, ballRadius * sinA * 0.95));
    }
    _centerPatchPath.close();

    _isPaintsReady = true;
  }

  @override
  void render(Canvas canvas) {
    if (!_isPaintsReady) return;

    // 1. Natural ground drop shadow (gives physical elevation above the pitch)
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(0, 3.5),
        width: ballRadius * 1.8,
        height: ballRadius * 0.7,
      ),
      _shadowPaint,
    );

    // 2. Realistic 3D spherical ball body
    canvas.drawCircle(Offset.zero, ballRadius, _corePaint);

    // 3. Classic soccer ball center patch
    canvas.drawPath(_centerPatchPath, _patchPaint);

    // 4. Radiating panel seams
    for (int i = 0; i < _seamStarts.length; i++) {
      canvas.drawLine(_seamStarts[i], _seamEnds[i], _seamPaint);
    }

    // 5. Subtle specular highlight on top-left
    canvas.drawCircle(
      Offset(-ballRadius * 0.35, -ballRadius * 0.35),
      ballRadius * 0.22,
      _highlightPaint,
    );

    // 6. Clean crisp rim
    canvas.drawCircle(Offset.zero, ballRadius, _borderPaint);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Optimized cooldown update
    if (_collisionCooldown > 0) {
      _collisionCooldown -= dt;
    }

    // Position update
    final velocityX = velocity.x;
    final velocityY = velocity.y;
    position.x += velocityX * dt;
    position.y += velocityY * dt;

    _speedUpdateTimer += dt;
    _positionCheckTimer += dt;

    if (_speedUpdateTimer >= _speedUpdateInterval) {
      _speedUpdateTimer = 0.0;
      _updateSpeedOptimized();
    }

    if (_positionCheckTimer >= _positionCheckInterval) {
      _positionCheckTimer = 0.0;
      _handleBoundaryChecks();
    }
  }

  @pragma('vm:prefer-inline')
  void _updateSpeedOptimized() {
    final currentSpeed = velocity.length;
    if (currentSpeed < maxSpeed) {
      const speedIncrease = speedIncrement * _speedUpdateInterval;
      final newSpeed = (currentSpeed + speedIncrease).clamp(currentSpeed, maxSpeed);
      final normalizer = newSpeed / currentSpeed;
      velocity.x *= normalizer;
      velocity.y *= normalizer;
    }
  }

  @pragma('vm:prefer-inline')
  void _handleBoundaryChecks() {
    final posX = position.x;
    final posY = position.y;
    
    // Wall collisions
    if (posX <= ballRadius) {
      position.x = ballRadius;
      velocity.x = (velocity.x.abs() * wallBounceMultiplier).clamp(0, maxHorizontalSpeed);
    } else if (posX >= gameSizeX - ballRadius) {
      position.x = gameSizeX - ballRadius;
      velocity.x = (-velocity.x.abs() * wallBounceMultiplier).clamp(-maxHorizontalSpeed, 0);
    }
    
    // Game over check with winner detection
    final topGoalLimit = game.topGoalY;
    if (posY <= ballRadius + topGoalLimit) {
      // Ball passed TOP goal line (Player 1 scores / wins!)
      velocity.setZero();
      onGameOver?.call(true);
    } else if (posY >= gameSizeY - ballRadius - 16.0) {
      // Ball passed BOTTOM goal line (Player 2 or AI scores / wins!)
      velocity.setZero();
      onGameOver?.call(false);
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Bar && _collisionCooldown <= 0) {
      _collisionCooldown = _cooldownDuration;
      _handleBarCollisionOptimized(other);
      onHitBar?.call();
    }
    super.onCollision(intersectionPoints, other);
  }

  @pragma('vm:prefer-inline')
  void _handleBarCollisionOptimized(Bar bar) {
    final barCenterX = bar.position.x + bar.size.x * 0.5;
    final barHalfWidth = bar.size.x * 0.5;
    final relativeHitX = ((position.x - barCenterX) / barHalfWidth).clamp(-1.0, 1.0);

    // Optimized velocity changes
    velocity.y = -velocity.y; // Reverse Y direction
    velocity.x += relativeHitX * 85; // Add horizontal angle
    
    // Fast clamping
    velocity.x = velocity.x.clamp(-maxHorizontalSpeed, maxHorizontalSpeed);
    
    // Ensure minimum vertical speed
    final absVelY = velocity.y.abs();
    if (absVelY < minVerticalSpeed) {
      velocity.y = velocity.y > 0 ? minVerticalSpeed : -minVerticalSpeed;
    }

    // Position correction to prevent clipping
    final isTopBar = bar.position.y < gameSizeY * 0.5;
    position.y = isTopBar 
      ? bar.position.y + bar.size.y + ballRadius + 1
      : bar.position.y - ballRadius - 1;
  }

  // Method to reset ball state efficiently
  void resetBall() {
    position = Vector2(gameSizeX * 0.5, (game.topGoalY + gameSizeY - 16.0) * 0.5);
    velocity.setValues(150, 200);
    _collisionCooldown = 0.0;
    _speedUpdateTimer = 0.0;
    _positionCheckTimer = 0.0;
  }
}
