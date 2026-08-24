import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../utils/campus_geofence_helper.dart';

class StudentAttendanceScreen extends StatefulWidget {
  final String studentId;
  final Map<String, dynamic> studentData;
  const StudentAttendanceScreen({super.key, required this.studentId, required this.studentData});
  @override
  State<StudentAttendanceScreen> createState() => _StudentAttendanceScreenState();
}
class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  // Campus boundary geofence now lives in CampusGeofenceHelper
  // (see lib/utils/campus_geofence_helper.dart)

  bool _isLoading = false;
  String? _message;
  bool _isSuccess = false;
  XFile? _capturedImage;

  bool _isAttendanceTime() {
    final now = DateTime.now();
    return now.hour == 20 || (now.hour == 20 && now.minute >= 0) && now.hour < 21;
    // 8 PM to 9 PM
  }

  Future<void> _markAttendance() async {
    // Time check
    final now = DateTime.now();
    if (now.hour < 20 || now.hour >= 21) {
      setState(() { _message = '⏰ Attendance can only be marked between 8:00 PM and 9:00 PM!'; _isSuccess = false; });
      return;
    }

    // Check already marked today
    final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final existing = await FirebaseFirestore.instance
        .collection('attendanceRecords')
        .where('studentId', isEqualTo: widget.studentId)
        .where('date', isEqualTo: today)
        .get();
    if (existing.docs.isNotEmpty) {
      setState(() { _message = "✅ Today's attendance has already been marked!"; _isSuccess = true; });
      return;
    }

    setState(() { _isLoading = true; _message = null; });

    try {
      // Location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() { _message = '❌ Location permission denied. Please allow it from Settings.'; _isSuccess = false; _isLoading = false; });
        return;
      }

      // Get location
      // Note: web browsers (especially desktops without a GPS chip) can
      // take a long time or never resolve when asking for GPS-level
      // "high" accuracy — always set a timeLimit so this can never hang
      // forever, and ask for a more realistic accuracy level on web.
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: kIsWeb ? LocationAccuracy.medium : LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      // Detect fake/mock GPS location
if (position.isMocked) {
  setState(() {
    _message = '❌ Fake/Mock location detected!\nPlease disable mock location apps.';
    _isSuccess = false;
    _isLoading = false;
  });
  return;
}
      final isInside = CampusGeofenceHelper.isInsideCampus(position.latitude, position.longitude);

      if (!isInside) {
        final outsideBy = CampusGeofenceHelper.distanceOutsideCampusMeters(position.latitude, position.longitude);
        setState(() {
          _message = '❌ You are ${outsideBy.toStringAsFixed(0)}m outside the campus boundary!\nYou must be inside the campus to mark attendance.';
          _isSuccess = false; _isLoading = false;
        });
        return;
      }

      // Capture photo
      final picker = ImagePicker();
      final photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 50);
      if (photo == null) {
        setState(() { _message = '❌ Taking a photo is required for attendance!'; _isSuccess = false; _isLoading = false; });
        return;
      }
      setState(() => _capturedImage = photo);

      // Save attendance
      await FirebaseFirestore.instance.collection('attendanceRecords').add({
        'studentId': widget.studentId,
        'studentName': widget.studentData['name'],
        'roll': widget.studentData['roll'],
        'room': widget.studentData['room'],
        'date': today,
        'time': '${now.hour}:${now.minute.toString().padLeft(2, '0')}',
        'latitude': position.latitude,
        'longitude': position.longitude,
        'insideCampus': true,
        'status': 'present',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update today status
      await FirebaseFirestore.instance.collection('students').doc(widget.studentId).update({'todayStatus': 'present'});

      setState(() { _message = '✅ Attendance marked successfully! You are inside the campus.'; _isSuccess = true; });
    } catch (e) {
      String msg = '❌ Error: ${e.toString()}';
      if (e is TimeoutException) {
        msg = '❌ Location request timed out.\nPlease make sure location/GPS is turned on and try again.';
      } else if (e.toString().toLowerCase().contains('timeout')) {
        msg = '❌ Location request timed out.\nPlease make sure location/GPS is turned on and try again.';
      }
      setState(() { _message = msg; _isSuccess = false; });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isTime = now.hour >= 20 && now.hour < 21;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(backgroundColor: const Color(0xFF1A3A5C),
        title: const Text('Mark Attendance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          // Time window info
          Container(padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isTime ? const Color(0xFFE8F5E9) : const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Icon(isTime ? Icons.check_circle : Icons.access_time,
                color: isTime ? const Color(0xFF2E7D32) : const Color(0xFFF0A500), size: 24),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(isTime ? 'Attendance Window Open! ✅' : 'Attendance Window Closed',
                  style: TextStyle(fontWeight: FontWeight.bold,
                    color: isTime ? const Color(0xFF2E7D32) : const Color(0xFFF0A500))),
                Text('Time: 8:00 PM – 9:00 PM only', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text('Current time: ${now.hour}:${now.minute.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ])),
            ])),
          const SizedBox(height: 16),

          // Location info
          Container(padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Icon(Icons.location_on, color: Color(0xFF1A3A5C)), SizedBox(width: 8),
                Text('Location Requirements', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A3A5C))),
              ]),
              const SizedBox(height: 8),
              const Text('📍 IILM University, Greater Noida', style: TextStyle(fontSize: 13)),
              const Text('📏 Must be inside campus boundary', style: TextStyle(fontSize: 13)),
              const Text('📸 Photo proof required', style: TextStyle(fontSize: 13)),
              const Text('🧑\u200d💻 Live face verification required', style: TextStyle(fontSize: 13)),
            ])),
          const SizedBox(height: 16),

          // Captured image preview
          if (_capturedImage != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: kIsWeb
                  ? Image.network(_capturedImage!.path, height: 200, width: double.infinity, fit: BoxFit.cover)
                  : Image.file(io.File(_capturedImage!.path), height: 200, width: double.infinity, fit: BoxFit.cover)),
            const SizedBox(height: 16),
          ],

          // Message
          if (_message != null) Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _isSuccess ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(12)),
            child: Text(_message!, style: TextStyle(
              color: _isSuccess ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
              fontWeight: FontWeight.w500))),
          const SizedBox(height: 20),

          // Mark button
          SizedBox(width: double.infinity, height: 56,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _markAttendance,
              icon: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.camera_alt, color: Colors.white),
              label: Text(_isLoading ? 'Processing...' : 'MARK ATTENDANCE',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
              style: ElevatedButton.styleFrom(
                backgroundColor: isTime ? const Color(0xFF2E7D32) : Colors.grey,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))))),

          const SizedBox(height: 20),
          // Attendance history
          const Align(alignment: Alignment.centerLeft,
            child: Text('Attendance History', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A3A5C)))),
          const SizedBox(height: 10),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('attendanceRecords')
                .where('studentId', isEqualTo: widget.studentId)
                .orderBy('createdAt', descending: true)
                .limit(10)
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData || snap.data!.docs.isEmpty) {
                return const Text('No attendance records yet.', style: TextStyle(color: Colors.grey));
              }
              return Column(children: snap.data!.docs.map((doc) {
                final d = doc.data() as Map<String, dynamic>;
                return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)]),
                  child: Row(children: [
                    const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(d['date'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      Text(
                        d.containsKey('distance')
                          ? 'Time: ${d['time'] ?? ''}  •  Distance: ${(d['distance'] ?? 0).toStringAsFixed(0)}m'
                          : 'Time: ${d['time'] ?? ''}  •  ${d['insideCampus'] == true ? 'Inside campus ✓' : ''}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ])),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
                      child: const Text('Present', style: TextStyle(color: Color(0xFF2E7D32), fontSize: 11, fontWeight: FontWeight.w600))),
                  ]));
              }).toList());
            }),
        ]),
      ),
    );
  }
}

