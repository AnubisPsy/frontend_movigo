import 'package:flutter/material.dart';
import 'package:movigo_frontend/widgets/trip/trip_card.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  bool _isAvailable = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MoviGO Conductor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // Navegar al historial
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Switch de disponibilidad
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                const Text(
                  'Disponible para viajes',
                  style: TextStyle(fontSize: 16),
                ),
                const Spacer(),
                Switch(
                  value: _isAvailable,
                  onChanged: (value) {
                    setState(() {
                      _isAvailable = value;
                    });
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Lista de viajes disponibles
          Expanded(
            child: _isAvailable
                ? ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: 5, // Ejemplo
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: TripCard(
                          origin: 'Origen $index',
                          destination: 'Destino $index',
                          onAccept: () {
                            // Lógica para aceptar viaje
                          },
                        ),
                      );
                    },
                  )
                : const Center(
                    child: Text(
                      'Activa tu disponibilidad para ver viajes',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
