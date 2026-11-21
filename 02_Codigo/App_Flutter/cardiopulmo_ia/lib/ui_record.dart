import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dsp.dart';
import 'models.dart';
import 'services.dart';
import 'ui_analysis.dart';
import 'ui_common.dart';

/// Graba desde la ESP32 (PCM crudo 8 kHz) y muestra la separación en tiempo real.
/// returnResult=true -> devuelve la Recording con Navigator.pop; false -> abre el análisis.
class RecorderPage extends StatefulWidget {
  final bool returnResult;
  const RecorderPage({super.key, required this.returnResult});
  @override
  State<RecorderPage> createState() => _RecorderPageState();
}

class _RecorderPageState extends State<RecorderPage> {
  static const ringLen = 16000; // 2 s
  late final EspClient client = context.read<EspClient>();
  late final AppSettings cfg = context.read<AppSettings>();
  late final Separator sep = Separator(gH: cfg.gH, gL: cfg.gL, gG: cfg.gG);
  final raw = BytesBuilder(), mov = BytesBuilder();
  final rings = List.generate(3, (_) => Float32List(ringLen));
  int pos = 0, count = 0;
  StreamSubscription? sub;

  @override
  void initState() {
    super.initState();
    sub = client.audio.listen(_onBlock);
  }

  void _onBlock(AudioBlock b) {
    final n = b.samples.length;
    final m = Uint8List(n)..fillRange(0, n, b.motion ? 1 : 0);
    raw.add(b.samples.buffer.asUint8List(b.samples.offsetInBytes, n * 2));
    mov.add(m);
    count += n;
    final o = sep.process(b.samples, motion: m, mute: cfg.muteMotion);
    final outs = [o.heart, o.lung, o.general];
    for (var i = 0; i < n; i++) {
      for (var k = 0; k < 3; k++) {
        rings[k][pos] = outs[k][i];
      }
      pos = (pos + 1) % ringLen;
    }
    if (mounted) setState(() {});
  }

  Float32List _snap(Float32List r) {
    final o = Float32List(r.length), n = r.length - pos;
    o.setRange(0, n, r, pos);
    o.setRange(n, r.length, r, 0);
    return o;
  }

  void _stop() {
    sub?.cancel();
    if (count < kFs) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Grabación muy corta (menos de 1 s)')));
      Navigator.pop(context);
      return;
    }
    final pcm = Uint8List.fromList(raw.takeBytes());
    final rec = Recording(DateTime.now().millisecondsSinceEpoch.toString(), DateTime.now(),
        pcm.buffer.asInt16List(0, pcm.length ~/ 2), Uint8List.fromList(mov.takeBytes()));
    if (widget.returnResult) {
      Navigator.pop(context, rec);
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AnalysisPage(rec: rec)));
    }
  }

  @override
  void dispose() {
    sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<EspClient>();
    final motion = c.tel['mot'] == 1;
    final left = Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(shape: BoxShape.circle, color: kBlue.withOpacity(.12), border: Border.all(color: kBlue.withOpacity(.3), width: 6)),
        child: const Icon(Icons.mic, size: 64, color: kBlue),
      ),
      const SizedBox(height: 12),
      Text(c.connected ? 'Grabando…' : 'Sin conexión con la ESP32', style: const TextStyle(fontWeight: FontWeight.w600)),
      Text('${two(count ~/ kFs ~/ 60)}:${two(count ~/ kFs % 60)}', style: const TextStyle(fontSize: 20)),
      if (motion) const Padding(padding: EdgeInsets.only(top: 6), child: Text('Movimiento detectado: audio silenciado', style: TextStyle(color: Colors.orange))),
      const SizedBox(height: 12),
      FilledButton.icon(onPressed: count > 0 ? _stop : null, icon: const Icon(Icons.stop), label: const Text('Detener')),
      if (!c.connected) TextButton(onPressed: () => c.connect(cfg.url), child: const Text('Reintentar conexión')),
    ]);
    Widget row(IconData ic, Color col, String label, Float32List d) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(children: [
            Icon(ic, color: col),
            const SizedBox(width: 8),
            Expanded(child: SizedBox(height: 64, child: CustomPaint(painter: WavePainter(d, col, autoscale: true), size: Size.infinite))),
            SizedBox(width: 78, child: Text(label, textAlign: TextAlign.right)),
          ]),
        );
    final right = Container(
      padding: const EdgeInsets.all(14),
      decoration: cardBox(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Separación en tiempo real', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        row(Icons.favorite, kHeart, 'Corazón', _snap(rings[0])),
        row(Icons.air, kLung, 'Pulmones', _snap(rings[1])),
        row(Icons.graphic_eq, kGen, 'Estado General', _snap(rings[2])),
      ]),
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auscultación Libre'),
        backgroundColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(children: [
              Icon(Icons.circle, size: 10, color: c.connected ? Colors.green : Colors.red),
              const SizedBox(width: 4),
              Text(c.connected ? 'En vivo' : 'Sin conexión'),
            ]),
          )
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (_, k) => k.maxWidth > 700
              ? Padding(padding: const EdgeInsets.all(16), child: Row(children: [Expanded(child: left), const SizedBox(width: 16), Expanded(flex: 2, child: right)]))
              : ListView(padding: const EdgeInsets.all(16), children: [left, const SizedBox(height: 16), right]),
        ),
      ),
    );
  }
}
