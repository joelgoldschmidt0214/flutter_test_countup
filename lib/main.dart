import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'puzzle_provider.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '一筆書きパズル',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: '一筆書きパズル'),
    );
  }
}

class MyHomePage extends ConsumerWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracedCells = ref.watch(puzzleProvider);
    final notifier = ref.read(puzzleProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'リセット',
            onPressed: () {
              notifier.reset();
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                '${tracedCells.length}/25',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: const PuzzleBoard(),
    );
  }
}

// ゲーム盤面の表示
class PuzzleBoard extends ConsumerWidget {
  const PuzzleBoard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracedCells = ref.watch(puzzleProvider);
    final notifier = ref.read(puzzleProvider.notifier);

    return Column(
      children: [
        // 上部の余白とヒント
        Expanded(
          flex: 2,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.swipe, size: 48, color: Colors.grey.shade600),
                const SizedBox(height: 8),
                Text(
                  'スタートからゴールまで\nすべてのマスをなぞろう',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        // ゲーム盤面（正方形）
        Expanded(
          flex: 5,
          child: Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanStart: (details) {
                        _handleTouch(
                          details.localPosition,
                          constraints,
                          notifier,
                        );
                      },
                      onPanUpdate: (details) {
                        _handleTouch(
                          details.localPosition,
                          constraints,
                          notifier,
                        );
                      },
                      onPanEnd: (details) {
                        notifier.checkClear(context);
                      },
                      child: Stack(
                        children: [
                          // グリッド（タッチイベントを通過させる）
                          IgnorePointer(
                            child: GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 5,
                                    crossAxisSpacing: 4,
                                    mainAxisSpacing: 4,
                                  ),
                              itemCount: 25,
                              itemBuilder: (context, index) {
                                final isTraced = tracedCells.contains(index);
                                final isStart = index == 0;
                                final isGoal = index == 24;

                                return Container(
                                  decoration: BoxDecoration(
                                    color: isTraced
                                        ? Colors.blue.shade100
                                        : (isStart
                                              ? Colors.green.shade100
                                              : (isGoal
                                                    ? Colors.red.shade100
                                                    : Colors.grey.shade200)),
                                    border: Border.all(
                                      color: isStart
                                          ? Colors.green
                                          : (isGoal
                                                ? Colors.red
                                                : Colors.black),
                                      width: isStart || isGoal ? 3 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: isStart
                                        ? const Icon(
                                            Icons.flag,
                                            color: Colors.green,
                                          )
                                        : (isGoal
                                              ? const Icon(
                                                  Icons.flag_outlined,
                                                  color: Colors.red,
                                                )
                                              : null),
                                  ),
                                );
                              },
                            ),
                          ),
                          // パスの描画
                          if (tracedCells.length > 1)
                            CustomPaint(
                              painter: PathPainter(tracedCells),
                              size: Size.infinite,
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        // 下部の余白
        Expanded(
          flex: 2,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (tracedCells.isNotEmpty)
                  Text(
                    '進行中: ${tracedCells.length}/25',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.flag, color: Colors.green, size: 20),
                    SizedBox(width: 4),
                    Text('スタート'),
                    SizedBox(width: 24),
                    Icon(Icons.flag_outlined, color: Colors.red, size: 20),
                    SizedBox(width: 4),
                    Text('ゴール'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _handleTouch(
    Offset position,
    BoxConstraints constraints,
    PuzzleNotifier notifier,
  ) {
    // GridViewの実際のサイズを計算
    const spacing = 4.0;
    final totalSpacing = spacing * 4;
    final cellSize = (constraints.biggest.width - totalSpacing) / 5;

    // どのセルがタップされたかを計算
    final col = (position.dx / (cellSize + spacing)).floor();
    final row = (position.dy / (cellSize + spacing)).floor();

    // グリッドの範囲内かチェック
    if (col >= 0 && col < 5 && row >= 0 && row < 5) {
      final cellIndex = row * 5 + col;
      notifier.addCell(cellIndex);
    }
  }
}

// パスを描画するCustomPainter
class PathPainter extends CustomPainter {
  final List<int> tracedCells;

  PathPainter(this.tracedCells);

  @override
  void paint(Canvas canvas, Size size) {
    if (tracedCells.length < 2) return;

    // セルのサイズを計算（スペーシングを考慮）
    const spacing = 4.0;
    final cellSize = (size.width - spacing * 4) / 5;

    // ペイントの設定
    final paint = Paint()
      ..color = Colors.blue.shade700
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // 影のペイント
    final shadowPaint = Paint()
      ..color = Colors.blue.shade900.withOpacity(0.3)
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    // セルインデックスから中心座標を計算
    Offset getCellCenter(int index) {
      final row = index ~/ 5;
      final col = index % 5;
      final x = col * (cellSize + spacing) + cellSize / 2;
      final y = row * (cellSize + spacing) + cellSize / 2;
      return Offset(x, y);
    }

    // パスを作成
    final path = Path();
    final shadowPath = Path();

    // 最初の点に移動
    final firstPoint = getCellCenter(tracedCells[0]);
    path.moveTo(firstPoint.dx, firstPoint.dy);
    shadowPath.moveTo(firstPoint.dx, firstPoint.dy);

    // すべてのポイントを直線で接続
    for (int i = 1; i < tracedCells.length; i++) {
      final currentPoint = getCellCenter(tracedCells[i]);
      path.lineTo(currentPoint.dx, currentPoint.dy);
      shadowPath.lineTo(currentPoint.dx, currentPoint.dy);
    }

    // 影を描画
    canvas.drawPath(shadowPath, shadowPaint);

    // パスを描画
    canvas.drawPath(path, paint);

    // 各セルの中心に丸を描画
    final dotPaint = Paint()
      ..color = Colors.blue.shade700
      ..style = PaintingStyle.fill;

    for (final cellIndex in tracedCells) {
      final center = getCellCenter(cellIndex);
      canvas.drawCircle(center, 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(PathPainter oldDelegate) {
    return oldDelegate.tracedCells.length != tracedCells.length;
  }
}
