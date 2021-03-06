import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';

const double CAMERA_ZOOM = 16;
const double CAMERA_TILT = 80;
const double CAMERA_BEARING = 30;
List<double> abc = [];
Set<Polyline> _polylines = Set<Polyline>();
List<LatLng> polylineCoordinates = [];
late PolylinePoints polylinePoints;

String googleAPIKey = "AIzaSyDmHM-IakxXdJqN59m-rYM-nBjQueCDam8";

class PoliceScreen extends StatefulWidget {
  const PoliceScreen({Key? key}) : super(key: key);

  @override
  _PoliceScreenState createState() => _PoliceScreenState();
}

class _PoliceScreenState extends State<PoliceScreen> {
  Completer<GoogleMapController> _controller = Completer();
  late BitmapDescriptor sourceIcon;
  late BitmapDescriptor destinationIcon;
  Set<Marker> _markers = Set<Marker>();
  late LocationData currentLocation;
  late LatLng destinationLocation;
  late int distance = 0;
  late String name = "";
  List<String> police_names = [
    "Police Station 1\nAddress: Santo Rosario St, Angeles, Pampanga\nContact: 0998-598-5526",
    "Police Station 2\nAddress: Richthofen St, Angeles, Pampanga\nContact: 0998-598-5528",
    "Police Station 3\nAddress: Pandan Rd, Angeles, Pampanga\nContact: 0998-598-5530",
    "Police Station 4\nAddress: M.A Roxas Hwy, Cor Constine, Baudago, Angeles, Pampanga\nContact: 0998-598-5532",
    "Police Station 5\nAddress: Fil-Am Friendship Hwy, Angeles, Pampanga\nContact: 0998-598-5536",
    "Police Station 6\nAddress: Jake Gonzales Blvd, Angeles, Pampanga\nContact: 0998-598-5538"
  ];
  List<LatLng> police_coords = [
    LatLng(15.135357013026496, 120.59118463662692),
    LatLng(15.150856321506675, 120.58439683142217),
    LatLng(15.162282851416602, 120.60939866998147),
    LatLng(15.169361764636506, 120.58452431547124),
    LatLng(15.14451215215298, 120.55899115171006),
    LatLng(15.147411892865492, 120.59502497994826)
  ];

  var location = new Location();
  var userLocation;

  void shortestDistance() async {
    currentLocation = await location.getLocation();
    double dist;
    for (int i = 0; i <= 5; i++) {
      //LatLng xyz = police_coords[i];
      dist = await Geolocator.distanceBetween(
          police_coords[i].latitude,
          police_coords[i].longitude,
          currentLocation.latitude,
          currentLocation.longitude);
      abc.add(dist);
    }
    double nearest = abc.reduce(min);
    int j = abc.indexOf(nearest);
    destinationLocation =
        LatLng(police_coords[j].latitude, police_coords[j].longitude);

    distance = nearest.toInt();
    name = police_names[j];
  }

  void initState() {
    shortestDistance();
    super.initState();
    location = new Location();
    polylinePoints = PolylinePoints();
    location.onLocationChanged.listen((LocationData cLoc) {
      currentLocation = cLoc;
      updatePinOnMap();
    });
    setSourceAndDestinationLocationMarkerIcons();
  }

  void setSourceAndDestinationLocationMarkerIcons() async {
    sourceIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(devicePixelRatio: 2.0), 'assets/origin.png');
    destinationIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(devicePixelRatio: 2.0), 'assets/destination.png');
  }

  @override
  Widget build(BuildContext context) {
    CameraPosition initialCameraPosition = CameraPosition(
        zoom: CAMERA_ZOOM,
        tilt: CAMERA_TILT,
        bearing: CAMERA_BEARING,
        target: LatLng(0, 0));

    return Scaffold(
        appBar: AppBar(
          title: Text(
            "Map",
          ),
          backgroundColor: Colors.redAccent[700],
        ),
        body: Stack(
          children: [
            Positioned.fill(
                child: GoogleMap(
              myLocationEnabled: false,
              compassEnabled: false,
              tiltGesturesEnabled: false,
              zoomControlsEnabled: false,
              polylines: _polylines,
              markers: _markers,
              mapType: MapType.terrain,
              initialCameraPosition: initialCameraPosition,
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
                shortestDistance();
                showPinsOnMap();
              },
            )),
            Positioned(top: 40, left: 0, right: 0, child: MapUserBadge()),
            Positioned(
                left: 0, right: 0, bottom: 20, child: MapDestBadge(name: name))
          ],
        ));
  }

  void showPinsOnMap() {
    setState(() {
      var pinPosition =
          LatLng(currentLocation.latitude, currentLocation.longitude);
      _markers.add(Marker(
          markerId: MarkerId('sourcePin'),
          position: pinPosition,
          icon: sourceIcon));
      _markers.add(Marker(
          markerId: MarkerId('destinationPin'),
          position: destinationLocation,
          icon: destinationIcon));
      setPolylines();
    });
  }

  void setPolylines() async {
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        "AIzaSyDmHM-IakxXdJqN59m-rYM-nBjQueCDam8",
        PointLatLng(currentLocation.latitude, currentLocation.longitude),
        PointLatLng(
            destinationLocation.latitude, destinationLocation.longitude));
    if (result.status == 'OK') {
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
      setState(() {
        _polylines.add(Polyline(
            width: 10,
            polylineId: PolylineId('Polyline'),
            color: Color.fromARGB(255, 40, 122, 198),
            points: polylineCoordinates));
      });
    }
  }

  void updatePinOnMap() async {
    CameraPosition cPosition = CameraPosition(
        zoom: CAMERA_ZOOM,
        tilt: CAMERA_TILT,
        bearing: CAMERA_BEARING,
        target: LatLng(currentLocation.latitude, currentLocation.longitude));
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(cPosition));

    if (mounted) {
      setState(() {
        var pinPosition =
            LatLng(currentLocation.latitude, currentLocation.longitude);
        _markers.removeWhere((m) => m.markerId.value == 'sourcePin');
        _markers.add(Marker(
            markerId: MarkerId('sourcePin'),
            position: pinPosition,
            icon: sourceIcon));
      });
    }
  }
}

class MapDestBadge extends StatelessWidget {
  const MapDestBadge({
    Key? key,
    required this.name,
  }) : super(key: key);

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: EdgeInsets.all(20),
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(100),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: Offset.zero)
            ]),
        child: Row(
          children: [
            Stack(
              children: [
                ClipOval(
                  child: Icon(
                    Icons.local_police_rounded,
                    size: 50.0,
                    color: Colors.red,
                  ),
                )
              ],
            ),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: TextStyle(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                ],
              ),
            ),
            Icon(Icons.location_pin, color: Colors.red, size: 50)
          ],
        ));
  }
}

var currentUser = FirebaseAuth.instance.currentUser;
var email = currentUser.email;

class MapUserBadge extends StatelessWidget {
  const MapUserBadge({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.all(12),
        margin: EdgeInsets.only(top: 0, bottom: 10, left: 20, right: 20),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(100),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: Offset.zero)
            ]),
        child: Row(
          children: [
            Container(
              width: 0,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
              ),
            ),
            Icon(
              Icons.person_pin,
              size: 50.0,
              color: Colors.green,
            ),
            SizedBox(width: 10),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(email,
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black)),
                ])),
            Icon(Icons.location_pin, color: Colors.green, size: 40)
          ],
        ));
  }
}
