// PhotosScreen: galería + añadir
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/progress_photo.dart';

class PhotosScreen extends ConsumerStatefulWidget {
  const PhotosScreen({super.key});
  @override
  ConsumerState<PhotosScreen> createState() => _PhotosScreenState();
}

class _PhotosScreenState extends ConsumerState<PhotosScreen> {
  String _filterPose = 'all';
  String? _selectedId1;
  String? _selectedId2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Galería'),
        actions: [
          if (_selectedId1 != null && _selectedId2 != null)
            IconButton(
              icon: const Icon(Icons.compare),
              onPressed: () => context.push('/progress/compare', extra: {'id1': _selectedId1, 'id2': _selectedId2}),
            ),
        ],
      ),
      body: FutureBuilder<List<ProgressPhoto>>(
        future: ref.read(photoRepoProvider).all(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snap.data!;
          final filtered = _filterPose == 'all' ? all : all.where((p) => p.pose == _filterPose).toList();
          return Column(
            children: [
              _poseFilter(),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text(
                            'Sin fotos. Añade tu primera foto de progreso con el botón +',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white60),
                          ),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final photo = filtered[i];
                          final isSelected = photo.id == _selectedId1 || photo.id == _selectedId2;
                          return GestureDetector(
                            onLongPress: () => _toggleSelect(photo.id),
                            onTap: () {
                              if (_selectedId1 != null && _selectedId2 == null && _selectedId1 != photo.id) {
                                setState(() => _selectedId2 = photo.id);
                              } else if (_selectedId1 == null) {
                                setState(() => _selectedId1 = photo.id);
                              } else {
                                setState(() {
                                  _selectedId1 = photo.id;
                                  _selectedId2 = null;
                                });
                              }
                            },
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      File(photo.imagePath),
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: AppTheme.surfaceMid,
                                        child: const Icon(Icons.broken_image, color: Colors.white60),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 4,
                                  left: 4,
                                  right: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      DateFormat('dd/MM/yy').format(photo.date),
                                      style: const TextStyle(color: Colors.white, fontSize: 10),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: AppTheme.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.check, size: 14, color: Colors.black),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addPhoto,
        icon: const Icon(Icons.add_a_photo),
        label: const Text('Añadir'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.black,
      ),
    );
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selectedId1 == id) {
        _selectedId1 = null;
      } else if (_selectedId2 == id) {
        _selectedId2 = null;
      } else if (_selectedId1 == null) {
        _selectedId1 = id;
      } else if (_selectedId2 == null) {
        _selectedId2 = id;
      } else {
        _selectedId1 = id;
        _selectedId2 = null;
      }
    });
  }

  Widget _poseFilter() {
    Widget chip(String label, String value) {
      final selected = _filterPose == value;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: FilterChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => setState(() => _filterPose = value),
        ),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          chip('Todas', 'all'),
          chip('Frente', 'front'),
          chip('Lado', 'side'),
          chip('Espalda', 'back'),
        ],
      ),
    );
  }

  Future<void> _addPhoto() async {
    final source = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Cámara'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galería'),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (picked == null) return;

    // copiar a app dir permanente
    final docs = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(docs.path, 'photos'));
    if (!await photosDir.exists()) await photosDir.create(recursive: true);
    final dest = p.join(photosDir.path, '${DateTime.now().millisecondsSinceEpoch}_${p.basename(picked.path)}');
    await File(picked.path).copy(dest);

    // preguntar pose
    final pose = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Pose'),
        children: [
          SimpleDialogOption(onPressed: () => Navigator.pop(context, 'front'), child: const Text('Frente')),
          SimpleDialogOption(onPressed: () => Navigator.pop(context, 'side'), child: const Text('Lado')),
          SimpleDialogOption(onPressed: () => Navigator.pop(context, 'back'), child: const Text('Espalda')),
        ],
      ),
    );
    if (pose == null) return;
    await ref.read(photoRepoProvider).add(
      imagePath: dest,
      pose: pose,
      date: DateTime.now(),
    );
    if (mounted) setState(() {});
  }
}
