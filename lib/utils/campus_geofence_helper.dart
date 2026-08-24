// campus_geofence_helper.dart
//
// Replaces the old simple circle-radius geofence (single point + 200m
// radius) with a POLYGON geofence that matches the actual shape of the
// campus boundary as seen on Google Maps — so a student standing just
// outside the gate/boundary wall is correctly marked "outside campus"
// even if they're technically within some fixed radius of the center.
//
// HOW TO GET YOUR CAMPUS POLYGON COORDINATES:
//   1. Open Google Maps, find your campus, switch to satellite view.
//   2. Right-click (desktop) or long-press (mobile) on each corner of
//      the campus boundary wall, in order, going around the perimeter.
//   3. Copy each "lat, lng" pair Google Maps shows you.
//   4. Paste all of them into `kCampusBoundary` below, in the same
//      order you clicked them (clockwise or counter-clockwise, doesn't
//      matter, just don't jump around).
//
// The polygon below is the real traced boundary of the IILM University,
// Greater Noida campus (7 corner points, collected from Google Maps).

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';

class CampusGeofenceHelper {
  /// Ordered list of [latitude, longitude] pairs tracing the campus
  /// boundary. Replace these with the real corner points you collect
  /// from Google Maps (see instructions above). Needs at least 3 points;
  /// realistically 6-12 points will trace an actual campus shape well.
  static const List<List<double>> kCampusBoundary = [
    [28.45955209192866, 77.49014626270895],
    [28.461831141589286, 77.48808584610427],
    [28.46270892761878, 77.48930903609478],
    [28.461451751413396, 77.49062649519446],
    [28.46236708512053, 77.49217674802014],
    [28.46144275546668, 77.49294675809352],
    [28.460005642934608, 77.49079789274877],
  ];

  /// Optional small buffer (in meters) added around the polygon to
  /// absorb normal GPS inaccuracy. Mobile GPS is typically accurate to
  /// 5-15m, so a small buffer is enough there. Web/browser geolocation
  /// (especially on desktops/laptops with no GPS chip, which fall back
  /// to WiFi-based positioning) can be off by 50-150m or more, so it
  /// needs a much larger tolerance to avoid rejecting students who are
  /// genuinely standing on campus.
  static double get kBufferMeters => kIsWeb ? 120.0 : 10.0;

  /// Returns true if [lat],[lng] falls inside the campus polygon
  /// (including the small buffer margin).
  static bool isInsideCampus(double lat, double lng) {
    if (_pointInPolygon(lat, lng, kCampusBoundary)) return true;
    if (kBufferMeters <= 0) return false;

    // Buffer check: also accept points within kBufferMeters of the
    // nearest polygon edge, so a student standing right on the
    // boundary line (where GPS could read either side) isn't unfairly
    // rejected.
    final distanceToEdge = _distanceToPolygonEdgeMeters(lat, lng, kCampusBoundary);
    return distanceToEdge <= kBufferMeters;
  }

  /// Ray-casting point-in-polygon algorithm.
  static bool _pointInPolygon(
      double lat, double lng, List<List<double>> polygon) {
    bool inside = false;
    final n = polygon.length;
    for (int i = 0, j = n - 1; i < n; j = i++) {
      final latI = polygon[i][0], lngI = polygon[i][1];
      final latJ = polygon[j][0], lngJ = polygon[j][1];

      final intersects = ((lngI > lng) != (lngJ > lng)) &&
          (lat <
              (latJ - latI) * (lng - lngI) / (lngJ - lngI) + latI);
      if (intersects) inside = !inside;
    }
    return inside;
  }

  /// Shortest distance (meters) from [lat],[lng] to any edge of the
  /// polygon — used only for the tolerance buffer above.
  static double _distanceToPolygonEdgeMeters(
      double lat, double lng, List<List<double>> polygon) {
    double minDist = double.infinity;
    final n = polygon.length;
    for (int i = 0, j = n - 1; i < n; j = i++) {
      final d = _distanceToSegmentMeters(
        lat, lng,
        polygon[j][0], polygon[j][1],
        polygon[i][0], polygon[i][1],
      );
      if (d < minDist) minDist = d;
    }
    return minDist;
  }

  static double _distanceToSegmentMeters(
    double lat, double lng,
    double lat1, double lng1,
    double lat2, double lng2,
  ) {
    // Approximate by sampling the segment — accurate enough at campus
    // scale (tens/hundreds of meters) without needing full geodesic math.
    const steps = 20;
    double minDist = double.infinity;
    for (int k = 0; k <= steps; k++) {
      final t = k / steps;
      final sampleLat = lat1 + (lat2 - lat1) * t;
      final sampleLng = lng1 + (lng2 - lng1) * t;
      final d = Geolocator.distanceBetween(lat, lng, sampleLat, sampleLng);
      if (d < minDist) minDist = d;
    }
    return minDist;
  }

  /// For display purposes — how far outside the campus the student is,
  /// used to show a helpful message like the old "You are Xm away".
  /// Returns 0 if already inside.
  static double distanceOutsideCampusMeters(double lat, double lng) {
    if (isInsideCampus(lat, lng)) return 0;
    return _distanceToPolygonEdgeMeters(lat, lng, kCampusBoundary);
  }
}
