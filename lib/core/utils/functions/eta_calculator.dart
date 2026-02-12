import 'dart:math';

import 'package:google_maps_flutter/google_maps_flutter.dart';

class EtaCalculators {
  final LatLng fromLoc;
  final LatLng toLoc;
  String vehicleType;

  EtaCalculators(this.fromLoc, this.toLoc, {this.vehicleType = 'car'});

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _deg2rad(double deg) => deg * pi / 180;

  Map<String, dynamic> calculateEta() {
    final distanceKm = _haversine(
      fromLoc.latitude,
      fromLoc.longitude,
      toLoc.latitude,
      toLoc.longitude,
    );

    final speeds = {'car': 40.0, 'motorcycle': 50.0};
    final avgSpeed = speeds[vehicleType.toLowerCase()] ?? 40.0;

    final etaMinutes = (distanceKm / avgSpeed) * 60;

    String etaFormatted;
    if (etaMinutes < 60) {
      etaFormatted = '${etaMinutes.toStringAsFixed(0)} minutes';
    } else {
      final etaHours = etaMinutes / 60;
      etaFormatted = '${etaHours.toStringAsFixed(1)} hours';
    }

    String distanceFormatted;
    if (distanceKm < 1) {
      distanceFormatted = '${(distanceKm * 1000).toStringAsFixed(0)} m';
    } else {
      distanceFormatted = '${distanceKm.toStringAsFixed(2)} km';
    }

    return {
      'distanceKm': distanceKm,
      'distanceFormatted': distanceFormatted,
      'etaMinutes': etaMinutes,
      'etaFormatted': etaFormatted,
    };
  }
}
