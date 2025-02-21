import 'package:flutter/material.dart';
import 'package:movigo_frontend/widgets/trip/trip_card.dart';
import 'package:movigo_frontend/widgets/common/custom_button.dart';

class DriverTripHistoryScreen extends StatefulWidget {
  const DriverTripHistoryScreen({super.key});

  @override
  State<DriverTripHistoryScreen> createState() =>
      _DriverTripHistoryScreenState();
}

class _DriverTripHistoryScreenState extends State<DriverTripHistoryScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _trips = [];
  String _selectedPeriod = 'today';
  double _totalEarnings = 0.0;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    setState(() => _isLoading = true);
    try {
      // Simulación de carga de datos
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _trips = List.generate(
          10,
          (index) => {
            'id': 'TRIP-$index',
            'origin': 'Origen $index',
            'destination': 'Destino $index',
            'date': DateTime.now().subtract(Duration(days: index)),
            'passengerName': 'Pasajero $index',
            'earnings': 25.0 + index,
            'rating': 4.5,
          },
        );
        _totalEarnings =
            _trips.fold(0.0, (sum, trip) => sum + (trip['earnings'] as double));
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cargar el historial')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
      body: Column(
        children: [
          // Panel de ganancias
          _buildEarningsPanel(),

          // Selector de período
          _buildPeriodSelector(),

          // Lista de viajes
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _trips.isEmpty
                    ? _buildEmptyState()
                    : _buildTripsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue,
      child: Column(
        children: [
          const Text(
            'Ganancias Totales',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${_totalEarnings.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          _buildPeriodChip('Hoy', 'today'),
          _buildPeriodChip('Esta semana', 'week'),
          _buildPeriodChip('Este mes', 'month'),
          _buildPeriodChip('Este año', 'year'),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String label, String value) {
    final isSelected = _selectedPeriod == value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() => _selectedPeriod = value);
            _loadTrips(); // Recargar viajes con el nuevo período
          }
        },
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
            'Los viajes que realices aparecerán aquí',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripsList() {
    return RefreshIndicator(
      onRefresh: _loadTrips,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _trips.length,
        itemBuilder: (context, index) {
          final trip = _trips[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: GestureDetector(
              onTap: () => _showTripDetails(trip),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDate(trip['date']),
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '\$${trip['earnings'].toStringAsFixed(2)}',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildLocationInfo(
                        icon: Icons.location_on,
                        label: 'Origen:',
                        location: trip['origin'],
                      ),
                      const SizedBox(height: 8),
                      _buildLocationInfo(
                        icon: Icons.location_searching,
                        label: 'Destino:',
                        location: trip['destination'],
                      ),
                      const Divider(height: 24),
                      Row(
                        children: [
                          Icon(Icons.person, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(trip['passengerName']),
                          const Spacer(),
                          Icon(Icons.star, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(trip['rating'].toString()),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLocationInfo({
    required IconData icon,
    required String label,
    required String location,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                location,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
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
                Navigator.pop(context);
                // Implementar filtro por fecha
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_money),
              title: const Text('Ganancias'),
              onTap: () {
                Navigator.pop(context);
                // Implementar filtro por ganancias
              },
            ),
            ListTile(
              leading: const Icon(Icons.star),
              title: const Text('Calificación'),
              onTap: () {
                Navigator.pop(context);
                // Implementar filtro por calificación
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
            // Aquí irían más detalles del viaje
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
