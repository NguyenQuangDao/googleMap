import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:math' show atan2, cos, pow, sin, sqrt;

// import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng myLocation = const LatLng(38.40507560, -122.59521022);
  String address = 'Bạn';
  Set<Marker> markers = {};
  Map<PolylineId, Polyline> polylines = {};
  // Timer? _timer; // Biến để lưu trữ timer
  late Polyline _kPolyline;
  @override
  void initState() {
    super.initState();
    _getCurrentLocation(); // Lấy vị trí hiện tại
    _kPolyline = Polyline(
      polylineId: const PolylineId('kPolyline'),
      points: [
        LatLng(38.40507560, -122.59521022),
        const LatLng(38.40507560, -122.59221022)
      ],
      width: 5,
      color: Colors.blue,
    );
  }

  List<LatLng> polylineCoordinates = [
    LatLng(38.40507560, -122.59521022),
    LatLng(38.40407560, -122.54521022),
    LatLng(38.40537560, -122.51521022)
  ];
  PolylinePoints polylinePoints = PolylinePoints();
  String googleAPiKey = "YOUR_GOOGLE_API_KEY";
  Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();
  // circle
  Set<Circle> circles = {};
  Future<void> fetchCoordinates() async {
    final response = await http.get(
        Uri.parse('https://6411ea8ff9fe8122ae17b101.mockapi.io/vi-pham-dien'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // final data = dataTest;
      // print(data);
      setState(() {
        circles = Set.from(data.map<Circle>((item) {
          return Circle(
            circleId: CircleId(item['id'].toString()),
            center: LatLng(double.parse(item['y'].toString()),
                double.parse(item['x'].toString())),
            radius: 10,
            fillColor: Colors.yellow,
            strokeColor: Colors.yellow,
            strokeWidth: 2,
          );
        }));
      });
    } else {
      throw Exception('Failed to load coordinates');
    }
  }

  // create circle
  void _onMapCreated(Completer<GoogleMapController> controller) {
    _mapController = controller;
    fetchCoordinates();
  }

  // setMarker

  setMarker(LatLng value) async {
    myLocation = value;

    List<Placemark> result =
        await placemarkFromCoordinates(value.latitude, value.longitude);
    if (result.isNotEmpty) {
      address =
          '${result[0].name}, ${result[0].locality} ${result[0].administrativeArea}';
    }
    setState(() {
      // Update the polyline with the new location
      _kPolyline = Polyline(
        polylineId: const PolylineId('kPolyline'),
        points: [myLocation, const LatLng(38.40507560, -122.59221022)],
        width: 5,
        color: Colors.blue,
      );
      Marker? existingMarker;

      // Kiểm tra xem có marker nào không
      if (markers.isNotEmpty) {
        existingMarker = markers.firstWhere(
          (marker) => marker.markerId == const MarkerId('1'),
          orElse: () =>
              markers.first, // Trả về marker đầu tiên nếu không tìm thấy
        );

        // Cập nhật vị trí của marker hiện có
        markers.remove(existingMarker);
        markers.add(
          existingMarker.copyWith(
            positionParam: value,
          ),
        );
      } else {
        // Nếu không có marker, thêm một marker mới
        markers.add(
          Marker(
            infoWindow: InfoWindow(title: address),
            position: myLocation,
            draggable: true,
            markerId: const MarkerId('1'),
            onDragEnd: (value) {
              setMarker(value);
            },
          ),
        );
      }
    });
    Fluttertoast.showToast(msg: '📍 $address');
  }

  // resetMarker
  // void resetMarker() async {
  //   List<Placemark> result = await placemarkFromCoordinates(
  //       myLocation.latitude, myLocation.longitude);
  //   if (result.isNotEmpty) {
  //     address =
  //         '${result[0].name}, ${result[0].locality} ${result[0].administrativeArea}';
  //   }
  //   setState(() {
  //     // Cập nhật lại marker
  //     markers.clear();
  //     markers.add(
  //       Marker(
  //         infoWindow: InfoWindow(title: address),
  //         position: myLocation,
  //         draggable: true,
  //         markerId: MarkerId(
  //             myLocation.toString()), // Change markerId to a unique value
  //         onDragEnd: (value) {
  //           setMarker(value);
  //         },
  //       ),
  //     );
  //   });
  // }

  //  CameraPosition
  Future<void> cameraToPosition(LatLng pos) async {
    final GoogleMapController controller = await _mapController.future;
    CameraPosition _newCameraPosition = CameraPosition(target: pos, zoom: 13);
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(_newCameraPosition),
    );
  }

