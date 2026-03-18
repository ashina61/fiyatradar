import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

class LocationService {
  Future<bool> checkPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await checkPermission();
      if (!hasPermission) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      return null;
    }
  }

  Future<String?> getAddressFromPosition(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final parts = <String>[];

        final thoroughfare = (place.thoroughfare ?? '').trim();
        final subLocality = (place.subLocality ?? '').trim();
        final locality = (place.locality ?? '').trim();
        final administrativeArea = (place.administrativeArea ?? '').trim();

        if (thoroughfare.isNotEmpty) {
          parts.add(thoroughfare);
        }
        if (subLocality.isNotEmpty) {
          parts.add(subLocality);
        }
        if (locality.isNotEmpty) {
          parts.add(locality);
        }
        if (administrativeArea.isNotEmpty) {
          parts.add(administrativeArea);
        }

        return parts.join(', ');
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<LocationData?> getLocationData() async {
    final position = await getCurrentPosition();
    if (position == null) {
      return null;
    }

    final address = await getAddressFromPosition(position);
    return LocationData(
      position: position,
      address: address,
      geoPoint: GeoPoint(position.latitude, position.longitude),
    );
  }

  double calculateDistance({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    return haversineMeters(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  double haversineMeters(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    const earthRadius = 6371000.0;
    final dLat = _degToRad(endLatitude - startLatitude);
    final dLng = _degToRad(endLongitude - startLongitude);
    final startLatRad = _degToRad(startLatitude);
    final endLatRad = _degToRad(endLatitude);

    final a =
        (math.sin(dLat / 2) * math.sin(dLat / 2)) +
        (math.cos(startLatRad) *
            math.cos(endLatRad) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2));
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _degToRad(double degrees) => degrees * (math.pi / 180);

  String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()}m';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }
}

class LocationData {
  final Position position;
  final String? address;
  final GeoPoint geoPoint;

  LocationData({
    required this.position,
    this.address,
    required this.geoPoint,
  });
}
