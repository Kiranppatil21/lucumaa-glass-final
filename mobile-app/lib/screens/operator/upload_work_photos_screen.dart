import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/network/app_exception.dart';
import '../../providers/uploads/upload_providers.dart';
import '../../widgets/primary_button.dart';

class UploadWorkPhotosScreen extends ConsumerStatefulWidget {
  const UploadWorkPhotosScreen({super.key});

  @override
  ConsumerState<UploadWorkPhotosScreen> createState() => _UploadWorkPhotosScreenState();
}

class _UploadWorkPhotosScreenState extends ConsumerState<UploadWorkPhotosScreen> {
  File? _selected;
  bool _uploading = false;

  Future<void> _pick() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (x == null) return;
    setState(() => _selected = File(x.path));
  }

  Future<void> _upload() async {
    final file = _selected;
    if (file == null) return;
    setState(() => _uploading = true);
    try {
      await ref.read(uploadServiceProvider).uploadWorkPhoto(file);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploaded')));
      setState(() => _selected = null);
    } catch (e) {
      final ex = AppException.fromDio(e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ex.message)));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Work Photos')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_selected != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_selected!, height: 240, width: double.infinity, fit: BoxFit.cover),
              )
            else
              Container(
                height: 240,
                width: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: const Text('No photo selected'),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _uploading ? null : _pick,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Take Photo'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    label: 'Upload',
                    isLoading: _uploading,
                    onPressed: (_selected == null || _uploading) ? null : _upload,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
