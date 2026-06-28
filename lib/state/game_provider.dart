import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/game_logic.dart';

/// 対戦モードの定義
enum GameMode {
  pvp, // 人間 vs 人間
  pvc, // 人間 vs CPU
}

/// ゲームの状態を不変(Immutable)に管理するためのクラス
class GameState {
  final List<List<StoneColor>> board;
  final StoneColor currentTurn;
  final Map<StoneColor, int> score;
  final bool isGameOver;
  final String message;
  final GameMode gameMode;
  final StoneColor humanColor; // 人間が操作する色
  final double turnTimeProgress; // 現在の手番の残り時間進捗率 (0.0〜1.0)

  GameState({
    required this.board,
    required this.currentTurn,
    required this.score,
    required this.isGameOver,
    required this.message,
    required this.gameMode,
    required this.humanColor,
    required this.turnTimeProgress,
  });

  GameState copyWith({
    List<List<StoneColor>>? board,
    StoneColor? currentTurn,
    Map<StoneColor, int>? score,
    bool? isGameOver,
    String? message,
    GameMode? gameMode,
    StoneColor? humanColor,
    double? turnTimeProgress,
  }) {
    return GameState(
      board: board ?? this.board,
      currentTurn: currentTurn ?? this.currentTurn,
      score: score ?? this.score,
      isGameOver: isGameOver ?? this.isGameOver,
      message: message ?? this.message,
      gameMode: gameMode ?? this.gameMode,
      humanColor: humanColor ?? this.humanColor,
      turnTimeProgress: turnTimeProgress ?? this.turnTimeProgress,
    );
  }
}

/// ゲームロジックを管理するNotifier
class GameNotifier extends Notifier<GameState> {
  Timer? _timer;
  static const int _turnLimitSeconds = 15;
  static const int _timerIntervalMs = 100;

  @override
  GameState build() {
    return GameState(
      board: GameLogic.createInitialBoard(),
      currentTurn: StoneColor.black,
      score: {StoneColor.black: 2, StoneColor.white: 2},
      isGameOver: false,
      message: '黒の番です',
      gameMode: GameMode.pvp,
      humanColor: StoneColor.black,
      turnTimeProgress: 0.0,
    );
  }

  /// 石を置く操作
  void placeStone(int row, int col) {
    if (state.isGameOver) return;

    final color = state.currentTurn;
    final nextBoard = GameLogic.placeStone(state.board, row, col, color);

    if (nextBoard != null) {
      // 状態更新を一度に行うことで、タイムアウト連鎖などの競合を防ぐ
      final newState = _calculateNextState(nextBoard, color);
      state = newState;
      
      // CPUの手番になった場合のトリガー処理は state 更新後に行う
      if (newState.gameMode == GameMode.pvc && newState.currentTurn != newState.humanColor) {
        _triggerCpuMove();
      }
      
      startTurnTimer();
    }
  }

  /// 次の状態を計算して返す（副作用なし）
  GameState _calculateNextState(List<List<StoneColor>> nextBoard, StoneColor currentColor) {
    final nextTurn = currentColor.opposite;
    final score = GameLogic.calculateScore(nextBoard);
    
    if (GameLogic.canMove(nextBoard, nextTurn)) {
      return state.copyWith(
        board: nextBoard,
        currentTurn: nextTurn,
        score: score,
        isGameOver: false,
        message: '${nextTurn == StoneColor.black ? "黒" : "白"}の番です',
        turnTimeProgress: 0.0, // 必ずリセット
      );
    } else if (GameLogic.canMove(nextBoard, currentColor)) {
      return state.copyWith(
        board: nextBoard,
        currentTurn: currentColor,
        score: score,
        isGameOver: false,
        message: '${currentColor == StoneColor.black ? "黒" : "白"}の番です（相手パス）',
        turnTimeProgress: 0.0, // 必ずリセット
      );
    } else {
      return state.copyWith(
        board: nextBoard,
        currentTurn: currentColor,
        score: score,
        isGameOver: true,
        message: 'ゲーム終了！',
        turnTimeProgress: 1.0, // ゲーム終了時は最大値に（タイマー停止用）
      );
    }
  }

