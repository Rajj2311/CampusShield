import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/tenant.dart';
import '../../widgets/ui.dart';
import 'subscription_card.dart';

/// College-wide settings: attendance window.
class AdminSettingsTab extends StatefulWidget {
  const AdminSettingsTab({super.key});
  @override
  State<AdminSettingsTab> createState() => _AdminSettingsTabState();
}

class _AdminSettingsTabState extends State<AdminSettingsTab> {
  late int _start = Tenant.attendanceStartHour;
  late int _end = Tenant.attendanceEndHour;
  bool _saving = false;
  String? _message;
  bool _isError = false;

  String _label(int h) {
    final h12 = h % 12 == 0 ? 12 : h % 12;
    final suffix = (h >= 12 && h < 24) ? 'PM' : 'AM';
    return '$h12:00 $suffix';
  }

  Future<void> _save() async {
    if (_end <= _start) {
      setState(() {
        _message = 'The end time must be after the start time.';
        _isError = true;
      });
      return;
    }
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      await Tenant.doc.update({
        'attendanceStartHour': _start,
        'attendanceEndHour': _end,
      });
      await Tenant.reload();
      _message = 'Settings saved.';
      _isError = false;
    } on FirebaseException {
      _message = 'Could not save the settings.';
      _isError = true;
    }
    if (mounted) setState(() => _saving = false);
  }

  Widget _hourPicker(String label, int value, ValueChanged<int> onChanged) {
    return Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
        const SizedBox(height: 4),
        DropdownButtonFormField<int>(
          initialValue: value,
          items: List.generate(24, (i) => i)
              .map((h) => DropdownMenuItem(value: h, child: Text(_label(h))))
              .toList(),
          onChanged: (v) => onChanged(v ?? value),
          decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none)),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text('Settings',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kNavy)),
      const SizedBox(height: 16),
      SectionCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Daily attendance window',
              style: TextStyle(fontWeight: FontWeight.bold, color: kNavy)),
          const SizedBox(height: 4),
          const Text('Students can mark attendance only during this time.',
              style: TextStyle(color: Colors.black54, fontSize: 12)),
          const SizedBox(height: 12),
          Row(children: [
            _hourPicker('From', _start, (v) => setState(() => _start = v)),
            const SizedBox(width: 12),
            _hourPicker('Until', _end, (v) => setState(() => _end = v)),
          ]),
        ]),
      ),
      if (_message != null)
        _isError
            ? ErrorBanner(_message!)
            : Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(_message!,
                    style: const TextStyle(color: Color(0xFF2E7D32))),
              ),
      PrimaryButton(label: 'SAVE', loading: _saving, onPressed: _save),
      const SizedBox(height: 20),
      const SubscriptionCard(),
      const SizedBox(height: 20),
      SectionCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Campus boundary',
              style: TextStyle(fontWeight: FontWeight.bold, color: kNavy)),
          const SizedBox(height: 4),
          Text(
              Tenant.geofence == null
                  ? 'No boundary set. A default boundary is used. Contact CampusShield support to set your campus boundary.'
                  : 'Boundary set (${Tenant.geofence!.length} points).',
              style: const TextStyle(color: Colors.black54, fontSize: 12)),
        ]),
      ),
    ]);
  }
}
