// Filtros digitales Butterworth (biquads en cascada) y separador de sonidos a 8 kHz.
import 'dart:math' as math;
import 'dart:typed_data';

class Biquad {
  double b0 = 1, b1 = 0, b2 = 0, a1 = 0, a2 = 0, z1 = 0, z2 = 0;
  Biquad.design(bool lowpass, double fs, double fc, double q) {
    final w = 2 * math.pi * fc / fs, c = math.cos(w), al = math.sin(w) / (2 * q), a0 = 1 + al;
    if (lowpass) {
      b0 = (1 - c) / 2 / a0;
      b1 = (1 - c) / a0;
    } else {
      b0 = (1 + c) / 2 / a0;
      b1 = -(1 + c) / a0;
    }
    b2 = b0;
    a1 = -2 * c / a0;
    a2 = (1 - al) / a0;
  }
  double process(double x) {
    final y = b0 * x + z1;
    z1 = b1 * x - a1 * y + z2;
    z2 = b2 * x - a2 * y;
    return y;
  }
}

/// Butterworth de orden 2*sections (sections=2 -> orden 4).
class Butter {
  final List<Biquad> _s;
  Butter._(this._s);
  factory Butter.low(double fs, double fc, {int sections = 2}) => Butter._(_build(true, fs, fc, sections));
  factory Butter.high(double fs, double fc, {int sections = 2}) => Butter._(_build(false, fs, fc, sections));
  static List<Biquad> _build(bool lp, double fs, double fc, int n) => List.generate(
      n, (k) => Biquad.design(lp, fs, fc, 1 / (2 * math.cos(math.pi * (2 * k + 1) / (4 * n)))));
  double process(double x) {
    for (final s in _s) {
      x = s.process(x);
    }
    return x;
  }
}

class Separated {
  final Float32List heart, lung, general;
  Separated(this.heart, this.lung, this.general);
}

double _clip(double v) => v > 1 ? 1 : (v < -1 ? -1 : v);

/// Entrada: PCM int16 a 8 kHz (preprocesado por la ESP32).
///  Cardíacos:      pasa-bajas 250 Hz
///  Pulmonares:     pasa-banda 200-1500 Hz
///  Estado general: pasa-bajas 3000 Hz
/// Cada canal con su amplificación (gH, gL, gG). Con [mute] y máscara de movimiento
/// la salida se silencia con fundido (sin clics).
class Separator {
  static const double fs = 8000;
  static const double heartLp = 250, lungLo = 200, lungHi = 1500, generalLp = 3000;
  double gH, gL, gG;
  final _dc = Butter.high(fs, 15, sections: 1);
  final _h = Butter.low(fs, heartLp);
  final _lh = Butter.high(fs, lungLo);
  final _ll = Butter.low(fs, lungHi);
  final _g = Butter.low(fs, generalLp);
  double _mg = 1;
  Separator({this.gH = 3, this.gL = 3, this.gG = 2});

  Separated process(Int16List raw, {Uint8List? motion, bool mute = false}) {
    final n = raw.length;
    final h = Float32List(n), l = Float32List(n), g = Float32List(n);
    for (var i = 0; i < n; i++) {
      final x = _dc.process(raw[i] / 32768.0);
      final m = mute && motion != null && motion[i] != 0;
      _mg += ((m ? 0.0 : 1.0) - _mg) * (m ? 0.02 : 0.003);
      h[i] = _clip(_h.process(x) * gH * _mg).toDouble();
      l[i] = _clip(_ll.process(_lh.process(x)) * gL * _mg).toDouble();
      g[i] = _clip(_g.process(x) * gG * _mg).toDouble();
    }
    return Separated(h, l, g);
  }
}

Uint8List _wav(int n, int fs, void Function(ByteData, int) fill) {
  final b = ByteData(44 + 2 * n);
  void s(int o, String t) {
    for (var i = 0; i < t.length; i++) {
      b.setUint8(o + i, t.codeUnitAt(i));
    }
  }
  s(0, 'RIFF');
  b.setUint32(4, 36 + 2 * n, Endian.little);
  s(8, 'WAVEfmt ');
  b.setUint32(16, 16, Endian.little);
  b.setUint16(20, 1, Endian.little);
  b.setUint16(22, 1, Endian.little);
  b.setUint32(24, fs, Endian.little);
  b.setUint32(28, fs * 2, Endian.little);
  b.setUint16(32, 2, Endian.little);
  b.setUint16(34, 16, Endian.little);
  s(36, 'data');
  b.setUint32(40, 2 * n, Endian.little);
  fill(b, 44);
  return b.buffer.asUint8List();
}

Uint8List wavFromFloat(Float32List d, {int fs = 8000}) => _wav(d.length, fs, (b, o) {
      for (var i = 0; i < d.length; i++) {
        b.setInt16(o + 2 * i, (d[i] * 32767).round().clamp(-32768, 32767), Endian.little);
      }
    });

Uint8List wavFromInt16(Int16List d, {int fs = 8000}) => _wav(d.length, fs, (b, o) {
      for (var i = 0; i < d.length; i++) {
        b.setInt16(o + 2 * i, d[i], Endian.little);
      }
    });
