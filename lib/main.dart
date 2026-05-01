import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pointycastle/export.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:crypto/crypto.dart';
import 'dart:typed_data';
import 'package:flutter_keychain/flutter_keychain.dart';
import 'dart:async';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.black,
  ));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          secondary: Colors.white70,
          surface: Color(0xFF121212),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _status = "Initializing...";
  bool _ready = false;
  String? _error;
  String _decryptedData = "";

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      setState(() => _status = "Checking APK integrity...");
      final integrityOk = await _checkApkIntegrity();
      if (!integrityOk) throw Exception("Integrity check failed");

      setState(() => _status = "Loading storage...");
      final storageData = await _loadFromStorage();
      
      if (storageData != null) {
        setState(() {
          _decryptedData = storageData;
          _status = storageData;
          _ready = true;
        });
      } else {
        setState(() {
          _status = "Storage loaded successfully\nNo encrypted data found";
          _ready = true;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _status = "ERROR";
        _ready = true;
      });
    }
  }

  Future<bool> _checkApkIntegrity() async {
    const channel = MethodChannel('app_integrity');
    
    try {
      final currentHash = await channel.invokeMethod('getSignatureHash');
      final storedHash = await FlutterKeychain.get(key: 'apk_signature_hash');
      
      if (storedHash == null) {
        await FlutterKeychain.put(key: 'apk_signature_hash', value: currentHash);
        return true;
      }
      
      return currentHash == storedHash;
    } catch (e) {
      return false;
    }
  }

  Future<String> _getDeviceFingerprint() async {
    final deviceInfo = DeviceInfoPlugin();
    String fingerprint = '';
    
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      fingerprint = '${androidInfo.brand}_${androidInfo.model}_${androidInfo.board}_${androidInfo.hardware}_${androidInfo.fingerprint}_${androidInfo.serialNumber}';
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      fingerprint = '${iosInfo.model}_${iosInfo.identifierForVendor}_${iosInfo.utsname.machine}';
    }
    
    final bytes = utf8.encode(fingerprint);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<String?> _loadFromStorage() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/secure_data.enc');
      
      if (!file.existsSync()) return null;

      final encryptedData = await file.readAsBytes();
      final key = await _getOrCreateKey();
      final decrypted = _decryptChacha20(encryptedData, key);
      return utf8.decode(decrypted);
    } catch (e) {
      return null;
    }
  }

  Future<Uint8List> _getOrCreateKey() async {
    try {
      final existingKey = await FlutterKeychain.get(key: 'chacha_key');
      if (existingKey != null) {
        return base64Decode(existingKey);
      }
    } catch (_) {}

    final fingerprint = await _getDeviceFingerprint();
    final salt = utf8.encode('secure_salt_2024');
    final keyMaterial = Uint8List.fromList(utf8.encode(fingerprint));
    final hashedKey = sha256.convert(keyMaterial + salt);
    final key = Uint8List.fromList(hashedKey.bytes);

    await FlutterKeychain.put(key: 'chacha_key', value: base64Encode(key));
    return key;
  }

  Uint8List _decryptChacha20(Uint8List encryptedData, Uint8List key) {
    final nonce = encryptedData.sublist(0, 12);
    final ciphertext = encryptedData.sublist(12);
    final cipher = ChaCha20Engine()..init(false, ParametersWithIV(KeyParameter(key), nonce));
    final decrypted = Uint8List(ciphertext.length);
    cipher.processBytes(ciphertext, 0, ciphertext.length, decrypted, 0);
    return decrypted;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_error != null) {
          SystemNavigator.pop();
          exit(0);
        }
        SystemNavigator.pop();
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0A0A0A), Color(0xFF000000)],
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_error != null) ...[
                    const Icon(Icons.error_outline, color: Colors.red, size: 64),
                    const SizedBox(height: 32),
                    Text(
                      _error!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                        fontFamily: 'monospace',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (_error == null && !_ready) ...[
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                      strokeWidth: 2,
                    ),
                    const SizedBox(height: 32),
                    Text(
                      _status,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontFamily: 'monospace',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (_error == null && _ready && _decryptedData.isNotEmpty) ...[
                    const Icon(Icons.lock_open, color: Colors.green, size: 48),
                    const SizedBox(height: 24),
                    Text(
                      _decryptedData,
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 16,
                        fontFamily: 'monospace',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (_error == null && _ready && _decryptedData.isEmpty) ...[
                    const Icon(Icons.storage, color: Colors.white70, size: 48),
                    const SizedBox(height: 24),
                    const Text(
                      "Storage empty",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                  if (_ready && _error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 48),
                      child: Text(
                        "Application will crash on exit",
                        style: TextStyle(
                          color: Colors.red.withOpacity(0.7),
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
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
