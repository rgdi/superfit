// PhotoCompareScreen: comparar dos fotos lado a lado
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/progress_photo.dart';

class PhotoCompareScreen extends ConsumerWidget {
  final String photoId1;
  final String photoId2;
  const PhotoCompareScreen({super.key, required this.photoId1, required this.photoId2});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Comparar')),
      body: FutureBuilder<List<ProgressPhoto?>>(
        future: Future.wait([
          ref.read(photoRepoProvider).byId(photoId1),
          ref.read(photoRepoProvider).byId(photoId2),
        ]),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final p1 = snap.data![0];
          final p2 = snap.data![1];
          if (p1 == null || p2 == null) {
            return const Center(child: Text('Foto no encontrada'));
          }
          // ordenar cronológicamente
          final first = p1.date.isBefore(p2.date) ? p1 : p2;
          final last = p1.date.isBefore(p2.date) ? p2 : p1;
          return Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(child: _photoSide(first, 'Antes')),
                    const VerticalDivider(width: 1, color: AppTheme.surfaceLight),
                    Expanded(child: _photoSide(last, 'Después')),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Diferencia: ${last.date.difference(first.date).inDays} días',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    if (last.weightKg != null && first.weightKg != null)
                      Text(
                        'Peso: ${first.weightKg!.toStringAsFixed(1)} → ${last.weightKg!.toStringAsFixed(1)} kg '
                        '(${last.weightKg! > first.weightKg! ? "+" : ""}${(last.weightKg! - first.weightKg!).toStringAsFixed(1)})',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    if (last.bodyFatPct != null && first.bodyFatPct != null)
                      Text(
                        '% Grasa: ${first.bodyFatPct!.toStringAsFixed(1)} → ${last.bodyFatPct!.toStringAsFixed(1)}%',
                        style: const TextStyle(color: Colors.white70),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _photoSide(ProgressPhoto photo, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          color: AppTheme.surfaceLight,
          child: Text(
            '$label · ${DateFormat('dd/MM/yy').format(photo.date)}',
            style: const TextStyle(fontSize: 11),
          ),
        ),
        Expanded(
          child: Image.file(
            File(photo.imagePath),
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, color: Colors.white60)),
          ),
        ),
      ],
    );
  }
}
