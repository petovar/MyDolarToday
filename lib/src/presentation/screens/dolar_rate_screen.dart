import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/exchange_rates.dart';
import '../../providers/rate_provider.dart' show RateProvider;
import '../../providers/theme_provider.dart' show ThemeProvider;
import '../widgets/widgets.dart';

class DolarRateScreen extends StatelessWidget {
  const DolarRateScreen({super.key});

  // Lógica para el botón de compartir
  void _shareRates(BuildContext context) {
    final provider = context.read<RateProvider>();
    final rate = provider.getCurrentRate();
    final currencyName = provider.selectedCurrency == CurrencyOption.dolarBCV
        ? 'Dólar BCV'
        : provider.selectedCurrency == CurrencyOption.usdt
        ? 'USDT (P2P)'
        : 'EURO (BCV Ref.)';

    final conversion = provider.usdInputController.text != '0.00'
        ? 'Conversión: ${provider.usdInputController.text} $currencyName = ${provider.bsResultController.text} Bs\n'
        : '';

    final message =
        'Tasa de Cambio Actual:\nMoneda: $currencyName\n1 $currencyName = ${provider.rateFormat.format(rate)} Bs\n${conversion}Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(provider.rates.updateDate)}';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Compartir:\n$message'),
        duration: const Duration(seconds: 5),
        backgroundColor: Colors.blueGrey,
      ),
    );
    SharePlus.instance.share(ShareParams(text: message));
  }

  @override
  Widget build(BuildContext context) {
    // Usamos context.watch para reconstruir solo las partes necesarias
    final provider = context.watch<RateProvider>();
    final String formattedDate = DateFormat(
      'dd/MM/yyyy HH:mm',
    ).format(provider.rates.updateDate);

    // Texto de propiedad que solicitaste
    const String ownershipText = '(Propiedad de Pedro Tovar.)';

    return Scaffold(
      appBar: AppBar(
        title: const Text('TASA DE DIVISAS'),
        centerTitle: true,
        actions: [
          // Botón de Cambio de Tema
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () {
              context.read<ThemeProvider>().toggleTheme();
            },
          ),
          // Botón de Recarga
          IconButton(
            icon: provider.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: provider.isLoading
                ? null
                : () async {
                    await provider.fetchRates();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          provider.lastError == null
                              ? 'Tasas actualizadas correctamente.'
                              : 'Error al actualizar: ${provider.lastError}',
                        ),
                        backgroundColor: provider.lastError == null
                            ? Colors.green
                            : Colors.red,
                      ),
                    );
                  },
          ),
          // Botón de Compartir
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareRates(context),
          ),
        ],
      ),
      // 1. Envolvemos el cuerpo en un Stack para superponer el texto
      body: Stack(
        children: [
          // 2. Contenido principal desplazable
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              20.0,
              20.0,
              20.0,
              60.0,
            ), // Ajustar el padding inferior para dejar espacio al footer
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // 1. DropdownButtonFormField para seleccionar la divisa
                DropdownButtonFormField<CurrencyOption>(
                  initialValue: provider.selectedCurrency,
                  decoration: const InputDecoration(
                    labelText: 'Seleccionar Divisa',
                    prefixIcon: Icon(Icons.money, color: Colors.teal),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: CurrencyOption.dolarBCV,
                      child: Text('DOLAR BCV'),
                    ),
                    DropdownMenuItem(
                      value: CurrencyOption.usdt,
                      child: Text('USDT (Binance P2P)'),
                    ),
                    DropdownMenuItem(
                      value: CurrencyOption.euro,
                      child: Text('EURO (BCV Ref.)'),
                    ),
                  ],
                  onChanged: (CurrencyOption? newValue) {
                    if (newValue != null) {
                      provider.setSelectedCurrency(newValue);
                    }
                  },
                ),

                const SizedBox(height: 30),

                // 2. Campo para ingresar la cantidad de dólares/divisa (Cálculo Forward)
                const CurrencyInputField(),

                const SizedBox(height: 20),

                // 3. Campo de texto para mostrar la tasa de cambio (ReadOnly)
                TextFormField(
                  textAlign: TextAlign.right,
                  controller: provider.rateController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Tasa de Cambio (1 Divisa = Bs)',
                    prefixIcon: Icon(
                      Icons.currency_exchange,
                      color: Colors.teal,
                    ),
                    suffixIcon: Icon(Icons.no_encryption),
                    hintText: 'Cargando...',
                  ),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),

                const SizedBox(height: 20),

                // 4. Campo de texto para el resultado de la conversión (Editable para Cálculo Inverso)
                const BsResultField(),

                const SizedBox(height: 40),

                // Botón de recarga
                ElevatedButton.icon(
                  onPressed: provider.isLoading
                      ? null
                      : () => context.read<RateProvider>().fetchRates(),
                  icon: provider.isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        )
                      : const Icon(Icons.cloud_download),
                  label: Text(
                    provider.isLoading ? 'ACTUALIZANDO...' : 'RECARGAR TASAS',
                  ),
                ),

                const SizedBox(height: 30),

                // Fecha de Última Actualización
                Center(
                  child: Text(
                    'Última Tasa Obtenida: $formattedDate',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12, // Fuente más pequeña pero legible
                    ),
                  ),
                ),
                // Aquí se puede añadir más SizedBox si el contenido es demasiado corto
                // para asegurar que el contenido desplazable no interfiera con el footer anclado.
                const SizedBox(height: 20),
              ],
            ),
          ),

          // 3. Texto de Propiedad anclado al fondo (Footer)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).scaffoldBackgroundColor, // Fondo para evitar que el texto se mezcle con el contenido
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 5.0,
                    spreadRadius: 1.0,
                    offset: Offset(0, -1),
                  ),
                ],
              ),
              child: Text(
                ownershipText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14, // Tamaño legible
                  color: Colors.grey[600], // Tono gris
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
