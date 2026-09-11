import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/user_screen.dart';
import 'services/battery_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DwnApp());
}

class DwnApp extends StatefulWidget {
  const DwnApp({super.key});

  @override
  State<DwnApp> createState() => _DwnAppState();
}

class _DwnAppState extends State<DwnApp> {
  @override
  void initState() {
    super.initState();
    _initializeForegroundService();
  }

  Future<void> _initializeForegroundService() async {
    await BatteryService.iniciarForegroundService();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Digital Wallet Notifier',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const UserScreen(),
    );
  }
}
