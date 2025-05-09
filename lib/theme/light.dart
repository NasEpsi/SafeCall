import 'package:flutter/material.dart';

ThemeData lightMode = ThemeData(
brightness: Brightness.light,
colorScheme: const ColorScheme.light(
primary: Color(0xFF2C3E50),      // Bleu-gris foncé moderne pour les éléments principaux
secondary: Color(0xFF2980B9),    // Bleu vif pour les accents (boutons, liens)
surface: Color(0xFFF4F6F8),       // Fond clair général
background: Color(0xFFFFFFFF),   // Arrière-plan de base
error: Color(0xFFE74C3C),        // Rouge doux pour erreurs
onPrimary: Color(0xFFFFFFFF),    // Texte sur boutons primaires
onSecondary: Color(0xFFFFFFFF),  // Texte sur boutons secondaires
onSurface: Color(0xFF2C3E50),    // Texte sur fond clair
onBackground: Color(0xFF2C3E50), // Texte général
onError: Color(0xFFFFFFFF),      // Texte sur fond d'erreur
),
);

