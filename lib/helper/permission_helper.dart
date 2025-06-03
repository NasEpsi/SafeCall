import 'package:flutter/services.dart';

class PermissionService {
  static const MethodChannel _channel = MethodChannel('com.example.safecall/permissions');

  static Future<bool> checkPermissions() async {
    try {
      return await _channel.invokeMethod('checkPermissions');
    } catch (e) {
      print('Erreur lors de la vérification des permissions: $e');
      return false;
    }
  }

  static Future<bool> requestPermissions() async {
    try {
      return await _channel.invokeMethod('requestPermissions');
    } catch (e) {
      print('Erreur lors de la demande des permissions: $e');
      return false;
    }
  }

  static Future<void> openAppSettings() async {
    try {
      await _channel.invokeMethod('openAppSettings');
    } catch (e) {
      print('Erreur lors de l\'ouverture des paramètres: $e');
    }
  }
}