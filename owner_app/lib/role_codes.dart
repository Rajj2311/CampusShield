import 'dart:math';

/// Generates a role registration code such as "WARDEN-K7M2QX".
String generateRoleCode(String prefix) {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final r = Random.secure();
  final suffix = List.generate(6, (_) => chars[r.nextInt(chars.length)]).join();
  return '$prefix-$suffix';
}
