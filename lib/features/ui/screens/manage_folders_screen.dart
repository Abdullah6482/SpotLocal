import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/database/db_helper.dart';
import '../../../core/models/scan_folder.dart';
import '../../scanner/models/scan_result.dart';
import '../../scanner/providers/scanner_provider.dart';
import '../theme/app_theme.dart';

class ManageFoldersScreen extends ConsumerStatefulWidget {
  const ManageFoldersScreen({super.key});

  @override
  ConsumerState<ManageFoldersScreen> createState() => _ManageFoldersScreenState();
}

class _ManageFoldersScreenState extends ConsumerState<ManageFoldersScreen> {
  List<ScanFolder> _folders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    final folders = await DbHelper().getScanFolders();
    if (mounted) {
      setState(() {
        _folders = folders;
        _isLoading = false;
      });
    }
  }

  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      await Permission.audio.request();
      await Permission.storage.request();

      if (await Permission.manageExternalStorage.isDenied ||
          await Permission.manageExternalStorage.isRestricted) {
        await Permission.manageExternalStorage.request();
      }
    }
    return true;
  }

  Future<void> _pickAndAddFolder() async {
    try {
      await _requestPermissions();

      final selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory != null && selectedDirectory.isNotEmpty) {
        final normalizedPath = normalizeFolderPath(selectedDirectory);

        await DbHelper().insertScanFolder(normalizedPath);
        await _loadFolders();

        if (mounted) {
          ref.read(scannerStateProvider.notifier).startScan(
            targetFolderPaths: [normalizedPath],
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Scanning: $normalizedPath'),
              backgroundColor: AppColors.card,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not pick folder: $e'),
            backgroundColor: Colors.red.shade900,
          ),
        );
      }
    }
  }

  Future<void> _toggleFolder(ScanFolder folder) async {
    if (folder.id == null) return;
    await DbHelper().toggleScanFolder(folder.id!, !folder.isEnabled);
    await _loadFolders();
    if (mounted) {
      ref.read(libraryVersionProvider.notifier).state++;
    }
  }

  Future<void> _deleteFolder(ScanFolder folder) async {
    if (folder.id == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Remove Scan Folder?', style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Tracks under "${folder.path}" will be removed from your SpotLocal library.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DbHelper().deleteScanFolder(folder.id!);
      await _loadFolders();
      if (mounted) {
        ref.read(libraryVersionProvider.notifier).state++;
      }
    }
  }

  void _showErrorDetails(List<ScanError> errors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Scan Log / Diagnostics', style: TextStyle(color: AppColors.textPrimary)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: errors.length,
            itemBuilder: (context, index) {
              final err = errors[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '• ${err.filePath}: ${err.errorMessage}',
                  style: const TextStyle(color: Colors.orangeAccent, fontSize: 12),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close', style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scannerState = ref.watch(scannerStateProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Manage Scan Folders'),
        backgroundColor: AppColors.background,
        actions: [
          if (scannerState.errors.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
              onPressed: () => _showErrorDetails(scannerState.errors),
            ),
        ],
      ),
      body: Column(
        children: [
          if (scannerState.status == ScanStatus.scanning)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Scanning Folders in Background...',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${scannerState.processedFiles}/${scannerState.totalFilesFound}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: scannerState.progressPercentage,
                    backgroundColor: AppColors.surfaceLight,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                  ),
                ],
              ),
            ),

          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, color: AppColors.accent, size: 22),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'SpotLocal scans ONLY your saved folders. WhatsApp voice notes and ringtones are strictly excluded.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.3),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                : _folders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.folder_off_outlined, color: AppColors.textSecondary, size: 56),
                            const SizedBox(height: 16),
                            const Text(
                              'No Scan Folders Configured',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Tap the button below to pick a folder from storage.',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _folders.length,
                        itemBuilder: (context, index) {
                          final folder = _folders[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            child: ListTile(
                              leading: Icon(
                                Icons.folder,
                                color: folder.isEnabled ? AppColors.accent : AppColors.textSecondary,
                                size: 32,
                              ),
                              title: Text(
                                folder.path,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: folder.isEnabled ? AppColors.textPrimary : AppColors.textSecondary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.sync, color: AppColors.accent, size: 20),
                                    onPressed: () {
                                      ref.read(scannerStateProvider.notifier).startScan(
                                        targetFolderPaths: [folder.path],
                                      );
                                    },
                                  ),
                                  Switch(
                                    value: folder.isEnabled,
                                    activeColor: AppColors.accent,
                                    onChanged: (_) => _toggleFolder(folder),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
                                    onPressed: () => _deleteFolder(folder),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          icon: const Icon(Icons.add, size: 22),
          label: const Text(
            'Add Scan Folder',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          onPressed: _pickAndAddFolder,
        ),
      ),
    );
  }
}
