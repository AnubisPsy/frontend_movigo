import 'package:flutter/material.dart';
import 'package:movigo_frontend/widgets/trip/trip_card.dart';
import 'package:movigo_frontend/widgets/common/custom_button.dart';

class TripHistoryScreen extends StatefulWidget {
  const TripHistoryScreen({super.key});

  @override
  State<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends State<TripHistoryScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _trips = [];

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    setState(() => _isLoading = true);
    try {
      // Aquí iría la llamada a la API
      await Future.delayed(const Duration(seconds: 1)); // Simulación
      setState(() {
        _trips = List.generate(
          10,
          (index) => {
            'id': 'TRIP-$index',
            'origin': 'Origen $index',
            'destination': 'Destino $index',
            'date': DateTime.now().subtract(Duration(days: index)),
            'driverName': 'Conductor $index',
            'vehicleInfo': 'Toyota Corolla - ABC12$index',
            'cost': 25.0 + index,
          },
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al cargar el historial'),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Viajes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilters,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTrips,
              child: _trips.isEmpty ? _buildEmptyState() : _buildTripsList(),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay viajes en tu historial',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tus viajes aparecerán aquí',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _trips.length,
      itemBuilder: (context, index) {
        final trip = _trips[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: GestureDetector(
            onTap: () => _showTripDetails(trip),
            child: TripCard(
              origin: trip['origin'],
              destination: trip['destination'],
              date: trip['date'],
              driverName: trip['driverName'],
              vehicleInfo: trip['vehicleInfo'],
              cost: trip['cost'],
              type: TripCardType.history,
            ),
          ),
        );
      },
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Filtrar por',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.date_range),
              title: const Text('Fecha'),
              onTap: () {
                // Implementar filtro por fecha
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_money),
              title: const Text('Costo'),
              onTap: () {
                // Implementar filtro por costo
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showTripDetails(Map<String, dynamic> trip) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detalles del Viaje',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TripCard(
              origin: trip['origin'],
              destination: trip['destination'],
              date: trip['date'],
              driverName: trip['driverName'],
              vehicleInfo: trip['vehicleInfo'],
              cost: trip['cost'],
              type: TripCardType.history,
            ),
            const SizedBox(height: 16),
            // Aquí podrías agregar más detalles del viaje
            const Spacer(),
            CustomButton(
              text: 'Reportar Problema',
              onPressed: () {
                // Implementar reporte de problema
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
