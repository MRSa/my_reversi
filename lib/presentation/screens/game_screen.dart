import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/game_provider.dart';
import '../../domain/game_logic.dart';

class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    final gameNotifier = ref.read(gameProvider.notifier);

    // ゲームオーバー時に結果ダイアログを表示
    ref.listen<GameState>(gameProvider, (previous, next) {
      if (previous != null && !previous.isGameOver && next.isGameOver) {
        _showGameOverDialog(context, next);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('リバーシ'),
        centerTitle: true,
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 持ち時間バーの表示
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: gameState.turnTimeProgress,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    gameState.currentTurn == StoneColor.black ? Colors.black : Colors.blueAccent,
                  ),
                  minHeight: 10,
                ),
              ),
            ),
            // 状態メッセージとスコアの表示
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildScoreIndicator(gameState, StoneColor.black, '黒'),
                  Text(
                    gameState.message,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  _buildScoreIndicator(gameState, StoneColor.white, '白'),
                ],
              ),
            ),
            // 盤面の表示（利用可能なスペースで最大サイズの正方形になるよう調整）
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    margin: const EdgeInsets.all(8.0),
                    padding: const EdgeInsets.all(8.0),
                    color: Colors.green[700],
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 8,
                      ),
                      itemCount: 64,
                      itemBuilder: (context, index) {
                        final row = index ~/ 8;
                        final col = index % 8;
                        final stone = gameState.board[row][col];
                        final canPlace = GameLogic.getFlippableStones(
                          gameState.board,
                          row,
                          col,
                          gameState.currentTurn,
                        ).isNotEmpty;

                        return GestureDetector(
                          onTap: () => gameNotifier.placeStone(row, col),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.green[600],
                              border: Border.all(color: Colors.green[900]!, width: 1),
                            ),
                            child: Center(
                              child: _buildStone(stone, canPlace),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            // 対戦モードおよび色の選択
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('モード: '),
                      ChoiceChip(
                        label: const Text('人間 vs 人間'),
                        selected: gameState.gameMode == GameMode.pvp,
                        onSelected: (selected) {
                          if (selected) gameNotifier.setGameMode(GameMode.pvp);
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('人間 vs CPU'),
                        selected: gameState.gameMode == GameMode.pvc,
                        onSelected: (selected) {
                          if (selected) gameNotifier.setGameMode(GameMode.pvc);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('自分の色: '),
                      ChoiceChip(
                        label: const Text('黒 (先攻)'),
                        selected: gameState.humanColor == StoneColor.black,
                        onSelected: (selected) {
                          if (selected) gameNotifier.setHumanColor(StoneColor.black);
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('白 (後攻)'),
                        selected: gameState.humanColor == StoneColor.white,
                        onSelected: (selected) {
                          if (selected) gameNotifier.setHumanColor(StoneColor.white);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // リセット/開始ボタン（下部に固定）
            Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: Builder(
                builder: (context) {
                  final isInitial = GameLogic.isInitialBoard(gameState.board);
                  final cpuStarts = gameState.gameMode == GameMode.pvc && 
                                  gameState.humanColor == StoneColor.white;
                  
                  String buttonText = 'ゲームリセット';
                  bool isEnabled = true;

                  if (isInitial) {
                    // 初期状態では常に「ゲーム開始」ボタンとして表示し、有効化する
                    buttonText = 'ゲーム開始';
                    isEnabled = true;
                  }

                  return ElevatedButton.icon(
                    onPressed: isEnabled ? () => _confirmReturnToTitle(context) : null,
                    icon: const Icon(Icons.refresh),
                    label: Text(buttonText),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreIndicator(GameState state, StoneColor color, String label) {
    return Column(
      children: [
        Text('$label: ${state.score[color]}'),
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color == StoneColor.black ? Colors.black : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey),
          ),
        ),
      ],
    );
  }

  void _showGameOverDialog(BuildContext context, GameState state) {
    final blackScore = state.score[StoneColor.black] ?? 0;
    final whiteScore = state.score[StoneColor.white] ?? 0;
    
    String resultMessage;
    if (blackScore > whiteScore) {
      resultMessage = '黒の勝利！';
    } else if (whiteScore > blackScore) {
      resultMessage = '白の勝利！';
    } else {
      resultMessage = '引き分けです！';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('ゲーム終了', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              resultMessage,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              '黒: $blackScore vs 白: $whiteScore',
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // ダイアログを閉じる
              // 開始画面に戻って設定をやり直す
              Navigator.of(context).pushReplacementNamed('/start');
            },
            child: const Text('もう一度プレイする'),
          ),
          TextButton(
            onPressed: () {
              if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
                exit(0);
              } else {
                SystemNavigator.pop();
              }
            },
            child: const Text('アプリを終了する'),
          ),
        ],
      ),
    );
  }

  void _confirmReturnToTitle(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認'),
        content: const Text('本当にタイトル画面に戻りますか？\n現在の進行状況は失われます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // ダイアログを閉じる
              Navigator.of(context).pushReplacementNamed('/start');
            },
            child: const Text('戻る', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildStone(StoneColor stone, bool canPlace) {
    if (stone == StoneColor.none) {
      return canPlace
          ? Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.black12,
                shape: BoxShape.circle,
              ),
            )
          : const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: stone == StoneColor.black ? Colors.black : Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
        border: Border.all(
          color: Colors.grey[800]!,
          width: 1,
        ),
      ),
    );
  }
}
