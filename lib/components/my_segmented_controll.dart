import 'package:flutter/material.dart';

/*
Displays the segmented control and content based on the selected tab.


*/
class MySegmentedControl extends StatelessWidget {
  final List<String> segments;
  final int selectedIndex;
  final Function(int) onSegmentChanged;

  const MySegmentedControl({
    super.key,
    required this.segments,
    required this.selectedIndex,
    required this.onSegmentChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: segments.asMap().entries.map((entry) {
          int index = entry.key;
          String label = entry.value;

          return Expanded(
            child: GestureDetector(
              onTap: () => onSegmentChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: selectedIndex == index
                      ? const LinearGradient(
                    colors: [Color(0xFF002C73 ), Color(0xFFFF06EA )],
                  )
                      : null,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selectedIndex == index
                        ? Colors.white
                        : const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}