# 詳細設計書 - リバーシゲーム

## 1. システム構成

本アプリは Flutter フレームワークを使用し、状態管理に `flutter_riverpod` を採用する。

### 1.1 レイヤー構造

- **Domain Layer**: ゲームルールを定義した純粋な Dart クラス。
- **State Layer**: UI と Domain の間を取り持ち、アプリケーションの状態（盤面など）を保持・管理する。
- **Presentation Layer**: Flutter ウィジェットを用いて盤面を描画し、ユーザー入力を受け付ける。

## 2. データ構造

### 2.1 StoneColor (Enum)

- `black`: 黒石
- `white`: 白石
- `none`: 空マス

### 2.2 GameState (Class)

不変(Immutable)なオブジェクトとして定義し、Riverpod で管理する。

- `board`: `List<List<StoneColor>>` (8x8 配列)
- `currentTurn`: `StoneColor` (現在の手番)
- `score`: `Map<StoneColor, int>` (各色の石の数)
- `isGameOver`: `bool` (ゲーム終了フラグ)
- `message`: `String` (画面に表示するメッセージ)
- `gameMode`: `GameMode` (PVP: 人間vs人間 / PVC: 人間vsCPU)
- `humanColor`: `StoneColor` (人間が操作する色)
- `turnTimeProgress`: `double` (現在の手番の残り時間進捗率 0.0〜1.0)

## 3. 主要クラス設計

### 3.1 GameLogic (Static Class)

UIや状態に依存しない純粋な計算ロジックを実装。

- `createInitialBoard()`: 初期盤面（中央の4石）を生成して返す。
- `getFlippableStones(board, row, col, color)`: 指定位置に置いたときに反転する石のリストを取得。空なら配置不可と判定。
- `placeStone(currentBoard, row, col, color)`: 反転処理を行い、新しい盤面状態を返す。
- `canMove(board, color)`: その色で打てる場所が一つでもあるか判定。
- `calculateScore(board)`: 盤面の石をカウントしスコアマップを生成。
- `getBestMove(board, color)`: CPU用の着手決定ロジック。四隅を優先し、それ以外はランダムに選択する。

### 3.2 GameNotifier (StateNotifier)

`GameState` を管理し、ユーザー操作に応じて状態を更新する。

- `placeStone(row, col)`: 
    1. `GameLogic.placeStone` で有効な手か判定。
    2. 有効であれば盤面を更新し、タイマーをリセットして次ターンのカウントダウンを開始。
    3. 次のプレイヤーが打てるか確認 $\rightarrow$ 打てればターン交代、打てなければパス処理を実行。
    4. PVCモードかつ CPUの手番になった場合、一定時間後に `cpuMove()` を実行。
- `cpuMove()`: 
    1. `GameLogic.getBestMove` で着手場所を決定。
    2. 決定した位置に石を配置し、状態を更新する。
- `startTurnTimer()`: 現在の手番のカウントダウンを開始し、定期的に `turnTimeProgress` を更新。時間切れ時に自動着手を実行。
- `resetGame()`: 状態を初期値に戻す。
- `setGameMode(mode)`: 対戦モードを切り替える。

### 3.3 StartScreen (ConsumerWidget)

ゲーム開始前の設定画面。

- **モード選択**: PVP/PVC の切り替え。
- **色選択**: 先攻(黒)/後攻(白) の選択。
- **遷移**: 「ゲーム開始」ボタンで `GameScreen` へ遷移し、同時に `gameProvider` を初期化してタイマーを開始する。

### 3.4 GameScreen (ConsumerWidget)

Riverpod の `gameProvider` を監視し、盤面を描画する。

- **GridView**: 64マスのグリッドを表示。各マスに `GestureDetector` を配置しタップイベントを検知。
- **AnimatedContainer**: 石の反転時に色が変わる様子を視覚的に滑らかにするため採用。
- **Game Over Dialog**: ゲーム終了時に表示される結果ダイアログ。勝敗の表示と「再戦」ボタンを提供。

## 4. ゲームフロー（シーケンス）

1. [ユーザー] $\rightarrow$ `StartScreen` でモード・色を選択し「開始」 $\rightarrow$ `GameScreen` へ遷移 & タイマー始動
2. [ユーザー] $\rightarrow$ マスタップ $\rightarrow$ `GameNotifier.placeStone` 呼出
3. [GameNotifier] $\rightarrow$ `GameLogic.placeStone` で盤面更新計算 $\rightarrow$ State 更新 $\rightarrow$ タイマーリセット
4. [UI] $\rightarrow$ Provider の変更を検知し、再描画 (タイマーバーがリセットされる)
5. [GameNotifier] $\rightarrow$ タイマーによる `turnTimeProgress` の定期的更新 $\rightarrow$ UIに反映
6. [GameNotifier] (時間切れ時) $\rightarrow$ ランダムな着手を自動実行 $\rightarrow$ State 更新
7. [GameNotifier] (PVCモード時) $\rightarrow$ 500ms待機 $\rightarrow$ `cpuMove()` 実行 $\rightarrow$ State 更新
8. [UI] $\rightarrow$ CPUの着手を反映して再描画
9. [GameNotifier] $\rightarrow$ ゲーム終了検知 $\rightarrow$ `GameScreen` で結果ダイアログ表示
10. [ユーザー] $\rightarrow$ ダイアログで「もう一度」選択 $\rightarrow$ `StartScreen` へ戻る
