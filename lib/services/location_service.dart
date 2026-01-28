import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationService {
  Future<bool> checkPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
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

        if (place.thoroughfare?.isNotEmpty ?? false) {
          parts.add(place.thoroughfare!);
        }
        if (place.subLocality?.isNotEmpty ?? false) {
          parts.add(place.subLocality!);
        }
        if (place.locality?.isNotEmpty ?? false) {
          parts.add(place.locality!);
        }
        if (place.administrativeArea?.isNotEmpty ?? false) {
          parts.add(place.administrativeArea!);
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
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
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
