import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import '../components/bar.dart';

class Ball extends CircleComponent with HasGameRef, CollisionCallbacks {
  Vector2 velocity = Vector2(150, 200);
  double speedIncreaseRate = 5.0; // Speed increment per second
  Function()? onHitBar;
  Function()? onGameOver;

  // Cache radius to avoid repeated calculations
  late double ballRadius;

  // Add collision cooldown to prevent multiple collisions
  double _collisionCooldown = 0.0;
  static const double _cooldownDuration = 0.1; // 100ms cooldown

  Ball() : super(priority: 1);

  @override
  Future<void> onLoad() async {
    super.onLoad();
    anchor = Anchor.center;
    add(CircleHitbox());

    // Cache the radius after size is set
    ballRadius = size.x / 2;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Update collision cooldown
    if (_collisionCooldown > 0) {
      _collisionCooldown -= dt;
    }

    // Increase speed gradually (less frequently)
    final currentSpeed = velocity.length;
    if (currentSpeed < 1000) { // Only increase if below max
      final newSpeed = currentSpeed + speedIncreaseRate * dt;
      velocity = velocity.normalized() * newSpeed.clamp(currentSpeed, 1000);
    }

    // Move position
    position += velocity * dt;

    // Cache game size for better performance
    final gameSize = gameRef.size;

    // Wall collision - simpler approach
    if (position.x <= ballRadius) {
      position.x = ballRadius;
      velocity.x = velocity.x.abs();
    } else if (position.x >= gameSize.x - ballRadius) {
      position.x = gameSize.x - ballRadius;
      velocity.x = -velocity.x.abs();
    }

    // Game over check
    if (position.y <= ballRadius || position.y >= gameSize.y - ballRadius) {
      velocity = Vector2.zero();
      onGameOver?.call();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Bar) {
      // Calculate the collision point relative to the bar's center
      final barCenter = other.position + other.size / 2;
      final ballCenter = position;

      // Calculate hit position on the bar (-1 to 1, where 0 is center)
      final relativeHitX = (ballCenter.x - barCenter.x) / (other.size.x / 2);

      // Reverse vertical direction
      velocity.y *= -1;

      // Add horizontal component based on where the ball hits the bar
      // This creates more interesting gameplay
      velocity.x += relativeHitX * 100; // Adjust multiplier for desired effect

      // Clamp horizontal speed to prevent excessive speeds
      velocity.x = velocity.x.clamp(-400, 400);

      // Ensure minimum vertical speed to prevent ball getting stuck
      if (velocity.y.abs() < 50) {
        velocity.y = velocity.y > 0 ? 50 : -50;
      }

      // Move ball out of collision to prevent sticking
      if (other.position.y < gameRef.size.y / 2) {
        // Top bar - move ball below it
        position.y = other.position.y + other.size.y + ballRadius + 1;
      } else {
        // Bottom bar - move ball above it
        position.y = other.position.y - ballRadius - 1;
      }

      onHitBar?.call();
    }
    super.onCollision(intersectionPoints, other);
  }
}