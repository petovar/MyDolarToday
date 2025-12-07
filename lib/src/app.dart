import 'package:flutter/material.dart';
import 'package:my_dolar_today/src/presentation/screens/dolar_rate_screen.dart';
import 'package:provider/provider.dart';

import 'providers/rate_provider.dart';

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) {
    // 1. Usamos ChangeNotifierProvider para crear e inyectar la instancia de RateProvider.
    // Esto hace que la lógica de negocio esté disponible para toda la aplicación.
    return ChangeNotifierProvider(
      create: (context) => RateProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Tasa de Divisas',
        theme: ThemeData(
          primarySwatch: Colors.teal,
          // Configuración visual para los TextField
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 15,
              horizontal: 15,
            ),
          ),
          // Estilo del botón
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        // La pantalla principal ahora puede acceder al RateProvider usando context.watch o context.read
        home: const DolarRateScreen(),
      ),
    );
  }
}
