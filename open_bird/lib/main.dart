import 'package:flutter/material.dart';

void main() {
  runApp(const OpenBirdApp());
}

class OpenBirdApp extends StatelessWidget {
  const OpenBirdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpenBird',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.yellow),
        useMaterial3: true,
      ),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  bool _isGameStarted = false;
  bool _isGameOver = false;
  int _score = 0;
  int _highScore = 0;

  double _birdY = 0.5;
  double _birdVelocity = 0.0;
  static const double _gravity = 0.0015;
  static const double _jumpStrength = -0.045;

  List<Pipe> _pipes = [];
  static const double _pipeWidth = 0.2;
  static const double _pipeGap = 0.35;
  static const double _pipeSpeed = 0.008;
  double _pipeTimer = 0.0;

  late AnimationController _gameLoopController;

  @override
  void initState() {
    super.initState();
    _gameLoopController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_gameLoop);
  }

  void _startGame() {
    setState(() {
      _isGameStarted = true;
      _isGameOver = false;
      _score = 0;
      _birdY = 0.5;
      _birdVelocity = 0.0;
      _pipes = [];
      _pipeTimer = 0.0;
    });
    _gameLoopController.repeat();
  }

  void _gameLoop() {
    if (!_isGameStarted || _isGameOver) return;

    setState(() {
      _birdVelocity += _gravity;
      _birdY += _birdVelocity;

      for (var pipe in _pipes) {
        pipe.x -= _pipeSpeed;
      }

      _pipes.removeWhere((pipe) {
        if (pipe.x + _pipeWidth < 0) {
          if (!pipe.scored) {
            _score++;
          }
          return true;
        }
        return false;
      });

      _pipeTimer += _pipeSpeed;
      if (_pipeTimer >= 0.5) {
        _pipeTimer = 0.0;
        _addPipe();
      }

      _checkCollisions();

      if (_birdY < 0.08 || _birdY > 0.92) {
        _gameOver();
      }
    });
  }

  void _addPipe() {
    final random = DateTime.now().millisecondsSinceEpoch % 1000 / 1000.0;
    final gapPosition = 0.3 + random * 0.4;
    _pipes.add(Pipe(x: 1.0, gapPosition: gapPosition));
  }

  void _checkCollisions() {
    final birdX = 0.25;

    for (var pipe in _pipes) {
      final pipeStart = pipe.x;
      final pipeEnd = pipe.x + _pipeWidth;

      if (birdX + 0.05 > pipeStart && birdX - 0.05 < pipeEnd) {
        if (_birdY < pipe.gapPosition || _birdY > pipe.gapPosition + _pipeGap) {
          _gameOver();
        }
      }
    }
  }

  void _jump() {
    if (!_isGameStarted || _isGameOver) {
      _startGame();
      return;
    }

    setState(() {
      _birdVelocity = _jumpStrength;
    });
  }

  void _gameOver() {
    setState(() {
      _isGameOver = true;
      if (_score > _highScore) {
        _highScore = _score;
      }
    });
    _gameLoopController.stop();
  }

  @override
  void dispose() {
    _gameLoopController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: _jump,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final screenHeight = constraints.maxHeight;

            return Stack(
              children: [
                Image.asset(
                  'assets/images/background.png',
                  width: screenWidth,
                  height: screenHeight,
                  fit: BoxFit.cover,
                ),
                ..._pipes.map((pipe) => [
                  Positioned(
                    left: pipe.x * screenWidth,
                    top: 0,
                    child: SizedBox(
                      width: _pipeWidth * screenWidth,
                      height: pipe.gapPosition * screenHeight,
                      child: Image.asset(
                        'assets/images/pipe.png',
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                  Positioned(
                    left: pipe.x * screenWidth,
                    top: (pipe.gapPosition + _pipeGap) * screenHeight,
                    child: SizedBox(
                      width: _pipeWidth * screenWidth,
                      height: (1 - pipe.gapPosition - _pipeGap) * screenHeight,
                      child: Image.asset(
                        'assets/images/pipe.png',
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                ]).expand((e) => e).toList(),
                Positioned(
                  left: 0.25 * screenWidth,
                  top: _birdY * screenHeight - 24,
                  child: Image.asset(
                    'assets/images/bird.png',
                    width: 48,
                    height: 48,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: Image.asset(
                    'assets/images/ground.png',
                    width: screenWidth,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 50,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      '$_score',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 4,
                            color: Colors.black,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (!_isGameStarted || _isGameOver)
                  Positioned(
                    top: screenHeight * 0.4,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Column(
                        children: [
                          Text(
                            _isGameOver ? 'Game Over' : 'OpenBird',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  blurRadius: 4,
                                  color: Colors.black,
                                  offset: Offset(2, 2),
                                ),
                              ],
                            ),
                          ),
                          if (_isGameOver) ...[
                            const SizedBox(height: 16),
                            Text(
                              'Score: $_score',
                              style: const TextStyle(
                                fontSize: 24,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'High Score: $_highScore',
                              style: const TextStyle(
                                fontSize: 24,
                                color: Colors.yellow,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          const Text(
                            'Tap to play',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class Pipe {
  double x;
  final double gapPosition;
  bool scored;

  Pipe({
    required this.x,
    required this.gapPosition,
    this.scored = false,
  });
}
