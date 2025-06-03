import 'package:flutter/material.dart';
import 'package:movigo_frontend/utils/colors.dart';
import 'package:movigo_frontend/utils/constants.dart';
import 'package:movigo_frontend/widgets/movigo_button.dart';
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar el historial: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
        backgroundColor: movigoPrimaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => RouteHelper.goToDriverHome(context),
        ),
        title: const Text(
          'Historial de Viajes',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          if (_filtersApplied)
            IconButton(
              icon: const Icon(Icons.filter_alt_off, color: Colors.white),
              onPressed: () {
                _resetFilters();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Filtros eliminados'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: _showFilters,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: movigoPrimaryColor,
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadTrips,
              color: movigoPrimaryColor,
              child: _trips.isEmpty ? _buildEmptyState() : _buildTripsList(),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.history,
              size: 50,
              color: movigoGreyColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _filtersApplied
                ? 'No hay viajes que coincidan con los filtros'
                : 'No hay viajes en tu historial',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: movigoDarkColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _filtersApplied
                ? 'Intenta con otros filtros'
                : 'Tus viajes completados aparecerán aquí',
            style: const TextStyle(
              fontSize: 16,
              color: movigoGreyColor,
            ),
          ),
          if (_filtersApplied)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: MovigoButton(
                text: 'Quitar filtros',
                onPressed: _resetFilters,
                color: movigoSecondaryColor,
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
            statusColor = movigoSecondaryColor;
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
            borderRadius: BorderRadius.circular(movigoButtonRadius),
          ),
          child: InkWell(
            onTap: () => _showTripDetails(trip),
            borderRadius: BorderRadius.circular(movigoButtonRadius),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius:
                              BorderRadius.circular(movigoButtonRadius),
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
                        style: const TextStyle(
                          color: movigoGreyColor,
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
                          style: const TextStyle(
                            fontSize: 16,
                            color: movigoDarkColor,
                          ),
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
                          style: const TextStyle(
                            fontSize: 16,
                            color: movigoDarkColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.person_outline, color: movigoGreyColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          trip['pasajero'] ?? 'Pasajero',
                          style: const TextStyle(
                            fontSize: 14,
                            color: movigoGreyColor,
                          ),
                        ),
                      ),
                      Text(
                        'L. ${(trip['tarifa'] ?? 0.0).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: movigoPrimaryColor,
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(movigoBottomSheetRadius),
        ),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: ListView(
                shrinkWrap: true,
                children: [
                  const Text(
                    'Filtrar viajes',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: movigoDarkColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Filtro por fecha
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(movigoButtonRadius),
                      border: Border.all(color: movigoBorderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.date_range, color: movigoPrimaryColor),
                            SizedBox(width: 8),
                            Text(
                              'Rango de fechas',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: movigoDarkColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () async {
                                  final selected = await showDatePicker(
                                    context: context,
                                    initialDate: _startDate ?? DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now(),
                                    builder: (context, child) {
                                      return Theme(
                                        data: Theme.of(context).copyWith(
                                          colorScheme: const ColorScheme.light(
                                            primary: movigoPrimaryColor,
                                            onPrimary: Colors.white,
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (selected != null) {
                                    setModalState(() {
                                      _startDate = selected;
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    border:
                                        Border.all(color: movigoBorderColor),
                                    borderRadius: BorderRadius.circular(
                                        movigoButtonRadius),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _startDate == null
                                            ? 'Fecha inicio'
                                            : DateFormat('dd/MM/yyyy')
                                                .format(_startDate!),
                                        style: TextStyle(
                                          color: _startDate == null
                                              ? movigoGreyColor
                                              : movigoDarkColor,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.calendar_today_outlined,
                                        size: 18,
                                        color: movigoGreyColor,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: GestureDetector(
                                onTap: () async {
                                  final selected = await showDatePicker(
                                    context: context,
                                    initialDate: _endDate ?? DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now(),
                                    builder: (context, child) {
                                      return Theme(
                                        data: Theme.of(context).copyWith(
                                          colorScheme: const ColorScheme.light(
                                            primary: movigoPrimaryColor,
                                            onPrimary: Colors.white,
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (selected != null) {
                                    setModalState(() {
                                      _endDate = selected;
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    border:
                                        Border.all(color: movigoBorderColor),
                                    borderRadius: BorderRadius.circular(
                                        movigoButtonRadius),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _endDate == null
                                            ? 'Fecha fin'
                                            : DateFormat('dd/MM/yyyy')
                                                .format(_endDate!),
                                        style: TextStyle(
                                          color: _endDate == null
                                              ? movigoGreyColor
                                              : movigoDarkColor,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.calendar_today_outlined,
                                        size: 18,
                                        color: movigoGreyColor,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_startDate != null || _endDate != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: TextButton.icon(
                              onPressed: () {
                                setModalState(() {
                                  _startDate = null;
                                  _endDate = null;
                                });
                              },
                              icon: const Icon(Icons.clear,
                                  color: movigoPrimaryColor, size: 18),
                              label: const Text(
                                'Limpiar fechas',
                                style: TextStyle(
                                  color: movigoPrimaryColor,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                alignment: Alignment.centerLeft,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Filtro por tarifa
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(movigoButtonRadius),
                      border: Border.all(color: movigoBorderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.attach_money, color: movigoPrimaryColor),
                            SizedBox(width: 8),
                            Text(
                              'Rango de tarifa',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: movigoDarkColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: _minCost?.toString() ?? '',
                                decoration: InputDecoration(
                                  labelText: 'Tarifa mínima',
                                  labelStyle: const TextStyle(color: movigoGreyColor),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 16,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide:
                                        const BorderSide(color: movigoBorderColor),
                                    borderRadius: BorderRadius.circular(
                                        movigoButtonRadius),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide:
                                        const BorderSide(color: movigoPrimaryColor),
                                    borderRadius: BorderRadius.circular(
                                        movigoButtonRadius),
                                  ),
                                  prefixText: 'L. ',
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  setModalState(() {
                                    _minCost = value.isNotEmpty
                                        ? double.tryParse(value)
                                        : null;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                initialValue: _maxCost?.toString() ?? '',
                                decoration: InputDecoration(
                                  labelText: 'Tarifa máxima',
                                  labelStyle: const TextStyle(color: movigoGreyColor),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 16,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide:
                                        const BorderSide(color: movigoBorderColor),
                                    borderRadius: BorderRadius.circular(
                                        movigoButtonRadius),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide:
                                        const BorderSide(color: movigoPrimaryColor),
                                    borderRadius: BorderRadius.circular(
                                        movigoButtonRadius),
                                  ),
                                  prefixText: 'L. ',
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  setModalState(() {
                                    _maxCost = value.isNotEmpty
                                        ? double.tryParse(value)
                                        : null;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        if (_minCost != null || _maxCost != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: TextButton.icon(
                              onPressed: () {
                                setModalState(() {
                                  _minCost = null;
                                  _maxCost = null;
                                });
                              },
                              icon: const Icon(Icons.clear,
                                  color: movigoPrimaryColor, size: 18),
                              label: const Text(
                                'Limpiar tarifas',
                                style: TextStyle(
                                  color: movigoPrimaryColor,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                alignment: Alignment.centerLeft,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Botones de acción
                  MovigoButton(
                    text: 'Aplicar Filtros',
                    onPressed: () {
                      _applyFilters();
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_trips.isEmpty
                              ? 'No hay resultados con los filtros seleccionados'
                              : 'Filtros aplicados: ${_trips.length} viajes encontrados'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          color: movigoPrimaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showTripDetails(Map<String, dynamic> trip) {
    print("Datos completos del viaje: $trip");
    print("Formato de la fecha recibida: ${trip['fecha']}");
    // Extraer datos importantes
    final origen = trip['origen'] ?? 'No disponible';
    final destino = trip['destino'] ?? 'No disponible';

    DateTime fecha = DateTime.now(); // Quitar 'final' para poder modificarla

    try {
      if (trip['fecha'] != null) {
        if (trip['fecha'] is String) {
          fecha = DateTime.parse(trip['fecha']);
        } else if (trip['fecha'] is DateTime) {
          fecha = trip['fecha'];
        }
      }
    } catch (e) {
      print('Error al analizar fecha: $e');
    }

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

    // Determinar el color según el estado
    Color statusColor = _getStatusColor(estadoId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(movigoBottomSheetRadius),
        ),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Detalles del Viaje',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: movigoDarkColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Estado del viaje
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(movigoButtonRadius),
                  border: Border.all(color: statusColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      estadoId == 4 ? Icons.check_circle : Icons.info_outline,
                      color: statusColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      estadoTexto,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Detalles principales
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(movigoButtonRadius),
                  border: Border.all(color: movigoBorderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(
                        'Fecha:',
                        DateFormat('dd/MM/yyyy').format(fecha),
                        Icons.calendar_today),
                    const Divider(height: 24),
                    _buildDetailRow(
                        'Hora inicio:', horaInicio, Icons.access_time),
                    const Divider(height: 24),
                    _buildDetailRow(
                        'Hora fin:', horaFin, Icons.access_time_filled),
                    const Divider(height: 24),
                    _buildDetailRow('Origen:', origen, Icons.location_on),
                    const Divider(height: 24),
                    _buildDetailRow(
                        'Destino:', destino, Icons.location_searching),
                    const Divider(height: 24),
                    _buildDetailRow(
                        'Costo:',
                        'L. ${costoNumerico.toStringAsFixed(2)}',
                        Icons.attach_money),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Información del pasajero
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(movigoButtonRadius),
                  border: Border.all(color: movigoBorderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Datos del Pasajero',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: movigoDarkColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow('Nombre:', pasajeroNombre, Icons.person),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Botón de cerrar
              MovigoButton(
                text: 'Cerrar',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
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
        return movigoSecondaryColor; // EN CURSO
      case 4:
        return Colors.green; // COMPLETADO
      case 5:
        return Colors.red; // CANCELADO
      default:
        return movigoGreyColor; // Desconocido
    }
  }

  // Método auxiliar para construir filas de detalles
  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: movigoPrimaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            color: movigoPrimaryColor,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: movigoGreyColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: movigoDarkColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
