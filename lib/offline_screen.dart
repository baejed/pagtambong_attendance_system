import 'dart:async';

import 'package:flutter/material.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:pagtambong_attendance_system/service/LogService.dart';

LogService logger = LogService();

class OfflineScreen extends StatefulWidget {
  const OfflineScreen({super.key});

  @override
  State createState() => _OfflineScreenState();
}

class _OfflineScreenState extends State<OfflineScreen> {
  bool isConnectedToInternet = false;
  late final AppLifecycleListener _lifecycleListener;

  StreamSubscription<InternetConnectionStatus>? _internetConnectionStreamSubscription;


  @override
  void initState() {
    super.initState();
    _internetConnectionStreamSubscription = InternetConnectionCheckerPlus().onStatusChange.listen((event) {
      logger.i(event);
      switch (event) {
        case InternetConnectionStatus.connected:
          setState(() {
            isConnectedToInternet = true;
          });
          break;
        case InternetConnectionStatus.disconnected:
          setState(() {
            isConnectedToInternet = false;
          });
          break;
        default:
          setState(() {
            isConnectedToInternet = false;
          });
          break;
      }
    });
    _lifecycleListener = AppLifecycleListener(
      onResume: _internetConnectionStreamSubscription?.resume,
      onHide: _internetConnectionStreamSubscription?.pause,
      onPause: _internetConnectionStreamSubscription?.pause,
    );
  }


  @override
  void dispose() {
    _internetConnectionStreamSubscription?.cancel();
    _lifecycleListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}