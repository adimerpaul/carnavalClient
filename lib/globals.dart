import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GlobalLocation extends ChangeNotifier {
  double latitude = 0.0;
  double longitude = 0.0;

  void updateLocation(double newLat, double newLng) {
    latitude = newLat;
    longitude = newLng;
    notifyListeners();  // Notifica cambios a la UI
  }
}

// Instancia global
final globalLocation = GlobalLocation();
double latitude = globalLocation.latitude;
double longitude = globalLocation.longitude;

Socket socket = io(dotenv.env['API_SOCKET']!,
    OptionBuilder()
        .setTransports(['websocket']) // for Flutter or Dart VM
        .disableAutoConnect()  // disable auto-connection
        .setExtraHeaders({'foo': 'bar'}) // optional
        .build()
);

bool swSocket = false;
bool loading = false;