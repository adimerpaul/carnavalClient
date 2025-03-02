import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;
class DatabaseHelper{
  static final DatabaseHelper _instance = DatabaseHelper.internal();
  static Database? _database;
  static String? url = dotenv.env['API_URL'];
  factory DatabaseHelper() => _instance;
  DatabaseHelper.internal();
  Future<Database?> get db async {
    if (_database != null) {
      return _database;
    }
    _database = await initDb();
    return _database;
  }
  Future<Database> initDb() async {
    String path = join(await getDatabasesPath(), 'database.db');
    var db = await openDatabase(path, version: 1, onCreate: _onCreate);
    return db;
  }
  void _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        id INTEGER,
        user_id INTEGER,
        name TEXT,
        email TEXT,
        dancer_id INTEGER,
        token TEXT,
        url TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE locations(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        latitude REAL,
        longitude REAL,
        timestamp TEXT
      )
    ''');
  }
  // lineas
  Future lineas() async {
    var url = dotenv.env['API_URL']! + '/lineas';
    var response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print("API request failed with status: ${response.statusCode}");
      return [];
    }
  }
  Future login(String username, String password) async {
    var url = dotenv.env['API_URL']! + '/login';
    var response = await http.post(Uri.parse(url), body: {
      'nickname': username,
      'password': password
    });

    print('API response: ${response.body}'); // Para verificar la respuesta de la API

    if (response.statusCode == 200) {
      var res = jsonDecode(response.body);

      // Verifica que la respuesta tenga los datos necesarios
      if (res['user'] == null || res['token'] == null) {
        print("Error: La respuesta de la API no contiene 'user' o 'token'");
        return;
      }

      var row = {
        'id': 1,
        'user_id': res['user']['id'],
        'name': res['user']['name'],
        'email': res['user']['email'],
        'dancer_id': res['user']['dancer_id'],
        'token': res['token'],
        'url': dotenv.env['API_URL']
      };

      try {
        Database? db = await this.db;
        if (db == null) {
          print("Database is not initialized.");
          return;
        }
        await db.delete('users', where: 'id = ?', whereArgs: [1]);
        await db.insert('users', row);
        print("User inserted successfully");
      } catch (e) {
        print("Error inserting user: $e");
      }

      return {
        'user': res['user'],
        'token': res['token']
      };
    } else {
      print("API request failed with status: ${response.statusCode}");
      return {
        'user': null,
        'token': null
      };
    }
  }

  Future getUser() async {
    Database? db = await this.db;
    var res = await db!.query('users', where: 'id = ?', whereArgs: [1]);
    return res.isNotEmpty ? res.first : null;
  }
  Future deleteUser() async {
    Database? db = await this.db;
    return await db!.delete('users', where: 'id = ?', whereArgs: [1]);
  }
  Future logout() async {
    await deleteUser();
  }
  Future sendLocation(double latitude, double longitude) async {
    Database? db = await this.db;
    await db!.insert('locations', {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': DateTime.now().toIso8601String(),
    });
    print("Ubicación guardada: ($latitude, $longitude)");
  }

  Future insertLocation(Map<String, dynamic> location) async {
    var user = await getUser();

    if (user == null || user['token'] == null) {
      print("Error: Usuario no autenticado o token faltante.");
      return;
    }

    var url = user['url'] + '/dancersUpdate';
    var token = user['token']; // Obtén el token del usuario

    var response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token', // Agrega el token en el encabezado de autorización
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'lat': location['latitud'],
        'lng': location['longitud'],
        'id': user['dancer_id'].toString(),
      }),
    );
    // print('API response: ${response.body}');
  }
}