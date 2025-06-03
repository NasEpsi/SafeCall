import 'package:flutter/services.dart';

class NativeBridge {
  static const MethodChannel _channel = MethodChannel('com.example.safecall/native_bridge');

  // Synchroniser les numéros bloqués avec le côté natif
  static Future<bool> updateBlockedNumbers(List<String> numbers) async {
    try {
      final result = await _channel.invokeMethod('updateBlockedNumbers', {
        'numbers': numbers,
      });
      return result as bool;
    } catch (e) {
      print('Erreur lors de la mise à jour des numéros bloqués: $e');
      return false;
    }
  }

  // Synchroniser les préfixes bloqués avec le côté natif
  static Future<bool> updateBlockedPrefixes(List<String> prefixes) async {
    try {
      final result = await _channel.invokeMethod('updateBlockedPrefixes', {
        'prefixes': prefixes,
      });
      return result as bool;
    } catch (e) {
      print('Erreur lors de la mise à jour des préfixes bloqués: $e');
      return false;
    }
  }

  // Récupérer les numéros bloqués depuis le côté natif
  static Future<List<String>> getBlockedNumbers() async {
    try {
      final result = await _channel.invokeMethod('getBlockedNumbers');
      return List<String>.from(result);
    } catch (e) {
      print('Erreur lors de la récupération des numéros bloqués: $e');
      return [];
    }
  }

  // Récupérer les préfixes bloqués depuis le côté natif
  static Future<List<String>> getBlockedPrefixes() async {
    try {
      final result = await _channel.invokeMethod('getBlockedPrefixes');
      return List<String>.from(result);
    } catch (e) {
      print('Erreur lors de la récupération des préfixes bloqués: $e');
      return [];
    }
  }

  // Vérifier si un numéro est bloqué
  static Future<bool> isNumberBlocked(String number) async {
    try {
      final result = await _channel.invokeMethod('isNumberBlocked', {
        'number': number,
      });
      return result as bool;
    } catch (e) {
      print('Erreur lors de la vérification du numéro: $e');
      return false;
    }
  }
}