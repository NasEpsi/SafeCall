import 'package:flutter/material.dart';

/*
* Button
*
*
* needs:
* a text
* a function onclick
*
* */

class MyButton extends StatelessWidget {
  // variable
  final String text;
  final void Function()? onTap;

  //constructor
  const MyButton({
    super.key,
    required this.text,
    required this.onTap,
  });

  // UI
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(25),
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(12)
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Theme.of(context).colorScheme.inversePrimary,

            ),

          ),
        ),
      ),
    );
  }
}
