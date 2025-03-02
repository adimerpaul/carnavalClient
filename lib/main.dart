import 'package:carnaval/pages/login.dart';
import 'package:carnaval/pages/home.dart'; // Importa tu página de inicio
import 'package:carnaval/services/DatabaseHelper.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'addons/foreground.dart';
import 'addons/notification.dart';
import 'addons/scaffold.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import '../globals.dart' as globals;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeService();

  await initNotifications();

  const bool isProduction = bool.fromEnvironment('dart.vm.product');
  await dotenv.load(fileName: isProduction ? ".env.production" : ".env");
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    requestPermissions();
  }
  Future<void> requestPermissions() async {
    await [
      Permission.storage,
      Permission.location,
      Permission.notification,
      Permission.ignoreBatteryOptimizations,
    ].request();
    // if (await Permission.storage.isGranted) {
    //   print('Permiso de almacenamiento concedido');
    //   success(context, 'Permiso de almacenamiento concedido');
    // }
  }
  initNotifications() async {
    globals.socket.connect();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Carnaval Oruro',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // Define rutas de navegación
      routes: {
        '/': (context) => HomePage(),  // Página inicial que verifica el usuario
        '/login': (context) => LoginPage(),
        '/home': (context) => HomePage(),
      },
      initialRoute: '/', // Ruta inicial
    );
  }
}
class InitialPage extends StatefulWidget {
  @override
  _InitialPageState createState() => _InitialPageState();
}

class _InitialPageState extends State<InitialPage> {
  @override
  void initState() {
    super.initState();
    _checkIfLoggedIn();
  }

  Future<void> _checkIfLoggedIn() async {
    var user = await DatabaseHelper().getUser();
    if (user != null) {
      Navigator.pushReplacementNamed(context, '/home'); // Redirige a Home si está logueado
    } else {
      Navigator.pushReplacementNamed(context, '/login'); // Redirige a Login si no está logueado
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: CircularProgressIndicator()), // Indicador de carga
    );
  }
}