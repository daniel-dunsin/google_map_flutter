import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/const.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final LatLng _startPoint = LatLng(37.33036067, -122.02845007);
  final LatLng _desitinationPoint = LatLng(37.33019556, -122.02611639);
  List<LatLng> polylineCoordinates = [];
  LatLng? userPoint;

  final Completer<GoogleMapController> mapController = Completer<GoogleMapController>();

  final _locationController = Location();

  @override
  void initState() {
    initActions();
    super.initState();
  }

  void initActions() async {
    await _getPolylineCoordinates();
    await _getUserPoints();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: userPoint == null
          ? Center(
              child: CircularProgressIndicator.adaptive(),
            )
          : GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                mapController.complete(controller);
              },
              initialCameraPosition: CameraPosition(
                target: userPoint!,
                zoom: 20,
              ),
              markers: {
                Marker(
                  markerId: MarkerId("_startPoint"),
                  position: _startPoint,
                  icon: BitmapDescriptor.defaultMarker,
                ),
                Marker(
                  markerId: MarkerId("_destinationPoint"),
                  position: _desitinationPoint,
                  icon: BitmapDescriptor.defaultMarker,
                ),
                Marker(
                  markerId: MarkerId("_userPoint"),
                  position: userPoint!,
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                ),
              },
              polylines: {
                Polyline(
                  polylineId: PolylineId("test_destination"),
                  points: polylineCoordinates,
                  width: 5,
                ),
              },
            ),
    );
  }

  _getPolylineCoordinates() async {
    final List<LatLng> coordinates = [];
    final PolylinePoints polylinePoints = PolylinePoints();
    final PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleApiKey: AppConstants.googleMapApiKey,
      request: PolylineRequest(
        origin: PointLatLng(_startPoint.latitude, _startPoint.longitude),
        destination: PointLatLng(_desitinationPoint.latitude, _desitinationPoint.longitude),
        mode: TravelMode.driving,
      ),
    );

    result.points.forEach(
      (point) => coordinates.add(
        LatLng(point.latitude, point.longitude),
      ),
    );

    setState(() {
      polylineCoordinates = [
        ...coordinates
      ];
    });
  }

  Future<void> _getUserPoints() async {
    bool serviceEnabled = false;
    PermissionStatus? permissonStatus;

    serviceEnabled = await _locationController.serviceEnabled();

    if (!serviceEnabled) {
      return;
    }

    permissonStatus = await _locationController.hasPermission();

    if (permissonStatus == PermissionStatus.deniedForever) return;
    if (permissonStatus == PermissionStatus.denied) {
      permissonStatus = await _locationController.requestPermission();
    }

    if (permissonStatus == PermissionStatus.granted || permissonStatus == PermissionStatus.grantedLimited) {
      _locationController.onLocationChanged.listen((LocationData locationData) async {
        if (locationData.latitude != null && locationData.longitude != null) {
          print("location changed ${locationData.longitude} ${locationData.latitude}");

          setState(() {
            userPoint = LatLng(
              locationData.latitude!,
              locationData.longitude!,
            );
          });

          final controller = await mapController.future;

          controller.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(
                  locationData.latitude!,
                  locationData.longitude!,
                ),
                zoom: 13,
              ),
            ),
          );
        }
      });
    }
  }
}
