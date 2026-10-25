import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flame/game.dart';
import 'game/my_game.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Advanced performance optimizations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Optimize for performance
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  
  // Enable hardware acceleration
  debugProfileBuildsEnabled = false;
  debugProfilePaintsEnabled = false;
  
  runApp(const GameApp());
}

class GameApp extends StatelessWidget {
  const GameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Goal',
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.0), // Prevent text scaling issues
          ),
          child: child!,
        );
      },
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late MyGame _game;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _game = MyGame();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Pause/resume game based on app state
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _game.pauseEngine();
        break;
      case AppLifecycleState.resumed:
        _game.resumeEngine();
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RepaintBoundary(
        child: Stack(
          children: [
            // Static gradient background that matches game vibe
            Positioned.fill(
              child: RepaintBoundary(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.5,
                      colors: [
                        Color(0xFF1a1a2e), // Dark blue center
                        Color(0xFF16213e), // Medium blue
                        Color(0xFF0f0f23), // Very dark blue edges
                      ],
                      stops: [0.0, 0.6, 1.0],
                    ),
                  ),
                  child: CustomPaint(
                    painter: StarFieldPainter(),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
            RepaintBoundary(
              child: GameWidget<MyGame>(
                game: _game,
                backgroundBuilder: (context) => const SizedBox.shrink(),
                overlayBuilderMap: {
                  'GameOver': (context, game) => GameOverOverlay(game: game),
                  'MainMenu': (context, game) => MainMenuOverlay(game: game),
                },
                initialActiveOverlays: const ['MainMenu'],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for static star field background
class StarFieldPainter extends CustomPainter {
  static final List<Offset> _stars = _generateStars();
  
  static List<Offset> _generateStars() {
    final stars = <Offset>[];
    const starCount = 150;
    
    for (int i = 0; i < starCount; i++) {
      // Create pseudo-random but consistent star positions
      final x = (i * 73.0) % 1.0;
      final y = (i * 127.0) % 1.0;
      stars.add(Offset(x, y));
    }
    
    return stars;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final dimPaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    final veryDimPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    // Draw stars at different brightness levels
    for (int i = 0; i < _stars.length; i++) {
      final star = _stars[i];
      final x = star.dx * size.width;
      final y = star.dy * size.height;
      
      // Vary star brightness and size
      if (i % 7 == 0) {
        canvas.drawCircle(Offset(x, y), 2.0, paint);
      } else if (i % 3 == 0) {
        canvas.drawCircle(Offset(x, y), 1.5, dimPaint);
      } else {
        canvas.drawCircle(Offset(x, y), 1.0, veryDimPaint);
      }
    }

    // Add some subtle nebula effect
    final nebulaPaint = Paint()
      ..color = const Color(0xFF4a5568).withOpacity(0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    canvas.drawCircle(
      Offset(size.width * 0.3, size.height * 0.2),
      size.width * 0.4,
      nebulaPaint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.7),
      size.width * 0.3,
      nebulaPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GameOverOverlay extends StatelessWidget {
  final MyGame game;

  const GameOverOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2d3748),
              Color(0xFF1a202c),
            ],
          ),
          border: Border.all(
            color: const Color(0xFF4a5568),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Custom logo (smaller for game over screen)
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF63b3ed).withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/Retro Game Logo Design.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Game Over',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Color(0xFF63b3ed),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Score: ${game.score}',
                style: const TextStyle(
                  color: Color(0xFFa0aec0),
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  game.overlays.remove('GameOver');
                  game.overlays.add('MainMenu');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3182ce),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 8,
                ),
                child: const Text(
                  'Main Menu',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MainMenuOverlay extends StatelessWidget {
  final MyGame game;

  const MainMenuOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2d3748),
              Color(0xFF1a202c),
            ],
          ),
          border: Border.all(
            color: const Color(0xFF4a5568),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Custom logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF63b3ed).withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/Retro Game Logo Design.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Goal',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                  shadows: [
                    Shadow(
                      color: Color(0xFF63b3ed),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose Mode',
                style: TextStyle(
                  color: Color(0xFFa0aec0),
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 160,
                child: ElevatedButton(
                  onPressed: () {
                    game.startGame(isTwoPlayer: false);
                    game.overlays.remove('MainMenu');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3182ce),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 8,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person, size: 20),
                      SizedBox(width: 8),
                      Text(
                        '1 Player',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 160,
                child: ElevatedButton(
                  onPressed: () {
                    game.startGame(isTwoPlayer: true);
                    game.overlays.remove('MainMenu');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF38a169),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 8,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people, size: 20),
                      SizedBox(width: 8),
                      Text(
                        '2 Player',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
