import 'package:flutter/material.dart';
import 'package:movigo_frontend/widgets/trip/trip_card.dart';
import 'package:movigo_frontend/widgets/common/custom_button.dart';
import 'package:movigo_frontend/core/navigation/route_helper.dart';
import 'package:movigo_frontend/data/services/trips_service.dart';

class TripHistoryScreen extends StatefulWidget {
  const TripHistoryScreen({super.key});

  @override
  State<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends State<TripHistoryScreen> {
  final TripsService _tripsService = TripsService();

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
      // Llamada al backend usando nuestro servicio
      final loadedTrips = await _tripsService.getTripHistory(
        startDate: _startDate,
        endDate: _endDate,
        minCost: _minCost,
        maxCost: _maxCost,
      );

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
        final tripDate = trip['date'] as DateTime;

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
        final cost = trip['cost'] as double;

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
            onPressed: () => RouteHelper.goToPassengerHome(context)),
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
                                  : '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'),
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
                                  : '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'),
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

                // Filtro por costo
                ExpansionTile(
                  leading: const Icon(Icons.attach_money),
                  title: const Text('Rango de costo'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                labelText: 'Costo mínimo',
                                prefix: Text('\$'),
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
                                labelText: 'Costo máximo',
                                prefix: Text('\$'),
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
                        child: const Text('Limpiar costos'),
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
