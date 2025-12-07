import 'package:flutter/material.dart';
import 'package:my_dolar_today/src/app.dart';

void main() {
  // Asegura que los bindings de Flutter estén inicializados para usar SharedPreferences
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const App());
}
