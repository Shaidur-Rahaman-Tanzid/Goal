import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flame/game.dart';

import 'game/my_game.dart';
import 'services/score_service.dart';
import 'utils/game_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ScoreService.init();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  debugProfileBuildsEnabled = false;
  debugProfilePaintsEnabled = false;

  runApp(const GameApp());
}

class GameApp extends StatelessWidget {
  const GameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Goal - Bounce & Win!',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: GameTheme.pitchBase,
      ),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.0),
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
      backgroundColor: GameTheme.pitchBase,
      body: RepaintBoundary(
        child: Stack(
          children: [
            // Authentic stadium football pitch background
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: StadiumPitchBackgroundPainter(),
                  size: Size.infinite,
                ),
              ),
            ),
            RepaintBoundary(
              child: GameWidget<MyGame>(
                game: _game,
                backgroundBuilder: (context) => const SizedBox.shrink(),
                overlayBuilderMap: {
                  'MainMenu': (context, game) => MainMenuOverlay(game: game),
                  'GameOver': (context, game) => GameOverOverlay(game: game),
                  'InGameHUD': (context, game) => InGameHUDOverlay(game: game),
                  'PauseMenu': (context, game) => PauseMenuOverlay(game: game),
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

/// Authentic Stadium Football Pitch Custom Painter
/// Clean championship lawn mowing bands, natural chalk lines, penalty areas, and floodlight vignette.
class StadiumPitchBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // 1. Natural alternating turf bands (authentic lawn mower cut stripes)
    const int stripeCount = 12;
    final double stripeHeight = size.height / stripeCount;
    final Paint stripeDark = Paint()..color = GameTheme.pitchBase;
    final Paint stripeLight = Paint()..color = GameTheme.pitchLawnBand;

    for (int i = 0; i < stripeCount; i++) {
      final rect = Rect.fromLTWH(0, i * stripeHeight, size.width, stripeHeight + 0.5);
      canvas.drawRect(rect, i.isEven ? stripeDark : stripeLight);
    }

    // 2. Realistic stadium floodlight vignette (soft illumination focused on the center)
    final vignettePaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.15,
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.38),
        ],
        stops: const [0.55, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, vignettePaint);

    // 3. Chalk pitch markings
    final linePaint = Paint()
      ..color = GameTheme.pitchLine
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final fillGoalZone = Paint()
      ..color = GameTheme.pitchGoalArea
      ..style = PaintingStyle.fill;

    final double topMargin = (size.height * 0.13).clamp(58.0, 92.0);
    const double bottomMargin = 16.0;
    const double sideMargin = 16.0;
    final pitchRect = Rect.fromLTRB(sideMargin, topMargin, size.width - sideMargin, size.height - bottomMargin);

    // Outer pitch boundary with rounded corners
    canvas.drawRRect(RRect.fromRectAndRadius(pitchRect, const Radius.circular(8.0)), linePaint);

    final double centerX = size.width * 0.5;
    final double centerY = (topMargin + size.height - bottomMargin) * 0.5;
    final double pitchWidth = pitchRect.width;
    final double pitchHeight = pitchRect.height;

    // Center halfway line
    canvas.drawLine(Offset(sideMargin, centerY), Offset(size.width - sideMargin, centerY), linePaint);

    // Center circle
    canvas.drawCircle(Offset(centerX, centerY), 48.0, linePaint);

    // Center kickoff spot
    final spotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(centerX, centerY), 3.5, spotPaint);

    // --- Top Goal & Penalty Box (Top Player / AI Defense Zone) ---
    final double penaltyWidth = pitchWidth * 0.62;
    final double penaltyHeight = pitchHeight * 0.14;
    final penaltyTopRect = Rect.fromCenter(
      center: Offset(centerX, topMargin + penaltyHeight * 0.5),
      width: penaltyWidth,
      height: penaltyHeight,
    );
    canvas.drawRect(penaltyTopRect, fillGoalZone);
    canvas.drawRect(penaltyTopRect, linePaint);

    // Top Goal Area (6-yard box)
    final double goalAreaWidth = pitchWidth * 0.32;
    final double goalAreaHeight = pitchHeight * 0.055;
    final goalAreaTopRect = Rect.fromCenter(
      center: Offset(centerX, topMargin + goalAreaHeight * 0.5),
      width: goalAreaWidth,
      height: goalAreaHeight,
    );
    canvas.drawRect(goalAreaTopRect, linePaint);

    // Top penalty spot
    canvas.drawCircle(Offset(centerX, topMargin + penaltyHeight * 0.72), 3.0, spotPaint);

    // --- Bottom Goal & Penalty Box (Player 1 Defense Zone) ---
    final penaltyBottomRect = Rect.fromCenter(
      center: Offset(centerX, size.height - bottomMargin - penaltyHeight * 0.5),
      width: penaltyWidth,
      height: penaltyHeight,
    );
    canvas.drawRect(penaltyBottomRect, fillGoalZone);
    canvas.drawRect(penaltyBottomRect, linePaint);

    // Bottom Goal Area
    final goalAreaBottomRect = Rect.fromCenter(
      center: Offset(centerX, size.height - bottomMargin - goalAreaHeight * 0.5),
      width: goalAreaWidth,
      height: goalAreaHeight,
    );
    canvas.drawRect(goalAreaBottomRect, linePaint);

    // Bottom penalty spot
    canvas.drawCircle(Offset(centerX, size.height - bottomMargin - penaltyHeight * 0.72), 3.0, spotPaint);

    // Corner flag arcs
    canvas.drawArc(Rect.fromCircle(center: Offset(sideMargin, topMargin), radius: 12), 0, 1.57, false, linePaint);
    canvas.drawArc(Rect.fromCircle(center: Offset(size.width - sideMargin, topMargin), radius: 12), 1.57, 1.57, false, linePaint);
    canvas.drawArc(Rect.fromCircle(center: Offset(sideMargin, size.height - bottomMargin), radius: 12), 4.71, 1.57, false, linePaint);
    canvas.drawArc(Rect.fromCircle(center: Offset(size.width - sideMargin, size.height - bottomMargin), radius: 12), 3.14, 1.57, false, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// In-Game Stadium Scoreboard HUD (Broadcast-Style, Compact Single Row)
class InGameHUDOverlay extends StatelessWidget {
  final MyGame game;

  const InGameHUDOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        child: SizedBox(
          height: 42,
          child: Stack(
            children: [
              // Left: Best Score Chip (in 1P mode)
              if (!game.isTwoPlayer)
                Align(
                  alignment: Alignment.centerLeft,
                  child: ValueListenableBuilder<int>(
                    valueListenable: game.bestScoreNotifier,
                    builder: (context, best, _) {
                      if (best == 0) return const SizedBox.shrink();
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: GameTheme.cardBg.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.emoji_events, color: GameTheme.gold, size: 13),
                            const SizedBox(width: 4),
                            Text(
                              'BEST: $best',
                              style: const TextStyle(
                                color: GameTheme.goldLight,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

              // Center: Broadcast Match Bug (Non-blocking IgnorePointer)
              Align(
                alignment: Alignment.center,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: GameTheme.cardBg.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12, width: 1.0),
                      boxShadow: GameTheme.softElevation(blur: 10, dy: 3),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          game.isTwoPlayer ? 'P1' : 'YOU',
                          style: const TextStyle(
                            color: GameTheme.player1Light,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: ValueListenableBuilder<int>(
                            valueListenable: game.scoreNotifier,
                            builder: (context, score, _) {
                              return Text(
                                '$score',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          game.isTwoPlayer ? 'P2' : 'AI',
                          style: const TextStyle(
                            color: GameTheme.player2Light,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Right: Clean Pause Button
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    game.pauseEngine();
                    game.overlays.add('PauseMenu');
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: GameTheme.cardBg.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 1.0),
                      boxShadow: GameTheme.softElevation(blur: 8, dy: 2),
                    ),
                    child: const Icon(Icons.pause, color: Colors.white, size: 18),
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

/// Pause Menu Overlay (Clean, Modern Glass Modal)
class PauseMenuOverlay extends StatelessWidget {
  final MyGame game;

  const PauseMenuOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 290,
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: GameTheme.cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white12, width: 1.2),
          boxShadow: GameTheme.softElevation(blur: 24, dy: 10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.pause_circle_outline, color: Colors.white70, size: 40),
            const SizedBox(height: 10),
            const Text(
              'GAME PAUSED',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  game.overlays.remove('PauseMenu');
                  game.resumeEngine();
                },
                icon: const Icon(Icons.play_arrow, size: 20),
                label: const Text('RESUME'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GameTheme.player1,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  game.overlays.remove('PauseMenu');
                  game.resumeEngine();
                  game.resetGame();
                },
                icon: const Icon(Icons.replay, size: 18),
                label: const Text('RESTART'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  game.overlays.remove('PauseMenu');
                  game.overlays.remove('InGameHUD');
                  game.overlays.add('MainMenu');
                  game.resumeEngine();
                },
                style: TextButton.styleFrom(
                  foregroundColor: GameTheme.textSecondary,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text('MAIN MENU', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Game Over Overlay (Authentic Match Finish & Winner Card)
class GameOverOverlay extends StatelessWidget {
  final MyGame game;

  const GameOverOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final isTwoPlayer = game.isTwoPlayer;
    final winner = game.winner;

    String winnerTitle;
    String winnerSubtitle;
    Color accentColor;
    IconData winnerIcon;

    if (isTwoPlayer) {
      if (winner == GameWinner.player1) {
        winnerTitle = 'PLAYER 1 WINS!';
        winnerSubtitle = 'Player 2 missed the ball';
        accentColor = GameTheme.player1;
        winnerIcon = Icons.emoji_events;
      } else {
        winnerTitle = 'PLAYER 2 WINS!';
        winnerSubtitle = 'Player 1 missed the ball';
        accentColor = GameTheme.player2;
        winnerIcon = Icons.emoji_events;
      }
    } else {
      if (winner == GameWinner.player1) {
        winnerTitle = 'GOAL! YOU WIN!';
        winnerSubtitle = 'Goal scored past the AI!';
        accentColor = GameTheme.player1;
        winnerIcon = Icons.emoji_events;
      } else {
        winnerTitle = 'AI SCORED & WON!';
        winnerSubtitle = 'The AI defended and scored';
        accentColor = GameTheme.player2;
        winnerIcon = Icons.sports_soccer;
      }
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: GameTheme.cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white12, width: 1.2),
          boxShadow: GameTheme.softElevation(blur: 28, dy: 10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Winner Trophy / Soccer Badge
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: accentColor.withValues(alpha: 0.5), width: 1.5),
              ),
              child: Icon(winnerIcon, color: accentColor, size: 36),
            ),
            const SizedBox(height: 14),

            // Winner Header
            Text(
              winnerTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              winnerSubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: GameTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),

            // Match Stats Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: isTwoPlayer
                  ? Column(
                      children: [
                        const Text(
                          '2-PLAYER HEAD-TO-HEAD',
                          style: TextStyle(
                            color: GameTheme.textMuted,
                            fontSize: 10,
                            letterSpacing: 1.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                const Text(
                                  'PLAYER 1',
                                  style: TextStyle(
                                    color: GameTheme.player1Light,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${game.p1Wins} Wins',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                            Container(width: 1, height: 30, color: Colors.white12),
                            Column(
                              children: [
                                const Text(
                                  'PLAYER 2',
                                  style: TextStyle(
                                    color: GameTheme.player2Light,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${game.p2Wins} Wins',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        if (game.isNewHighScore)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: GameTheme.gold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: GameTheme.gold.withValues(alpha: 0.4)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star, color: GameTheme.gold, size: 13),
                                SizedBox(width: 4),
                                Text(
                                  'NEW BEST SCORE!',
                                  style: TextStyle(
                                    color: GameTheme.goldLight,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 10,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                const Text(
                                  'RALLY SCORE',
                                  style: TextStyle(
                                    color: GameTheme.textMuted,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${game.score}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                            Container(width: 1, height: 32, color: Colors.white12),
                            Column(
                              children: [
                                const Text(
                                  'PERSONAL BEST',
                                  style: TextStyle(
                                    color: GameTheme.goldLight,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${game.bestScore}',
                                  style: const TextStyle(
                                    color: GameTheme.goldLight,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 22),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      game.resetGame();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.replay, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'PLAY AGAIN',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      game.overlays.remove('GameOver');
                      game.overlays.add('MainMenu');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24, width: 1.2),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text(
                      'MAIN MENU',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Main Menu Overlay (Modern, Authentic Sports Card)
class MainMenuOverlay extends StatefulWidget {
  final MyGame game;

  const MainMenuOverlay({super.key, required this.game});

  @override
  State<MainMenuOverlay> createState() => _MainMenuOverlayState();
}

class _MainMenuOverlayState extends State<MainMenuOverlay> {
  @override
  Widget build(BuildContext context) {
    final bestScore = ScoreService.getBestScore1P();
    final p1Wins = ScoreService.getP1Wins();
    final p2Wins = ScoreService.getP2Wins();

    return Center(
      child: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: GameTheme.cardBg,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white12, width: 1.2),
            boxShadow: GameTheme.softElevation(blur: 32, dy: 14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Clean Logo Presentation (No harsh radioactive bloom)
              Container(
                width: 116,
                height: 116,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white12, width: 1.0),
                  boxShadow: GameTheme.softElevation(blur: 16, dy: 6),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Image.asset(
                    'assets/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/Retro Game Logo Design.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.sports_soccer, size: 56, color: GameTheme.player1),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title in crisp, modern athletic typography
              const Text(
                'GOAL',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 4),

              // Subtitle Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: GameTheme.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: GameTheme.gold.withValues(alpha: 0.35)),
                ),
                child: const Text(
                  'BOUNCE & WIN',
                  style: TextStyle(
                    color: GameTheme.goldLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // High Score / Stats Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.emoji_events, color: GameTheme.gold, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '1P Best Score: $bestScore',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (bestScore > 0 || p1Wins > 0 || p2Wins > 0) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () async {
                              await ScoreService.resetAll();
                              widget.game.bestScore = 0;
                              widget.game.p1Wins = 0;
                              widget.game.p2Wins = 0;
                              setState(() {});
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white10,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.refresh, size: 13, color: Colors.white54),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (p1Wins > 0 || p2Wins > 0) ...[
                      const SizedBox(height: 5),
                      Text(
                        '2P Record: P1 ($p1Wins) vs P2 ($p2Wins)',
                        style: const TextStyle(
                          color: GameTheme.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // Mode 1: 1 Player Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    widget.game.startGame(isTwoPlayer: false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GameTheme.player1,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.smart_toy_outlined, size: 20),
                      SizedBox(width: 8),
                      Text(
                        '1 PLAYER (VS AI)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Mode 2: 2 Player Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    widget.game.startGame(isTwoPlayer: true);
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24, width: 1.2),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 20),
                      SizedBox(width: 8),
                      Text(
                        '2 PLAYERS (VERSUS)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
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
