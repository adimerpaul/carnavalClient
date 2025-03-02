import 'dart:async';
import 'package:carnaval/addons/notification.dart';
import 'package:dio_cache_interceptor_hive_store/dio_cache_interceptor_hive_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart'; // Para obtener la ubicación
import 'package:path_provider/path_provider.dart';
import '../services/DatabaseHelper.dart';
import 'package:intl/intl.dart'; // Asegúrate de tener esta importación
import '../globals.dart' as globals;
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isSendingLocation =
      false; // Estado para verificar si se está enviando la ubicación

  final MapController _mapController = MapController();
  final List<Map<String, String>> _mapTypes = [
    {
      'name': 'Normal',
      'url': 'https://mt1.google.com/vt/lyrs=r&x={x}&y={y}&z={z}'
    },
    {
      'name': 'Satélite',
      'url': 'https://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}'
    },
    {
      'name': 'Híbrido',
      'url': 'https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}'
    },
    {
      'name': 'Terreno',
      'url': 'https://mt1.google.com/vt/lyrs=p&x={x}&y={y}&z={z}'
    },
  ];
  String _selectedMapUrl = 'https://mt1.google.com/vt/lyrs=r&x={x}&y={y}&z={z}';
  bool loadingLocation = false;
  bool loading = false;
  // double myLatitud = 0.0;
  // double myLongitud = 0.0;
  String? user = '';
  List<LatLng> _polylineCoordinates = [
    LatLng(0, 0),
    // LatLng(-17.970, -67.1150),
    // LatLng(-17.975, -67.1180),
    // LatLng(-17.980, -67.1200),
  ];

  Timer? _timer;
  bool _backgroundStatus = false;
  int _countdown = 10;
  List danceAll = [];
  String vista = '0';

  @override
  void initState() {
    super.initState();
    // showNotification('Bienvenido a la aplicación de Carnaval Oruro', 0);
    _statusBackGround();
    getPath().then((value) => print(value));
    // moveteCamaraMyLocationAnimate();
    linesGet();
    // getUser();
    final service = FlutterBackgroundService();
    service.on('updateLocation').listen((event) {
      if (event != null) {
        setState(() {
          globals.latitude = event['latitude'];
          globals.longitude = event['longitude'];
        });
        //
        // Mover la cámara a la nueva ubicación
        _mapController.move(LatLng(globals.latitude, globals.longitude), 18.0);
      }
    });
    service.on('updateCountdown').listen((event) {
      if (event != null) {
        setState(() {
          _countdown = event['countdown'];
        });
      }
    });
    initSocket();
  }

  initSocket() async {
    globals.socket.emit('danceAll');
    globals.socket.connect();
    globals.socket.on('connect', (_) {
      print('Conectado al servidor');
      globals.swSocket = true;
    });
    globals.socket.on('disconnect', (_) {
      print('Desconectado del servidor');
      globals.swSocket = false;
    });
    // danceAll
    globals.socket.on('danceAll', (data) {
      // print('danceAll: $data');
      // {cog: {value: 1760}, dancers: [{id: 1, name: GRAN TRADICIONAL AUTENTICA DIABLADA ORURO, imagen: diablada.png, lat: -17.97008232979924, lng: -67.11217403411867, video: W4s7d_4Erwo, history: No hay historia}, {id: 2, name: FRATERNIDAD HIJOS DEL SOL LOS INCAS, imagen: incas.png, lat: 0, lng: 0, video: W4s7d_4Erwo, history: No hay historia}, {id: 3, name: CONJUNTO FOLKLORICO MORENADA ZONA NORTE, imagen: morenada.png, lat: 0, lng: 0, video: W4s7d_4Erwo, history: No hay historia}, {id: 4, name: FRAT. ARTISTICA ZAMPOÑEROS HIJOS DEL PAGADOR, imagen: zamponeros.png, lat: 0, lng: 0, video: W4s7d_4Erwo, history: No hay historia}, {id: 5, name: CENTRO TRADICIONAL NEGRITOS DE PAGADOR, imagen: negritos.png, lat: 0, lng: 0, video: W4s7d_4Erwo, history: No hay historia}, {id: 6, name: CONJUNTO FOLKLORICO AHUATIRIS, imagen: antawaras.png, lat: 0, lng: 0, video: W4s7d_4Erwo, history: No hay historia}, {id: 7, name: CONJUNTO WACA WACAS SAN AGUSTIN DERECHO, imagen: wacatoncoris.png, lat: 0, lng: 0, video: W4s7d_4Erwo
      print( data['dancers']);
      globals.socket.emit('cogsMore');
      danceAll = data['dancers'];
      vista = data['cog']['value'].toString();
      loading = false;
      setState(() {});
    });
  //   this.socket.on('danceOne', (data) => {
  //   this.$store.loading = false
  //   // console.log('danceOne', data)
  //   const id = data.id
  //   const findDancer = this.$store.dancers.find((d) => parseInt(d.id) === parseInt(id))
  //   if (findDancer) {
  //     findDancer.lat = data.lat
  //     findDancer.lng = data.lng
  //   }
  //   this.$store.cog = data.cog.value
  //   // por socket aumentar el contador de cogs
  //   this.socket.emit('cogsMore')
  // })
    globals.socket.on('danceOne', (data) {
      print('danceOne: $data');
      globals.socket.emit('cogsMore');
      vista = data['cog']['value'].toString();
      final id = data['id'];
      final findDancer = danceAll.firstWhere((d) => double.parse(d['id'].toString()) == double.parse(id.toString()), orElse: () => {});
      if (findDancer != null) {
        print('findDancer: $findDancer');
        findDancer['lat'] = double.parse(data['lat'].toString()).toString();
        findDancer['lng'] = double.parse(data['lng'].toString()).toString();
      }
      setState(() {});
    });
  }

  getUser() async {
    // final response = await DatabaseHelper().getUser();
    user = 'Usuario';
    setState(() {});
  }

  linesGet() async {
    final response = await DatabaseHelper().lineas();
    _polylineCoordinates = [];
    for (var item in response) {
      // print(item);
      // print(item[0]);
      _polylineCoordinates.add(LatLng(item[0], item[1]));
    }
    setState(() {});
  }

  _statusBackGround() async {
    final service = FlutterBackgroundService();
    var isRunning = await service.isRunning();
    if (isRunning) {
      _backgroundStatus = true;
    } else {
      _backgroundStatus = false;
    }
    setState(() {});
  }

  _backGround() async {
    final service = FlutterBackgroundService();
    var isRunning = await service.isRunning();
    if (isRunning) {
      service.invoke("stopService");
      _backgroundStatus = false;
    } else {
      service.startService();
      _backgroundStatus = true;
    }
    setState(() {
      _countdown = 10;
      _backgroundStatus = _backgroundStatus;
    });
  }

  // void _toggleLocationSending() async {
  //   if (_isSendingLocation) {
  //     // Si ya se está enviando, detener el envío
  //     setState(() {
  //       _isSendingLocation = false;
  //     });
  //     _timer?.cancel(); // Detiene el temporizador
  //   } else {
  //     // Inicia el envío de ubicación cada 5 segundos
  //     setState(() {
  //       _isSendingLocation = true;
  //     });
  //     _timer = Timer.periodic(Duration(seconds: 5), (timer) async {
  //       await _sendLocation();
  //     });
  //   }
  // }

  Future<void> moveteCamaraMyLocationAnimate() async {
    final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    _mapController.move(LatLng(position.latitude, position.longitude), 16.0);
    globals.latitude = position.latitude;
    globals.longitude = position.longitude;
    setState(() {
      // myLatitud = position.latitude;
      // myLongitud = position.longitude;
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancela el temporizador al salir
    super.dispose();
  }

  Future<String> getPath() async {
    final cacheDirectory = await getTemporaryDirectory();
    return cacheDirectory.path;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        // Hace la barra de estado transparente
        statusBarIconBrightness: Brightness.dark,
        // Iconos claros (para fondos oscuros)
        statusBarBrightness: Brightness.dark, // Brillo del contenido (para iOS)
      ),
      // child: Scaffold(
      //   // appBar: AppBar(
      //   //   title: Text('Carnaval Oruro'),
      //   // ),
      //   backgroundColor: Colors.grey[400],
      //   body: Center(
      //     child: Column(
      //       mainAxisAlignment: MainAxisAlignment.center,
      //       children: [
      //         Text('Bienvenido a la aplicación de Carnaval Oruro'),
      //         ElevatedButton(
      //           onPressed: _backGround,
      //           style: ElevatedButton.styleFrom(
      //             backgroundColor: _backgroundStatus ? Colors.red : Colors.green, // Cambia el color
      //             foregroundColor: Colors.white, // Cambia el color del texto
      //           ),
      //           child: Text(_backgroundStatus ? 'Enviando' : 'Mandar ubicación',style: TextStyle(fontSize: 20)),
      //         ),
      //         SizedBox(height: 20),
      //         ElevatedButton(
      //           onPressed: () async {
      //             await DatabaseHelper().logout();
      //             Navigator.pushReplacementNamed(context, '/');
      //           },
      //           child: Text('Cerrar sesión'),
      //         ),
      //       ],
      //     ),
      //   ),
      // ),
      child: Scaffold(
          backgroundColor: Colors.grey[400],
          body: Stack(children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(-17.965, -67.1125),
                initialZoom: 15.0,
                maxZoom: 21.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: _selectedMapUrl,
                  userAgentPackageName: 'dev.fleaflet.flutter_map.example',
                  tileProvider: CachedTileProvider(
                    maxStale: const Duration(days: 360),
                    store: HiveCacheStore(
                      '/data/user/0/com.example.carnaval/cache',
                      hiveBoxName: 'HiveCacheStore',
                    ),
                  ),
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _polylineCoordinates,
                      strokeWidth: 7.0,
                      color: Colors.blue,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    for (var item in danceAll)
                      Marker(
                        width: 120.0,
                        height: 75.0,
                        point: LatLng(double.parse(item['lat']), double.parse(item['lng'])),
                        child: Transform.translate(
                          offset: Offset(20, 20), // Ajusta el desplazamiento hacia arriba
                          child: Column(
                            mainAxisSize: MainAxisSize.min, // Evita que la columna crezca innecesariamente
                            children: [
                              Image.asset('assets/images/${item['imagen']}', width: 40, height: 40),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                child: Center(
                                  child: Text(
                                    item['name'],
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.black,
                                      height: 1.1,
                                    ),
                                  ),
                                ),
                                decoration: BoxDecoration(
                                  color: Color(0xFFf9bb61),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Marker(
                      width: 80.0,
                      height: 80.0,
                      point: LatLng(globals.latitude, globals.longitude),
                      child: Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40.0,
                      ),
                    ),
                  ],
                ),
                Positioned(
                    top: 50,
                    left: 15,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Morenada Central',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Image.asset('assets/images/logoCentral.png', width: 100, height: 100)
                          ),
                          SizedBox(height: 10),
                          ElevatedButton.icon(
                            // onPressed: () async {
                            //   globals.socket.emit('danceAll');
                            // },
                            onPressed: () async {
                              setState(() {
                                loading = true;
                              });
                              // await linesGet();
                              globals.socket.emit('danceAll');
                            },
                            icon: Icon(Icons.refresh, color: Colors.white),
                            label: loading ? CircularProgressIndicator() : Text('Actualizar'),
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.resolveWith<Color>(
                                    (Set<MaterialState> states) {
                                  if (states.contains(MaterialState.pressed)) {
                                    return Colors.green.shade700; // Color más oscuro cuando se presiona
                                  }
                                  return Colors.green; // Color normal
                                },
                              ),
                              foregroundColor: MaterialStateProperty.all(Colors.white),
                              elevation: MaterialStateProperty.resolveWith<double>(
                                    (Set<MaterialState> states) {
                                  if (states.contains(MaterialState.pressed)) {
                                    return 2.0; // Menos elevación cuando se presiona
                                  }
                                  return 6.0; // Elevación normal
                                },
                              ),
                              shape: MaterialStateProperty.all(
                                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          Chip(
                            label: Text(
                                'Vistas '+ vista,
                                style: TextStyle(color: Colors.white)
                            ),
                            avatar: CircleAvatar(
                              backgroundColor: Colors.redAccent,
                              child: Icon(Icons.remove_red_eye,color: Colors.white),
                            ),
                            backgroundColor: Colors.redAccent,
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          ),
                          // Row(
                          //   children: [
                          //     Icon(Icons.person, color: Colors.black),
                          //     Text(' ' + user! ?? 'asas',
                          //         style: TextStyle(
                          //             fontSize: 20,
                          //             color: Colors.black,
                          //             fontWeight: FontWeight.bold)),
                          //   ],
                          // ),
                          // ElevatedButton.icon(
                          //   onPressed: () async {
                          //     // confirm
                          //     // await DatabaseHelper().logout();
                          //     // Navigator.pushReplacementNamed(context, '/');
                          //     showDialog(
                          //       context: context,
                          //       builder: (BuildContext context) {
                          //         return AlertDialog(
                          //           title: Text('Cerrar sesión'),
                          //           content:
                          //               Text('¿Estás seguro de cerrar sesión?'),
                          //           actions: [
                          //             TextButton(
                          //               onPressed: () {
                          //                 Navigator.pop(context);
                          //               },
                          //               child: Text('Cancelar'),
                          //             ),
                          //             TextButton(
                          //               onPressed: () async {
                          //                 await DatabaseHelper().logout();
                          //                 Navigator.pushReplacementNamed(
                          //                     context, '/');
                          //               },
                          //               child: Text('Aceptar'),
                          //             ),
                          //           ],
                          //         );
                          //       },
                          //     );
                          //   },
                          //   icon: Icon(Icons.logout, color: Colors.white),
                          //   label: Text('Cerrar sesión'),
                          //   style: ElevatedButton.styleFrom(
                          //     backgroundColor: Colors.red, // background
                          //     foregroundColor: Colors.white, // foreground
                          //   ),
                          // ),
                        ])),
                Positioned(
                  top: 20,
                  right: 20,
                  child: Column(
                    children: [
                      SizedBox(
                        height: 20,
                      ),
                      Container(
                        padding: EdgeInsets.only(left: 10, right: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedMapUrl,
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedMapUrl = newValue;
                              });
                            }
                          },
                          items: _mapTypes.map<DropdownMenuItem<String>>((map) {
                            return DropdownMenuItem<String>(
                              value: map['url']!,
                              child: Text(map['name']!),
                            );
                          }).toList(),
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(top: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: loadingLocation
                            ? CircularProgressIndicator()
                            : IconButton(
                                onPressed: () async {
                                  setState(() {
                                    loadingLocation = true;
                                  });
                                  await moveteCamaraMyLocationAnimate();
                                  setState(() {
                                    loadingLocation = false;
                                  });
                                },
                                icon: Icon(Icons.my_location),
                              ),
                      ),
                      // boton de dirrecionar al norte
                      Container(
                        margin: EdgeInsets.only(top: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: IconButton(
                          onPressed: () {
                            _mapController.rotate(0.0);
                            _mapController.move(LatLng(-17.965, -67.1125), 15.0);
                            // LatLng(-17.965, -67.1125)
                          },
                          icon: Icon(Icons.navigation),
                        ),
                      ),
                      //   bbootn de mandar ubicacion
                      // ElevatedButton.icon(
                      //   icon: Icon(Icons.send, color: Colors.white),
                      //   onPressed: _backGround,
                      //   style: ElevatedButton.styleFrom(
                      //     backgroundColor: _backgroundStatus
                      //         ? Colors.red
                      //         : Colors.green, // Cambia el color
                      //     foregroundColor:
                      //     Colors.white, // Cambia el color del texto
                      //   ),
                      //   label: Text(
                      //     _backgroundStatus
                      //         ? 'Enviando (${_countdown})'
                      //         : 'Mandar ',
                      //   ),
                      // ),
                    ],
                  ),
                )
              ],
            ),
          ])),
    );
  }
}
