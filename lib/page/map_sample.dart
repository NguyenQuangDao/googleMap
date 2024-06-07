import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:math' show atan2, cos, pow, sin, sqrt;

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart' as loc;
import 'package:location/location.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  static MapType mapType = MapType.normal;
  @override
  // ignore: library_private_types_in_public_api
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static MapType mapType = MapType.normal;
  LatLng myLocation = const LatLng(38.39761337033967, -122.60055340826511);
  // LatLng myLocation = const LatLng(21.0721, 105.7739);
  // LatLng myLocation = const LatLng(9.7252219, 106.1796974);
  String address = 'Bạn';
  Set<Marker> markers = {};
  final locationController = loc.Location();
  LatLng? currentPosition;
  Map<PolylineId, Polyline> polylines = {};
  Set<Circle> circles = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) async => await initializeMap());
    fetchCoordinates();
  }

  // create circle
  void _onMapCreated(Completer<GoogleMapController> controller) {
    _mapController = controller;
    fetchCoordinates();
  }

  String googleAPiKey = "AIzaSyAGc5rFjpa05CBX7Yvdmb0tcr_kseiAYk0";
  Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();
  // circle

  Future<void> fetchCoordinates() async {
    // const data = dataTest;
    // setState(() {
    //   Color getFillColor(Map<String, dynamic> item) {
    //     if (item.containsKey('color') && item['color'] != null) {
    //       return Colors.red.withOpacity(0.5);
    //     } else {
    //       return Colors.yellow.withOpacity(0.5);
    //     }
    //   }

    //   circles = Set.from(data.map<Circle>((item) {
    //     return Circle(
    //       circleId: CircleId(item['id'].toString()),
    //       center: LatLng(double.parse(item['y'].toString()),
    //           double.parse(item['x'].toString())),
    //       radius: getFillColor(item) == Colors.red.withOpacity(0.5) ? 3 : 0.5,
    //       fillColor: getFillColor(item),
    //       strokeColor: getFillColor(item),
    //       strokeWidth: 2,
    //     );
    //   }));
    // });
    final response = await http.get(
        Uri.parse('https://6411ea8ff9fe8122ae17b101.mockapi.io/vi-pham-dien'));
    print('aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaâ ++ ${response.statusCode}');
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      print(data);
      setState(() {
        Color getFillColor(Map<String, dynamic> item) {
          if (item.containsKey('color') && item['color'] != null) {
            return Colors.red.withOpacity(0.5);
          } else {
            return Colors.yellow.withOpacity(0.5);
          }
        }

        circles = Set.from(data.map<Circle>((item) {
          return Circle(
            circleId: CircleId(item['id'].toString()),
            center: LatLng(item['y'], item['x']),
            radius: getFillColor(item) == Colors.red.withOpacity(0.5) ? 3 : 0.5,
            fillColor: getFillColor(item),
            strokeColor: getFillColor(item),
            strokeWidth: 2,
          );
        }));
      });
    } else {
      throw Exception('Failed to load coordinates');
    }
  }

  // setMarker
  setMarker(LatLng value) async {
    myLocation = value;

    List<Placemark> result =
        await placemarkFromCoordinates(value.latitude, value.longitude);
    if (result.isNotEmpty) {
      address =
          '${result[0].name}, ${result[0].locality} ${result[0].administrativeArea}';
      Fluttertoast.showToast(msg: '📍 $address');
    }
    setState(() {
      showSimpleToast(myLocation);
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
      initializeMap();
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

//  khởi tạo polyline
  Future<void> initializeMap() async {
    await fetchLocationUpdates();
    final coordinates = await fetchPolylinePoints();
    generatePolyLineFromPoints(coordinates);
  }

// giao diện
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đảm bảo hành lang an toàn điện'),
        backgroundColor: Colors.blue,
      ),
      body: Stack(children: [
        GooglemapLidar(),
        // Location Button
        currentLocation(),
        DropdownMapType(),
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
        zoom: 14.0,
      ),
      mapType: mapType,
      markers: {
        Marker(
          infoWindow: InfoWindow(title: address),
          position: myLocation,
          draggable: true,
          markerId: const MarkerId('1'),
        ),
      },
      circles: Set<Circle>.of(circles),
      onTap: (value) {
        setMarker(value);
        print(value);
      },
      polylines: Set<Polyline>.of(polylines.values),
    );
  }

  Positioned currentLocation() {
    return Positioned(
      bottom: 20.0,
      right: 65.0,
      child: FloatingActionButton(
        onPressed: () {
          setMarker(const LatLng(38.39761337033967, -122.60055340826511));
          // setMarker(const LatLng(21.0795, 105.7789));
        },
        child: const Icon(Icons.location_searching),
      ),
    );
  }

///////////////////////////////////////
// polyline
  Future<void> fetchLocationUpdates() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await locationController.serviceEnabled();
    if (serviceEnabled) {
      serviceEnabled = await locationController.requestService();
    } else {
      return;
    }

    permissionGranted = await locationController.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await locationController.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    locationController.onLocationChanged.listen((currentLocation) {
      if (currentLocation.latitude != null &&
          currentLocation.longitude != null) {
        setState(() {
          currentPosition = LatLng(
            currentLocation.latitude!,
            currentLocation.longitude!,
          );
        });
      }
    });
  }

  Future<List<LatLng>> fetchPolylinePoints() async {
    final polylinePoints = PolylinePoints();
    final result = await polylinePoints.getRouteBetweenCoordinates(
      'AIzaSyAGc5rFjpa05CBX7Yvdmb0tcr_kseiAYk0',
      const PointLatLng(38.40507560, -122.59221022),
      // const PointLatLng(21.0795, 105.7789),
      PointLatLng(myLocation.latitude, myLocation.longitude),
    );
    if (result.points.isNotEmpty) {
      return result.points
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();
    } else {
      debugPrint(result.errorMessage);
      return [];
    }
  }

  Future<void> generatePolyLineFromPoints(
      List<LatLng> polylineCoordinates) async {
    const id = PolylineId('polyline');
    final polyline = Polyline(
      polylineId: id,
      color: Colors.blueAccent,
      points: polylineCoordinates,
      width: 5,
    );

    setState(() => polylines[id] = polyline);
  }
}

