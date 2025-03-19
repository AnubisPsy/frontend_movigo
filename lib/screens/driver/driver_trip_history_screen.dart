import 'package:flutter/material.dart';
import 'package:movigo_frontend/widgets/common/custom_button.dart';
import 'package:movigo_frontend/core/navigation/route_helper.dart';
import 'package:movigo_frontend/data/services/driver_service.dart';
import 'package:intl/intl.dart';

class DriverTripHistoryScreen extends StatefulWidget {
  const DriverTripHistoryScreen({super.key});

  @override
  State<DriverTripHistoryScreen> createState() =>
      _DriverTripHistoryScreenState();
}

class _DriverTripHistoryScreenState extends State<DriverTripHistoryScreen> {
  final DriverService _driverService = DriverService();

  bool _isLoading = false;
  List<Map<String, dynamic>> _allTrips = []; // Lista original sin filtrar
  List<Map<String, dynamic>> _trips = []; // Lista filtrada para mostrar

  // Variables para filtros
  DateTime? _startDate;
  DateTime? _endDate;
  double? _minCost;
  double? _maxCost;
  bool _filtersApplied = false;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    setState(() => _isLoading = true);
    try {
      // Llamada al backend usando nuestro servicio de conductor
      final loadedTrips = await _driverService.getTripHistory();

      setState(() {
        _allTrips = loadedTrips;
        _trips = loadedTrips;
        _filtersApplied = _startDate != null ||
            _endDate != null ||
            _minCost != null ||
            _maxCost != null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar el historial: ${e.toString()}'),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Aplicar filtros a la lista original
  void _applyFilters() {
    setState(() {
      _trips = _allTrips.where((trip) {
        // Filtrar por fecha
        bool dateFilter = true;
        final tripDate = DateTime.parse(
            trip['fecha_creacion'] ?? DateTime.now().toIso8601String());

        if (_startDate != null) {
          dateFilter = dateFilter &&
              tripDate.isAfter(_startDate!.subtract(const Duration(days: 1)));
        }

        if (_endDate != null) {
          dateFilter = dateFilter &&
              tripDate.isBefore(_endDate!.add(const Duration(days: 1)));
        }

        // Filtrar por costo
        bool costFilter = true;
        final cost = trip['tarifa'] as double? ?? 0.0;

        if (_minCost != null) {
          costFilter = costFilter && cost >= _minCost!;
        }

        if (_maxCost != null) {
          costFilter = costFilter && cost <= _maxCost!;
        }

        return dateFilter && costFilter;
      }).toList();

      _filtersApplied = _startDate != null ||
          _endDate != null ||
          _minCost != null ||
          _maxCost != null;
    });
  }

  // Resetear todos los filtros
  void _resetFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _minCost = null;
      _maxCost = null;
      _filtersApplied = false;
      _trips = _allTrips;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => RouteHelper.goToDriverHome(context)),
        title: const Text('Historial de Viajes'),
        actions: [
          if (_filtersApplied)
            IconButton(
              icon: const Icon(Icons.filter_alt_off),
              onPressed: () {
                _resetFilters();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Filtros eliminados')),
                );
              },
            ),
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
            _filtersApplied
                ? 'No hay viajes que coincidan con los filtros'
                : 'No hay viajes en tu historial',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _filtersApplied
                ? 'Intenta con otros filtros'
                : 'Tus viajes aparecerán aquí',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
          if (_filtersApplied)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: ElevatedButton(
                onPressed: _resetFilters,
                child: const Text('Quitar filtros'),
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
        // Formatear la fecha
        final tripDate = DateTime.parse(
            trip['fecha_creacion'] ?? DateTime.now().toIso8601String());

        // Obtener el estado del viaje
        String statusText = 'Desconocido';
        Color statusColor = Colors.grey;

        switch (trip['estado']) {
          case 1:
            statusText = 'PENDIENTE';
            statusColor = Colors.orange;
            break;
          case 2:
            statusText = 'ACEPTADO';
            statusColor = Colors.blue;
            break;
          case 3:
            statusText = 'EN CURSO';
            statusColor = Colors.amber;
            break;
          case 4:
            statusText = 'COMPLETADO';
            statusColor = Colors.green;
            break;
          case 5:
            statusText = 'CANCELADO';
            statusColor = Colors.red;
            break;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => _showTripDetails(trip),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          statusText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        DateFormat('dd/MM/yyyy').format(tripDate),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          trip['origen'] ?? 'Origen no disponible',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_searching, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          trip['destino'] ?? 'Destino no disponible',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.person),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          trip['pasajero'] ?? 'Pasajero',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      Text(
                        'L. ${(trip['tarifa'] ?? 0.0).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(16),
            height: MediaQuery.of(context).size.height * 0.6,
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

                // Filtro por fecha
                ExpansionTile(
                  leading: const Icon(Icons.date_range),
                  title: const Text('Rango de fechas'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () async {
                                final selected = await showDatePicker(
                                  context: context,
                                  initialDate: _startDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (selected != null) {
                                  setModalState(() {
                                    _startDate = selected;
                                  });
                                }
                              },
                              child: Text(_startDate == null
                                  ? 'Fecha inicio'
                                  : DateFormat('dd/MM/yyyy')
                                      .format(_startDate!)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextButton(
                              onPressed: () async {
                                final selected = await showDatePicker(
                                  context: context,
                                  initialDate: _endDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (selected != null) {
                                  setModalState(() {
                                    _endDate = selected;
                                  });
                                }
                              },
                              child: Text(_endDate == null
                                  ? 'Fecha fin'
                                  : DateFormat('dd/MM/yyyy').format(_endDate!)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_startDate != null || _endDate != null)
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _startDate = null;
                            _endDate = null;
                          });
                        },
                        child: const Text('Limpiar fechas'),
                      ),
                  ],
                ),

                // Filtro por tarifa
                ExpansionTile(
                  leading: const Icon(Icons.attach_money),
                  title: const Text('Rango de tarifa'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                labelText: 'Tarifa mínima',
                                prefix: Text('L. '),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                if (value.isNotEmpty) {
                                  setModalState(() {
                                    _minCost = double.tryParse(value);
                                  });
                                } else {
                                  setModalState(() {
                                    _minCost = null;
                                  });
                                }
                              },
                              controller: TextEditingController(
                                text: _minCost?.toString() ?? '',
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                labelText: 'Tarifa máxima',
                                prefix: Text('L. '),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                if (value.isNotEmpty) {
                                  setModalState(() {
                                    _maxCost = double.tryParse(value);
                                  });
                                } else {
                                  setModalState(() {
                                    _maxCost = null;
                                  });
                                }
                              },
                              controller: TextEditingController(
                                text: _maxCost?.toString() ?? '',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_minCost != null || _maxCost != null)
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _minCost = null;
                            _maxCost = null;
                          });
                        },
                        child: const Text('Limpiar tarifas'),
                      ),
                  ],
                ),

                const Spacer(),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _applyFilters();
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(_trips.isEmpty
                                  ? 'No hay resultados con los filtros seleccionados'
                                  : 'Filtros aplicados: ${_trips.length} viajes encontrados'),
                            ),
                          );
                        },
                        child: const Text('Aplicar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showTripDetails(Map<String, dynamic> trip) {
    // Extraer datos importantes
    final origen = trip['origen'] ?? 'No disponible';
    final destino = trip['destino'] ?? 'No disponible';
    final fecha =
        trip['fecha'] != null ? DateTime.parse(trip['fecha']) : DateTime.now();

    // Extraer hora_inicio y hora_fin si existen
    final horaInicio = trip['hora_inicio'] ?? 'No disponible';
    final horaFin = trip['hora_fin'] ?? 'No disponible';

    // Manejo seguro del costo
    final costo = trip['costo'] ?? 0.0;
    final costoNumerico = costo is String
        ? double.tryParse(costo) ?? 0.0
        : (costo is num ? costo : 0.0);

    // Información del pasajero
    final pasajeroNombre = trip['pasajero'] ?? 'No disponible';

    // Estado del viaje
    final estadoId = trip['estado_id'] ?? 0;
    final estadoTexto = trip['estado'] ?? 'Desconocido';

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

            // Wrap most of the content in Expanded + SingleChildScrollView
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Estado del viaje
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(estadoId),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        estadoTexto,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Detalles principales
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailRow('Fecha:',
                                DateFormat('dd/MM/yyyy').format(fecha)),
                            const Divider(),
                            _buildDetailRow('Hora inicio:', horaInicio),
                            const Divider(),
                            _buildDetailRow('Hora fin:', horaFin),
                            const Divider(),
                            _buildDetailRow('Origen:', origen),
                            const Divider(),
                            _buildDetailRow('Destino:', destino),
                            const Divider(),
                            _buildDetailRow('Costo:',
                                'L. ${costoNumerico.toStringAsFixed(2)}'),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Información del pasajero
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pasajero',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildDetailRow('Nombre:', pasajeroNombre),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Button at the bottom
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  }

// Método para determinar el color del estado
  Color _getStatusColor(int status) {
    switch (status) {
      case 1:
        return Colors.orange; // PENDIENTE
      case 2:
        return Colors.blue; // ACEPTADO
      case 3:
        return Colors.amber; // EN CURSO
      case 4:
        return Colors.green; // COMPLETADO
      case 5:
        return Colors.red; // CANCELADO
      default:
        return Colors.grey; // Desconocido
    }
  }

// Método auxiliar para construir filas de detalles
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
