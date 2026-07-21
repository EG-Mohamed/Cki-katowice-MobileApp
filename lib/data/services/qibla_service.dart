import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';

class QiblaReading {
  const QiblaReading({required this.heading, required this.qiblaBearing});

  final double heading;
  final double qiblaBearing;

  double get needleAngle => (qiblaBearing - heading) % 360;
  bool get isAligned {
    final diff = needleAngle.abs() % 360;
    final delta = diff > 180 ? 360 - diff : diff;
    return delta < 5;
  }
}

class QiblaService {
  static const double _kaabaLat = 21.4225;
  static const double _kaabaLng = 39.8262;

  double? _qiblaBearing;
  double? _distanceKm;

  double? get distanceKm => _distanceKm;
  bool get hasCompass => FlutterCompass.events != null;

  Future<bool> ensurePermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<void> resolveLocation() async {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
    );
    _qiblaBearing = _bearingToKaaba(position.latitude, position.longitude);
    _distanceKm =
        Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          _kaabaLat,
          _kaabaLng,
        ) /
        1000;
  }

  Stream<QiblaReading> readings() {
    final events = FlutterCompass.events;
    if (events == null) return const Stream.empty();
    return events
        .where((e) => e.heading != null && _qiblaBearing != null)
        .map(
          (e) =>
              QiblaReading(heading: e.heading!, qiblaBearing: _qiblaBearing!),
        );
  }

  double _bearingToKaaba(double lat, double lng) {
    final phiK = _kaabaLat * math.pi / 180;
    final phi = lat * math.pi / 180;
    final deltaLng = (_kaabaLng - lng) * math.pi / 180;
    final y = math.sin(deltaLng);
    final x =
        math.cos(phi) * math.tan(phiK) - math.sin(phi) * math.cos(deltaLng);
    final bearing = math.atan2(y, x) * 180 / math.pi;
    return (bearing + 360) % 360;
  }
}
