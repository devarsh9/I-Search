import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Place{
  final String shopName;
  final String address;
  final String description;
  final String thumbnail;
  final LatLng locationCoords;

  Place({
    @required this.shopName,
    @required this.address,
    @required this.description,
    @required this.thumbnail,
    @required this.locationCoords
  });
}