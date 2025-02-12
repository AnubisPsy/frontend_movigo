// lib/widgets/profile_button.dart
import 'package:flutter/material.dart';
import '../screens/profile_settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileButton extends StatefulWidget {
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

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProfileSettingsScreen()),
        );
      },
      icon: Icon(Icons.person),
      label: Text(userName ?? 'Usuario'),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.blue.shade700,
      ),
    );
  }
}