// _kPolyline
  // static final Polyline _kPolyline = Polyline(
  //   polylineId: const PolylineId('kPolyline'),
  //   points: [
  //     LatLng(38.40507560, -122.59521022),
  //     const LatLng(38.40507560, -122.59221022)
  //   ],
  //   width: 5,
  //   color: Colors.blue,
  // );

  // kPolygon
  // static const Polygon _kPolygon = Polygon(
  //   polygonId: PolygonId('_kPolygon'),
  //   points: [
  //     LatLng(38.40507560, -122.59521022),
  //     LatLng(38.40507560, -122.59221022)
  //   ],
  // );
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map Lidar'),
        backgroundColor: Colors.blue,
      ),
      body: Stack(children: [
        GooglemapLidar(),
        // Location Button
        currentLocation(),
        runLocation()
      ]),
    );
  }

  // ignore: non_constant_identifier_names
  GoogleMap GooglemapLidar() {
    return GoogleMap(
      onMapCreated: ((GoogleMapController controller) =>
          {_onMapCreated(Completer<GoogleMapController>())}),
      initialCameraPosition: CameraPosition(
        target: myLocation,
        zoom: 16.0,
      ),
      mapType: MapType.satellite,
      markers: {
        Marker(
          infoWindow: InfoWindow(title: address),
          position: myLocation,
          draggable: true,
          markerId: const MarkerId('1'),
        ),
      },
      circles: circles,
      onTap: (value) {
        setMarker(value);
      },
      polylines: {_kPolyline},
      // polygons: {_kPolygon},
    );
  }

  // _getPolyline() async {
  //   PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
  //       googleAPiKey,
  //       const LatLng(38.40507560, -122.59521022) as PointLatLng,
  //       myLocation as PointLatLng,
  //       travelMode: TravelMode.driving,
  //       wayPoints: [
  //         PolylineWayPoint(
  //           location: "Sabo, Yaba Lagos Nigeria",
  //         ),
  //       ]);
  //   if (result.points.isNotEmpty) {
  //     result.points.forEach((PointLatLng point) {
  //       polylineCoordinates.add(LatLng(point.latitude, point.longitude));
  //     });
  //   }
  //   _addPolyLine();
  // }

  // _addPolyLine() {
  //   PolylineId id = PolylineId("poly");
  //   Polyline polyline = Polyline(
  //     polylineId: id,
  //     visible: true,
  //     color: Colors.blue.withOpacity(0.5),
  //     points: polylineCoordinates,
  //   );
  //   polylines[id] = polyline;
  //   setState(() {});
  // }

  LatLng _currentPosition = LatLng(0, 0); // Vị trí mặc định
  void _getCurrentLocation() async {
    final location = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = LatLng(location.latitude, location.longitude);
    });
    // print('${location.latitude}, ${location.longitude}');
  }

  // Future<void> _listenLocationChanges() async {
  //   var distance =
  //       calculateDistance(_currentPosition, LatLng(21.075526, 105.777397));
  //   if (distance <= 200) {
  //     showSimpleToastErr();
  //   }
  // }

  Positioned currentLocation() {
    return Positioned(
      bottom: 20.0,
      right: 65.0,
      child: FloatingActionButton(
        onPressed: () {
          setMarker(const LatLng(38.40507560, -122.59521022));
        },
        child: const Icon(Icons.location_searching),
      ),
    );
  }

  Positioned runLocation() {
    return Positioned(
      bottom: 20.0,
      right: 140.0,
      child: FloatingActionButton(
        onPressed: () {
          // _getPolyline();
        },
        child: const Icon(Icons.running_with_errors),
      ),
    );
  }
}

// tính khoảng cách từ vị trí đến tâm
double calculateDistance(LatLng point1, LatLng point2) {
  const double earthRadius = 6371000; // Bán kính trái đất (m)
  double lat1 = point1.latitude;
  double lon1 = point1.longitude;
  double lat2 = point2.latitude;
  double lon2 = point2.longitude;
  double dLat = (lat2 - lat1) * (math.pi / 180);
  double dLon = (lon2 - lon1) * (math.pi / 180);
  double a = pow(sin(dLat / 2), 2) +
      cos(lat1 * (math.pi / 180)) *
          cos(lat2 * (math.pi / 180)) *
          pow(sin(dLon / 2), 2);
  double c = 2 * atan2(sqrt(a), sqrt(1 - a));
  double distance = earthRadius * c;
  return distance;
}

void showSimpleToastErr() {
  Fluttertoast.showToast(
    msg: "Bạn đang trong vùng nguy hiểm!!",
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.TOP,
    backgroundColor: Colors.red,
    textColor: Colors.white,
    timeInSecForIosWeb: 5,
    fontSize: 20,
  );
}

void showSimpleToast() {
  Fluttertoast.showToast(
    msg: "Bạn đã thoát khỏi vùng nguy hiểm!!",
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.TOP,
    backgroundColor: Colors.blue,
    textColor: Colors.white,
    timeInSecForIosWeb: 1,
    fontSize: 20,
  );
}
