import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'models.dart';

// ------------------------------------------------------------------ Ajustes
class AppSettings extends ChangeNotifier {
  String url = 'ws://192.168.4.1:81';
  double gH = 3, gL = 3, gG = 2;
  bool muteMotion = true;
  late SharedPreferences _sp;

  Future<void> init() async {
    _sp = await SharedPreferences.getInstance();
    url = _sp.getString('url') ?? url;
    gH = _sp.getDouble('gH') ?? gH;
    gL = _sp.getDouble('gL') ?? gL;
    gG = _sp.getDouble('gG') ?? gG;
    muteMotion = _sp.getBool('mute') ?? true;
  }

  void set({String? url, double? gH, double? gL, double? gG, bool? muteMotion}) {
    this.url = url ?? this.url;
    this.gH = gH ?? this.gH;
    this.gL = gL ?? this.gL;
    this.gG = gG ?? this.gG;
    this.muteMotion = muteMotion ?? this.muteMotion;
    _sp.setString('url', this.url);
    _sp.setDouble('gH', this.gH);
    _sp.setDouble('gL', this.gL);
    _sp.setDouble('gG', this.gG);
    _sp.setBool('mute', this.muteMotion);
    notifyListeners();
  }
}

// ------------------------------------------------------------------ Cliente ESP32
class AudioBlock {
  final Int16List samples;
  final bool motion;
  AudioBlock(this.samples, this.motion);
}

/// Protocolo (WebSocket, puerto 81):
///  binario: [0xA2, flags(bit0=movimiento), int16 LE ... ]  PCM crudo a 8 kHz
///  texto:   JSON de telemetría {"t":1,"bpm":..,"bv":..,"fing":..,"mot":..,"acc":..,"rssi":..}
class EspClient extends ChangeNotifier {
  WebSocketChannel? _ch;
  StreamSubscription? _sub;
  bool connected = false, connecting = false;
  String status = 'Desconectado';
  Map<String, dynamic> tel = {};
  final _ctl = StreamController<AudioBlock>.broadcast();
  Stream<AudioBlock> get audio => _ctl.stream;

  Future<void> connect(String url) async {
    if (connecting) return;
    connecting = true;
    status = 'Conectando…';
    notifyListeners();
    await disconnect(quiet: true);
    try {
      final ch = WebSocketChannel.connect(Uri.parse(url));
      await ch.ready.timeout(const Duration(seconds: 6));
      _ch = ch;
      _sub = ch.stream.listen(_onData, onDone: _lost, onError: (_) => _lost());
      connected = true;
      status = 'En vivo';
    } catch (_) {
      connected = false;
      status = 'Sin conexión';
    }
    connecting = false;
    notifyListeners();
  }

  void _lost() {
    connected = false;
    status = 'Sin conexión';
    notifyListeners();
  }

  Future<void> disconnect({bool quiet = false}) async {
    await _sub?.cancel();
    await _ch?.sink.close();
    _sub = null;
    _ch = null;
    connected = false;
    if (!quiet) {
      status = 'Desconectado';
      notifyListeners();
    }
  }

  void send(String s) {
    if (connected) _ch?.sink.add(s);
  }

  void _onData(dynamic d) {
    if (d is String) {
      try {
        final j = jsonDecode(d) as Map<String, dynamic>;
        if (j.containsKey('t')) {
          tel = j;
          notifyListeners();
        }
      } catch (_) {}
      return;
    }
    if (d is List<int>) {
      final b = d is Uint8List ? d : Uint8List.fromList(d);
      if (b.length < 4 || b[0] != 0xA2) return;
      final n = (b.length - 2) ~/ 2;
      final out = Int16List(n);
      final bd = ByteData.sublistView(b);
      for (var i = 0; i < n; i++) {
        out[i] = bd.getInt16(2 + 2 * i, Endian.little);
      }
      _ctl.add(AudioBlock(out, (b[1] & 1) != 0));
    }
  }
}

// ------------------------------------------------------------------ Almacenamiento
/// Guarda pacientes (SharedPreferences) y grabaciones crudas (.pcm + .mov).
/// Se conservan solo las 2 grabaciones más recientes por paciente.
class Store extends ChangeNotifier {
  List<Patient> patients = [];
  late SharedPreferences _sp;
  late Directory _dir;

  Future<void> init() async {
    _sp = await SharedPreferences.getInstance();
    _dir = Directory('${(await getApplicationDocumentsDirectory()).path}/recs');
    await _dir.create(recursive: true);
    final s = _sp.getString('patients');
    if (s != null) {
      patients = (jsonDecode(s) as List).map((e) => Patient.fromJson(e as Map<String, dynamic>)).toList();
    }
  }

  Future<void> _persist() async {
    await _sp.setString('patients', jsonEncode(patients.map((p) => p.toJson()).toList()));
    notifyListeners();
  }

  Future<void> addPatient(Patient p, Recording? r) async {
    patients.add(p);
    if (r != null) {
      await addRecording(p, r);
    } else {
      await _persist();
    }
  }

  Future<void> addRecording(Patient p, Recording r) async {
    final s = r.samples;
    await File('${_dir.path}/${r.id}.pcm').writeAsBytes(s.buffer.asUint8List(s.offsetInBytes, s.lengthInBytes));
    await File('${_dir.path}/${r.id}.mov').writeAsBytes(r.motion);
    p.recs.insert(0, RecMeta(r.id, r.date, r.seconds));
    while (p.recs.length > 2) {
      final o = p.recs.removeLast();
      for (final e in ['pcm', 'mov']) {
        final f = File('${_dir.path}/${o.id}.$e');
        if (await f.exists()) await f.delete();
      }
    }
    await _persist();
  }

  Future<Recording> load(RecMeta m) async {
    final pcm = Uint8List.fromList(await File('${_dir.path}/${m.id}.pcm').readAsBytes());
    final mov = Uint8List.fromList(await File('${_dir.path}/${m.id}.mov').readAsBytes());
    return Recording(m.id, m.date, pcm.buffer.asInt16List(0, pcm.length ~/ 2), mov);
  }
}
