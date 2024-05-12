import 'dart:async';
import 'dart:math' as math;
import 'dart:math' show atan2, cos, pow, sin, sqrt;

// import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as location;
import 'package:location/location.dart';

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
  final location.Location _locationController = location.Location();
  LatLng myLocation = const LatLng(21.0721, 105.7739);
  static const LatLng locationGo = LatLng(21.0799, 105.7782);
  String address = 'Bạn';
  Set<Marker> markers = {};
  Map<PolylineId, Polyline> polylines = {};
  Timer? _timer; // Biến để lưu trữ timer
  @override
  void initState() {
    super.initState();
    _getCurrentLocation(); // Lấy vị trí hiện tại
  }

  Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();
  // circle
  Circle circle = const Circle(
    circleId: CircleId('circle_id'), // ID của hình tròn
    center: LatLng(0, 0), // Vị trí trung tâm của hình tròn (giá trị mặc định)
    radius: 0, // Bán kính của hình tròn (giá trị mặc định)
    fillColor: Colors.blue, // Màu nền của hình tròn
    strokeWidth: 2, // Độ dày của đường viền
    strokeColor: Colors.blue, // Màu của đường viền
  );
  // create circle
  void _onMapCreated(Completer<GoogleMapController> controller) {
    _mapController = controller;
    _listenLocationChanges();

    setState(() {
      circle = Circle(
        circleId: const CircleId('circle_id'),
        center: const LatLng(21.075526, 105.777397),
        radius: 200,
        fillColor: Colors.blue.withOpacity(0.3),
        strokeWidth: 2,
        strokeColor: Colors.blue,
      );
    });
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
      markers.add(
        Marker(
          infoWindow: InfoWindow(title: address),
          position: myLocation,
          draggable: true,
          markerId:
              MarkerId(value.toString()), // Change markerId to a unique value
          onDragEnd: (value) {
            setMarker(value);
          },
        ),
      );
    });
    Fluttertoast.showToast(msg: '📍 $address');
  }

  // resetMarker
  void resetMarker() async {
    List<Placemark> result = await placemarkFromCoordinates(
        myLocation.latitude, myLocation.longitude);
    if (result.isNotEmpty) {
      address =
          '${result[0].name}, ${result[0].locality} ${result[0].administrativeArea}';
    }
    setState(() {
      // Cập nhật lại marker
      markers.clear();
      markers.add(
        Marker(
          infoWindow: InfoWindow(title: address),
          position: myLocation,
          draggable: true,
          markerId: MarkerId(
              myLocation.toString()), // Change markerId to a unique value
          onDragEnd: (value) {
            setMarker(value);
          },
        ),
      );
    });
  }

  //  CameraPosition
  Future<void> cameraToPosition(LatLng pos) async {
    final GoogleMapController controller = await _mapController.future;
    CameraPosition _newCameraPosition = CameraPosition(target: pos, zoom: 13);
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(_newCameraPosition),
    );
  }

  // getLocationUpdates
  Future<void> getLocationUpdates() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await _locationController.serviceEnabled();
    if (_serviceEnabled) {
      _serviceEnabled = await _locationController.requestService();
    } else {
      return;
    }

    _permissionGranted = await _locationController.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _locationController.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _locationController.onLocationChanged
        .listen((LocationData currentLocation) {
      if (currentLocation.latitude != null &&
          currentLocation.longitude != null) {
        setState(() {
          myLocation =
              LatLng(currentLocation.latitude!, currentLocation.longitude!);
          cameraToPosition(myLocation);
        });
      }
    });
  }

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

  LatLng _currentPosition = LatLng(0, 0); // Vị trí mặc định
  void _getCurrentLocation() async {
    final location = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = LatLng(location.latitude, location.longitude);
    });
    print('${location.latitude}, ${location.longitude}');
  }

  Future<void> _listenLocationChanges() async {
    var distance =
        calculateDistance(_currentPosition, LatLng(21.075526, 105.777397));
    if (distance <= 200) {
      showSimpleToastErr();
    }
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
      markers: {
        Marker(
            infoWindow: InfoWindow(title: address),
            position: myLocation,
            draggable: true,
            markerId: const MarkerId('1'),
            onDragEnd: (value) {
              setMarker(value);
            }),
        Marker(
            infoWindow: InfoWindow(title: address),
            position: locationGo,
            draggable: true,
            markerId: const MarkerId('2'),
            onDragEnd: (value) {}),
      },
      // ignore: unnecessary_null_comparison
      circles: circle != null ? {circle} : {},
      onTap: (value) {
        // setMarker(value);
      },
      onCameraMove: (CameraPosition position) {
        setState(() {
          _currentPosition = position.target;
        });
        getLocationUpdates();

        _runPeriodicTask();
      },
    );
  }

  void _runPeriodicTask() {
    // _runPeriodicTask();
    if (_timer != null) {
      _timer!.cancel(); // Hủy timer hiện tại
    }

    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _getCurrentLocation();
      _listenLocationChanges();
      if (kDebugMode) {
        print(calculateDistance(_currentPosition, locationGo));
      }
    });
  }

////////////////////
  Future<List<LatLng>> getPolylinePoints() async {
    List<LatLng> polylineCoordinates = [];
    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      'AIzaSyAGZs6yjzRaaATGnzgkDUg2QQc21gYuG1g',
      PointLatLng(myLocation.latitude, myLocation.longitude),
      PointLatLng(locationGo.latitude, locationGo.longitude),
      travelMode: TravelMode.driving,
    );
    if (result.points.isNotEmpty) {
      for (var point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }
    } else {
      if (kDebugMode) {
        print(result.errorMessage);
      }
    }
    return polylineCoordinates;
  }

  void generatePolyLineFromPoints(List<LatLng> polylineCoordinates) async {
    PolylineId id = const PolylineId("poly");
    Polyline polyline = Polyline(
        polylineId: id,
        color: Colors.black,
        points: polylineCoordinates,
        width: 8);
    setState(() {
      polylines[id] = polyline;
    });
  }

  Positioned currentLocation() {
    return Positioned(
      bottom: 20.0,
      right: 60.0,
      child: FloatingActionButton(
        onPressed: () {
          _timer!.cancel();
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
          getLocationUpdates().then(
            (_) => {
              getPolylinePoints().then((coordinates) => {
                    generatePolyLineFromPoints(coordinates),
                  }),
            },
          );
          // resetMarker();
          _runPeriodicTask();
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
