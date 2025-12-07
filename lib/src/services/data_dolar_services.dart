import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart' as dom;
import 'package:http/http.dart' as http;
import '../models/p2porder_model.dart';

class DolarRateService {
  final String bcvUrl = "http://www.bcv.org.ve/";

  // Cliente HTTP temporal para BCV (maneja certificados no confiables)
  Future<double> _fetchValueFromBcv(int targetIndex) async {
    // Usamos HttpClient para manejar certificados autofirmados del BCV si es necesario.
    HttpClient client = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;

    try {
      final url = Uri.parse(bcvUrl);
      final request = await client.getUrl(url);
      final response = await request.close();

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        var document = parse(responseBody);

        // El scraping depende de la estructura HTML. Se busca el valor BCV.
        final List<dom.Element> strongElements = document.querySelectorAll(
          'div.col-sm-6.col-xs-6.centrado strong',
        );

        if (strongElements.length > targetIndex) {
          final dom.Element targetElement = strongElements[targetIndex];
          String valueText = targetElement.text.trim();

          // Reemplazamos separador de miles y usamos punto para decimal
          valueText = valueText.replaceAll('.', '').replaceAll(',', '.');
          final double? value = double.tryParse(valueText);

          client.close();
          return value ?? -1.0;
        }
      }
      client.close();
      return -1.0;
    } catch (e) {
      debugPrint('Excepción al obtener BCV (Index $targetIndex): $e');
      return -1.0;
    }
  }

  // Generalmente Dolar es el 5to elemento (índice 4 en 0-based)
  Future<double> fetchDolarValue() async => _fetchValueFromBcv(4);

  // Generalmente Euro es el 1er elemento (índice 0 en 0-based)
  Future<double> fetchEuroValue() async => _fetchValueFromBcv(0);

  // Obtiene el precio del USDT a través del API P2P de Binance
  Future<double> getUSDTPriceInVES() async {
    const apiUrl =
        'https://p2p.binance.com/bapi/c2c/v2/friendly/c2c/adv/search';
    final requestBody = jsonEncode({
      "asset": "USDT",
      "fiat": "VES",
      "tradeType": "BUY",
      "page": 1,
      "rows": 10,
      "payTypes": [],
      "publisherType": null,
    });

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final List data = jsonResponse['data'] ?? [];

        if (data.isEmpty) return 0.0;

        // =========================================================
        // === CÁLCULO DEL PROMEDIO (Promedio de las 10 órdenes) ===
        // =========================================================
        final orders = data.map((item) => P2POrder.fromJson(item)).toList();
        // 1. Sumar todos los precios usando 'fold'
        final double totalSum = orders.fold(
          0.0,
          (previousValue, order) => previousValue + order.price,
        );

        // 2. Dividir la suma por el número total de órdenes
        final double averagePrice = totalSum / orders.length;

        debugPrint(
          'Precios de USDT (${orders.length} órdenes): ${orders.map((o) => o.price).toList()}',
        );
        debugPrint('Promedio calculado: $averagePrice');

        return averagePrice;

        // // Se usa la primera orden (la más barata al comprar)
        // final orders = data.map((item) => P2POrder.fromJson(item)).toList();
        // return orders.first.price;
      } else {
        debugPrint(
          'Fallo la carga de la API de Binance P2P. Código: ${response.statusCode}',
        );
        return 0.0;
      }
    } catch (e) {
      debugPrint('Error al obtener la cotización USDT: $e');
      return 0.0;
    }
  }
}
