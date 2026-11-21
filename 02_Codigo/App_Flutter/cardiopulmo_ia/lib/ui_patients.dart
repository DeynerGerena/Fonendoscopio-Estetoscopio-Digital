import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dsp.dart';
import 'models.dart';
import 'services.dart';
import 'ui_analysis.dart';
import 'ui_common.dart';
import 'ui_record.dart';

class PatientsPage extends StatefulWidget {
  const PatientsPage({super.key});
  @override
  State<PatientsPage> createState() => _PatientsPageState();
}

class _PatientsPageState extends State<PatientsPage> {
  String q = '';
  @override
  Widget build(BuildContext context) {
    final list = context.watch<Store>().patients.where((p) => p.name.toLowerCase().contains(q.toLowerCase())).toList()
      ..sort((a, b) => (b.last ?? DateTime(2000)).compareTo(a.last ?? DateTime(2000)));
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Historial de Pacientes'), backgroundColor: Colors.transparent, automaticallyImplyLeading: false),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage())),
        icon: const Icon(Icons.person_add),
        label: const Text('Registrar'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(padding: const EdgeInsets.all(16), children: [
              TextField(
                onChanged: (v) => setState(() => q = v),
                decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: 'Buscar paciente…', filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)),
              ),
              const SizedBox(height: 12),
              if (list.isEmpty) const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Aún no hay pacientes registrados'))),
              for (final p in list)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    tileColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    leading: const CircleAvatar(backgroundColor: Color(0xFFE3EBFB), child: Icon(Icons.person, color: kBlue)),
                    title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(p.last == null ? 'Sin grabaciones' : 'Última: ${fmtDate(p.last!)}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PatientDetailPage(patient: p))),
                  ),
                ),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFFE9EEFA), borderRadius: BorderRadius.circular(14)),
                child: const Row(children: [Icon(Icons.info, color: kBlue), SizedBox(width: 10), Expanded(child: Text('Se conservan las dos grabaciones más recientes de cada paciente.'))]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final name = TextEditingController(), age = TextEditingController(), notes = TextEditingController();
  Recording? rec;
  Uint8List? previewWav;

  Future<void> _record() async {
    final r = await Navigator.push<Recording>(context, MaterialPageRoute(builder: (_) => const RecorderPage(returnResult: true)));
    if (r != null) {
      final s = context.read<AppSettings>();
      previewWav = wavFromFloat(Separator(gG: s.gG).process(r.samples, motion: r.motion, mute: s.muteMotion).general);
      setState(() => rec = r);
    }
  }

  Future<void> _save() async {
    final a = int.tryParse(age.text.trim());
    if (name.text.trim().isEmpty || a == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Escribe el nombre y una edad válida')));
      return;
    }
    await context.read<Store>().addPatient(Patient(DateTime.now().millisecondsSinceEpoch.toString(), name.text.trim(), a, notes.text.trim()), rec);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Registrar Paciente'), backgroundColor: Colors.transparent),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(padding: const EdgeInsets.all(20), children: [
                TextField(controller: name, decoration: const InputDecoration(labelText: 'Nombre completo', hintText: 'Ej. Juan Pérez', prefixIcon: Icon(Icons.person))),
                const SizedBox(height: 12),
                TextField(controller: age, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Edad (años)', hintText: 'Ej. 45', prefixIcon: Icon(Icons.cake))),
                const SizedBox(height: 12),
                TextField(controller: notes, maxLines: 2, decoration: const InputDecoration(labelText: 'Observaciones (opcional)', prefixIcon: Icon(Icons.edit_note))),
                const SizedBox(height: 20),
                FilledButton.icon(onPressed: _record, icon: const Icon(Icons.mic), label: Text(rec == null ? 'Grabar Auscultación' : 'Volver a grabar')),
                if (previewWav != null) ...[const SizedBox(height: 12), WavPlayerBar(wav: previewWav!)],
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar'))),
                  const SizedBox(width: 12),
                  Expanded(child: FilledButton(onPressed: _save, child: const Text('Guardar'))),
                ]),
              ]),
            ),
          ),
        ),
      );
}

class PatientDetailPage extends StatelessWidget {
  final Patient patient;
  const PatientDetailPage({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<Store>();
    return Scaffold(
      appBar: AppBar(title: Column(children: [Text(patient.name), Text('Edad: ${patient.age} años', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.normal))]), centerTitle: true, backgroundColor: Colors.transparent),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(padding: const EdgeInsets.all(20), children: [
              if (patient.notes.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(patient.notes, style: const TextStyle(color: Colors.black54))),
              const Text('Grabaciones disponibles', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              if (patient.recs.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Text('Sin grabaciones')),
              for (final m in patient.recs)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    tileColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    title: Text(fmtDateTime(m.date)),
                    subtitle: Text(fmtDur(m.seconds)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final r = await store.load(m);
                      if (context.mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => AnalysisPage(rec: r)));
                    },
                  ),
                ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () async {
                  final r = await Navigator.push<Recording>(context, MaterialPageRoute(builder: (_) => const RecorderPage(returnResult: true)));
                  if (r != null) await store.addRecording(patient, r);
                },
                icon: const Icon(Icons.mic),
                label: const Text('Nueva grabación'),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
