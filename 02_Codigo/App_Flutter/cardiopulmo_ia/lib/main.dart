import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services.dart';
import 'ui_common.dart';
import 'ui_home.dart';
import 'ui_patients.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = Store(), settings = AppSettings();
  await Future.wait([store.init(), settings.init()]);
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider.value(value: store),
    ChangeNotifierProvider.value(value: settings),
    ChangeNotifierProvider(create: (_) => EspClient()),
  ], child: const App()));
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'CardioPulmo IA',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: kBlue,
          scaffoldBackgroundColor: const Color(0xFFF3F6FD),
          filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(shape: const StadiumBorder(), minimumSize: const Size(0, 48))),
          outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(shape: const StadiumBorder(), minimumSize: const Size(0, 48))),
        ),
        home: const Shell(),
      );
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int i = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EspClient>().connect(context.read<AppSettings>().url);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: IndexedStack(index: i, children: [
          HomePage(onPatients: () => setState(() => i = 1)),
          const PatientsPage(),
          const SettingsPage(),
        ]),
        bottomNavigationBar: NavigationBar(
          selectedIndex: i,
          onDestinationSelected: (v) => setState(() => i = v),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Inicio'),
            NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Pacientes'),
            NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Ajustes'),
          ],
        ),
      );
}
