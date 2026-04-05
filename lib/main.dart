import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';

void main() => runApp(const SnakeGameApp());

class SnakeGameApp extends StatelessWidget {
  const SnakeGameApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Snow Snake',
        theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: const Color(0xFF0a1a2f)),
        debugShowCheckedModeBanner: false,
        home: const MenuScreen(),
      );
}

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});
  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [Color(0xFF1a3a5f), Color(0xFF0a1a2f)],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              ShaderMask(
                shaderCallback: (Rect bounds) => const LinearGradient(
                  colors: [Colors.cyan, Colors.lightBlueAccent],
                ).createShader(bounds),
                child: const Text(
                  '❄️ SNOW SNAKE ❄️',
                  style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(height: 80),
              _buildMenuButton('🎮 ИГРАТЬ', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GameScreen()))),
              const SizedBox(height: 20),
              _buildMenuButton('⚙️ НАСТРОЙКИ', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
              const SizedBox(height: 20),
              _buildMenuButton('🛒 МАГАЗИН', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopScreen()))),
              const SizedBox(height: 20),
              _buildMenuButton('🌐 МУЛЬТИПЛЕЕР', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MultiplayerScreen()))),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(12),
                child: const Text('🐍 2025 | Winter Edition', style: TextStyle(color: Colors.white38)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(String text, VoidCallback onTap) => ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
            side: const BorderSide(color: Colors.cyan, width: 2),
          ),
        ),
        child: Text(text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
      );
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late List<Snake> snakes;
  late List<Food> foods;
  late Timer gameTimer;
  bool isGameRunning = true;
  int playerScore = 0;
  String playerName = "YOU";
  final Random _random = Random();
  late AnimationController _snowController;

  @override
  void initState() {
    super.initState();
    _snowController = AnimationController(duration: const Duration(seconds: 3), vsync: this)..repeat();
    _initGame();
  }

  void _initGame() {
    snakes = [
      Snake(Offset(400, 300), Colors.yellow, playerName, true),
      Snake(Offset(200, 300), Colors.red, "BOT_1", false),
      Snake(Offset(600, 300), Colors.green, "BOT_2", false),
      Snake(Offset(300, 400), Colors.orange, "BOT_3", false),
      Snake(Offset(500, 200), Colors.purple, "BOT_4", false),
    ];
    foods = List.generate(8, (_) => Food(_randomOffset()));
    playerScore = snakes.first.body.length;
    gameTimer = Timer.periodic(const Duration(milliseconds: 80), (_) => _updateGame());
  }

  Offset _randomOffset() => Offset(50 + _random.nextInt(700).toDouble(), 50 + _random.nextInt(500).toDouble());

  void _updateGame() {
    if (!isGameRunning) return;
    for (var snake in snakes) {
      snake.move();
      _checkFoodCollision(snake);
    }
    _checkCollisions();
    setState(() {
      playerScore = snakes.first.body.length;
    });
  }

  void _checkFoodCollision(Snake snake) {
    for (int i = 0; i < foods.length; i++) {
      if ((snake.head - foods[i].position).distance < 15) {
        snake.grow();
        foods[i] = Food(_randomOffset());
        break;
      }
    }
  }

  void _checkCollisions() {
    for (int i = 0; i < snakes.length; i++) {
      for (int j = 0; j < snakes.length; j++) {
        if (i != j && snakes[i].isCollidingWith(snakes[j])) {
          if (snakes[i].isPlayer) {
            _gameOver();
            return;
          }
        }
      }
      if (snakes[i].isOutOfBounds(Size(800, 600))) {
        if (snakes[i].isPlayer) {
          _gameOver();
          return;
        }
      }
    }
  }

  void _gameOver() {
    isGameRunning = false;
    gameTimer.cancel();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('💀 ВЫ УМЕРЛИ 💀', style: TextStyle(color: Colors.white)),
        content: Text('Ваш размер: ${playerScore}', style: const TextStyle(color: Colors.white70, fontSize: 18)),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow[700]),
            child: const Text('В МЕНЮ', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    gameTimer.cancel();
    _snowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onPanUpdate: (details) {
          if (!isGameRunning) return;
          final snake = snakes.first;
          if (details.delta.dx.abs() > details.delta.dy.abs()) {
            snake.changeDirection(details.delta.dx > 0 ? Direction.right : Direction.left);
          } else {
            snake.changeDirection(details.delta.dy > 0 ? Direction.down : Direction.up);
          }
        },
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1a3a5f), Color(0xFF0a1a2f)],
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: SnowPainter(_snowController.value),
                  size: Size.infinite,
                ),
              ),
              Center(
                child: Container(
                  width: 800,
                  height: 600,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.cyan.withOpacity(0.3), blurRadius: 30)],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: CustomPaint(
                      painter: GamePainter(snakes, foods),
                      size: const Size(800, 600),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Colors.cyan, Colors.blue]),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Text('🐍 РАЗМЕР: $playerScore 🐍', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        children: [
                          const Text('🏆 ЛИДЕРЫ 🏆', style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold)),
                          ...snakes.map((s) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Text('${s.name}: ${s.body.length}', style: TextStyle(color: s.color, fontWeight: FontWeight.bold)),
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: isGameRunning ? null : () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellow[700],
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(20),
                      ),
                      child: const Text('ИГРАТЬ', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Настройки'), backgroundColor: Colors.transparent),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎵 Звук: ВКЛ', style: TextStyle(fontSize: 24)),
              const SizedBox(height: 20),
              const Text('🐍 Скорость змей: НОРМАЛЬНАЯ', style: TextStyle(fontSize: 24)),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Назад')),
            ],
          ),
        ),
      );
}

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Магазин'), backgroundColor: Colors.transparent),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('✨ СКИНЫ ДЛЯ ЗМЕЙ ✨', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              _buildSkin('🐍 КЛАССИЧЕСКАЯ', Colors.yellow),
              _buildSkin('❄️ ЛЕДЯНАЯ', Colors.cyan),
              _buildSkin('🔥 ОГНЕННАЯ', Colors.orange),
              _buildSkin('💎 ЗОЛОТАЯ', Colors.amber),
            ],
          ),
        ),
      );
  Widget _buildSkin(String name, Color color) => Padding(
        padding: const EdgeInsets.all(8),
        child: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(backgroundColor: color.withOpacity(0.3)),
          child: Text(name, style: TextStyle(color: color, fontSize: 18)),
        ),
      );
}

