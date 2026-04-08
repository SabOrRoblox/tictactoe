// flutter app
import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(T3App());
}

class T3App extends StatelessWidget {
  @override
  Widget build(BuildContext c) => MaterialApp(
    title: 'T3 ELITE',
    theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Color(0xFF1a1a2e)),
    debugShowCheckedModeBanner: false,
    home: T3Menu(),
  );
}

class T3Menu extends StatefulWidget {
  @override
  _T3MenuState createState() => _T3MenuState();
}

class _T3MenuState extends State<T3Menu> {
  String? _userId;
  String _name = '';
  int _elo = 1000;
  bool _loading = true;
  
  @override
  void initState() {
    super.initState();
    _initUser();
  }
  
  Future<void> _initUser() async {
    final p = await SharedPreferences.getInstance();
    String? id = p.getString('user_id');
    if (id == null) {
      final bytes = utf8.encode(DateTime.now().millisecondsSinceEpoch.toString());
      id = sha256.convert(bytes).toString().substring(0, 16);
      await p.setString('user_id', id);
    }
    _userId = id;
    
    final savedName = p.getString('user_name');
    final savedElo = p.getInt('user_elo');
    
    setState(() {
      _name = savedName ?? 'Player_${id!.substring(0, 6)}';
      _elo = savedElo ?? 1000;
      _loading = false;
    });
  }
  
