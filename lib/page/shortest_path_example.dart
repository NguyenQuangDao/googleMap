import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class ShortestPathApp extends StatefulWidget {
  @override
  _ShortestPathAppState createState() => _ShortestPathAppState();
}

class _ShortestPathAppState extends State<ShortestPathApp> {
  static const _initialCameraPosition = CameraPosition(
    target: LatLng(37.7749, -122.4194), // San Francisco
    zoom: 11.5,
  );

  late GoogleMapController _googleMapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tìm Đường Đi Ngắn Nhất'),
      ),
      body: GoogleMap(
        initialCameraPosition: _initialCameraPosition,
        markers: _markers,
        polylines: _polylines,
        onMapCreated: (controller) => _googleMapController = controller,
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.search),
        onPressed: () => _searchPlaces(),
      ),
    );
  }

  Future<void> _searchPlaces() async {
    // Lấy điểm xuất phát và điểm đến từ người dùng
    // ...

    String origin = 'origin_location';
    String destination = 'destination_location';

    await _calculateShortestPath(origin, destination);
  }

  Future<void> _calculateShortestPath(String origin, String destination) async {
    String apiKey =
        'AIzaSyAGc5rFjpa05CBX7Yvdmb0tcr_kseiAYk0'; // Thay đổi bằng API Key của bạn

    String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&key=$apiKey';

    var response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);

      if (data['status'] == 'OK') {
        _polylines.clear();
        _markers.clear();

        var points = data['routes'][0]['overview_polyline']['points'];
        var polylineCoordinates = _decodePolyline(points);

        _markers.add(
          Marker(
            markerId: MarkerId('origin'),
            position: LatLng(
              _getLocationFromString(origin).latitude,
              _getLocationFromString(origin).longitude,
            ),
          ),
        );

        _markers.add(
          Marker(
            markerId: MarkerId('destination'),
            position: LatLng(
              _getLocationFromString(destination).latitude,
              _getLocationFromString(destination).longitude,
            ),
          ),
        );

        _polylines.add(
          Polyline(
            polylineId: PolylineId('shortest_path'),
            color: Colors.blue,
            points: polylineCoordinates,
          ),
        );

        setState(() {});
      }
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      LatLng p = LatLng((lat / 1E5).toDouble(), (lng / 1E5).toDouble());
      poly.add(p);
    }
    return poly;
  }

  LatLng _getLocationFromString(String value) {
    List<String> coordinates = value.split(',');
    double latitude = double.parse(coordinates[0]);
    double longitude = double.parse(coordinates[1]);
    return LatLng(latitude, longitude);
  }
}
