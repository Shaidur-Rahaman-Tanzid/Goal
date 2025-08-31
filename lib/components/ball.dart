import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import '../components/bar.dart';

class Ball extends CircleComponent with HasGameRef, CollisionCallbacks {
  Vector2 velocity = Vector2(150, 200);
  Function()? onHitBar;
  Function()? onGameOver;

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
  static const double wallBounceMultiplier = 0.98; // Slight energy loss on wall bounce

  Ball() : super(priority: 1);

  @override
  Future<void> onLoad() async {
    super.onLoad();
    anchor = Anchor.center;
    add(CircleHitbox());

    // Cache all frequently used values
    ballRadius = size.x * 0.5; // Faster than division
    gameSize = gameRef.size;
    gameSizeX = gameSize.x;
    gameSizeY = gameSize.y;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Optimized cooldown update
    if (_collisionCooldown > 0) {
      _collisionCooldown -= dt;
    }

    // Ultra-optimized position update (most critical for performance)
    final velocityX = velocity.x;
    final velocityY = velocity.y;
    position.x += velocityX * dt;
    position.y += velocityY * dt;

    // Reduce frequency of expensive operations
    _speedUpdateTimer += dt;
    _positionCheckTimer += dt;

    // Speed updates less frequently
    if (_speedUpdateTimer >= _speedUpdateInterval) {
      _speedUpdateTimer = 0.0;
      _updateSpeedOptimized();
    }

    // Position checks at controlled frequency
    if (_positionCheckTimer >= _positionCheckInterval) {
      _positionCheckTimer = 0.0;
      _handleBoundaryChecks();
    }
  }

  @pragma('vm:prefer-inline')
  void _updateSpeedOptimized() {
    final currentSpeed = velocity.length;
    if (currentSpeed < maxSpeed) {
      final speedIncrease = speedIncrement * _speedUpdateInterval;
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
    
    // Ultra-optimized wall collisions
    if (posX <= ballRadius) {
      position.x = ballRadius;
      velocity.x = (velocity.x.abs() * wallBounceMultiplier).clamp(0, maxHorizontalSpeed);
    } else if (posX >= gameSizeX - ballRadius) {
      position.x = gameSizeX - ballRadius;
      velocity.x = (-velocity.x.abs() * wallBounceMultiplier).clamp(-maxHorizontalSpeed, 0);
    }
    
    // Game over check (top/bottom boundaries)
    if (posY <= ballRadius || posY >= gameSizeY - ballRadius) {
      velocity.setZero();
      onGameOver?.call();
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
    // Ultra-fast collision response
    final barCenterX = bar.position.x + bar.size.x * 0.5;
    final barHalfWidth = bar.size.x * 0.5;
    final relativeHitX = ((position.x - barCenterX) / barHalfWidth).clamp(-1.0, 1.0);

    // Optimized velocity changes
    velocity.y = -velocity.y; // Reverse Y direction
    velocity.x += relativeHitX * 75; // Add horizontal component
    
    // Fast clamping
    velocity.x = velocity.x.clamp(-maxHorizontalSpeed, maxHorizontalSpeed);
    
    // Ensure minimum vertical speed
    final absVelY = velocity.y.abs();
    if (absVelY < minVerticalSpeed) {
      velocity.y = velocity.y > 0 ? minVerticalSpeed : -minVerticalSpeed;
    }

    // Optimized position correction
    final isTopBar = bar.position.y < gameSizeY * 0.5;
    position.y = isTopBar 
      ? bar.position.y + bar.size.y + ballRadius + 1
      : bar.position.y - ballRadius - 1;
  }

  // Method to reset ball state efficiently
  void resetBall() {
    position = gameSize * 0.5;
    velocity.setValues(150, 200);
    _collisionCooldown = 0.0;
    _speedUpdateTimer = 0.0;
    _positionCheckTimer = 0.0;
  }
}