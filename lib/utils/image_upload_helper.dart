import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';

class ImageUploadHelper {
  static final _picker = ImagePicker();

  // Camera se photo lo
  static Future<XFile?> pickFromCamera() async {
    final xFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 60,
      maxWidth: 1080,
    );
    return xFile;
  }

  // Gallery se photo lo
  static Future<XFile?> pickFromGallery() async {
    final xFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,
      maxWidth: 1080,
    );
    return xFile;
  }

  // Firebase Storage pe upload karo
  static Future<String> uploadImage(XFile file, String folder) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = FirebaseStorage.instance.ref().child('$folder/$fileName');
    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      final task = await ref.putData(bytes);
      return await task.ref.getDownloadURL();
    } else {
      final task = await ref.putFile(io.File(file.path));
      return await task.ref.getDownloadURL();
    }
  }

  // Camera ya Gallery — user se choice lo
  static Future<XFile?> showPickerDialog(context) async {
    XFile? picked;
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 12),
        Container(width: 40, height: 4,
          decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        const Text('Upload Photo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ListTile(
          leading: Container(padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFF1A3A5C).withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.camera_alt, color: Color(0xFF1A3A5C))),
          title: const Text('Take Photo'),
          onTap: () async {
            picked = await pickFromCamera();
            Navigator.pop(context);
          }),
        ListTile(
          leading: Container(padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFF1A3A5C).withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.photo_library, color: Color(0xFF1A3A5C))),
          title: const Text('Choose from Gallery'),
          onTap: () async {
            picked = await pickFromGallery();
            Navigator.pop(context);
          }),
        const SizedBox(height: 16),
      ])),
    );
    return picked;
  }
}