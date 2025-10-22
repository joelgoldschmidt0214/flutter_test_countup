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

// フェーズ2: ゲーム盤面の表示
class PuzzleBoard extends ConsumerWidget {
  const PuzzleBoard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracedCells = ref.watch(puzzleProvider);
    final notifier = ref.read(puzzleProvider.notifier);

    return GestureDetector(
      onPanStart: (details) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final localPosition = box.globalToLocal(details.globalPosition);
        _handleTouch(localPosition, notifier, context, ref);
      },
      onPanUpdate: (details) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final localPosition = box.globalToLocal(details.globalPosition);
        _handleTouch(localPosition, notifier, context, ref);
      },
      onPanEnd: (details) {
        // ドラッグが終わったらクリア判定
        notifier.checkClear(context);
      },
      child: Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Stack(
              children: [
                // グリッド
                GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                              : (isGoal ? Colors.red : Colors.black),
                          width: isStart || isGoal ? 3 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: isStart
                            ? const Icon(Icons.flag, color: Colors.green)
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
                // パスの描画
                if (tracedCells.length > 1)
                  CustomPaint(
                    painter: PathPainter(tracedCells),
                    size: Size.infinite,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleTouch(
    Offset position,
    PuzzleNotifier notifier,
    BuildContext context,
    WidgetRef ref,
  ) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final size = box.size;

    // パディングを考慮
    final contentSize = size.width < size.height ? size.width : size.height;
    final padding = 16.0;
    final gridSize = contentSize - (padding * 2);
    final cellSize = gridSize / 5;

    // グリッドの開始位置を計算
    final startX = (size.width - contentSize) / 2 + padding;
    final startY = (size.height - contentSize) / 2 + padding;

    // 相対位置を計算
    final relativeX = position.dx - startX;
    final relativeY = position.dy - startY;

    // グリッド外の場合は無視
    if (relativeX < 0 ||
        relativeY < 0 ||
        relativeX > gridSize ||
        relativeY > gridSize) {
      return;
    }

    final col = (relativeX / cellSize).floor();
    final row = (relativeY / cellSize).floor();

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

    // パスを作成（ベジェ曲線で滑らかに）
    final path = Path();
    final shadowPath = Path();

    // 最初の点に移動
    final firstPoint = getCellCenter(tracedCells[0]);
    path.moveTo(firstPoint.dx, firstPoint.dy);
    shadowPath.moveTo(firstPoint.dx, firstPoint.dy);

    // 2点目がある場合
    if (tracedCells.length == 2) {
      final secondPoint = getCellCenter(tracedCells[1]);
      path.lineTo(secondPoint.dx, secondPoint.dy);
      shadowPath.lineTo(secondPoint.dx, secondPoint.dy);
    } else {
      // 3点以上の場合は滑らかなベジェ曲線で接続
      for (int i = 1; i < tracedCells.length; i++) {
        final currentPoint = getCellCenter(tracedCells[i]);

        if (i == 1) {
          // 最初の線分
          final controlPoint = Offset(
            (currentPoint.dx + firstPoint.dx) / 2,
            (currentPoint.dy + firstPoint.dy) / 2,
          );
          path.quadraticBezierTo(
            controlPoint.dx,
            controlPoint.dy,
            currentPoint.dx,
            currentPoint.dy,
          );
          shadowPath.quadraticBezierTo(
            controlPoint.dx,
            controlPoint.dy,
            currentPoint.dx,
            currentPoint.dy,
          );
        } else if (i == tracedCells.length - 1) {
          // 最後の線分
          path.lineTo(currentPoint.dx, currentPoint.dy);
          shadowPath.lineTo(currentPoint.dx, currentPoint.dy);
        } else {
          // 中間の線分
          final prevPoint = getCellCenter(tracedCells[i - 1]);
          final controlPoint = Offset(
            (currentPoint.dx + prevPoint.dx) / 2,
            (currentPoint.dy + prevPoint.dy) / 2,
          );
          path.quadraticBezierTo(
            controlPoint.dx,
            controlPoint.dy,
            currentPoint.dx,
            currentPoint.dy,
          );
          shadowPath.quadraticBezierTo(
            controlPoint.dx,
            controlPoint.dy,
            currentPoint.dx,
            currentPoint.dy,
          );
        }
      }
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
