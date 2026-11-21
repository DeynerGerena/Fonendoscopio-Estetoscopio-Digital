import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

const kBlue = Color(0xFF2F6FDB);
const kHeart = Color(0xFFE8444F);
const kLung = Color(0xFF2F8FE0);
const kGen = Color(0xFF7B4FD6);

String two(int n) => n.toString().padLeft(2, '0');
String fmtDate(DateTime d) => '${two(d.day)}/${two(d.month)}/${d.year}';
String fmtDateTime(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  return '${fmtDate(d)} • ${two(h)}:${two(d.minute)} ${d.hour < 12 ? 'AM' : 'PM'}';
}

String fmtDur(double s) {
  final t = s.floor();
  return '${t ~/ 60}:${two(t % 60)}';
}

BoxDecoration cardBox([Color c = Colors.white]) => BoxDecoration(
    color: c, borderRadius: BorderRadius.circular(18), boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 3))]);

class WavePainter extends CustomPainter {
  final Float32List d;
  final Color color;
  final double? cursor;
  final bool autoscale;
  WavePainter(this.d, this.color, {this.cursor, this.autoscale = false});

  @override
  void paint(Canvas c, Size s) {
    final mid = s.height / 2;
    c.drawLine(Offset(0, mid), Offset(s.width, mid), Paint()..color = Colors.black12);
    if (d.isNotEmpty) {
      double sc = 1;
      if (autoscale) {
        double pk = 0;
        for (var i = 0; i < d.length; i += 4) {
          pk = math.max(pk, d[i].abs());
        }
        sc = 1 / math.max(pk, 0.05);
      }
      final p = Paint()..color = color..strokeWidth = 1.2;
      final w = s.width.floor();
      final step = d.length / w;
      for (var x = 0; x < w; x++) {
        final a = (x * step).floor().clamp(0, d.length - 1);
        final b = math.max(a + 1, math.min(d.length, ((x + 1) * step).ceil()));
        double mn = d[a], mx = d[a];
        for (var i = a; i < b; i++) {
          if (d[i] < mn) mn = d[i];
          if (d[i] > mx) mx = d[i];
        }
        c.drawLine(Offset(x.toDouble(), mid - mx * sc * mid * 0.95), Offset(x.toDouble(), mid - mn * sc * mid * 0.95), p);
      }
    }
    if (cursor != null) {
      final x = cursor! * s.width;
      c.drawLine(Offset(x, 0), Offset(x, s.height), Paint()..color = kBlue..strokeWidth = 2);
    }
  }

  @override
  bool shouldRepaint(covariant WavePainter o) => true;
}

/// Reproductor de un WAV en memoria (se escribe a un archivo temporal).
class WavPlayerBar extends StatefulWidget {
  final Uint8List wav;
  final ValueChanged<double>? onProgress;
  const WavPlayerBar({super.key, required this.wav, this.onProgress});
  @override
  State<WavPlayerBar> createState() => _WavPlayerBarState();
}

class _WavPlayerBarState extends State<WavPlayerBar> {
  static int _n = 0;
  final _p = AudioPlayer();
  Duration pos = Duration.zero, dur = Duration.zero;
  bool playing = false;
  String? path;
  double vol = 1;

  @override
  void initState() {
    super.initState();
    _p.onPositionChanged.listen((d) {
      if (!mounted) return;
      setState(() => pos = d);
      if (dur.inMilliseconds > 0) widget.onProgress?.call(d.inMilliseconds / dur.inMilliseconds);
    });
    _p.onDurationChanged.listen((d) => mounted ? setState(() => dur = d) : null);
    _p.onPlayerStateChanged.listen((s) => mounted ? setState(() => playing = s == PlayerState.playing) : null);
    _p.onPlayerComplete.listen((_) {
      widget.onProgress?.call(0);
      if (mounted) setState(() => pos = Duration.zero);
    });
    _prepare();
  }

  @override
  void didUpdateWidget(covariant WavPlayerBar old) {
    super.didUpdateWidget(old);
    if (!identical(old.wav, widget.wav)) {
      _p.stop();
      _prepare();
    }
  }

  Future<void> _prepare() async {
    final f = File('${(await getTemporaryDirectory()).path}/play_${_n++}.wav');
    await f.writeAsBytes(widget.wav);
    path = f.path;
    dur = Duration(milliseconds: (widget.wav.length - 44) * 1000 ~/ 16000);
    if (mounted) setState(() => pos = Duration.zero);
  }

  Future<void> _toggle() async {
    if (path == null) return;
    if (playing) {
      await _p.pause();
    } else if (pos > Duration.zero && pos < dur) {
      await _p.resume();
    } else {
      await _p.play(DeviceFileSource(path!), volume: vol);
    }
  }

  @override
  void dispose() {
    _p.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = dur.inMilliseconds.toDouble();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(color: const Color(0xFFE9EEFA), borderRadius: BorderRadius.circular(30)),
      child: Row(children: [
        IconButton(onPressed: _toggle, icon: Icon(playing ? Icons.pause : Icons.play_arrow, color: kBlue)),
        Text('${fmtDur(pos.inMilliseconds / 1000)} / ${fmtDur(total / 1000)}'),
        Expanded(
          child: Slider(
            value: total <= 0 ? 0 : pos.inMilliseconds.clamp(0, total.toInt()).toDouble(),
            max: total <= 0 ? 1 : total,
            onChanged: (v) => _p.seek(Duration(milliseconds: v.toInt())),
          ),
        ),
        const Icon(Icons.volume_up, color: kBlue),
      ]),
    );
  }
}
