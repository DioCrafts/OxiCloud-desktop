import 'package:flutter/material.dart';

class MobileUploadSheet extends StatelessWidget {
  final VoidCallback onUploadFile;
  final VoidCallback onTakePhoto;
  final VoidCallback onCreateFolder;

  const MobileUploadSheet({
    super.key,
    required this.onUploadFile,
    required this.onTakePhoto,
    required this.onCreateFolder,
  });

  static Future<void> show({
    required BuildContext context,
    required VoidCallback onUploadFile,
    required VoidCallback onTakePhoto,
    required VoidCallback onCreateFolder,
  }) {
    return showModalBottomSheet(
      context: context,
      builder: (_) => MobileUploadSheet(
        onUploadFile: onUploadFile,
        onTakePhoto: onTakePhoto,
        onCreateFolder: onCreateFolder,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text('Upload file'),
              onTap: () {
                Navigator.pop(context);
                onUploadFile();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take photo'),
              onTap: () {
                Navigator.pop(context);
                onTakePhoto();
              },
            ),
            ListTile(
              leading: const Icon(Icons.create_new_folder_outlined),
              title: const Text('New folder'),
              onTap: () {
                Navigator.pop(context);
                onCreateFolder();
              },
            ),
          ],
        ),
      ),
    );
  }
}
