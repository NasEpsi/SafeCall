import 'package:flutter/services.dart';

class CallLogService {
  static const MethodChannel _channel = MethodChannel('com.example.safecall/call_logs');

  // Fonction pour récupérer les appels récents
  Future<List<String>> getRecentCalls() async {
    try {
      final List<dynamic> calls = await _channel.invokeMethod('getRecentCalls');
      return List<String>.from(calls);
    } on PlatformException catch (e) {
      print("Erreur lors du chargement des appels : ${e.message}");
      return [];
    }
  }
}