// lib/screens/role_handler_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:movigo/screens/conductor/home_screen.dart';
import 'package:movigo/screens/viaje/home_screen.dart'; // pantalla del pasajero

// lib/screens/role_handler_screen.dart
class RoleHandlerScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
        future: _getUserRole(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            // Rol 1: Pasajero, Rol 2: Conductor (ajusta según tus valores)
            if (snapshot.data == 2) {
              return ConductorHomeScreen();
            } else {
              return PasajeroHomeScreen();
            }
          }
          return CircularProgressIndicator();
        });
  }

  Future<int> _getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userRole') ?? 1; // 1 como valor por defecto
  }
}
