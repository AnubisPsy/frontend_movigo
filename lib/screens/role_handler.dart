// lib/screens/role_handler.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'conductor/conductor.home_screen.dart';
import '../screens/home_screen.dart';
import 'conductor/conductor.home_screen.dart';

class RoleHandler extends StatefulWidget {
  const RoleHandler({Key? key}) : super(key: key); // Añadir const aquí

  @override
  State<RoleHandler> createState() => _RoleHandlerState();
}

class _RoleHandlerState extends State<RoleHandler> {
  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  Future<void> _checkRole() async {
    final prefs = await SharedPreferences.getInstance();
    final userRole = prefs.getInt('userRole');

    if (!mounted) return;

    debugPrint('Rol del usuario: $userRole');

    if (userRole == 2) {
      // Conductor
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ConductorHomeScreen()),
      );
    } else {
      // Pasajero o valor por defecto
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