class MultiplayerScreen extends StatelessWidget {
  const MultiplayerScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Мультиплеер'), backgroundColor: Colors.transparent),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🌐 ПОИСК ИГРОКОВ...', style: TextStyle(fontSize: 24)),
              const SizedBox(height: 30),
              const CircularProgressIndicator(),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Отмена'),
              ),
            ],
          ),
        ),
      );
}

enum Direction { up, down, left, right }

class Snake {
  List<Offset> body;
  Direction direction;
  final Color color;
  final String name;
  final bool isPlayer;
  Direction _nextDirection;

  Snake(Offset start, this.color, this.name, this.isPlayer)
      : body = [start, start - const Offset(20, 0), start - const Offset(40, 0)],
        direction = Direction.right,
        _nextDirection = Direction.right;

  Offset get head => body.first;

  void changeDirection(Direction newDir) {
    if ((direction == Direction.left && newDir == Direction.right) ||
        (direction == Direction.right && newDir == Direction.left) ||
        (direction == Direction.up && newDir == Direction.down) ||
        (direction == Direction.down && newDir == Direction.up)) return;
    _nextDirection = newDir;
  }

  void move() {
    direction = _nextDirection;
    Offset newHead = head;
    switch (direction) {
      case Direction.up:
        newHead += const Offset(0, -20);
        break;
      case Direction.down:
        newHead += const Offset(0, 20);
        break;
      case Direction.left:
        newHead += const Offset(-20, 0);
        break;
      case Direction.right:
        newHead += const Offset(20, 0);
        break;
    }
    body.insert(0, newHead);
    body.removeLast();
  }

  void grow() {
    body.add(body.last);
  }

  bool isCollidingWith(Snake other) {
    for (var segment in body) {
      if (other.body.contains(segment) && other.body.indexOf(segment) != 0) return true;
    }
    return false;
  }

  bool isOutOfBounds(Size size) {
    return head.dx < 0 || head.dx > size.width || head.dy < 0 || head.dy > size.height;
  }
}

class Food {
  final Offset position;
  Food(this.position);
}

class GamePainter extends CustomPainter {
  final List<Snake> snakes;
  final List<Food> foods;

  GamePainter(this.snakes, this.foods);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = const Color(0xFF0a1a2f));
    for (var food in foods) {
      final paint = Paint()..color = Colors.red;
      canvas.drawCircle(food.position, 8, paint);
      canvas.drawCircle(food.position, 4, Paint()..color = Colors.white);
    }
    for (var snake in snakes) {
      for (int i = 0; i < snake.body.length; i++) {
        final paint = Paint()..color = snake.color.withOpacity(1.0 - (i * 0.02));
        canvas.drawCircle(snake.body[i], 12, paint);
        if (i == 0) {
          canvas.drawCircle(snake.body[i], 14, Paint()..color = snake.color);
          canvas.drawCircle(snake.body[i] + const Offset(-5, -5), 4, Paint()..color = Colors.white);
          canvas.drawCircle(snake.body[i] + const Offset(5, -5), 4, Paint()..color = Colors.white);
          canvas.drawCircle(snake.body[i] + const Offset(0, 5), 3, Paint()..color = Colors.black);
        }
      }
      final textSpan = TextSpan(text: snake.name, style: TextStyle(color: snake.color, fontSize: 14, fontWeight: FontWeight.bold));
      TextPainter(text: textSpan, textDirection: TextDirection.ltr)
        ..layout()
        ..paint(canvas, snake.head + const Offset(-20, -25));
    }
  }

  @override
  bool shouldRepaint(covariant GamePainter oldDelegate) => true;
}

class SnowPainter extends CustomPainter {
  final double progress;
  SnowPainter(this.progress);
  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42);
    for (int i = 0; i < 100; i++) {
      final x = (random.nextDouble() * size.width + progress * 100) % size.width;
      final y = (random.nextDouble() * size.height + progress * 50) % size.height;
      canvas.drawCircle(Offset(x, y), 2, Paint()..color = Colors.white.withOpacity(0.5));
    }
  }
  @override
  bool shouldRepaint(covariant SnowPainter oldDelegate) => true;
}
