import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/game.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:goal/game/my_game.dart';
import 'package:goal/services/score_service.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ScoreService.init();
  });

  testWidgets('AI paddle tracks ball smoothly when ball moves toward it and does not oscillate',
      (WidgetTester tester) async {
    final game = MyGame();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 800,
            child: GameWidget(
              game: game,
              overlayBuilderMap: {
                'MainMenu': (context, game) => const SizedBox(),
                'GameOver': (context, game) => const SizedBox(),
                'InGameHUD': (context, game) => const SizedBox(),
                'PauseMenu': (context, game) => const SizedBox(),
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    game.startGame(isTwoPlayer: false);
    await tester.pump();

    final topBar = game.topBar;
    final ball = game.ball;

    expect(topBar.isPlayerControlled, isFalse);

    // Ball starts moving up towards AI
    ball.velocity = Vector2(0, -200);
    ball.position = Vector2(100, 200);

    final initialX = topBar.position.x;

    double prevX = initialX;
    for (int i = 0; i < 20; i++) {
      game.update(0.016);
      if (topBar.position.x != prevX) {
        expect(topBar.position.x < prevX, isTrue,
            reason: 'Bar should move left towards target without reversing direction');
      }
      prevX = topBar.position.x;
    }

    // Ball moves downward (away from AI)
    ball.velocity = Vector2(0, 200);
    prevX = topBar.position.x;

    final centerTarget = (game.size.x - topBar.size.x) / 2;
    for (int i = 0; i < 30; i++) {
      game.update(0.016);
      if (topBar.position.x != prevX && prevX < centerTarget) {
        expect(topBar.position.x >= prevX, isTrue,
            reason: 'Bar should move right towards center without jittering');
      }
      prevX = topBar.position.x;
    }
  });

  testWidgets('In 1-Player mode, passing top boundary makes Player 1 win and saves best score',
      (WidgetTester tester) async {
    final game = MyGame();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 800,
            child: GameWidget(
              game: game,
              overlayBuilderMap: {
                'MainMenu': (context, game) => const SizedBox(),
                'GameOver': (context, game) => const SizedBox(),
                'InGameHUD': (context, game) => const SizedBox(),
                'PauseMenu': (context, game) => const SizedBox(),
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    game.startGame(isTwoPlayer: false);
    await tester.pump();

    // Trigger ball passing top boundary (AI missed)
    game.ball.position = Vector2(200, 5);
    game.ball.velocity = Vector2(0, -200);
    game.update(0.05);

    expect(game.isGameOver, isTrue);
    expect(game.winner, equals(GameWinner.player1));
    expect(ScoreService.getBestScore1P(), greaterThan(0));
  });

  testWidgets('In 2-Player mode, winner is correctly identified for Player 1 and Player 2',
      (WidgetTester tester) async {
    final game = MyGame();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 800,
            child: GameWidget(
              game: game,
              overlayBuilderMap: {
                'MainMenu': (context, game) => const SizedBox(),
                'GameOver': (context, game) => const SizedBox(),
                'InGameHUD': (context, game) => const SizedBox(),
                'PauseMenu': (context, game) => const SizedBox(),
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // 2-Player mode: Player 1 scores on Player 2 (passes top)
    game.startGame(isTwoPlayer: true);
    await tester.pump();

    game.ball.position = Vector2(200, 5);
    game.ball.velocity = Vector2(0, -200);
    game.update(0.05);

    expect(game.isGameOver, isTrue);
    expect(game.winner, equals(GameWinner.player1));
    expect(ScoreService.getP1Wins(), equals(1));

    // Next round: Player 2 scores on Player 1 (passes bottom)
    game.startGame(isTwoPlayer: true);
    await tester.pump();

    game.ball.position = Vector2(200, game.size.y - 5);
    game.ball.velocity = Vector2(0, 200);
    game.update(0.05);

    expect(game.isGameOver, isTrue);
    expect(game.winner, equals(GameWinner.player2));
    expect(ScoreService.getP2Wins(), equals(1));
  });
}

