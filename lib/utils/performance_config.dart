/// Performance configuration constants for mobile optimization
class PerformanceConfig {
  // Frame rate settings
  static const double targetFps = 60.0;
  static const double aiUpdateFps = 45.0;
  
  // Game physics settings
  static const double maxBallSpeed = 800.0;
  static const double ballSpeedIncrement = 3.0;
  static const double minVerticalSpeed = 60.0;
  static const double maxHorizontalSpeed = 350.0;
  
  // AI settings
  static const double aiSpeed = 380.0;
  static const double aiPredictionOffset = 0.12;
  static const double aiErrorMargin = 15.0;
  static const double aiReactionDelay = 0.02;
  
  // Collision settings
  static const double collisionCooldown = 0.08;
  static const double speedUpdateInterval = 0.1;
  
  // Visual settings
  static const double lottieFrameRate = 24.0;
  static const double cardElevation = 8.0;
  
  // Memory optimization
  static const double cacheUpdateInterval = 0.5;
  static const int maxParticles = 10; // For future particle effects
  
  // Touch sensitivity
  static const double touchSensitivity = 1.0;
  static const double minMovementThreshold = 3.0;
}
