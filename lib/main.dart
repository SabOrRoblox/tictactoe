import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class X9C {
  static String _k1 = String.fromCharCodes([83,78,65,75,69,95,88,57,95,67,82,89,80,84,79,95,50,48,50,53,95,83,69,67,85,82,69,95,75,69,89]);
  static String _k2 = String.fromCharCodes([55,120,57,65,51,107,76,50,109,78,56,112,81,53,114,84,49,118,87,54,121,90,48,98,67,52,100,70,56,103,72]);
  static String? _fp;
  static String? _lh;
  static bool _vl = false;
  
  static Future<String> _gf() async {
    if (_fp != null) return _fp!;
    try {
      final d = DeviceInfoPlugin();
      String s = '';
      if (Platform.isAndroid) {
        final a = await d.androidInfo;
        s = '${a.id}_${a.device}_${a.hardware}_${a.board}';
      } else if (Platform.isIOS) {
        final i = await d.iosInfo;
        s = '${i.identifierForVendor}_${i.name}_${i.model}';
      }
      final b = utf8.encode(s + _k1);
      _fp = sha256.convert(b).toString();
      return _fp!;
    } catch (_) {
      final t = DateTime.now().millisecondsSinceEpoch.toString();
      final r = Random().nextInt(999999).toString();
      final b = utf8.encode(t + r + _k1);
      return sha256.convert(b).toString();
    }
  }
  
  static Future<bool> _cl(String k) async {
    try {
      final f = await _gf();
      final e = _gh(f);
      final c = _gh(k);
      if (c == e) {
        _vl = true;
        _lh = c;
        await _sl(k);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
  
  static String _gh(String d) {
    final b = utf8.encode(d + _k1);
    return sha256.convert(b).toString().substring(0, 32);
  }
  
  static Future<void> _sl(String k) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('x9k', k);
    await p.setString('x9h', _lh!);
    await p.setBool('x9v', true);
  }
  
  static Future<bool> _ck() async {
    if (_vl) return true;
    final p = await SharedPreferences.getInstance();
    final v = p.getBool('x9v') ?? false;
    if (!v) return false;
    final k = p.getString('x9k');
    final h = p.getString('x9h');
    if (k == null || h == null) return false;
    final c = _gh(k);
    if (c == h) {
      _vl = true;
      _lh = h;
      return true;
    }
    return false;
  }
  
  static bool _iv() => _vl;
  
  static Future<void> _cr() async {
    if (!_iv()) {
      final f = await _gf();
      final s = _sf();
      final c = _cs(s);
      if (!await _vc(c)) await _ts();
    }
  }
  
  static String _sf() {
    final m = [];
    m.add(_gm());
    m.add(_gf2());
    m.add(_gt());
    return m.join('|');
  }
  
  static String _gm() {
    try {
      if (Platform.isAndroid) {
        final p = Process.runSync('getprop', ['ro.build.fingerprint']);
        return p.stdout.toString().trim();
      }
    } catch (_) {}
    return 'X9';
  }
  
  static String _gf2() {
    try {
      final f = File('/system/bin/app_process');
      if (f.existsSync()) return f.statSync().modified.toString();
    } catch (_) {}
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
  
  static String _gt() {
    try {
      final d = Directory('/data/data/com.android.providers.settings');
      if (d.existsSync()) return d.statSync().changed.toString();
    } catch (_) {}
    return 'X9';
  }
  
  static String _cs(String d) {
    final b = utf8.encode(d + _k2);
    return sha256.convert(b).toString();
  }
  
  static Future<bool> _vc(String c) async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString('x9s');
    if (s == null) {
      await p.setString('x9s', c);
      return true;
    }
    return s == c;
  }
  
  static Future<void> _ts() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('x9t', true);
    await p.clear();
    exit(0);
  }
  
  static Future<bool> _ns() async {
    final c = await Connectivity().checkConnectivity();
    if (c == ConnectivityResult.none) return true;
    try {
      final f = await _gf();
      final r = await _pn();
      return r.contains(_gh(f).substring(0, 8));
    } catch (_) {
      return false;
    }
  }
  
  static Future<String> _pn() async {
    await Future.delayed(Duration(milliseconds: 100));
    return 'X9OK${DateTime.now().year}';
  }
  
  static Future<bool> _ab() async {
    try {
      final p = await SharedPreferences.getInstance();
      final d = p.getBool('x9d') ?? false;
      if (d) return true;
      if (Platform.isAndroid) {
        final f = File('/data/local/tmp/x9.chk');
        if (f.existsSync()) return true;
      }
      final r = Random().nextBool();
      return r;
    } catch (_) {
      return false;
    }
  }
}

class X9A extends StatefulWidget {
  @override
  _X9AState createState() => _X9AState();
}

class _X9AState extends State<X9A> with WidgetsBindingObserver {
  bool _l = false;
  bool _c = true;
  Timer? _t;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _i();
  }
  
  Future<void> _i() async {
    await X9C._cr();
    final v = await X9C._ck();
    if (!v) {
      final f = await X9C._gf();
      final l = _gl(f);
      final v2 = await X9C._cl(l);
      if (!v2) {
        setState(() => _l = false);
        return;
      }
    }
    if (await X9C._ab()) {
      setState(() => _l = false);
      return;
    }
    if (!await X9C._ns()) {
      _st();
      return;
    }
    setState(() {
      _l = true;
      _c = false;
    });
    _sp();
  }
  
  String _gl(String f) {
    final h = X9C._gh(f + 'X9PRO');
    return 'X9-${h.substring(0,4)}-${h.substring(4,8)}-${h.substring(8,12)}-${h.substring(12,16)}';
  }
  
  void _sp() {
    Timer.periodic(Duration(seconds: 30), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      X9C._cr();
      if (!X9C._iv()) {
        setState(() => _l = false);
        t.cancel();
      }
    });
  }
  
  void _st() {
    _t?.cancel();
    _t = Timer.periodic(Duration(seconds: 5), (t) {
      if (t.tick > 12) {
        t.cancel();
        _x();
      }
    });
  }
  
  void _x() {
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => X9L()),
        (_) => false,
      );
    }
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.paused) {
      _t?.cancel();
    } else if (s == AppLifecycleState.resumed) {
      if (!X9C._iv()) {
        _i();
      } else {
        X9C._cr();
      }
    }
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _t?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext c) {
    if (_c) {
      return MaterialApp(
        home: Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [Color(0xFF1a3a5f), Color(0xFF0a1a2f)],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.cyan),
                  SizedBox(height: 30),
                  Text('X9', style: TextStyle(color: Colors.cyan, fontSize: 24)),
                ],
              ),
            ),
          ),
        ),
      );
    }
    if (!_l) return X9L();
    return X9M();
  }
}

