import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:pagtambong_attendance_system/service/LogService.dart';

LogService logger = LogService();

class ConnectivityService {
  static const int _timeoutSeconds = 5;
  static const _maxRetries = 2;
  static const Duration _checkInterval = Duration(seconds: 30);

  final InternetConnectionCheckerPlus _checker = InternetConnectionCheckerPlus();
  final _connectivityController = StreamController<bool>.broadcast();
  Timer? _periodicTimer;
  bool _lastKnownStatus = true;

  Stream<bool> get connectivityStream => _connectivityController.stream;

  // List of reliable endpoints
  final List<String> _testUrls = [
    'https://www.google.com',
    'https://cloudflare.com',
    'https://www.apple.com',
  ];

  ConnectivityService() {
    _initConnectivityListener();
  }

  void _initConnectivityListener() {
    _periodicTimer = Timer.periodic(_checkInterval, (_) => checkConnectivity);

    // Listen to connectivity changes
    Connectivity().onConnectivityChanged.listen((result) async {
      if (result == ConnectivityResult.none) {
        _updateConnectionStatus(false);
      } else {
        // Double check internet connectivity
        checkConnectivity();
      }
    });
  }

  Future<bool> checkConnectivity() async {
    try {
      final hasInterface = await _checker.hasConnection;

      if (!hasInterface) {
        _updateConnectionStatus(false);

        return false;
      }

      // Test actual internet connectivity with timeout
      bool isConnected = await _testConnection();
      _updateConnectionStatus(isConnected);
      return isConnected;
    } catch (e) {
      _updateConnectionStatus(false);
      return false;
    }
  }

  Future<bool> _testConnection() async {
    for (int retry = 0; retry < _maxRetries; retry++) {
      for (String url in _testUrls) {
        try {
          final response = await http.get(Uri.parse(url)).timeout(
            Duration(seconds: _timeoutSeconds),
            onTimeout: () {
              throw TimeoutException('Connection Timed Out');
            }
          );

          if (response.statusCode == 200) {
            return true;
          }
        } catch (e) {
          continue; // Try next url
        }
      }

      // Delay
      await Future.delayed(const Duration(milliseconds: 500));
    }
    return false;
  }

  void _updateConnectionStatus(bool isConnected) {
    if (_lastKnownStatus != isConnected) {
      _lastKnownStatus = isConnected;
      _connectivityController.add(isConnected);
    }
  }

  void dispose() {
    _periodicTimer?.cancel();
    _connectivityController.close();
  }
}