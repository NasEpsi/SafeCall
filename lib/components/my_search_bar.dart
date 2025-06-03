import 'package:flutter/material.dart'
    '';
class MySearchBar extends StatelessWidget {
  final TextEditingController controller;

  const MySearchBar({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Rechercher un numéro ou un nom...',
          prefixIcon: const Icon(Icons.search, color: Color(0xFF007AFF)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }
}