import 'package:flutter/material.dart';

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

  static void goToDriverInfo(BuildContext context) {
    Navigator.pushNamed(context, '/driver/info');
  }

  static void goToVehicleInfo(BuildContext context) {
    Navigator.pushNamed(context, '/driver/vehicle-info');
  }

  static void goToDriverActiveTrip(BuildContext context) {
    Navigator.pushNamed(context, '/driver/active-trip');
  }

  static void goToDriverHistory(BuildContext context) {
    Navigator.pushNamed(context, '/driver/history');
  }

  // Utilidades de navegación
  static void goBack(BuildContext context) {
    Navigator.pop(context);
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
}
