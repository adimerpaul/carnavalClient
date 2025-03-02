import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../addons/scaffold.dart';
import '../services/DatabaseHelper.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _loading = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _usernameController.text = '';
    _passwordController.text = '';
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {_loading = true;});
      var res =  await DatabaseHelper().login(_usernameController.text, _passwordController.text);
      print(res);
      if (res['user'] != null && res['token'] != null) {
        success(context, 'Bienvenido ${res['user']['name']}');
        Navigator.pushReplacementNamed(context, '/home');
      }else{
        error(context, 'Error al iniciar sesión');
      }
      setState(() {_loading = false;});
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent, // Hace la barra de estado transparente
        statusBarIconBrightness: Brightness.light, // Iconos claros (para fondos oscuros)
        statusBarBrightness: Brightness.dark, // Brillo del contenido (para iOS)
      ),
      child: Scaffold(
        backgroundColor: Colors.grey[400],
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Image.asset(
                    'assets/images/logofull.png',
                    height: 100,
                  ),
                  SizedBox(height: 20),
                  // Campo de nombre de usuario
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Nombre de usuario',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa tu nombre de usuario';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  // Campo de contraseña
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      border: OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    obscureText: !_isPasswordVisible,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa tu contraseña';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  // Botón de inicio de sesión
                  ElevatedButton(
                    onPressed: _loading ? null : _login,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 32.0),
                      child: _loading
                          ? CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                          : Text('Iniciar sesión', style: TextStyle(fontSize: 20)),
                    ),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      backgroundColor: Colors.blueAccent, // Color del botón
                      foregroundColor: Colors.white,
                    ),
                  ),
                  SizedBox(height: 20),
                  // Enlace para crear cuenta
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("¿Nuevo usuario? "),
                      GestureDetector(
                        onTap: () {
                          // Navegar a la página de registro
                        },
                        child: Text(
                          "Crear cuenta",
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}