  // 旧メソッドを削除し、上記の新ロジックに統合済み。
  // もし他で呼ばれている場合は _calculateNextState を使うように変更する。
  void _handleNextState(List<List<StoneColor>> nextBoard, StoneColor currentColor) {
    state = _calculateNextState(nextBoard, currentColor);
    if (state.gameMode == GameMode.pvc && state.currentTurn != state.humanColor) {
      _triggerCpuMove();
    }
  }

  /// CPU着手のトリガー（遅延処理）
  void _triggerCpuMove() {
    Future.delayed(const Duration(milliseconds: 500), () {
      cpuMove();
    });
  }

  /// CPUの思考および着手実行
  void cpuMove() {
    if (state.isGameOver) return;
    
    final move = GameLogic.getBestMove(state.board, state.currentTurn);
    if (move != null) {
      placeStone(move.row, move.col);
    }
  }

  /// ターンのカウントダウンタイマーを開始する
  void startTurnTimer() {
    _timer?.cancel(); // 既存のタイマーがあれば停止

    _timer = Timer.periodic(Duration(milliseconds: _timerIntervalMs), (timer) {
      // タイマーコールバック内であれば state は初期化済みであるため安全にアクセス可能
      if (state.isGameOver) {
        timer.cancel();
        return;
      }

      // 100ms ごとに進捗率を更新
      final increment = _timerIntervalMs / (_turnLimitSeconds * 1000);
      final newProgress = state.turnTimeProgress + increment;

      if (newProgress >= 1.0) {
        // 時間切れ：タイマーを止めて自動着手を実行
        timer.cancel();
        _handleTimeout();
      } else {
        state = state.copyWith(turnTimeProgress: newProgress);
      }
    });
  }

  /// 時間切れ時の処理
  void _handleTimeout() {
    final color = state.currentTurn;
    final move = GameLogic.getRandomMove(state.board, color);

    if (move != null) {
      // 置ける場所があればランダムに配置
      placeStone(move.row, move.col);
    } else {
      // 置けない場合はパス処理として、手番を交代してタイマー再開
      // placeStone を介さず直接 _handleNextState のロジックを適用させるため
      // ここでは便宜上空の盤面で placeStone を呼ばず、擬似的にパスさせる必要がある。
      // ただし GameLogic.canMove が False ならば自動的にパスになるはずなので
      // 実際には CPU/人間が打てない場合は getRandomMove が null を返す。
      
      // パス処理の実行（GameLogic でチェックし、次の人に回す）
      _handleTimeoutPass();
    }
  }

  void _handleTimeoutPass() {
    // 現在のプレイヤーをパスさせて次へ
    final currentColor = state.currentTurn;
    final nextBoard = state.board; // 盤面は変わらず
    
    state = _calculateNextState(nextBoard, currentColor);
    if (state.gameMode == GameMode.pvc && state.currentTurn != state.humanColor) {
      _triggerCpuMove();
    }
    startTurnTimer();
  }

  /// 対戦モードの変更
  void setGameMode(GameMode mode) {
    state = state.copyWith(gameMode: mode);
  }

  /// プレイヤーの色を変更
  void setHumanColor(StoneColor color) {
    final oldColor = state.humanColor;
    state = state.copyWith(humanColor: color);

    // 色を変えたことで、現在の手番が CPU になった場合にトリガー (ゲーム中ではない想定だが安全のため)
    if (oldColor != color && state.gameMode == GameMode.pvc && 
        state.currentTurn != color && !state.isGameOver) {
      _triggerCpuMove();
    }
  }

  /// ゲームのリセット
  void resetGame() {
    final isHumanWhite = state.humanColor == StoneColor.white;
    final mode = state.gameMode;

    state = GameState(
      board: GameLogic.createInitialBoard(),
      currentTurn: StoneColor.black,
      score: {StoneColor.black: 2, StoneColor.white: 2},
      isGameOver: false,
      message: isHumanWhite && mode == GameMode.pvc 
          ? 'CPU(黒)の番です' 
          : '黒の番です',
      gameMode: mode,
      humanColor: state.humanColor,
      turnTimeProgress: 0.0,
    );

    // PVCモードで人間が白の場合、CPUから開始
    if (mode == GameMode.pvc && isHumanWhite) {
      _triggerCpuMove();
    }
    startTurnTimer(); // リセット後にタイマーを再開
  }
}

/// Riverpod Provider の定義
final gameProvider = NotifierProvider<GameNotifier, GameState>(GameNotifier.new);
