import 'package:cloud_firestore/cloud_firestore.dart';

/// Converts Firestore values to/from plain JSON for the owner's data editor.
/// Timestamps become {"_ts": millis}, GeoPoints {"_geo": [lat, lng]},
/// document references {"_ref": "path"}.
dynamic encodeValue(dynamic v) {
  if (v is Timestamp) return {'_ts': v.millisecondsSinceEpoch};
  if (v is GeoPoint) return {'_geo': [v.latitude, v.longitude]};
  if (v is DocumentReference) return {'_ref': v.path};
  if (v is Map) return v.map((k, val) => MapEntry(k.toString(), encodeValue(val)));
  if (v is List) return v.map(encodeValue).toList();
  return v;
}

dynamic decodeValue(dynamic v) {
  if (v is Map) {
    if (v.length == 1 && v['_ts'] is num) {
      return Timestamp.fromMillisecondsSinceEpoch((v['_ts'] as num).toInt());
    }
    if (v.length == 1 && v['_geo'] is List && (v['_geo'] as List).length == 2) {
      final g = v['_geo'] as List;
      return GeoPoint((g[0] as num).toDouble(), (g[1] as num).toDouble());
    }
    if (v.length == 1 && v['_ref'] is String) {
      return FirebaseFirestore.instance.doc(v['_ref'] as String);
    }
    return v.map((k, val) => MapEntry(k.toString(), decodeValue(val)));
  }
  if (v is List) return v.map(decodeValue).toList();
  return v;
}
