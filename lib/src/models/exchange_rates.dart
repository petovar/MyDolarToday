import 'package:flutter/material.dart';

// Enum para representar las opciones de divisas
enum CurrencyOption { dolarBCV, usdt, euro }

// Clase para almacenar las tasas de cambio y la fecha
@immutable
class ExchangeRates {
  final double dolarBCV;
  final double usdt;
  final double euro;
  final DateTime updateDate;

  const ExchangeRates({
    required this.dolarBCV,
    required this.usdt,
    required this.euro,
    required this.updateDate,
  });

  // Constructor para datos iniciales o vacíos
  ExchangeRates.empty()
    : dolarBCV = 0.0,
      usdt = 0.0,
      euro = 0.0,
      updateDate = DateTime.now();

  // Serialización a JSON para guardar en SharedPreferences
  Map<String, dynamic> toJson() => {
    'dolarBCV': dolarBCV,
    'usdt': usdt,
    'euro': euro,
    'updateDate': updateDate.toIso8601String(),
  };

  // Deserialización desde JSON para leer de SharedPreferences
  factory ExchangeRates.fromJson(Map<String, dynamic> json) {
    return ExchangeRates(
      dolarBCV: json['dolarBCV'] ?? 0.0,
      usdt: json['usdt'] ?? 0.0,
      euro: json['euro'] ?? 0.0,
      updateDate: DateTime.tryParse(json['updateDate'] ?? '') ?? DateTime.now(),
    );
  }
}
