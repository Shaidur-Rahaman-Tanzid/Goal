import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/collisions.dart';
import '../components/ball.dart';
import '../game/my_game.dart';
import '../utils/game_theme.dart';

class Bar extends RectangleComponent
    with CollisionCallbacks, DragCallbacks, HasGameReference<MyGame> {
  final bool isBottom;
  bool isPlayerControlled;

  // Cached ball reference
  Ball? _ballCache;

  // AI speed settings
  static const double aiSpeed = 400.0;

  // Cached layout values
  late double _maxX;
  late double _barHalfWidth;
  bool _isInitialized = false;

  // Pre-cached rendering objects (zero allocations in render loop)
  late Paint _shadowPaint;
  late Paint _bodyPaint;
  late Paint _borderPaint;
  late Paint _highlightPaint;
  late Paint _gripPaint;
  late RRect _rrect;
  late RRect _shadowRrect;
  late RRect _highlightRrect;

  Bar({required this.isBottom, required this.isPlayerControlled})
      : super(priority: 2);

  @override
  Future<void> onLoad() async {
    super.onLoad();

    add(RectangleHitbox());

    _updateDimensions(size);
    _initPaints();
    _isInitialized = true;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _updateDimensions(size);
    if (_isInitialized) {
      _initPaints();
    }
  }

  void _updateDimensions(Vector2 gameSize) {
    _maxX = (gameSize.x - size.x).clamp(0.0, double.infinity);
    _barHalfWidth = size.x * 0.5;

    final rect = size.toRect();
    _rrect = RRect.fromRectAndRadius(rect, Radius.circular(size.y * 0.5));
    _shadowRrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(rect.left + 2, rect.top + 4, rect.width - 4, rect.height),
      Radius.circular(size.y * 0.5),
    );
    _highlightRrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        rect.left + 8,
        rect.top + 2,
        rect.width - 16,
        rect.height * 0.35,
      ),
      Radius.circular(size.y * 0.25),
    );
  }

  void _initPaints() {
    final baseColor = isBottom ? GameTheme.player1 : GameTheme.player2;
    final darkColor = isBottom ? GameTheme.player1Dark : GameTheme.player2Dark;

    _shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    _bodyPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(0, size.y),
        [baseColor, darkColor],
      )
      ..style = PaintingStyle.fill;

    _borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    _highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    _gripPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
  }

  @override
  void render(Canvas canvas) {
    if (!_isInitialized) return;

    // 1. Natural ground drop shadow (elevates paddle above the pitch)
    canvas.drawRRect(_shadowRrect, _shadowPaint);

    // 2. Smooth athletic striker body
    canvas.drawRRect(_rrect, _bodyPaint);

    // 3. Subtle top specular highlight
    canvas.drawRRect(_highlightRrect, _highlightPaint);

    // 4. Center tactile grip pinstripes
    final centerX = size.x * 0.5;
    final centerY = size.y * 0.5;
    canvas.drawLine(Offset(centerX - 8, centerY - 3), Offset(centerX - 8, centerY + 3), _gripPaint);
    canvas.drawLine(Offset(centerX, centerY - 4), Offset(centerX, centerY + 4), _gripPaint);
    canvas.drawLine(Offset(centerX + 8, centerY - 3), Offset(centerX + 8, centerY + 3), _gripPaint);

    // 5. Clean, elegant rim
    canvas.drawRRect(_rrect, _borderPaint);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (!isPlayerControlled || !_isInitialized) return;

    // Direct position update for immediate response
    final deltaX = event.localDelta.x;
    final newX = (position.x + deltaX).clamp(0.0, _maxX);
    position.x = newX;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Only run AI for non-player controlled top bars
    if (!isPlayerControlled && !isBottom && _isInitialized) {
      _updateAI(dt);
    }
  }

  void _updateAI(double dt) {
    // Ensure we have a valid ball reference
    if (_ballCache == null || !_ballCache!.isMounted) {
      _ballCache = game.children.whereType<Ball>().firstOrNull;
      if (_ballCache == null) return;
    }

    final ball = _ballCache!;
    final ballVel = ball.velocity;

    double targetCenterX;
    double maxSpeed;

    if (ballVel.y < 0) {
      // Ball is moving towards the AI paddle (upwards)
      // Directly track the ball's horizontal position
      targetCenterX = ball.position.x;
      maxSpeed = aiSpeed;
    } else {
      // Ball is moving away (downwards towards player)
      // Smoothly return towards the center of the field for optimal defense
      targetCenterX = game.size.x * 0.5;
      maxSpeed = aiSpeed * 0.65;
    }

    final targetX = (targetCenterX - _barHalfWidth).clamp(0.0, _maxX);
    final currentX = position.x;
    final diff = targetX - currentX;
    final distance = diff.abs();

    // Deadzone: if already aligned within 0.5px, stay completely still
    if (distance < 0.5) return;

    // Smooth proportional speed: decelerates cleanly when close to target to prevent any overshoot
    final desiredSpeed = (distance * 12.0).clamp(40.0, maxSpeed);
    final step = desiredSpeed * dt;

    if (step >= distance) {
      position.x = targetX;
    } else {
      position.x += diff.sign * step;
    }
  }

  // Clear ball cache when game resets or restarts
  void clearBallCache() {
    _ballCache = null;
  }

  // Method for immediate position updates (for networking, etc.)
  void setPosition(double x) {
    if (!_isInitialized) return;
    position.x = x.clamp(0.0, _maxX);
  }
}
