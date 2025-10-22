import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// パズルの状態
class PuzzleState {
  final List<int> tracedCells;
  final List<Offset> touchPath;

  const PuzzleState({this.tracedCells = const [], this.touchPath = const []});

  PuzzleState copyWith({List<int>? tracedCells, List<Offset>? touchPath}) {
    return PuzzleState(
      tracedCells: tracedCells ?? this.tracedCells,
      touchPath: touchPath ?? this.touchPath,
    );
  }
}

// パズルの状態を管理するNotifier
class PuzzleNotifier extends StateNotifier<PuzzleState> {
  PuzzleNotifier() : super(const PuzzleState());

  // タッチ位置を記録
  void addTouchPoint(Offset point) {
    state = state.copyWith(touchPath: [...state.touchPath, point]);
  }

  // 新しいセルを追加
  void addCell(int cellIndex) {
    // 重複チェック
    if (state.tracedCells.contains(cellIndex)) {
      return;
    }

    // 最初は必ずセル0から開始
    if (state.tracedCells.isEmpty && cellIndex != 0) {
      return;
    }

    // 隣接チェック
    if (state.tracedCells.isNotEmpty) {
      int lastCell = state.tracedCells.last;
      if (!_isAdjacent(lastCell, cellIndex)) {
        return;
      }
    }

    state = state.copyWith(tracedCells: [...state.tracedCells, cellIndex]);
    HapticFeedback.lightImpact();
  }

  // 2つのセルが隣接しているかチェック（上下左右のみ、斜めは不可）
  bool _isAdjacent(int cell1, int cell2) {
    final row1 = cell1 ~/ 5;
    final col1 = cell1 % 5;
    final row2 = cell2 ~/ 5;
    final col2 = cell2 % 5;

    // 上下左右のいずれかに隣接している
    return (row1 == row2 && (col1 - col2).abs() == 1) ||
        (col1 == col2 && (row1 - row2).abs() == 1);
  }

  // クリア判定と行き詰まり判定
  void checkClear(BuildContext context) {
    // すべてのセル（25個）がなぞられ、最後がゴール（24）である
    if (state.tracedCells.length == 25 && state.tracedCells.last == 24) {
      // クリア演出
      HapticFeedback.heavyImpact();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.celebration, color: Colors.amber, size: 32),
              SizedBox(width: 8),
              Text('クリア！'),
            ],
          ),
          content: const Text('おめでとうございます！\nすべてのマスをなぞりました。'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                reset();
              },
              child: const Text('もう一度プレイ'),
            ),
          ],
        ),
      );
    } else if (state.tracedCells.isNotEmpty && _isStuck()) {
      // 行き詰まった場合
      HapticFeedback.mediumImpact();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.warning_amber, color: Colors.orange, size: 32),
              SizedBox(width: 8),
              Text('行き詰まりました'),
            ],
          ),
          content: Text(
            'これ以上進めません。\nまだ25個中 ${25 - state.tracedCells.length}個のマスが残っています。',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                reset();
              },
              child: const Text('リトライ'),
            ),
          ],
        ),
      );
    }
  }

  // 行き詰まったかどうかをチェック
  bool _isStuck() {
    if (state.tracedCells.isEmpty) return false;

    final lastCell = state.tracedCells.last;
    final row = lastCell ~/ 5;
    final col = lastCell % 5;

    // 上下左右の隣接セルをチェック
    final adjacentCells = <int>[];

    // 上
    if (row > 0) adjacentCells.add((row - 1) * 5 + col);
    // 下
    if (row < 4) adjacentCells.add((row + 1) * 5 + col);
    // 左
    if (col > 0) adjacentCells.add(row * 5 + (col - 1));
    // 右
    if (col < 4) adjacentCells.add(row * 5 + (col + 1));

    // すべての隣接セルが既になぞられている場合、行き詰まり
    return adjacentCells.every((cell) => state.tracedCells.contains(cell));
  }

  // リセット
  void reset() {
    state = const PuzzleState();
  }
}

// Providerの定義
final puzzleProvider = StateNotifierProvider<PuzzleNotifier, PuzzleState>((
  ref,
) {
  return PuzzleNotifier();
});