  @override
  Widget build(BuildContext c) {
    if (_loading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/back.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Center(child: CircularProgressIndicator(color: Colors.amber)),
        ),
      );
    }
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/back.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.7), BlendMode.darken),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Spacer(),
              Container(
                padding: EdgeInsets.all(30),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.amber.shade800, Colors.orange.shade900]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.3), blurRadius: 20)],
                ),
                child: Column(
                  children: [
                    Text('T3', style: TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('ELITE', style: TextStyle(fontSize: 24, letterSpacing: 8, color: Colors.white70)),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.amber, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person, color: Colors.amber),
                    SizedBox(width: 10),
                    Text(_name, style: TextStyle(fontSize: 18, color: Colors.white)),
                    SizedBox(width: 20),
                    Icon(Icons.star, color: Colors.amber),
                    SizedBox(width: 10),
                    Text('$_elo', style: TextStyle(fontSize: 18, color: Colors.amber, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Spacer(),
              _buildButton('FIND MATCH', () => Navigator.push(c, MaterialPageRoute(builder: (_) => T3Game(userId: _userId!, name: _name, elo: _elo)))),
              SizedBox(height: 15),
              _buildButton('LEADERBOARD', () => Navigator.push(c, MaterialPageRoute(builder: (_) => T3Leaderboard()))),
              SizedBox(height: 15),
              _buildButton('PROFILE', () {}),
              Spacer(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildButton(String t, VoidCallback o) => ElevatedButton(
    onPressed: o,
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.amber.shade800,
      foregroundColor: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 60, vertical: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
    ),
    child: Text(t, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
  );
}

class T3Game extends StatefulWidget {
  final String userId;
  final String name;
  final int elo;
  
  T3Game({required this.userId, required this.name, required this.elo});
  
  @override
  _T3GameState createState() => _T3GameState();
}

class _T3GameState extends State<T3Game> {
  static const String WS_URL = 'wss://d1ada3d8f630afe2964f9916b3bc65450d8c8a7299326acc28565f6186bb038e80071092f86d3f34fdbcd.render.com/ws';
  
  WebSocketChannel? _channel;
  List<String> _board = List.filled(9, '');
  String _turn = '';
  String _winner = '';
  int _playerFlag = 0;
  bool _connected = false;
  bool _searching = true;
  bool _gameActive = false;
  String _status = 'Searching for opponent...';
  int _eloChange = 0;
  Timer? _pingTimer;
  int _seq = 0;
  
  @override
  void initState() {
    super.initState();
    _connect();
  }
  
  void _connect() {
    _channel = WebSocketChannel.connect(Uri.parse(WS_URL));
    
    _channel!.stream.listen((data) {
      _handleMessage(data);
    }, onError: (e) {
      setState(() => _status = 'Connection error');
    }, onDone: () {
      if (mounted) {
        setState(() {
          _connected = false;
          _status = 'Disconnected';
        });
        Future.delayed(Duration(seconds: 3), () {
          if (mounted) _connect();
        });
      }
    });
    
    _startPing();
  }
  
  void _startPing() {
    _pingTimer = Timer.periodic(Duration(seconds: 25), (_) {
      if (_channel != null) {
        final buf = ByteData(6);
        buf.setUint8(0, 0x01);
        buf.setUint8(1, 0);
        buf.setUint32(2, ++_seq);
        _channel!.sink.add(buf.buffer.asUint8List());
      }
    });
  }
  
  void _handleMessage(dynamic data) {
    final buf = data is ByteBuffer ? data.asUint8List() : data as Uint8List;
    if (buf.length < 6) return;
    
    final op = buf[0];
    final seq = (buf[2] << 24) | (buf[3] << 16) | (buf[4] << 8) | buf[5];
    
    if (op == 0x02) return;
    
    if (op == 0x04) {
      final elo = (buf[6] << 24) | (buf[7] << 16) | (buf[8] << 8) | buf[9];
      setState(() {
        _connected = true;
        _status = 'Connected';
      });
      
      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted) _sendFindMatch();
      });
    }
    
    if (op == 0x06) {
      setState(() {
        _searching = false;
        _gameActive = true;
        _board = List.filled(9, '');
        for (int i = 0; i < 9; i++) {
          if (buf.length > 6 + i) {
            _board[i] = buf[6 + i] == 1 ? 'X' : (buf[6 + i] == 2 ? 'O' : '');
          }
        }
        _playerFlag = buf.length > 16 ? buf[16] : 1;
        _turn = 'X';
        _status = _playerFlag == 1 ? 'Your turn (X)' : 'Opponent\'s turn';
      });
    }
    
    if (op == 0x08) {
      setState(() {
        for (int i = 0; i < 9; i++) {
          if (buf.length > 6 + i) {
            _board[i] = buf[6 + i] == 1 ? 'X' : (buf[6 + i] == 2 ? 'O' : '');
          }
        }
        final t = buf[15];
        _turn = t == 1 ? 'X' : (t == 2 ? 'O' : '');
        final myTurn = (_playerFlag == 1 && _turn == 'X') || (_playerFlag == 2 && _turn == 'O');
        _status = myTurn ? 'Your turn' : 'Opponent\'s turn';
      });
    }
    
    if (op == 0x09) {
      setState(() {
        for (int i = 0; i < 9; i++) {
          if (buf.length > 6 + i) {
            _board[i] = buf[6 + i] == 1 ? 'X' : (buf[6 + i] == 2 ? 'O' : '');
          }
        }
        final w = buf[15];
        _winner = w == 1 ? 'X' : (w == 2 ? 'O' : (w == 3 ? 'draw' : ''));
        _eloChange = buf[16];
        _gameActive = false;
        
        if (_winner == 'X' && _playerFlag == 1) _status = 'You win! +$_eloChange ELO';
        else if (_winner == 'O' && _playerFlag == 2) _status = 'You win! +$_eloChange ELO';
        else if (_winner == 'draw') _status = 'Draw!';
        else _status = 'You lose!';
      });
    }
  }
  
  void _sendFindMatch() {
    final buf = ByteData(6 + widget.userId.length);
    buf.setUint8(0, 0x03);
    buf.setUint8(1, 0);
    buf.setUint32(2, ++_seq);
    for (int i = 0; i < widget.userId.length; i++) {
      buf.setUint8(6 + i, widget.userId.codeUnitAt(i));
    }
    _channel!.sink.add(buf.buffer.asUint8List());
  }
  
  void _makeMove(int cell) {
    if (!_gameActive || _board[cell].isNotEmpty) return;
    
    final myTurn = (_playerFlag == 1 && _turn == 'X') || (_playerFlag == 2 && _turn == 'O');
    if (!myTurn) return;
    
    final buf = ByteData(7);
    buf.setUint8(0, 0x07);
    buf.setUint8(1, 0);
    buf.setUint32(2, ++_seq);
    buf.setUint8(6, cell);
    _channel!.sink.add(buf.buffer.asUint8List());
    
    setState(() {
      _board[cell] = _playerFlag == 1 ? 'X' : 'O';
      _status = 'Opponent\'s turn';
    });
  }
  
  @override
  void dispose() {
    _pingTimer?.cancel();
    _channel?.sink.close();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext c) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/back.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.8), BlendMode.darken),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                title: Text('ELO: ${widget.elo}${_eloChange != 0 ? ' ${_eloChange > 0 ? "+" : ""}$_eloChange' : ''}'),
                backgroundColor: Colors.transparent,
                centerTitle: true,
              ),
              Expanded(
                child: Center(
                  child: _searching
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.amber),
                          SizedBox(height: 20),
                          Text(_status, style: TextStyle(fontSize: 18, color: Colors.white70)),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_status, style: TextStyle(fontSize: 20, color: Colors.amber)),
                          SizedBox(height: 30),
                          Container(
                            width: 320,
                            height: 320,
                            decoration: BoxDecoration(
                              color: Colors.black38,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.amber, width: 3),
                            ),
                            child: GridView.builder(
                              physics: NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
                              itemCount: 9,
                              itemBuilder: (c, i) => GestureDetector(
                                onTap: () => _makeMove(i),
                                child: Container(
                                  margin: EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.amber.withOpacity(0.5)),
                                  ),
                                  child: Center(
                                    child: Text(
                                      _board[i],
                                      style: TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold,
                                        color: _board[i] == 'X' ? Colors.cyan : Colors.red,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 30),
                          if (!_gameActive)
                            ElevatedButton(
                              onPressed: () => Navigator.pop(c),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                              child: Text('MENU'),
                            ),
                        ],
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class T3Leaderboard extends StatelessWidget {
  @override
  Widget build(BuildContext c) {
    return Scaffold(
      appBar: AppBar(title: Text('LEADERBOARD'), backgroundColor: Colors.transparent),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/back.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.8), BlendMode.darken),
          ),
        ),
        child: Center(
          child: Text('TOP 100 PLAYERS', style: TextStyle(color: Colors.amber, fontSize: 24)),
        ),
      ),
    );
  }
}
