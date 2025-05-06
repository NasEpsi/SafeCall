import 'package:flutter/material.dart';
/*
  *
  * Text Fied of a form where user can write
  *
  * -----------------------------------------------------
  *
  * It needs
  * - textController who allow to access to what the user wrote
  * - a placeholder
  * - obscure text (booleen that will hide the text when its true)
  *  */

class MyTextField extends StatelessWidget {
  // controller
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;

  //constructor
  const MyTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.obscureText,
  });

  //UI
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        // border when its not selected
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color:Theme.of(context).colorScheme.tertiary,
          ),
          borderRadius: BorderRadius.circular(12),
        ),


        // border when its selected
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
          ),
          borderRadius: BorderRadius.circular(12),
        ),

        fillColor: Theme.of(context).colorScheme.inversePrimary,
        filled: true,

        hintText: hintText,
        hintStyle: TextStyle(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
