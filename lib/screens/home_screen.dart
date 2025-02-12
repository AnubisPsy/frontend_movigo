// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../widgets/profile_button.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('MoviGO'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ProfileButton(),
          ),
        ],
      ),
      body: Center(
        child: Text('Contenido del Home'),
      ),
    );
  }
}
