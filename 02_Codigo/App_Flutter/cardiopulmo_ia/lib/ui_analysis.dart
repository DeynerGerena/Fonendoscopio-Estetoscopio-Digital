import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dsp.dart';
import 'models.dart';
import 'services.dart';
import 'ui_common.dart';

/// Procesa la grabación cruda con los tres filtros y permite escuchar, amplificar y exportar.
class AnalysisPage extends StatefulWidget {
  final Recording rec;
  const AnalysisPage({super.key, required this.rec});
  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  static const names = ['Cardíacos', 'Pulmonares', 'Estado General'];
  static const keys = ['cardiacos', 'pulmonares', 'general'];
  static const cols = [kHeart, kLung, kGen];
  static const icons = [Icons.favorite, Icons.air, Icons.graphic_eq];
  static const lims = ['pasa-bajas ≤ 250 Hz', 'pasa-banda 200–1500 Hz', 'pasa-bajas ≤ 3000 Hz'];

  int ch = 0;
  late List<double> gains;
  late Separated sep;
  late Uint8List wav;
  double prog = 0;

  Recording get rec => widget.rec;
  Float32List get cur => [sep.heart, sep.lung, sep.general][ch];

  @override
  void initState() {
    super.initState();
    final s = context.read<AppSettings>();
    gains = [s.gH, s.gL, s.gG];
    _proc();
  }

  void _proc() {
    final mute = context.read<AppSettings>().muteMotion;
    sep = Separator(gH: gains[0], gL: gains[1], gG: gains[2]).process(rec.samples, motion: rec.motion, mute: mute);
    wav = wavFromFloat(cur);
  }

  (String, Color) _quality() {
    double pk = 0, ss = 0;
    for (final x in cur) {
      pk = math.max(pk, x.abs());
      ss += x * x;
    }
    final rms = math.sqrt(ss / math.max(1, cur.length));
    if (pk >= 0.99) return ('Señal saturada: baja la amplificación', Colors.orange);
    if (rms < 0.002) return ('Señal débil: sube la amplificación', Colors.orange);
    return ('Señal óptima', Colors.green);
  }

  Future<void> _share(bool all) async {
    final dir = await getTemporaryDirectory();
    final data = [sep.heart, sep.lung, sep.general];
    final files = <XFile>[];
    for (final i in all ? [0, 1, 2] : [ch]) {
      final f = File('${dir.path}/fono_${rec.id}_${keys[i]}.wav');
      await f.writeAsBytes(wavFromFloat(data[i]));
      files.add(XFile(f.path));
    }
    if (all) {
      final f = File('${dir.path}/fono_${rec.id}_crudo.wav');
      await f.writeAsBytes(wavFromInt16(rec.samples));
      files.add(XFile(f.path));
    }
    await Share.shareXFiles(files, text: 'Fonendoscopio ${fmtDateTime(rec.date)}');
  }

  @override
  Widget build(BuildContext context) {
    final (qText, qCol) = _quality();
    final moved = rec.motion.where((e) => e != 0).length * 100 / math.max(1, rec.motion.length);
    final dur = rec.seconds;

    final tabs = Row(children: [
      for (var i = 0; i < 3; i++)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: ChoiceChip(
              selected: ch == i,
              showCheckmark: false,
              selectedColor: kBlue,
              labelStyle: TextStyle(color: ch == i ? Colors.white : Colors.black87),
              avatar: Icon(icons[i], size: 18, color: ch == i ? Colors.white : cols[i]),
              label: Text(names[i], overflow: TextOverflow.ellipsis),
              onSelected: (_) => setState(() {
                ch = i;
                wav = wavFromFloat(cur);
              }),
            ),
          ),
        ),
    ]);

    final wave = Container(
      padding: const EdgeInsets.all(12),
      decoration: cardBox(),
      child: Column(children: [
        Align(alignment: Alignment.centerLeft, child: Text('${names[ch]} — ${lims[ch]}', style: const TextStyle(color: Colors.black54))),
        SizedBox(height: 220, child: CustomPaint(painter: WavePainter(cur, cols[ch], cursor: prog), size: Size.infinite)),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          for (var i = 0; i <= 5; i++) Text('${(dur * i / 5).toStringAsFixed(dur < 10 ? 1 : 0)}s', style: const TextStyle(fontSize: 11)),
        ]),
      ]),
    );

    final side = Container(
      padding: const EdgeInsets.all(14),
      decoration: cardBox(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(Icons.check_circle, color: qCol), const SizedBox(width: 8), Expanded(child: Text('${names[ch]}\n$qText'))]),
        if (moved > 0.5) Padding(padding: const EdgeInsets.only(top: 6), child: Text('Movimiento: ${moved.toStringAsFixed(0)} % silenciado', style: const TextStyle(color: Colors.black54, fontSize: 12))),
        const SizedBox(height: 10),
        Text('Amplificación ×${gains[ch].toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.w600)),
        Slider(
          value: gains[ch],
          min: 0.5,
          max: 30,
          activeColor: cols[ch],
          onChanged: (v) => setState(() => gains[ch] = v),
          onChangeEnd: (_) => setState(_proc),
        ),
      ]),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Análisis de Grabación'), backgroundColor: Colors.transparent),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (_, k) {
            final wide = k.maxWidth > 700;
            return ListView(padding: const EdgeInsets.all(16), children: [
              Text('${fmtDateTime(rec.date)} • ${fmtDur(dur)}', style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 8),
              tabs,
              const SizedBox(height: 12),
              wide ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 3, child: wave), const SizedBox(width: 12), Expanded(child: side)]) : Column(children: [wave, const SizedBox(height: 12), side]),
              const SizedBox(height: 12),
              WavPlayerBar(wav: wav, onProgress: (p) => setState(() => prog = p)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: FilledButton.icon(onPressed: () => _share(true), icon: const Icon(Icons.download), label: const Text('Descargar todo'))),
                const SizedBox(width: 8),
                Expanded(child: OutlinedButton.icon(onPressed: () => _share(false), icon: const Icon(Icons.share), label: const Text('Compartir'))),
              ]),
            ]);
          },
        ),
      ),
    );
  }
}
