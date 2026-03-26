import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final MapController _mapController = MapController();

  // Default centre: Hyderabad (RGUKT region)
  LatLng _pickedCenter = const LatLng(17.3850, 78.4867);

  bool _isLocating = false;
  bool _isGeocoding = false;
  String _address = 'Move the map to select a location';

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _tryGetCurrentLocation();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _tryGetCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );
      final newCenter = LatLng(pos.latitude, pos.longitude);
      if (mounted) {
        setState(() => _pickedCenter = newCenter);
        _mapController.move(newCenter, 15);
        await _reverseGeocode(newCenter);
      }
    } catch (_) {
      // Keep default centre — network / permission unavailable
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _reverseGeocode(LatLng point) async {
    setState(() => _isGeocoding = true);
    try {
      final dio = Dio();
      final res = await dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'lat': point.latitude,
          'lon': point.longitude,
          'format': 'json',
        },
        options: Options(
          headers: {'User-Agent': 'DisasterClaimApp/1.0'},
          receiveTimeout: const Duration(seconds: 6),
        ),
      );
      final name = res.data['display_name'] as String? ?? '';
      setState(() {
        _address = name.isNotEmpty
            ? name
            : _coordLabel(point);
      });
    } catch (_) {
      if (mounted) setState(() => _address = _coordLabel(point));
    } finally {
      if (mounted) setState(() => _isGeocoding = false);
    }
  }

  String _coordLabel(LatLng p) =>
      '${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}';

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    if (!hasGesture) return;
    setState(() => _pickedCenter = camera.center);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), () {
      _reverseGeocode(camera.center);
    });
  }

  void _confirmLocation() {
    Navigator.of(context).pop((
      address: _address,
      latitude: _pickedCenter.latitude,
      longitude: _pickedCenter.longitude,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Pick Incident Location',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        actions: [
          TextButton(
            onPressed: (_isGeocoding || _isLocating) ? null : _confirmLocation,
            child: const Text(
              'Confirm',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Map ──────────────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _pickedCenter,
              initialZoom: 13,
              onPositionChanged: _onPositionChanged,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName:
                    'com.example.livelihood_loss_compensation',
              ),
            ],
          ),

          // ── Centre pin ───────────────────────────────────────────────────
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_pin,
                  color: Color(0xFF2E7D32),
                  size: 52,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                SizedBox(height: 24), // vertical offset so pin tip = map centre
              ],
            ),
          ),

          // ── GPS button ───────────────────────────────────────────────────
          Positioned(
            right: 16,
            bottom: 160,
            child: FloatingActionButton.small(
              heroTag: 'gps_btn',
              backgroundColor: Colors.white,
              elevation: 4,
              onPressed: _isLocating ? null : _tryGetCurrentLocation,
              child: _isLocating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF2E7D32),
                      ),
                    )
                  : const Icon(
                      Icons.my_location,
                      color: Color(0xFF2E7D32),
                    ),
            ),
          ),

          // ── Address bar & confirm button ─────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Color(0xFF2E7D32),
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _isGeocoding
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 2),
                                child: Text(
                                  'Getting address…',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                              )
                            : Text(
                                _address,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isGeocoding ? null : _confirmLocation,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text(
                        'Use This Location',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
