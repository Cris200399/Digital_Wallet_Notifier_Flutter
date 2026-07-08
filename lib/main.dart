import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/user_screen.dart';

void main() {
  runApp(const DwnApp());
}

class DwnApp extends StatelessWidget {
  const DwnApp({super.key});

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
