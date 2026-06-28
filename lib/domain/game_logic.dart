
import 'dart:math';

/// 石の色を定義
enum StoneColor {
  black,
  white,
  none;

  StoneColor get opposite {
    if (this == black) return white;
    if (this == white) return black;
    return none;
  }
}

/// 座標を保持するシンプルなクラス
class Point {
  final int row;
  final int col;
  Point(this.row, this.col);
}

/// リバーシの純粋なゲームロジックを提供。状態を持たず、関数として動作する。
class GameLogic {
  static const int boardSize = 8;

  /// 初期盤面を生成して返す
  static List<List<StoneColor>> createInitialBoard() {
    final board = List.generate(
      boardSize,
      (_) => List.filled(boardSize, StoneColor.none),
    );
    board[3][3] = StoneColor.white;
    board[4][4] = StoneColor.white;
    board[3][4] = StoneColor.black;
    board[4][3] = StoneColor.black;
    return board;
  }

  /// 指定した位置に石が置けるか判定し、置ける場合はひっくり返せる石のリストを返す
  static List<Point> getFlippableStones(List<List<StoneColor>> board, int row, int col, StoneColor color) {
    if (row < 0 || row >= boardSize || col < 0 || col >= boardSize) return [];
    if (board[row][col] != StoneColor.none) return [];

    List<Point> allFlippable = [];

    final directions = [
      [-1, -1], [-1, 0], [-1, 1],
      [0, -1],           [0, 1],
      [1, -1],  [1, 0],  [1, 1],
    ];

    for (var dir in directions) {
      List<Point> directionFlippable = [];
      int r = row + dir[0];
      int c = col + dir[1];

      while (r >= 0 && r < boardSize && c >= 0 && c < boardSize && board[r][c] == color.opposite) {
        directionFlippable.add(Point(r, c));
        r += dir[0];
        c += dir[1];
      }

      if (r >= 0 && r < boardSize && c >= 0 && c < boardSize && board[r][c] == color) {
        allFlippable.addAll(directionFlippable);
      }
    }

    return allFlippable;
  }

  /// 石を配置した後の新しい盤面を返す。置けない場合は null を返す。
  static List<List<StoneColor>>? placeStone(List<List<StoneColor>> currentBoard, int row, int col, StoneColor color) {
    final flippable = getFlippableStones(currentBoard, row, col, color);
    if (flippable.isEmpty) return null;

    // 盤面のディープコピーを作成
    final newBoard = currentBoard.map((rowList) => List<StoneColor>.from(rowList)).toList();

    // 石を置く
    newBoard[row][col] = color;

    // 石をひっくり返す
    for (var p in flippable) {
      newBoard[p.row][p.col] = color;
    }

    return newBoard;
  }

  /// その色で打てる場所があるか判定
  static bool canMove(List<List<StoneColor>> board, StoneColor color) {
    for (int r = 0; r < boardSize; r++) {
      for (int c = 0; c < boardSize; c++) {
        if (getFlippableStones(board, r, c, color).isNotEmpty) {
          return true;
        }
      }
    }
    return false;
  }

  /// スコアを計算
  static Map<StoneColor, int> calculateScore(List<List<StoneColor>> board) {
    int black = 0;
    int white = 0;
    for (var row in board) {
      for (var stone in row) {
        if (stone == StoneColor.black) black++;
        if (stone == StoneColor.white) white++;
      }
    }
    return {StoneColor.black: black, StoneColor.white: white};
  }

  /// ゲーム終了判定（両者打てない場合）
  static bool isGameOver(List<List<StoneColor>> board) {
    return !canMove(board, StoneColor.black) && !canMove(board, StoneColor.white);
  }

  /// 盤面が初期状態であるかを確認する
  static bool isInitialBoard(List<List<StoneColor>> board) {
    final initial = createInitialBoard();
    for (int r = 0; r < boardSize; r++) {
      for (int c = 0; c < boardSize; c++) {
        if (board[r][c] != initial[r][c]) return false;
      }
    }
    return true;
  }

  /// ランダムに着手場所を選択する。
  static Point? getRandomMove(List<List<StoneColor>> board, StoneColor color) {
    List<Point> validMoves = [];
    for (int r = 0; r < boardSize; r++) {
      for (int c = 0; c < boardSize; c++) {
        if (getFlippableStones(board, r, c, color).isNotEmpty) {
          validMoves.add(Point(r, c));
        }
      }
    }
    if (validMoves.isEmpty) return null;
    return validMoves[Random().nextInt(validMoves.length)];
  }

  /// CPU用の着手決定ロジック。四隅を優先し、それ以外はランダムに選択する。
  static Point? getBestMove(List<List<StoneColor>> board, StoneColor color) {
    List<Point> validMoves = [];
    for (int r = 0; r < boardSize; r++) {
      for (int c = 0; c < boardSize; c++) {
        if (getFlippableStones(board, r, c, color).isNotEmpty) {
          validMoves.add(Point(r, c));
        }
      }
    }

    if (validMoves.isEmpty) return null;

    // 四隅の座標
    final corners = [
      Point(0, 0), Point(0, 7),
      Point(7, 0), Point(7, 7),
    ];

    // 四隅で打てる場所があるか確認
    List<Point> availableCorners = validMoves.where((p) {
      return corners.any((c) => c.row == p.row && c.col == p.col);
    }).toList();

    if (availableCorners.isNotEmpty) {
      // 角が打てるなら、角の中からランダムに選択
      return availableCorners[Random().nextInt(availableCorners.length)];
    }

    // それ以外はランダムに選択
    return validMoves[Random().nextInt(validMoves.length)];
  }
}
