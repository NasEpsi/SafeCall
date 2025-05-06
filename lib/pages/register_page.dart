import 'package:flutter/material.dart';
import '../components/my_button.dart';
import '../components/my_text_field.dart';
import '../services/auth/auth_service.dart';
import '../services/database/database_service.dart';

/*
*Register Page
*
*
* form who allow the user to create an account
*
* ---------------------
*
* we need :
* - email
* - password
* - password again
*  */

class RegisterPage extends StatefulWidget {
  final void Function()? onTap;

  const RegisterPage({
    super.key,
    required this.onTap,
  });

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _auth = AuthService();
  final _db = DatabaseService();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
  TextEditingController();

  // methode to create an account

  void register() async {
    // if the password and the password again are the same, create the user

    if (passwordController.text == confirmPasswordController.text) {
      try {
        await _auth.registerEmailPassword(
            emailController.text,
            passwordController.text
        );
        // if the account is created in Auth, we save the data in the database
        await _db.saveUserInfoInFirebase(
          email: emailController.text,
        );
      } catch (e) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(e.toString()),
            ),
          );
        }
      }
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Les mots de passes ne correspondent pas"),
        ),
      );
    }
  }

  //UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // logo
              Icon(
                Icons.lock_open_rounded,
                size: 60,
                color: Theme.of(context).colorScheme.primary,
              ),

              const SizedBox(
                height: 40,
              ),

              Text(
                "Créez votre compte !",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 16,
                ),
              ),

              const SizedBox(
                height: 5,
              ),

              // champ email
              MyTextField(
                  controller: emailController,
                  hintText: "Saisissez votre email...",
                  obscureText: false),

              const SizedBox(
                height: 15,
              ),

              // champMDP
              MyTextField(
                  controller: passwordController,
                  hintText: "Saisissez votre mot de passe...",
                  obscureText: true),

              const SizedBox(
                height: 15,
              ),

              // Password confirmation
              MyTextField(
                  controller: confirmPasswordController,
                  hintText: "Vérifiez votre mot de passe",
                  obscureText: true),

              const SizedBox(
                height: 15,
              ),

              // button create account
              MyButton(
                text: "Creez votre compte",
                onTap: register,
              ),

              const SizedBox(
                height: 15,
              ),

              // link to register page
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Déja un compte ?",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 5),
                  GestureDetector(
                    onTap: widget.onTap,
                    child: Text(
                      "Connectez vous ",
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
