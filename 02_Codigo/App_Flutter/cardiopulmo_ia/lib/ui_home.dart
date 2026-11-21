import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services.dart';
import 'ui_common.dart';
import 'ui_record.dart';

class HomePage extends StatelessWidget {
  final VoidCallback onPatients;
  const HomePage({super.key, required this.onPatients});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<EspClient>();
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(padding: const EdgeInsets.all(20), children: [
            Align(
              alignment: Alignment.centerRight,
              child: Chip(
                avatar: Icon(Icons.circle, size: 10, color: c.connected ? Colors.green : Colors.red),
                label: Text(c.connected ? 'ESP32 conectada' : c.status),
              ),
            ),
            const SizedBox(height: 8),
            const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.favorite_border, size: 64, color: kBlue),
              Icon(Icons.air, size: 56, color: kBlue),
            ]),
            const SizedBox(height: 8),
            const Text('CardioPulmo IA',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Color(0xFF1A2B4C))),
            const Text('Escucha • Analiza • Cuida', textAlign: TextAlign.center, style: TextStyle(color: kBlue)),
            const SizedBox(height: 32),
            _BigCard(
              color: kBlue,
              icon: Icons.medical_services_outlined,
              title: 'Auscultación Libre',
              sub: 'Graba y separa en tiempo real',
              light: true,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecorderPage(returnResult: false))),
            ),
            const SizedBox(height: 14),
            _BigCard(
              color: const Color(0xFFD9D4F5),
              icon: Icons.groups_2_outlined,
              title: 'Pacientes',
              sub: 'Gestiona registros y revisa historial',
              onTap: onPatients,
            ),
            const SizedBox(height: 28),
            const Text('Sistema de apoyo diagnóstico — prototipo experimental, no es un dispositivo médico',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.black45, fontSize: 12)),
          ]),
        ),
      ),
    );
  }
}

class _BigCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title, sub;
  final bool light;
  final VoidCallback onTap;
  const _BigCard({required this.color, required this.icon, required this.title, required this.sub, required this.onTap, this.light = false});
  @override
  Widget build(BuildContext context) {
    final fg = light ? Colors.white : const Color(0xFF1A2B4C);
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(18)),
        child: Row(children: [
          Icon(icon, size: 40, color: fg),
          const SizedBox(width: 16),
          Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: fg)),
            Text(sub, style: TextStyle(color: fg.withOpacity(.85))),
          ])),
          Icon(Icons.chevron_right, color: fg),
        ]),
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController url = TextEditingController(text: context.read<AppSettings>().url);
  double mot = 0.6;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettings>();
    final c = context.watch<EspClient>();
    final t = c.tel;
    Widget gain(String label, double v, Color col, void Function(double) f) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$label  ×${v.toStringAsFixed(1)}'),
          Slider(value: v, min: 0.5, max: 30, activeColor: col, onChanged: f),
        ]);
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(padding: const EdgeInsets.all(20), children: [
            const Text('Ajustes', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(controller: url, decoration: const InputDecoration(labelText: 'Dirección de la ESP32', helperText: 'ws://192.168.4.1:81 (modo AP) o la IP en tu WiFi')),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                  child: FilledButton(
                      onPressed: c.connecting
                          ? null
                          : () {
                              s.set(url: url.text.trim());
                              c.connect(s.url);
                            },
                      child: Text(c.connected ? 'Reconectar' : 'Conectar'))),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton(onPressed: c.connected ? c.disconnect : null, child: const Text('Desconectar'))),
            ]),
            const SizedBox(height: 6),
            Text('Estado: ${c.status}'
                '${t.isEmpty ? '' : '  •  PPG: ${t['bv'] == 1 ? '${t['bpm']} lpm' : '--'}  •  RSSI ${t['rssi']} dBm'}'),
            const Divider(height: 32),
            const Text('Amplificación (post-filtro, en la app)', style: TextStyle(fontWeight: FontWeight.w600)),
            gain('Cardíacos (≤250 Hz)', s.gH, kHeart, (v) => s.set(gH: v)),
            gain('Pulmonares (200–1500 Hz)', s.gL, kLung, (v) => s.set(gL: v)),
            gain('Estado general (≤3000 Hz)', s.gG, kGen, (v) => s.set(gG: v)),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Silenciar audio con movimiento'),
              subtitle: const Text('Usa la bandera del acelerómetro/giroscopio de la ESP32'),
              value: s.muteMotion,
              onChanged: (v) => s.set(muteMotion: v),
            ),
            Text('Umbral de movimiento (ESP32): ${mot.toStringAsFixed(2)} m/s²'),
            Slider(value: mot, min: 0.1, max: 3, onChanged: (v) => setState(() => mot = v), onChangeEnd: (v) => c.send('MT=${v.toStringAsFixed(2)}')),
          ]),
        ),
      ),
    );
  }
}
