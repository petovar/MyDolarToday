import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/rate_provider.dart' show RateProvider;
// import '../providers/rate_provider.dart';

// Widget para el campo de entrada de la cantidad de Divisa (USD/EUR/USDT)
class CurrencyInputField extends StatelessWidget {
  const CurrencyInputField({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<RateProvider>();

    return TextFormField(
      controller: provider.usdInputController,
      onChanged: (value) => provider.calculateForward(),
      focusNode: provider.usdInputFocusNode,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.right,
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          RegExp(r'^\d*[.]?\d*'), // Permite números, coma o punto
          // RegExp(r'^\d*[,.]?\d*'), // Permite números, coma o punto
        ),
      ],
      decoration: InputDecoration(
        labelText: 'Cantidad a convertir',
        hintText: 'Ej: 100.50',
        prefixIcon: const Icon(Icons.attach_money, color: Colors.green),
        suffixIcon: IconButton(
          icon: const Icon(Icons.clear, color: Colors.grey),
          onPressed: provider.clearUsdInput,
        ),
      ),
    );
  }
}

// Widget para el campo de entrada/salida de Bolívares
class BsResultField extends StatelessWidget {
  const BsResultField({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<RateProvider>();

    // El formato de número para el input de Bolívares debe ser numérico
    // y permitir el formato de miles para que el usuario pueda escribir.
    // La lógica de limpieza se hará en el provider.
    return TextFormField(
      textAlign: TextAlign.right,
      controller: provider.bsResultController,
      onChanged: (value) => provider.calculateInverse(),
      focusNode: provider.bsResultFocusNode,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          RegExp(
            r'[\d,.]',
          ), // Permite números, comas y puntos (para formato Bs)
        ),
      ],
      decoration: const InputDecoration(
        labelText: 'Resultado en Bolívares (Bs)',
        prefixIcon: Icon(Icons.payment, color: Colors.blue),
        suffixIcon: IconButton(
          icon: Icon(Icons.clear, color: Colors.grey),
          onPressed: null,
        ),
        hintText: '0.00 Bs',
      ),
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.blue,
      ),
    );
  }
}
