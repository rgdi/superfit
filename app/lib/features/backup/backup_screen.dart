// Pantalla de backup: export/import JSON con preview
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../core/theme/app_theme.dart';
import '../../core/providers.dart';
import '../../data/repositories/backup_service.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  String? _lastExportPath;
  String? _lastImportName;
  bool _busy = false;

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      final db = await ref.read(databaseProvider.future);
      final service = BackupService(db);
      final file = await service.exportToJson();
      setState(() => _lastExportPath = file.path);
      final size = await file.length();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup creado: ${(size / 1024).toStringAsFixed(1)} KB'),
            backgroundColor: AppTheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    setState(() => _busy = true);
    try {
      final dir = await getApplicationDocumentsDirectory();
      final files = dir.listSync().whereType<File>().where((f) => f.path.contains('superfit-backup-')).toList()
        ..sort((a, b) => b.path.compareTo(a.path));
      if (files.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No hay backups disponibles')));
        }
        return;
      }
      // Mostrar lista
      final selected = await showDialog<File>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: const Text('Selecciona un backup'),
          children: files.take(10).map((f) {
            final name = p.basename(f.path);
            return SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, f),
              child: Text(name),
            );
          }).toList(),
        ),
      );
      if (selected == null) return;
      final db = await ref.read(databaseProvider.future);
      final service = BackupService(db);
      await service.importFromJson(selected);
      setState(() => _lastImportName = p.basename(selected.path));
      // Invalidar providers
      ref.invalidate(catalogRepoProvider);
      ref.invalidate(sessionRepoProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Backup restaurado'),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup y restauración')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.cloud_sync, color: Colors.white, size: 28),
                      SizedBox(width: 12),
                      Text(
                        'Respaldo local',
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tus datos son 100% tuyos. Exporta un JSON para tener una copia en otro dispositivo o restaurar después de un cambio.',
                    style: TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_lastExportPath != null) ...[
              _infoCard(
                icon: Icons.check_circle,
                color: AppTheme.primary,
                title: 'Último export',
                subtitle: p.basename(_lastExportPath!),
              ),
              const SizedBox(height: 12),
            ],
            if (_lastImportName != null) ...[
              _infoCard(
                icon: Icons.download_done,
                color: AppTheme.accent,
                title: 'Último import',
                subtitle: _lastImportName!,
              ),
              const SizedBox(height: 12),
            ],
            FilledButton.icon(
              onPressed: _busy ? null : _export,
              icon: const Icon(Icons.upload),
              label: const Text('Exportar backup'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 18),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _busy ? null : _import,
              icon: const Icon(Icons.download),
              label: const Text('Restaurar desde backup'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.accent,
                side: const BorderSide(color: AppTheme.accent, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 18),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            if (_busy) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoCard({required IconData icon, required Color color, required String title, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(subtitle, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            onPressed: () => Clipboard.setData(ClipboardData(text: subtitle)),
          ),
        ],
      ),
    );
  }
}
