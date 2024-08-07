import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LocationMap(),
    );
  }
}

class LocationMap extends StatefulWidget {
  @override
  _LocationMapState createState() => _LocationMapState();
}

class _LocationMapState extends State<LocationMap> {
  LatLng _currentLocation = const LatLng(-6.597146, 106.806039);
  LatLng? _masterLocation;
  LatLng? _attendLocation;
  bool _isLoading = false;
  String _locationText = "Data Lokasi Kosong";
  final MapController _mapController = MapController();
  final double _currentZoom = 12.2;

  Future<void> _getCurrentLocation() async {
    LocationPermission permission;

    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return;
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
      _locationText = "(${_currentLocation.latitude}, ${_currentLocation.longitude})";
      _mapController.move(_currentLocation, 17.0);
    });
  }

  Future<void> _saveMasterLocation() async {
    await _getCurrentLocation();
    setState(() {
      _masterLocation = _currentLocation;
      _locationText = "(${_masterLocation!.latitude}, ${_masterLocation!.longitude})";
    });
  }

  Future<void> _checkProximity() async {
    if (_masterLocation == null) {
      _showAlert('Error', 'Data lokasi master belum ada.', Colors.red);
      return;
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    double distance = Geolocator.distanceBetween(
      _masterLocation!.latitude,
      _masterLocation!.longitude,
      position.latitude,
      position.longitude,
    );

    if (distance <= 50) {
      _showAlert('Absen Berhasil', 'Anda berada dalam radius 50 meter.', Colors.green);
    } else {
      _showAlert('Absen Gagal', 'Anda berada di luar radius 50 meter.', Colors.red);
    }
  }

  Future<void> _handleCreate() async {
    setState(() {
      _isLoading = true;
    });
    await _saveMasterLocation();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _handleAttend() async {
    if (_masterLocation == null) {
      _showAlert('Error', 'Data lokasi master belum ada.', Colors.red);
      return;
    }

    await _getCurrentLocation();
    setState(() {
      _attendLocation = _currentLocation;
    });
    await _checkProximity();
  }

  void _showAlert(String title, String message, Color color) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title,
            style: TextStyle(color: color),
          ),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: Text("Test Attendance HashMicro", style: TextStyle(color: Colors.white, fontSize: 20, ),),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentLocation,
                    initialZoom: _currentZoom,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          width: 50,
                          height: 50,
                          point: _currentLocation,
                          child:  const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 35,
                          ),
                        ),
                        if (_attendLocation != null)
                          Marker(
                            width: 50,
                            height: 50,
                            point: _attendLocation!,
                            child:  const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 35,
                            ),
                          ),
                      ],
                    ),
                    if (_masterLocation != null)
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: _masterLocation!,
                            color: Colors.blue.withOpacity(0.3),
                            borderStrokeWidth: 2,
                            borderColor: Colors.blue,
                            useRadiusInMeter: true,
                            radius: 50, // 50 meters radius
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              Container(
                height: 250,
                decoration: const BoxDecoration(
                  color: Colors.white,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          const Text(
                            "Master Data Lokasi",
                            style: TextStyle(fontSize: 20, color: Colors.orangeAccent),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Text(
                            _locationText,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          InkWell(
                            onTap: _handleCreate,
                            child: Container(
                              height: 45,
                              width: 130,
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(
                                child: Text(
                                  "Create",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 20,
                          ),
                          InkWell(
                            onTap: _handleAttend,
                            child: Container(
                              height: 45,
                              width: 130,
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(
                                child: Text(
                                  "Attend",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
