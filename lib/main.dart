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
      debugShowCheckedModeBanner: false,
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
    final puzzleState = ref.watch(puzzleProvider);
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
                '${puzzleState.tracedCells.length}/25',
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
    final puzzleState = ref.watch(puzzleProvider);
    final notifier = ref.read(puzzleProvider.notifier);
    final tracedCells = puzzleState.tracedCells;

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
                        notifier.addTouchPoint(details.localPosition);
                        _handleTouch(
                          details.localPosition,
                          constraints,
                          notifier,
                        );
                      },
                      onPanUpdate: (details) {
                        notifier.addTouchPoint(details.localPosition);
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

                                return AnimatedScale(
                                  scale: isTraced ? 0.85 : 1.0,
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOut,
                                  child: Container(
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
                                  ),
                                );
                              },
                            ),
                          ),
                          // パスの描画
                          if (puzzleState.touchPath.length > 1)
                            CustomPaint(
                              painter: PathPainter(puzzleState.touchPath),
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

// パスを描画するCustomPainter（実際の指の軌跡を滑らかに描画）
class PathPainter extends CustomPainter {
  final List<Offset> touchPath;

  PathPainter(this.touchPath);

  @override
  void paint(Canvas canvas, Size size) {
    if (touchPath.length < 2) return;

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

    // 滑らかな曲線を作成（Catmull-Rom スプライン）
    final path = Path();
    final shadowPath = Path();

    // 最初の点に移動
    path.moveTo(touchPath[0].dx, touchPath[0].dy);
    shadowPath.moveTo(touchPath[0].dx, touchPath[0].dy);

    // ポイントが少ない場合は直線で接続
    if (touchPath.length == 2) {
      path.lineTo(touchPath[1].dx, touchPath[1].dy);
      shadowPath.lineTo(touchPath[1].dx, touchPath[1].dy);
    } else {
      // 滑らかな曲線を描画
      for (int i = 0; i < touchPath.length - 1; i++) {
        final p0 = touchPath[i];
        final p1 = touchPath[i + 1];

        // 2次ベジェ曲線で滑らかに接続
        final controlPoint = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);

        path.quadraticBezierTo(p0.dx, p0.dy, controlPoint.dx, controlPoint.dy);
        shadowPath.quadraticBezierTo(
          p0.dx,
          p0.dy,
          controlPoint.dx,
          controlPoint.dy,
        );
      }

      // 最後の点まで描画
      final lastPoint = touchPath.last;
      path.lineTo(lastPoint.dx, lastPoint.dy);
      shadowPath.lineTo(lastPoint.dx, lastPoint.dy);
    }

    // 影を描画
    canvas.drawPath(shadowPath, shadowPaint);

    // パスを描画
    canvas.drawPath(path, paint);

    // スタート地点に丸を描画
    final dotPaint = Paint()
      ..color = Colors.blue.shade700
      ..style = PaintingStyle.fill;
    canvas.drawCircle(touchPath.first, 5, dotPaint);
  }

  @override
  bool shouldRepaint(PathPainter oldDelegate) {
    return oldDelegate.touchPath.length != touchPath.length;
  }
}
