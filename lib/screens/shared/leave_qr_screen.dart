import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';

class LeaveQRScreen extends StatelessWidget {
  final Map<String, dynamic> leaveData;
  final String leaveId;
  const LeaveQRScreen({super.key, required this.leaveData, required this.leaveId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A3A5C),
      appBar: AppBar(backgroundColor: const Color(0xFF1A3A5C), elevation: 0,
        title: const Text('Gate Pass', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white)),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('leaveRequests').doc(leaveId).snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: Colors.white));
          final d = snap.data!.data() as Map<String, dynamic>;
          final gateStatus = d['gateStatus'] ?? 'ready';
          final qrToken = d['qrToken'] ?? '';
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: QrImageView(data: qrToken, version: QrVersions.auto, size: 220)),
                const SizedBox(height: 24),
                Text(d['name'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Room ${d['room'] ?? ''}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: gateStatus == 'completed' ? const Color(0xFF2E7D32) :
                           gateStatus == 'out' ? const Color(0xFFF0A500) : Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    gateStatus == 'completed' ? 'LEAVE COMPLETED' :
                    gateStatus == 'out' ? 'CURRENTLY OUT' : 'SHOW THIS AT THE GATE',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                const SizedBox(height: 24),
                if (d['exitTime'] != null) Text('Exit: ${d['exitTime']}', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                if (d['returnTime'] != null) Text('Return: ${d['returnTime']}', style: const TextStyle(color: Colors.white60, fontSize: 12)),
              ]),
            ),
          );
        }),
    );
  }
}

