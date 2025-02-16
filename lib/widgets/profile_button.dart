import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/conductor/profile_conductor_screen.dart'; // Asegúrate de que la ruta sea correcta
import '../screens/profile_settings_screen.dart';

class ProfileButton extends StatefulWidget {
  const ProfileButton({Key? key}) : super(key: key);

  @override
  _ProfileButtonState createState() => _ProfileButtonState();
}

class _ProfileButtonState extends State<ProfileButton> {
  String? userName;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('userName') ?? 'Usuario';
    });
  }

// En profile_button.dart
  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () async {
        final prefs = await SharedPreferences.getInstance();
        final rol = prefs.getInt('userRole');

        if (!mounted) return;

        if (rol == 2) {
          // Para conductores
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileConductorScreen(),
            ),
          ).then((_) => _loadUserName());
        } else {
          // Para pasajeros
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileSettingsScreen(),
            ),
          ).then((_) => _loadUserName());
        }
      },
      icon: const Icon(Icons.person),
      label: Text(userName ?? 'Usuario'),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.blue.shade700,
      ),
    );
  }
}
