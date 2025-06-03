import 'package:flutter/material.dart';
import 'package:movigo_frontend/screens/auth/login_screen.dart';
import 'package:movigo_frontend/screens/auth/register_screen.dart';
import 'package:movigo_frontend/screens/auth/forgot_password_screen.dart';
import 'package:movigo_frontend/screens/auth/verify_code_screen.dart';
import 'package:movigo_frontend/screens/auth/reset_password_screen.dart';
import 'package:movigo_frontend/screens/common/trip_completed_screen.dart';

// Pantallas de pasajero
import 'package:movigo_frontend/screens/passenger/passenger_home_screen.dart';
import 'package:movigo_frontend/screens/passenger/passenger_history_screen.dart';
import 'package:movigo_frontend/screens/passenger/trip_price_screen.dart';

// Pantallas de conductor
import 'package:movigo_frontend/screens/driver/vehicle_info_screen.dart';
import 'package:movigo_frontend/screens/driver/driver_trip_history_screen.dart';
import 'package:movigo_frontend/screens/driver/driver_home_screen.dart';
import 'package:movigo_frontend/screens/driver/driver_active_trip_screen.dart';
import 'package:movigo_frontend/screens/driver/driver_negotiation_screen.dart';

//Pantallas del perfil
import 'package:movigo_frontend/screens/profile/change_password_screen.dart';
import 'package:movigo_frontend/screens/profile/edit_profile_screen.dart';
import 'package:movigo_frontend/screens/profile/profile_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MoviGO',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
        ),
      ),
      initialRoute: '/login',
      routes: {
        // Rutas de autenticación
        '/login': (context) => const MovigoLoginScreen(),
        '/register': (context) => const MovigoRegisterScreen(),
        '/forgot-password': (context) => const MovigoForgotPasswordScreen(),
        '/verify-code': (context) => const MovigoVerifyCodeScreen(),
        '/reset-password': (context) => const MovigoResetPasswordScreen(),

        //Rutas del perfil
        '/profile': (context) => const ProfileScreen(),
        '/profile/edit': (context) => const EditProfileScreen(),
        '/profile/change-password': (context) => const ChangePasswordScreen(),

        //Rutas en común
        '/trip-completed': (context) => const MovigoTripCompletedScreen(
              tripData: {}, // Esto se pasa como argumento al navegar
              isConductor: false, // Esto también
            ),

        // Rutas de pasajero
        '/passenger/home': (context) => const PassengerHomeScreen(),
        '/passenger/history': (context) => const TripHistoryScreen(),
        '/passenger/trip-price': (context) => const TripPriceScreen(),

        /// Rutas de conductor
        '/driver/vehicle-info': (context) => const VehicleInfoScreen(),
        '/driver/home': (context) => const DriverHomeScreen(),
        '/driver/history': (context) => const DriverTripHistoryScreen(),
        '/driver/active-trip': (context) =>
            const MovigoDriverActiveTripScreen(),
        '/driver/negotiation': (context) => const DriverNegotiationScreen(),
      },
      // Manejo de rutas no definidas
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: const Text('Error'),
            ),
            body: const Center(
              child: Text('Ruta no encontrada'),
            ),
          ),
        );
      },
    );
  }
}
