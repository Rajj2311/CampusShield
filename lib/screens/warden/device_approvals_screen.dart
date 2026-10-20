import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/warden_helper.dart';
import '../../utils/tenant.dart';

class DeviceApprovalsScreen extends StatefulWidget {
  const DeviceApprovalsScreen({super.key});
  @override
  State<DeviceApprovalsScreen> createState() =>
      _DeviceApprovalsScreenState();
}

class _DeviceApprovalsScreenState
    extends State<DeviceApprovalsScreen> {
  String? _wardenHostel;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final h = await WardenHelper.getMyHostel();
    setState(() => _wardenHostel = h);
  }

  Future<void> _approve(String reqId, String studentId,
      String newDeviceId, String newDeviceName) async {
    final batch = FirebaseFirestore.instance.batch();

    // Update the student's device
    batch.update(
      Tenant.col('students').doc(studentId),
      {
        'boundDeviceId':   newDeviceId,
        'boundDeviceName': newDeviceName,
        'deviceBoundAt':   FieldValue.serverTimestamp(),
      });

    // Close the request
    batch.update(
      Tenant.col('deviceChangeRequests').doc(reqId),
      {
        'status':     'approved',
        'resolvedAt': FieldValue.serverTimestamp(),
      });

    await batch.commit();

    // Notify the student
    await Tenant.col('notifications')
        .doc(studentId)
        .collection('items').add({
      'title':     '✅ Device Change Approved!',
      'body':      'Your new device has been approved. '
                   'You can now log in.',
      'type':      'device_request',
      'isRead':    false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Device approved!'),
        backgroundColor: Color(0xFF2E7D32)));
  }

  Future<void> _reject(String reqId, String studentId) async {
    await Tenant.col('deviceChangeRequests').doc(reqId).update({
      'status':     'rejected',
      'resolvedAt': FieldValue.serverTimestamp(),
    });

    await Tenant.col('notifications')
        .doc(studentId)
        .collection('items').add({
      'title':     '❌ Device Change Rejected',
      'body':      'The warden has not approved the new device. '
                   'Log in using your previous device.',
      'type':      'device_request',
      'isRead':    false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('❌ Device request rejected.'),
        backgroundColor: Color(0xFFC62828)));
  }

  @override
  Widget build(BuildContext context) {
    if (_wardenHostel == null) return const Scaffold(
      body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3A5C),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          const Text('Device Approvals', style: TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold,
            fontSize: 16)),
          Text(_wardenHostel!, style: const TextStyle(
            color: Color(0xFFF0A500), fontSize: 11)),
        ]),
        iconTheme: const IconThemeData(color: Colors.white)),
      body: StreamBuilder<QuerySnapshot>(
        stream: Tenant.col('deviceChangeRequests')
            .where('block', isEqualTo: _wardenHostel)
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(
            child: CircularProgressIndicator());

          if (snap.data!.docs.isEmpty) return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              Icon(Icons.smartphone_outlined,
                size: 64, color: Colors.grey),
              SizedBox(height: 12),
              Text('No pending device requests.',
                style: TextStyle(color: Colors.grey, fontSize: 14)),
              SizedBox(height: 6),
              Text('All students are logged in using their registered devices.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center),
            ]));

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: snap.data!.docs.length,
            itemBuilder: (context, i) {
              final doc = snap.data!.docs[i];
              final d   = doc.data() as Map<String, dynamic>;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFF0A500).withOpacity(0.5)),
                  boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8)]),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                    // Student info
                    Row(children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFF1A3A5C)
                            .withOpacity(0.1),
                        child: const Icon(Icons.person,
                          color: Color(0xFF1A3A5C))),
                      const SizedBox(width: 10),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        Text(d['studentName'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                        Text('${d['roll']}  •  Room ${d['room']}',
                          style: const TextStyle(
                            fontSize: 12, color: Colors.grey)),
                      ])),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0A500)
                              .withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10)),
                        child: const Text('Pending',
                          style: TextStyle(
                            color: Color(0xFFF0A500),
                            fontSize: 11,
                            fontWeight: FontWeight.bold))),
                    ]),
                    const SizedBox(height: 14),

                    // Device comparison
                    Row(children: [
                      // Old device
                      Expanded(child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(10)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                          const Row(children: [
                            Icon(Icons.phonelink_off,
                              size: 14, color: Color(0xFFC62828)),
                            SizedBox(width: 4),
                            Text('Old Device',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFFC62828),
                                fontWeight: FontWeight.bold)),
                          ]),
                          const SizedBox(height: 4),
                          Text(d['oldDeviceName'] ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500)),
                        ])),),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward,
                        color: Colors.grey, size: 16),
                      const SizedBox(width: 8),
                      // New device
                      Expanded(child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(10)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                          const Row(children: [
                            Icon(Icons.smartphone,
                              size: 14, color: Color(0xFF2E7D32)),
                            SizedBox(width: 4),
                            Text('New Device',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF2E7D32),
                                fontWeight: FontWeight.bold)),
                          ]),
                          const SizedBox(height: 4),
                          Text(d['newDeviceName'] ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500)),
                        ]))),
                    ]),
                    const SizedBox(height: 12),

                    // Warning
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(8)),
                      child: const Row(children: [
                        Icon(Icons.warning_amber,
                          size: 14, color: Color(0xFFF0A500)),
                        SizedBox(width: 6),
                        Expanded(child: Text(
                          'Approve this request only if the student has contacted you personally. '
                          'Proxy attendance may occur.',
                          style: TextStyle(fontSize: 11,
                            color: Color(0xFF8B6900)))),
                      ])),
                    const SizedBox(height: 12),

                    // Buttons
                    Row(children: [
                      Expanded(child: ElevatedButton.icon(
                        onPressed: () => _reject(doc.id, d['studentId']),
                        icon: const Icon(Icons.block,
                          size: 16, color: Colors.white),
                        label: const Text('REJECT', style: TextStyle(
                          color: Colors.white, fontSize: 12,
                          fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC62828),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8))))),
                      const SizedBox(width: 10),
                      Expanded(child: ElevatedButton.icon(
                        onPressed: () => _approve(
                          doc.id,
                          d['studentId'],
                          d['newDeviceId'],
                          d['newDeviceName']),
                        icon: const Icon(Icons.check,
                          size: 16, color: Colors.white),
                        label: const Text('APPROVE', style: TextStyle(
                          color: Colors.white, fontSize: 12,
                          fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8))))),
                    ]),
                  ])));
            });
        }),
    );
  }
}