class X9L extends StatelessWidget {
  final _c = TextEditingController();
  
  @override
  Widget build(BuildContext c) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0a1a2f), Color(0xFF0d1b2a)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.security, size: 80, color: Colors.cyan),
                  SizedBox(height: 30),
                  Text(
                    String.fromCharCodes([76,73,67,69,78,83,69,32,75,69,89]),
                    style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 50),
                  TextField(
                    controller: _c,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'XXXX-XXXX-XXXX-XXXX',
                      hintStyle: TextStyle(color: Colors.grey),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.cyan),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.cyan, width: 2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      prefixIcon: Icon(Icons.vpn_key, color: Colors.cyan),
                    ),
                  ),
                  SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () async {
                      final k = _c.text.trim();
                      if (await X9C._cl(k)) {
                        Navigator.pushReplacement(c, MaterialPageRoute(builder: (_) => X9A()));
                      } else {
                        ScaffoldMessenger.of(c).showSnackBar(
                          SnackBar(content: Text('Invalid'), backgroundColor: Colors.red),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyan,
                      padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text('ACTIVATE', style: TextStyle(fontSize: 18, color: Colors.black)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class X9M extends StatelessWidget {
  @override
  Widget build(BuildContext c) {
    return MaterialApp(
      title: String.fromCharCodes([83,78,65,75,69]),
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Color(0xFF0a1a2f)),
      debugShowCheckedModeBanner: false,
      home: X9MS(),
    );
  }
}

class X9MS extends StatefulWidget {
  @override
  _X9MSState createState() => _X9MSState();
}

class _X9MSState extends State<X9MS> {
  @override
  Widget build(BuildContext c) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
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
              Spacer(),
              ShaderMask(
                shaderCallback: (b) => LinearGradient(
                  colors: [Colors.cyan, Colors.lightBlueAccent],
                ).createShader(b),
                child: Text(
                  String.fromCharCodes([10052,32,83,78,79,87,32,83,78,65,75,69,32,10052]),
                  style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              SizedBox(height: 80),
              _b(String.fromCharCodes([127918,32,80,76,65,89,32,127918]), () => Navigator.push(c, MaterialPageRoute(builder: (_) => X9G()))),
              Spacer(),
              Padding(
                padding: EdgeInsets.all(12),
                child: Text('X9 SECURE', style: TextStyle(color: Colors.white38)),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _b(String t, VoidCallback o) => ElevatedButton(
    onPressed: o,
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 50, vertical: 18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(40),
        side: BorderSide(color: Colors.cyan, width: 2),
      ),
    ),
    child: Text(t, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
  );
}

enum X9D { u, d, l, r }

class X9S {
  List<Offset> b;
  X9D d;
  final Color c;
  final String n;
  final bool p;
  X9D _nd;
  
  X9S(Offset s, this.c, this.n, this.p)
      : b = [s, s - Offset(20, 0), s - Offset(40, 0)],
        d = X9D.r,
        _nd = X9D.r;
  
  Offset get h => b.first;
  
  void cd(X9D nd) {
    if ((d == X9D.l && nd == X9D.r) ||
        (d == X9D.r && nd == X9D.l) ||
        (d == X9D.u && nd == X9D.d) ||
        (d == X9D.d && nd == X9D.u)) return;
    _nd = nd;
  }
  
  void m() {
    d = _nd;
    Offset nh = h;
    switch (d) {
      case X9D.u: nh += Offset(0, -20); break;
      case X9D.d: nh += Offset(0, 20); break;
      case X9D.l: nh += Offset(-20, 0); break;
      case X9D.r: nh += Offset(20, 0); break;
    }
    b.insert(0, nh);
    b.removeLast();
  }
  
  void g() => b.add(b.last);
  
  bool cw(X9S o) {
    for (var s in b) {
      if (o.b.contains(s) && o.b.indexOf(s) != 0) return true;
    }
    return false;
  }
  
  bool oob(Size s) => h.dx < 0 || h.dx > s.width || h.dy < 0 || h.dy > s.height;
}

class X9F {
  final Offset p;
  X9F(this.p);
}

class X9G extends StatefulWidget {
  @override
  _X9GState createState() => _X9GState();
}

class _X9GState extends State<X9G> with TickerProviderStateMixin {
  late List<X9S> s;
  late List<X9F> f;
  late Timer t;
  bool r = true;
  int sc = 0;
  final Random _r = Random();
  late AnimationController _ac;
  
  @override
  void initState() {
    super.initState();
    _ac = AnimationController(duration: Duration(seconds: 3), vsync: this)..repeat();
    _i();
  }
  
  void _i() {
    s = [
      X9S(Offset(400, 300), Colors.yellow, "YOU", true),
      X9S(Offset(200, 300), Colors.red, "B1", false),
      X9S(Offset(600, 300), Colors.green, "B2", false),
      X9S(Offset(300, 400), Colors.orange, "B3", false),
      X9S(Offset(500, 200), Colors.purple, "B4", false),
    ];
    f = List.generate(8, (_) => X9F(_ro()));
    sc = s.first.b.length;
    t = Timer.periodic(Duration(milliseconds: 80), (_) => _u());
  }
  
  Offset _ro() => Offset(50 + _r.nextInt(700).toDouble(), 50 + _r.nextInt(500).toDouble());
  
  void _u() {
    if (!r) return;
    for (var sn in s) {
      sn.m();
      _fc(sn);
    }
    _cc();
    setState(() => sc = s.first.b.length);
  }
  
  void _fc(X9S sn) {
    for (int i = 0; i < f.length; i++) {
      if ((sn.h - f[i].p).distance < 15) {
        sn.g();
        f[i] = X9F(_ro());
        break;
      }
    }
  }
  
  void _cc() {
    for (int i = 0; i < s.length; i++) {
      for (int j = 0; j < s.length; j++) {
        if (i != j && s[i].cw(s[j])) {
          if (s[i].p) {
            _go();
            return;
          }
        }
      }
      if (s[i].oob(Size(800, 600))) {
        if (s[i].p) {
          _go();
          return;
        }
      }
    }
  }
  
  void _go() {
    r = false;
    t.cancel();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(String.fromCharCodes([128128,32,71,65,77,69,32,79,86,69,82,32,128128]), style: TextStyle(color: Colors.white)),
        content: Text('SCORE: $sc', style: TextStyle(color: Colors.white70, fontSize: 18)),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow[700]),
            child: Text('MENU', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    t.cancel();
    _ac.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext c) {
    return Scaffold(
      body: GestureDetector(
        onPanUpdate: (d) {
          if (!r) return;
          final sn = s.first;
          if (d.delta.dx.abs() > d.delta.dy.abs()) {
            sn.cd(d.delta.dx > 0 ? X9D.r : X9D.l);
          } else {
            sn.cd(d.delta.dy > 0 ? X9D.d : X9D.u);
          }
        },
        child: Container(
          decoration: BoxDecoration(
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
                  painter: X9SP(_ac.value),
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
                      painter: X9GP(s, f),
                      size: Size(800, 600),
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
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.cyan, Colors.blue]),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Text('SIZE: $sc', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                right: 20,
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      Text('TOP', style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold)),
                      ...s.map((sn) => Padding(
                        padding: EdgeInsets.symmetric(vertical: 2),
                        child: Text('${sn.n}: ${sn.b.length}', style: TextStyle(color: sn.c, fontWeight: FontWeight.bold)),
                      )),
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

class X9GP extends CustomPainter {
  final List<X9S> s;
  final List<X9F> f;
  
  X9GP(this.s, this.f);
  
  @override
  void paint(Canvas c, Size sz) {
    c.drawRect(Rect.fromLTWH(0, 0, sz.width, sz.height), Paint()..color = Color(0xFF0a1a2f));
    for (var fd in f) {
      c.drawCircle(fd.p, 8, Paint()..color = Colors.red);
      c.drawCircle(fd.p, 4, Paint()..color = Colors.white);
    }
    for (var sn in s) {
      for (int i = 0; i < sn.b.length; i++) {
        c.drawCircle(sn.b[i], 12, Paint()..color = sn.c.withOpacity(1.0 - (i * 0.02)));
        if (i == 0) {
          c.drawCircle(sn.b[i], 14, Paint()..color = sn.c);
          c.drawCircle(sn.b[i] + Offset(-5, -5), 4, Paint()..color = Colors.white);
          c.drawCircle(sn.b[i] + Offset(5, -5), 4, Paint()..color = Colors.white);
          c.drawCircle(sn.b[i] + Offset(0, 5), 3, Paint()..color = Colors.black);
        }
      }
      final ts = TextSpan(text: sn.n, style: TextStyle(color: sn.c, fontSize: 14, fontWeight: FontWeight.bold));
      TextPainter(text: ts, textDirection: TextDirection.ltr)
        ..layout()
        ..paint(c, sn.h + Offset(-20, -25));
    }
  }
  
  @override
  bool shouldRepaint(X9GP o) => true;
}

class X9SP extends CustomPainter {
  final double p;
  X9SP(this.p);
  
  @override
  void paint(Canvas c, Size sz) {
    final r = Random(42);
    for (int i = 0; i < 100; i++) {
      final x = (r.nextDouble() * sz.width + p * 100) % sz.width;
      final y = (r.nextDouble() * sz.height + p * 50) % sz.height;
      c.drawCircle(Offset(x, y), 2, Paint()..color = Colors.white.withOpacity(0.5));
    }
  }
  
  @override
  bool shouldRepaint(X9SP o) => true;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(X9A());
}
