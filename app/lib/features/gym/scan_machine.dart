// Escáner de máquinas: QR (cámara) y NFC a la vez; gana el primero que lea.
//
// Las Technogym llevan junto al logo NFC un QR "s.technogym.com/<línea>/<modelo>".
// Si el punto NFC de tu máquina es una etiqueta con esa misma URL, también se
// lee acercando el móvil. Si es un lector (para la llave mywellness) el móvil
// no puede leerlo: usa el QR.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:nfc_manager/nfc_manager.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/gym_machine.dart';
import '../../domain/engine/machine_code.dart';
import 'gym_machines_screen.dart';

/// Abre el escáner y devuelve el código leído (o null si se cancela).
Future<MachineCode?> scanMachineCode(BuildContext context) =>
    Navigator.of(context).push<MachineCode>(MaterialPageRoute(builder: (_) => const _ScanScreen()));

/// Escanea y devuelve la máquina del usuario (vinculándola o creándola si hace falta).
Future<GymMachine?> scanAndResolveMachine(BuildContext context, WidgetRef ref) async {
  final code = await scanMachineCode(context);
  if (code == null || !context.mounted) return null;
  await ref.read(gymMachinesProvider.notifier).ready;
  if (!context.mounted) return null;
  final machines = ref.read(gymMachinesProvider);
  final r = resolveScan<GymMachine>(
    code,
    machines,
    codesOf: (m) => m.codes,
    typesOf: (m) => m.typeIds,
    nameOf: (m) => m.name,
  );
  switch (r.match) {
    case ScanMatch.linked:
      return r.machine;
    case ScanMatch.probable:
      final yes = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(code.suggestedName ?? 'Máquina escaneada'),
          content: Text('¿Es tu "${r.machine!.name}"? La vincularé para reconocerla al instante la próxima vez.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No, es otra')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sí')),
          ],
        ),
      );
      if (yes == null) return null;
      if (yes) {
        final m = r.machine!.copyWith(codes: {...r.machine!.codes, code.raw}.toList());
        await ref.read(gymMachinesProvider.notifier).upsert(m);
        return m;
      }
      if (!context.mounted) return null;
      return _create(context, ref, code);
    case ScanMatch.unknown:
      return _create(context, ref, code);
  }
}

Future<GymMachine?> _create(BuildContext context, WidgetRef ref, MachineCode code) async {
  final add = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Máquina nueva'),
      content: Text(code.suggestedName != null
          ? '${code.suggestedName}\n\nNo está en tus máquinas. ¿La añado? Solo tendrás que revisar la pila de pesos.'
          : 'Este código no es de Technogym. ¿Lo vinculo a una máquina nueva?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Añadir')),
      ],
    ),
  );
  if (add != true || !context.mounted) return null;
  await Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => MachineEditScreen(
      prefillName: code.suggestedName,
      prefillTypes: code.guessedTypes,
      prefillCodes: [code.raw],
    ),
  ));
  return ref.read(gymMachinesProvider).where((m) => m.codes.contains(code.raw)).firstOrNull;
}

class _ScanScreen extends StatefulWidget {
  const _ScanScreen();
  @override
  State<_ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<_ScanScreen> {
  final MobileScannerController _camera = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _done = false;
  bool _nfcOn = false;

  @override
  void initState() {
    super.initState();
    _startNfc();
  }

  Future<void> _startNfc() async {
    try {
      if (!await NfcManager.instance.isAvailable()) return;
      setState(() => _nfcOn = true);
      await NfcManager.instance.startSession(onDiscovered: (tag) async {
        final text = _readTag(tag);
        if (text != null) _finish(text);
      });
    } catch (_) {
      // Sin NFC o sin permiso: seguimos solo con la cámara.
    }
  }

  String? _readTag(NfcTag tag) {
    final ndef = Ndef.from(tag);
    for (final r in ndef?.cachedMessage?.records ?? const <NdefRecord>[]) {
      if (r.typeNameFormat == NdefTypeNameFormat.nfcWellknown && r.type.length == 1) {
        if (r.type.first == 0x55) return decodeNdefUri(r.payload); // 'U'
        if (r.type.first == 0x54) return decodeNdefText(r.payload); // 'T'
      }
      if (r.typeNameFormat == NdefTypeNameFormat.absoluteUri) return String.fromCharCodes(r.type);
    }
    // Sin NDEF: usamos el identificador de la etiqueta (sirve para pegatinas propias)
    final id = _findId(tag.data);
    return id == null ? null : 'nfc:${id.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';
  }

  List<int>? _findId(Object? data) {
    if (data is Map) {
      final v = data['identifier'];
      if (v is List && v.isNotEmpty) return v.cast<int>();
      for (final e in data.values) {
        final r = _findId(e);
        if (r != null) return r;
      }
    }
    return null;
  }

  void _finish(String text) {
    if (_done) return;
    final code = MachineCode.parse(text);
    if (code == null) return;
    _done = true;
    if (mounted) Navigator.of(context).pop(code);
  }

  @override
  void dispose() {
    _camera.dispose();
    if (_nfcOn) NfcManager.instance.stopSession().catchError((_) {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Escanear máquina')),
      body: Stack(
        children: [
          MobileScanner(
            controller: _camera,
            onDetect: (capture) {
              for (final b in capture.barcodes) {
                if (b.rawValue != null) return _finish(b.rawValue!);
              }
            },
            errorBuilder: (context, error, child) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No puedo usar la cámara (${error.errorCode.name}). '
                  '${_nfcOn ? 'Acerca el móvil al logo NFC de la máquina.' : 'Revisa el permiso de cámara.'}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.primary, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 32,
            child: Card(
              color: Colors.black87,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _nfcOn
                      ? 'Apunta al QR de la máquina, o acerca el móvil al logo NFC.'
                      : 'Apunta al QR que hay junto al logo NFC de la máquina.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
