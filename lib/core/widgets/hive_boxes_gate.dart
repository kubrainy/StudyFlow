import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app_widgets.dart';

/// Sayfa açılmadan önce [boxes] kutularının açık olmasını sağlar. Her modül
/// kendi sayfasını bununla sarar; böylece kutular `main.dart`'ta değil, onları
/// kullanan modülde açılır.
///
/// Kutular zaten açıksa (başka bir modül açmıştır) beklemeden [child] çizilir.
/// Açık bir kutuyu tekrar açmak Hive'da zararsızdır. Kutular kapatılmaz:
/// aynı kutuyu birkaç modül kullanıyor ve kapatılan kutuyu okuyan ekran
/// "Box not found" hatası verir.
class HiveBoxesGate extends StatefulWidget {
  const HiveBoxesGate({super.key, required this.boxes, required this.child});

  final List<String> boxes;
  final Widget child;

  @override
  State<HiveBoxesGate> createState() => _HiveBoxesGateState();
}

class _HiveBoxesGateState extends State<HiveBoxesGate> {
  late bool _ready = widget.boxes.every(Hive.isBoxOpen);
  Object? _error;

  @override
  void initState() {
    super.initState();
    if (!_ready) _open();
  }

  Future<void> _open() async {
    setState(() => _error = null);
    try {
      await Future.wait([for (final name in widget.boxes) Hive.openBox(name)]);
      if (mounted) setState(() => _ready = true);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) return widget.child;
    if (_error != null) {
      return Scaffold(
        body: AppErrorView(message: 'Veriler açılamadı', onRetry: _open),
      );
    }
    return const Scaffold(body: AppLoadingView());
  }
}
