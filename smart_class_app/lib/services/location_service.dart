import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static Future<Position?> getCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled().timeout(
        const Duration(seconds: 8),
        onTimeout: () => false,
      );
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission().timeout(
        const Duration(seconds: 8),
        onTimeout: () => LocationPermission.denied,
      );

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission().timeout(
          const Duration(seconds: 12),
          onTimeout: () => LocationPermission.denied,
        );
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever ||
          permission == LocationPermission.unableToDetermine) {
        return null;
      }

      final accuracy = kIsWeb ? LocationAccuracy.medium : LocationAccuracy.high;

      try {
        if (kIsWeb) {
          return await Geolocator.getCurrentPosition(
            desiredAccuracy: accuracy,
          ).timeout(
            const Duration(seconds: 20),
            onTimeout: () => throw TimeoutException('Location request timed out'),
          );
        }

        return await Geolocator.getCurrentPosition(
          desiredAccuracy: accuracy,
          timeLimit: const Duration(seconds: 20),
        ).timeout(
          const Duration(seconds: 22),
          onTimeout: () => throw TimeoutException('Location request timed out'),
        );
      } catch (_) {
        // Some mobile browsers stall indefinitely; fall back to last known if available.
        return await Geolocator.getLastKnownPosition();
      }
    } catch (_) {
      return null;
    }
  }

  static String formatCoordinates(double lat, double lng) {
    return '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
  }
}
