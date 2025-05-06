import 'package:flutter/material.dart';
import '../components/my_button.dart';
import '../components/my_text_field.dart';
import '../services/auth/auth_service.dart';

/*
* Login Page
*un utilisateur peut se connecter avec :
* - email
* - mdp
*
* -----------------------------------------------------
*
* si l'utilisateur est authentifié => redirection vers homepage
* si le compte n'existe pas ,lien vers registerpage */

class LoginPage extends StatefulWidget {
  final void Function()? onTap;

  const LoginPage({
    super.key,
    required this.onTap,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _auth = AuthService();

  //textcontroller
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void login() async {
    try {
      // on essaie de se connecter avec les infos donnes par l'utilisateur
      await _auth.loginEmailPassword(
          emailController.text, passwordController.text);
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
  }

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
                "Noous sommes heureux de vous voir !",
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

              // password
              MyTextField(
                  controller: passwordController,
                  hintText: "Saisissez votre mot de passe...",
                  obscureText: true),

              const SizedBox(
                height: 15,
              ),

              // forgotten password
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "Mot de passe oublié ?",
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(
                height: 15,
              ),

              // button log in
              MyButton(
                text: "Connexion",
                onTap: login,
              ),

              const SizedBox(
                height: 15,
              ),

              // link to register page
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Pas encore de compte ?",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 5),
                  GestureDetector(
                    onTap: widget.onTap,
                    child: Text(
                      "Créez un compte !",
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
