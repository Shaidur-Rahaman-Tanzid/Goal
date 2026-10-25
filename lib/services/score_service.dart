import 'package:shared_preferences/shared_preferences.dart';

/// Service to handle persistent local storage for best scores and player stats.
class ScoreService {
  static const String _keyBestScore1P = 'best_score_1p';
  static const String _keyP1Wins = 'p1_wins_2p';
  static const String _keyP2Wins = 'p2_wins_2p';

  static SharedPreferences? _prefs;

  /// Initializes SharedPreferences instance. Call in main() before runApp.
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Gets the best score in 1 Player mode.
  static int getBestScore1P() {
    return _prefs?.getInt(_keyBestScore1P) ?? 0;
  }

  /// Checks if [score] beats the current record.
  /// If so, saves it locally and returns true (indicating a new high score).
  static Future<bool> saveBestScore1P(int score) async {
    final currentBest = getBestScore1P();
    if (score > currentBest) {
      await _prefs?.setInt(_keyBestScore1P, score);
      return true;
    }
    return false;
  }

  /// Gets all-time Player 1 wins in 2 Player mode.
  static int getP1Wins() {
    return _prefs?.getInt(_keyP1Wins) ?? 0;
  }

  /// Gets all-time Player 2 wins in 2 Player mode.
  static int getP2Wins() {
    return _prefs?.getInt(_keyP2Wins) ?? 0;
  }

  /// Increments Player 1 win count.
  static Future<void> incrementP1Wins() async {
    final wins = getP1Wins() + 1;
    await _prefs?.setInt(_keyP1Wins, wins);
  }

  /// Increments Player 2 win count.
  static Future<void> incrementP2Wins() async {
    final wins = getP2Wins() + 1;
    await _prefs?.setInt(_keyP2Wins, wins);
  }

  /// Clears stored records (for testing or reset option).
  static Future<void> resetAll() async {
    await _prefs?.remove(_keyBestScore1P);
    await _prefs?.remove(_keyP1Wins);
    await _prefs?.remove(_keyP2Wins);
  }
}
