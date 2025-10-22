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
            child: GridView.builder(
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
                        ? Colors.blue
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
