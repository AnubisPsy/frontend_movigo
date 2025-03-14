import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class MapaEnTiempoReal extends StatefulWidget {
  final bool esViajePendiente;
  final Map<String, dynamic>? tripData;

  const MapaEnTiempoReal({
    Key? key,
    this.esViajePendiente = false,
    this.tripData,
  }) : super(key: key);

  @override
  State<MapaEnTiempoReal> createState() => _MapaEnTiempoRealState();
}

class _MapaEnTiempoRealState extends State<MapaEnTiempoReal> {
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionStreamSubscription;
  final List<Marker> _markers = [];

  LatLng _currentPosition =
      LatLng(14.0723, -87.1921); // Posición por defecto (Tegucigalpa)
  final List<LatLng> _positionHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  @override
  void dispose() {
    _stopLocationUpdates();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Verificar si el servicio de ubicación está habilitado
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Verificar permisos de ubicación
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Obtener posición actual
    await _getCurrentLocation();

    // Iniciar actualizaciones de ubicación
    _startLocationUpdates();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _positionHistory.add(_currentPosition);
        _isLoading = false;
        _updateMarkers();
      });

      _mapController.move(_currentPosition, 15.0);
    } catch (e) {
      print('Error al obtener ubicación: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startLocationUpdates() {
    // Cancelar suscripción existente si hay alguna
    _stopLocationUpdates();

    // Configurar opciones de localización
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Actualizar cada 10 metros de movimiento
    );

    // Suscribirse a actualizaciones de posición
    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position position) {
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _positionHistory.add(_currentPosition);
        _updateMarkers();
      });

      _mapController.move(_currentPosition, 15.0);
    });
  }

  void _stopLocationUpdates() {
    if (_positionStreamSubscription != null) {
      _positionStreamSubscription!.cancel();
      _positionStreamSubscription = null;
    }
  }

  void _updateMarkers() {
    _markers.clear();

    // Marcador de posición actual
    _markers.add(
      Marker(
        width: 40.0,
        height: 40.0,
        point: _currentPosition,
        builder: (ctx) => const Icon(
          Icons.location_on,
          color: Colors.blue,
          size: 40.0,
        ),
      ),
    );

    // Si es un viaje pendiente, agregar marcadores de origen y destino
    if (widget.esViajePendiente && widget.tripData != null) {
      // Para pruebas, usamos posiciones relativas a la posición actual
      final LatLng origen =
          LatLng(_currentPosition.latitude - 0.005, _currentPosition.longitude);

      final LatLng destino =
          LatLng(_currentPosition.latitude + 0.005, _currentPosition.longitude);

      _markers.add(
        Marker(
          width: 40.0,
          height: 40.0,
          point: origen,
          builder: (ctx) => const Icon(
            Icons.location_on,
            color: Colors.green,
            size: 40.0,
          ),
        ),
      );

      _markers.add(
        Marker(
          width: 40.0,
          height: 40.0,
          point: destino,
          builder: (ctx) => const Icon(
            Icons.location_on,
            color: Colors.red,
            size: 40.0,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        center: _currentPosition,
        zoom: 15.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.movigo.app',
        ),
        MarkerLayer(markers: _markers),
        if (_positionHistory.length > 1)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _positionHistory,
                strokeWidth: 4.0,
                color: Colors.blue,
              ),
            ],
          ),
      ],
    );
  }
}
