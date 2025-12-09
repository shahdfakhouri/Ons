import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const OnsApp());
}

class OnsApp extends StatelessWidget {
  const OnsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ons',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        fontFamily: 'Arial',
      ),
      home: const HomeScreen(),
    );
  }
}
