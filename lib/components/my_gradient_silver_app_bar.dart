import 'package:flutter/material.dart';

/*
A custom SliverAppBar with gradient background and title.
Used at the top of the blocked numbers page.

*/

class MyGradientSliverAppBar extends StatelessWidget {
  final String title;

  const MyGradientSliverAppBar({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF002C73),
              Color(0xFFFF06EA),
            ],
          ),
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 24,
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    );
  }
}