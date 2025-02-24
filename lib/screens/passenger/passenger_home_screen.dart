import 'package:flutter/material.dart';
import 'package:movigo_frontend/widgets/common/custom_button.dart';
import 'package:movigo_frontend/core/navigation/route_helper.dart';

class PassengerHomeScreen extends StatefulWidget {
  const PassengerHomeScreen({super.key});

  @override
  State<PassengerHomeScreen> createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MoviGO'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              RouteHelper.goToPassengerHistory(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => RouteHelper.goToProfile(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Aquí irá el mapa
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('Mapa aquí'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Panel inferior
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.location_on),
                      hintText: '¿Dónde estás?',
                      border: OutlineInputBorder(),
                    ),
                    onTap: () {
                      // Mostrar búsqueda de origen
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.location_searching),
                      hintText: '¿A dónde vas?',
                      border: OutlineInputBorder(),
                    ),
                    onTap: () {
                      // Mostrar búsqueda de destino
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    text: 'Solicitar Viaje',
                    onPressed: () {
                      // Navegar a la pantalla de solicitud de viaje
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
