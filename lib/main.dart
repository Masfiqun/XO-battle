import 'dart:math' show Random;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TicTacToeApp());
}

class TicTacToeApp extends StatelessWidget {
  const TicTacToeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tic-Tac-Toe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Poppins',
        brightness: Brightness.light,
        colorSchemeSeed: Colors.purple,
      ),
      home: const GamePage(),
    );
  }
}

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with TickerProviderStateMixin {
  static const int boardSize = 9;
  static const List<List<int>> winLines = <List<int>>[
    [0, 1, 2],
    [3, 4, 5],
    [6, 7, 8],
    [0, 3, 6],
    [1, 4, 7],
    [2, 5, 8],
    [0, 4, 8],
    [2, 4, 6],
  ];

  late List<String?> _board;
  String _currentPlayer = 'X';
  String? _winner;
  List<int>? _winningLine;
  bool _gameOver = false;
  int _scoreX = 0;
  int _scoreO = 0;
  int _draws = 0;
  final List<int> _moveHistory = [];

  late final AnimationController _celebrateCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void initState() {
    super.initState();
    _resetBoard(firstRound: true);
  }

  @override
  void dispose() {
    _celebrateCtrl.dispose();
    super.dispose();
  }

  void _resetBoard({bool firstRound = false}) {
    setState(() {
      _board = List<String?>.filled(boardSize, null);
      _winningLine = null;
      _winner = null;
      _gameOver = false;
      _moveHistory.clear();
      _currentPlayer = firstRound
          ? (Random().nextBool() ? 'X' : 'O')
          : (_currentPlayer == 'X' ? 'O' : 'X');
      _celebrateCtrl.reset();
    });
  }

  void _handleTap(int index) {
    if (_gameOver || _board[index] != null) return;

    HapticFeedback.lightImpact();
    setState(() {
      _board[index] = _currentPlayer;
      _moveHistory.add(index);

      final line = _checkWinner();
      if (line != null) {
        _gameOver = true;
        _winner = _currentPlayer;
        _winningLine = line;
        if (_winner == 'X') _scoreX++; else _scoreO++;
        _celebrateCtrl.forward();
        HapticFeedback.mediumImpact();
        return;
      }
      if (_board.every((cell) => cell != null)) {
        _gameOver = true;
        _winner = 'Draw';
        _draws++;
        _celebrateCtrl.forward();
        return;
      }
      _currentPlayer = _currentPlayer == 'X' ? 'O' : 'X';
    });
  }

  List<int>? _checkWinner() {
    for (final line in winLines) {
      final a = _board[line[0]];
      final b = _board[line[1]];
      final c = _board[line[2]];
      if (a != null && a == b && b == c) return line;
    }
    return null;
  }

  void _undo() {
    if (_gameOver || _moveHistory.isEmpty) return;
    setState(() {
      final last = _moveHistory.removeLast();
      _board[last] = null;
      _currentPlayer = _currentPlayer == 'X' ? 'O' : 'X';
    });
  }

  String _statusText() {
    if (_winner == 'Draw') return '🤝 It\'s a Draw!';
    if (_winner == 'X' || _winner == 'O') return '$_winner Wins! 🎉';
    return 'Turn: $_currentPlayer';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.grid_3x3, color: Colors.white, size: 28),
            const SizedBox(width: 8),
            Text(
              'XO Battle',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                foreground: Paint()
                  ..shader = const LinearGradient(
                    colors: [
                      Color(0xFF00F5FF),
                      Color(0xFFFF00E5),
                    ],
                  ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
              ),
            ),
          ],
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _Scoreboard(scoreX: _scoreX, scoreO: _scoreO, draws: _draws),
              ),
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  _statusText(),
                  key: ValueKey(_statusText()),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: cs.onPrimary.withOpacity(0.9),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white24, width: 2),
                          ),
                          child: _Board(
                            board: _board,
                            winningLine: _winningLine,
                            onTap: _handleTap,
                            gameOver: _gameOver,
                            colorScheme: cs,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.15),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _undo,
                        icon: const Icon(Icons.undo),
                        label: const Text("Undo"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.15),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _resetBoard,
                        icon: const Icon(Icons.refresh),
                        label: const Text("Restart"),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Board extends StatelessWidget {
  final List<String?> board;
  final List<int>? winningLine;
  final void Function(int index) onTap;
  final bool gameOver;
  final ColorScheme colorScheme;

  const _Board({
    required this.board,
    required this.winningLine,
    required this.onTap,
    required this.gameOver,
    required this.colorScheme,
  });

  bool _isWinningCell(int i) => winningLine?.contains(i) ?? false;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
      itemCount: 9,
      itemBuilder: (context, i) {
        final value = board[i];
        final isWin = _isWinningCell(i);

        return GestureDetector(
          onTap: () => onTap(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white24, width: 1.5),
              color: isWin
                  ? Colors.yellow.withOpacity(0.25)
                  : Colors.transparent,
              boxShadow: isWin
                  ? [
                      BoxShadow(
                        color: Colors.yellowAccent.withOpacity(0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      )
                    ]
                  : [],
            ),
            child: Center(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                style: TextStyle(
                  fontSize: value == null ? 0 : 64,
                  fontWeight: FontWeight.w900,
                  color: value == 'X' ? Colors.cyanAccent : Colors.pinkAccent,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                    )
                  ],
                ),
                child: Text(value ?? ""),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Scoreboard extends StatelessWidget {
  final int scoreX;
  final int scoreO;
  final int draws;

  const _Scoreboard({
    required this.scoreX,
    required this.scoreO,
    required this.draws,
  });

  @override
  Widget build(BuildContext context) {
    TextStyle scoreStyle = const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(children: [
            const Text("Player X", style: TextStyle(color: Colors.white70)),
            Text("$scoreX", style: scoreStyle),
          ]),
          Column(children: [
            const Text("Draws", style: TextStyle(color: Colors.white70)),
            Text("$draws", style: scoreStyle),
          ]),
          Column(children: [
            const Text("Player O", style: TextStyle(color: Colors.white70)),
            Text("$scoreO", style: scoreStyle),
          ]),
        ],
      ),
    );
  }
}
