import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flame/game.dart';
import 'package:lottie/lottie.dart';
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
  bool _isBackgroundVisible = true;

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
    
    // Optimize background animation based on app state
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        setState(() {
          _isBackgroundVisible = false;
        });
        _game.pauseEngine();
        break;
      case AppLifecycleState.resumed:
        setState(() {
          _isBackgroundVisible = true;
        });
        _game.resumeEngine();
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: RepaintBoundary(
        child: Stack(
          children: [
            if (_isBackgroundVisible)
              Positioned.fill(
                child: RepaintBoundary(
                  child: LottieBuilder.asset(
                    'assets/bg.json',
                    fit: BoxFit.contain,
                    frameRate: FrameRate(20.0), // Further reduced for performance
                    alignment: Alignment.center,
                    options: LottieOptions(
                      enableMergePaths: false,
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

class GameOverOverlay extends StatelessWidget {
  final MyGame game;

  const GameOverOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        elevation: 8, // Reduced elevation for better performance
        color: Colors.black87,
        child: Padding(
          padding: const EdgeInsets.all(20), // Slightly reduced padding
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Game Over',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26, // Slightly smaller font
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Score: ${game.score}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  game.overlays.remove('GameOver');
                  game.overlays.add('MainMenu');
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Main Menu'),
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
      child: Card(
        elevation: 8, // Reduced elevation for better performance
        color: Colors.black87,
        child: Padding(
          padding: const EdgeInsets.all(20), // Slightly reduced padding
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose Mode',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26, // Slightly smaller font
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 140, // Fixed width for consistent layout
                child: ElevatedButton(
                  onPressed: () {
                    game.startGame(isTwoPlayer: false);
                    game.overlays.remove('MainMenu');
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('1 Player'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: 140, // Fixed width for consistent layout
                child: ElevatedButton(
                  onPressed: () {
                    game.startGame(isTwoPlayer: true);
                    game.overlays.remove('MainMenu');
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('2 Player'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