//////////////////////////////////////////////////////
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
  // Làm tròn đến 2 chữ số thập phân
  double roundedDistance = double.parse(distance.toStringAsFixed(2));
  return roundedDistance;
}

void showSimpleToast(LatLng location) {
  Fluttertoast.showToast(
    msg:
        "Khoảng cách tới vùng nguy hiểm ${calculateDistance(location, const LatLng(38.40507560, -122.59221022))} mét",
    // msg:"Khoảng cách tới nơi an toàn ${calculateDistance(location, const LatLng(21.0795, 105.7789))} mét",
    toastLength: Toast.LENGTH_LONG,
    gravity: ToastGravity.TOP,
    backgroundColor: Colors.blue.shade400,
    textColor: Colors.white,
    timeInSecForIosWeb: 5,
    fontSize: 22,
  );
}

// DropdownMapType
const List<String> list = <String>['Normal', 'Satellite', 'Terrain', 'Hybrid'];

class DropdownMapType extends StatefulWidget {
  const DropdownMapType({Key? key}) : super(key: key);

  @override
  State<DropdownMapType> createState() => _DropdownMapTypeState();
}

class _DropdownMapTypeState extends State<DropdownMapType> {
  String dropdownValue = list.first;
  late GoogleMapController _controller;
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 20,
          bottom: 30,
          child: InkWell(
            onTap: () {
              // Open dropdown
              // Here you can add any additional action you want to perform when the dropdown is tapped
              showDropdown(context);
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[300], // Background color
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    dropdownValue,
                    style: TextStyle(color: Colors.black), // Text color
                  ),
                  Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void showDropdown(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Container(
            width: MediaQuery.of(context).size.width * 0.5,
            child: DropdownButton<String>(
              value: dropdownValue,
              icon: const Icon(Icons.arrow_downward),
              elevation: 16,
              style: TextStyle(color: Colors.black), // Text color
              onChanged: (String? value) {
                setState(() {
                  dropdownValue = value!;
                });
                handleItemClick(value);
                Navigator.pop(context);
              },
              items: list.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  void handleItemClick(String? value) {
    switch (value) {
      case 'Normal':
        setState(() {
          _MapScreenState.mapType = MapType.normal;
        });
        break;
      case 'Satellite':
        setState(() {
          _MapScreenState.mapType = MapType.satellite;
        });
        break;
      case 'Terrain':
        setState(() {
          _MapScreenState.mapType = MapType.terrain;
        });
        break;
      case 'Hybrid':
        setState(() {
          _MapScreenState.mapType = MapType.hybrid;
        });
        break;
    }
  }
}
