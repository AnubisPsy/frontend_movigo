import 'package:flutter/material.dart';
import 'package:movigo_frontend/data/services/storage_service.dart';

class RouteHelper {
  // Rutas de Autenticación
  static void goToLogin(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (route) => false,
    );
  }

  static void goToRegister(BuildContext context) {
    Navigator.pushNamed(context, '/register');
  }

  static void goToForgotPassword(BuildContext context) {
    Navigator.pushNamed(context, '/forgot-password');
  }

  static void goToVerifyCode(
      BuildContext context, Map<String, dynamic> arguments) {
    Navigator.pushNamed(
      context,
      '/verify-code',
      arguments: arguments,
    );
  }

  static void goToDriverInfo(BuildContext context) {
    Navigator.pushNamed(context, '/driver/info');
  }

  static void goToVehicleInfo(BuildContext context) {
    Navigator.pushNamed(context, '/driver/vehicle-info');
  }

  static void goToDriverHistory(BuildContext context) {
    Navigator.pushNamed(context, '/driver/history');
  }

  static void goToResetPassword(
      BuildContext context, Map<String, dynamic> arguments) {
    Navigator.pushNamed(
      context,
      '/reset-password',
      arguments: arguments,
    );
  }

  // Rutas de Perfil
  static void goToProfile(BuildContext context) {
    Navigator.pushNamed(context, '/profile');
  }

  static Future<void> goToEditProfile(
      BuildContext context, Map<String, dynamic> userData) {
    return Navigator.pushNamed(
      context,
      '/profile/edit',
      arguments: userData,
    );
  }

  static void goToChangePassword(BuildContext context) {
    Navigator.pushNamed(context, '/profile/change-password');
  }

  // Rutas de Pasajero
  static void goToPassengerHome(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/passenger/home',
      (route) => false,
    );
  }

  static void goToRequestTrip(
    BuildContext context, {
    required String origin,
    required String destination,
  }) {
    Navigator.pushNamed(
      context,
      '/passenger/request-trip',
      arguments: {
        'origin': origin,
        'destination': destination,
      },
    );
  }

  static void goToPassengerActiveTrip(BuildContext context) {
    Navigator.pushNamed(context, '/passenger/active-trip');
  }

  static void goToPassengerHistory(BuildContext context) {
    Navigator.pushNamed(context, '/passenger/history');
  }

  // Rutas de Conductor
  static void goToDriverHome(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/driver/home',
      (route) => false,
    );
  }

  // Utilidades de navegación
  static Future<void> goBack(BuildContext context) async {
    // Si estamos en la pantalla de perfil, verificar el rol antes de volver
    if (ModalRoute.of(context)?.settings.name == '/profile') {
      final userData = await StorageService.getUser();
      final userRole =
          userData?['rol'] ?? '1'; // Default a pasajero si no hay rol

      if (userRole == '1') {
        goToPassengerHome(context);
      } else {
        goToDriverHome(context);
      }
    } else {
      // Comportamiento normal para otras pantallas
      Navigator.pop(context);
    }
  }

  static void closeDialog(BuildContext context) {
    Navigator.pop(context);
  }

  static void goToHomeBasedOnRole(BuildContext context, String role) {
    if (role == '1') {
      goToPassengerHome(context);
    } else {
      goToDriverHome(context);
    }
  }

// En route_helper.dart
  static void goToDriverActiveTrip(BuildContext context,
      {Map<String, dynamic>? arguments}) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/driver/active-trip',
      (route) => false,
      arguments: arguments,
    );
  }

  
}
