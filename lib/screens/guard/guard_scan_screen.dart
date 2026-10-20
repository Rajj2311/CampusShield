import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../utils/tenant.dart';

class GuardScanScreen extends StatefulWidget {
  final String guardName;
  const GuardScanScreen({super.key, this.guardName = 'Guard'});
  @override
  State<GuardScanScreen> createState() => _GuardScanScreenState();
}

class _GuardScanScreenState extends State<GuardScanScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool    _isProcessing  = false;
  String? _resultMessage;
  Color   _resultColor   = Colors.green;
  IconData _resultIcon   = Icons.qr_code_scanner;

  Future<void> _handleScan(String qrToken) async {
    // Skip if already processing
    if (_isProcessing) return;

    // Stop the scanner immediately to prevent double scans
    await _controller.stop();
    setState(() { _isProcessing = true; _resultMessage = null; });

    try {
      final snap = await Tenant.col('leaveRequests')
          .where('qrToken', isEqualTo: qrToken)
          .limit(1).get();

      if (snap.docs.isEmpty) {
        _showResult('INVALID PASS\nQR code not recognized.',
          const Color(0xFFC62828), Icons.cancel);
        return;
      }

      final doc        = snap.docs.first;
      final d          = doc.data();
      final gateStatus = d['gateStatus'] ?? 'ready';
      final now        = DateTime.now();
      final timeStr    =
          '${now.hour}:${now.minute.toString().padLeft(2,'0')}';
      final dateStr    =
          '${now.day.toString().padLeft(2,'0')}/'
          '${now.month.toString().padLeft(2,'0')}/'
          '${now.year}';

      if (gateStatus == 'completed') {
        _showResult('ALREADY CLOSED\nThis leave has been completed.',
          const Color(0xFFC62828), Icons.cancel);
        return;
      }

      if (gateStatus == 'pending_warden_approval') {
        _showResult('PENDING WARDEN APPROVAL.',
          const Color(0xFFF0A500), Icons.hourglass_top);
        return;
      }

      if (gateStatus == 'ready') {
        // ── FIRST SCAN = EXIT ──────────────────────────────
        await Tenant.col('leaveRequests').doc(doc.id).update({
          'gateStatus':    'out',
          'exitTime':      timeStr,
          'exitDate':      dateStr,
          'exitTimestamp': FieldValue.serverTimestamp(),
          'guardIdExit':   widget.guardName,
        });

        // Set the student's attendance to 'leave'
        await Tenant.col('students')
            .where('roll', isEqualTo: d['roll'])
            .limit(1).get()
            .then((s) {
          if (s.docs.isNotEmpty) {
            s.docs.first.reference.update({'todayStatus': 'leave'});
          }
        });

        await _logActivity(doc.id, d, 'EXIT', timeStr, dateStr);

        _showResult(
          'EXIT APPROVED ✅\n'
          '${d['name']}\n'
          'Room ${d['room']}\n'
          'Time: $timeStr',
          const Color(0xFF2E7D32), Icons.check_circle);

      } else if (gateStatus == 'out') {
        // ── SECOND SCAN = RETURN ───────────────────────────

        // Check for late return
        final toTimestamp = d['toTimestamp'] as int?;
        bool isLate = false;
        if (toTimestamp != null) {
          final toDate = DateTime.fromMillisecondsSinceEpoch(toTimestamp);
          final endOfDay = DateTime(
            toDate.year, toDate.month, toDate.day, 23, 59, 59);
          isLate = now.isAfter(endOfDay);
        }

        if (isLate) {
          // Late return — warden approval 
          await _sendWardenApproval(doc.id, d, 'late_return', timeStr, dateStr);
          _showResult(
            'LATE RETURN ⚠️\n'
            '${d['name']}\n'
            'Leave was till ${d['to']}\n'
            'Warden approval required.',
            const Color(0xFFF0A500), Icons.warning_amber);
        } else {
          // Normal return: complete directly
          String duration = '';
          final exitTs = d['exitTimestamp'];
          if (exitTs != null) {
            final exitTime = (exitTs as Timestamp).toDate();
            final diff = now.difference(exitTime);
            final hours   = diff.inHours;
            final minutes = diff.inMinutes % 60;
            duration = hours > 0
                ? '${hours}h ${minutes}m'
                : '${minutes}m';
          }

          await Tenant.col('leaveRequests').doc(doc.id).update({
            'gateStatus':      'completed',
            'returnTime':      timeStr,
            'returnDate':      dateStr,
            'returnTimestamp': FieldValue.serverTimestamp(),
            'guardIdReturn':   widget.guardName,
            'duration':        duration,
          });

          // ── Student attendance after return = 'absent'   ─
          await Tenant.col('students')
              .where('roll', isEqualTo: d['roll'])
              .limit(1).get()
              .then((s) {
            if (s.docs.isNotEmpty) {
              s.docs.first.reference.update({'todayStatus': 'absent'});
            }
          });

          await _logActivity(doc.id, d, 'RETURN', timeStr, dateStr);

          _showResult(
            'RETURN LOGGED ✅\n'
            '${d['name']}\n'
            'Room ${d['room']}\n'
            '${duration.isNotEmpty ? 'Duration: $duration' : 'Time: $timeStr'}',
            const Color(0xFF1565C0), Icons.check_circle);
        }
      } else {
        _showResult(
          'UNKNOWN STATUS\n${d['name']}\nStatus: $gateStatus',
          const Color(0xFFC62828), Icons.error);
      }

    } catch (e) {
      _showResult('ERROR\n${e.toString()}',
        const Color(0xFFC62828), Icons.error);
    }
  }

  void _showResult(String message, Color color, IconData icon) {
    if (!mounted) return;
    setState(() {
      _resultMessage = message;
      _resultColor   = color;
      _resultIcon    = icon;
      _isProcessing  = false;
    });

    // After 4 seconds, hide the result and resume the scanner
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() => _resultMessage = null);
      _controller.start();
    });
  }

  Future<void> _sendWardenApproval(String docId,
      Map<String, dynamic> d, String type,
      String timeStr, String dateStr) async {
    final block = d['block'] ?? d['hostelBlock'] ?? '';

    await Tenant.col('leaveRequests').doc(docId).update({
      'gateStatus':           'pending_warden_approval',
      'approvalType':         type,
      'guardScanTime':        timeStr,
      'guardScanDate':        dateStr,
      'guardName':            widget.guardName,
      'wardenApprovalStatus': 'pending',
    });

    final wardenSnap = await Tenant.col('wardens')
        .where('hostelBlock', isEqualTo: block)
        .limit(1).get();

    if (wardenSnap.docs.isNotEmpty) {
      final wardenId = wardenSnap.docs.first.id;
      await Tenant.col('notifications')
          .doc(wardenId)
          .collection('items').add({
        'title':     '⚠️ Gate Approval Required',
        'body':      '${d['name']} (Room ${d['room']}) — '
                     'Leave was valid untill ${d['to']}. '
                     'The Guard Scan at $timeStr ',
        'type':      'gate_approval',
        'relatedId': docId,
        'isRead':    false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await _logActivity(docId, d,
      type == 'late_return' ? 'LATE_RETURN' : 'EXPIRED',
      timeStr, dateStr);
  }

  Future<void> _logActivity(String docId, Map<String, dynamic> d,
      String action, String timeStr, String dateStr) async {
    await Tenant.col('gateHistory').add({
      'studentName': d['name'],
      'roll':        d['roll'],
      'room':        d['room'],
      'hostelBlock': d['block'] ?? d['hostelBlock'] ?? '',
      'action':      action,
      'time':        timeStr,
      'date':        dateStr,
      'guardName':   widget.guardName,
      'leaveId':     docId,
      'createdAt':   FieldValue.serverTimestamp(),
    });

    await Tenant.col('activity').add({
      'title':
          'Gate $action: ${d['name']} (Room ${d['room']}) — $timeStr',
      'time':      'Just now',
      'type':      'gate',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A3A5C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3A5C), elevation: 0,
        title: const Text('Scan Gate Pass', style: TextStyle(
          color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white)),
      body: Stack(children: [

        // Camera
        MobileScanner(
          controller: _controller,
          onDetect: (capture) {
            final barcodes = capture.barcodes;
            if (barcodes.isNotEmpty &&
                barcodes.first.rawValue != null &&
                !_isProcessing) {
              _handleScan(barcodes.first.rawValue!);
            }
          }),

        // Scan frame
        Center(child: Container(
          width: 260, height: 260,
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFFF0A500), width: 3),
            borderRadius: BorderRadius.circular(20)))),

        // Instruction
        Positioned(top: 40, left: 0, right: 0,
          child: Center(child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20)),
            child: const Text('Place QR code inside the frame',
              style: TextStyle(color: Colors.white, fontSize: 13))))),

        // Processing indicator
        if (_isProcessing && _resultMessage == null)
          const Center(child: CircularProgressIndicator(
            color: Color(0xFFF0A500))),

        // Result card
        if (_resultMessage != null)
          Positioned(bottom: 40, left: 20, right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _resultColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 12)]),
              child: Column(children: [
                Icon(_resultIcon, color: Colors.white, size: 36),
                const SizedBox(height: 8),
                Text(_resultMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.bold, fontSize: 15)),
              ]))),
      ]),
    );
  }
}