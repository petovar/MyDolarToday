import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/exchange_rates.dart';
import '../services/data_dolar_services.dart';

class RateProvider with ChangeNotifier {
  // ====================================================================
  // ESTADO INTERNO
  // ====================================================================
  CurrencyOption _selectedCurrency = CurrencyOption.dolarBCV;
  ExchangeRates _rates = ExchangeRates.empty();
  bool _isLoading = false;
  String? _lastError;

  bool _usdInputHasfoscus = false;
  bool _bsResultHasfoscus = false;

  // Controladores de Texto (Gestionados por el Provider)
  final TextEditingController usdInputController = TextEditingController(
    text: '1.0',
  );
  final TextEditingController rateController = TextEditingController();
  final TextEditingController bsResultController = TextEditingController();

  final DolarRateService _rateService = DolarRateService();

  FocusNode usdInputFocusNode = FocusNode();
  FocusNode bsResultFocusNode = FocusNode();

  // Formateadores
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'es_VE',
    symbol: 'Bs',
    decimalDigits: 2,
  );
  final NumberFormat rateFormat = NumberFormat('#,##0.00', 'es_VE');

  // ====================================================================
  // GETTERS (para que la vista acceda al estado)
  // ====================================================================

  CurrencyOption get selectedCurrency => _selectedCurrency;
  ExchangeRates get rates => _rates;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;

  // ====================================================================
  // LÓGICA DE INICIALIZACIÓN Y DISPOSE
  // ====================================================================

  RateProvider() {
    usdInputFocusNode.addListener(() {
      if (usdInputFocusNode.hasFocus) {
        usdInputController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: usdInputController.text.length,
        );
        _usdInputHasfoscus = true;
        debugPrint('USD Input has focus: $_usdInputHasfoscus');
      } else {
        // Formatear el valor al perder el foco
        final value = double.tryParse(usdInputController.text) ?? 0.0;
        usdInputController.text = value.toStringAsFixed(2);
        _usdInputHasfoscus = false;
        debugPrint('USD Input has focus: $_usdInputHasfoscus');
      }
    });

    bsResultFocusNode.addListener(() {
      if (bsResultFocusNode.hasFocus) {
        bsResultController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: bsResultController.text.length,
        );
        _bsResultHasfoscus = true;
        debugPrint('Bs Result has focus: $_bsResultHasfoscus');
      } else {
        // Formatear el valor al perder el foco
        final value = double.tryParse(bsResultController.text) ?? 0.0;
        bsResultController.text = _currencyFormat.format(value);
        _bsResultHasfoscus = false;
        debugPrint('Bs Result has focus: $_bsResultHasfoscus');
      }
    });

    // Inicializamos los listeners para los controladores de texto
    // usdInputController.addListener(_handleUsdInputChange); // Eliminado
    // bsResultController.addListener(_handleBsResultChange); // Eliminado
    // IMPORTANTE: Eliminamos los listeners de los controladores.
    // Esto evita los bucles infinitos y la corrupción del formato de entrada.
    // La conversión se dispara ahora desde el `onChanged` del TextFormField.
    _loadRates().then((_) {
      // Si la funcionalidad inversa es necesaria, se puede mantener el listener de Bs.
      // Pero para corregir el bug principal, lo eliminamos.
      // bsResultController.addListener(_handleBsResultChange);

      // Una vez cargadas las tasas, calculamos la conversión inicial.

      calculateForward();
    });
  }

  @override
  void dispose() {
    // Remoción de listeners y dispose de controladores
    // usdInputController.removeListener(_handleUsdInputChange); // Eliminado
    // bsResultController.removeListener(_handleBsResultChange); // Eliminado
    usdInputController.dispose();
    rateController.dispose();
    bsResultController.dispose();
    usdInputFocusNode.dispose();
    bsResultFocusNode.dispose();

    super.dispose();
  }

  // ====================================================================
  // PERSISTENCIA (Sin cambios)
  // ====================================================================

  Future<void> _saveRates(ExchangeRates rates) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('exchangeRates', jsonEncode(rates.toJson()));
  }

  Future<void> _loadRates() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString('exchangeRates');

    if (jsonString != null) {
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      _rates = ExchangeRates.fromJson(jsonMap);
    }
    _updateRateFields(notify: false); // No notificar, estamos en init
    // Si no hay datos, se llamará a _fetchRates() en la vista.
  }

  // ====================================================================
  // LÓGICA DE CARGA DE DATOS (Sin cambios)
  // ====================================================================

  Future<void> fetchRates() async {
    if (_isLoading) return;

    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      // 1. Obtener tasas
      final dolarBcv = await _rateService.fetchDolarValue();
      final euroBcv = await _rateService.fetchEuroValue();
      final usdtRate = await _rateService.getUSDTPriceInVES();

      // 2. Crear el nuevo objeto de tasas (usa el valor anterior si falla)
      final newRates = ExchangeRates(
        dolarBCV: dolarBcv > 0 ? dolarBcv : _rates.dolarBCV,
        usdt: usdtRate > 0 ? usdtRate : _rates.usdt,
        euro: euroBcv > 0 ? euroBcv : _rates.euro,
        updateDate: DateTime.now(),
      );

      // 3. Actualizar estado y persistir
      _rates = newRates;
      _isLoading = false;
      await _saveRates(newRates);

      // 4. Actualizar los campos y notificar a la UI
      _updateRateFields();
    } catch (e) {
      _isLoading = false;
      _lastError = e.toString();
      notifyListeners();
      debugPrint('Error en fetchRates: $e');
    }
  }

  // ====================================================================
  // CÁLCULO Y ACTUALIZACIÓN
  // ====================================================================

  double getCurrentRate() {
    switch (_selectedCurrency) {
      case CurrencyOption.dolarBCV:
        return _rates.dolarBCV;
      case CurrencyOption.usdt:
        return _rates.usdt;
      case CurrencyOption.euro:
        return _rates.euro;
    }
  }

  // Maneja el cambio de moneda seleccionado
  void setSelectedCurrency(CurrencyOption newValue) {
    if (_selectedCurrency != newValue) {
      _selectedCurrency = newValue;

      rateController.text = rateFormat.format(getCurrentRate());

      final double? amount = double.tryParse(
        usdInputController.text.replaceAll(',', '.'),
      );
      if (amount != null && amount > 0) {
        calculateForward();
      }

      notifyListeners();
    }
  }

  // Actualiza los campos de texto de tasa y recalcula el resultado
  void _updateRateFields({bool notify = true}) {
    final currentRate = getCurrentRate();

    // Actualizar el campo de texto de la tasa
    rateController.text = rateFormat.format(currentRate);

    // Recalcular el resultado (conversión Forward: USD -> Bs)
    calculateForward(); // Llamamos al método público actualizado

    if (notify) {
      notifyListeners();
    }
  }

  // *** FUNCIÓN CLAVE PARA LA SOLUCIÓN DEL BUG DE FORMATO ***
  // Ahora es pública y se llama desde el onChanged del CurrencyInputField
  void calculateForward() {
    String cleanInput = usdInputController.text.replaceAll(',', '.');

    final double? amount = double.tryParse(
      cleanInput.isEmpty ? '0.0' : cleanInput,
    );
    final double currentRate = getCurrentRate();

    if (amount != null && currentRate > 0) {
      final double result = amount * currentRate;
      bsResultController.text = _currencyFormat
          .format(result)
          .replaceAll(_currencyFormat.currencySymbol, '');
    } else {
      bsResultController.text = _currencyFormat
          .format(0.0)
          .replaceAll(_currencyFormat.currencySymbol, '');
    }

    notifyListeners();
  }

  // Mantenemos esta función si la tienes conectada a otro campo de BS para la conversión inversa.
  // Sin embargo, para solucionar tu problema, es mejor asegurarse de que el input USD solo use
  // calculateForward y no active esta lógica inmediatamente.
  void calculateInverse() {
    // 1. Intentar obtener el monto de Bolívares (Bs)
    if (!_bsResultHasfoscus) return;
    final String cleanBsText = bsResultController.text.replaceAll(
      ',',
      '.',
    ); // Usar punto como decimal
    // .replaceAll('.', '') // Quitar separadores de miles

    final double? bsAmount = double.tryParse(
      cleanBsText.isEmpty ? '0.0' : cleanBsText,
    );
    final double currentRate = getCurrentRate();

    if (bsAmount != null && currentRate > 0) {
      final double result = bsAmount / currentRate;
      // 2. Actualizar el campo de Divisa (USD/EUR/USDT)
      usdInputController.text = NumberFormat('0.00', 'es_VE').format(result);
    } else {
      usdInputController.text = NumberFormat('0.00', 'es_VE').format(0.0);
    }
  }

  // Limpiar el campo de divisas
  void clearUsdInput() {
    usdInputController.clear();
    calculateForward();
    // notifyListeners(); // Ya está dentro de calculateForward
  }
}
