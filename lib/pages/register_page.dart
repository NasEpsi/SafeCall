import 'package:flutter/material.dart';
import '../components/my_button.dart';
import '../components/my_text_field.dart';
import '../services/auth/auth_service.dart';

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
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();


  // methode to create an account
  void register() async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // if the password and the password again are the same, create the user
    if (passwordController.text == confirmPasswordController.text) {
      try {
        // This method already saves user info to Firestore
        await _auth.registerEmailPassword(
            emailController.text,
            passwordController.text,
            phoneController.text
        );
        // Close loading dialog on success
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        // Close loading dialog on error
        if (mounted) {
          Navigator.pop(context);
          showDialog(
            context: context,
            builder: (context) =>
                AlertDialog(
                  title: const Text("Error"),
                  content: Text(e.toString()),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("OK"),
                    ),
                  ],
                ),
          );
        }
      }
    } else {
      // Close loading dialog for password mismatch
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (context) =>
            AlertDialog(
              title: const Text("Error"),
              content: const Text("Les mots de passes ne correspondent pas"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
                ),
              ],
            ),
      );
    }
  }

    // Methode pour se connecter avec Google
    void signInWithGoogle() async {
      try {
        await _auth.signInWithGoogleService();
      } catch (e) {
        print(e);
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
          child: SingleChildScrollView(
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
                    fontWeight: FontWeight.bold,
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

                // champ phone number
                MyTextField(
                  controller: phoneController,
                  hintText: "Saisissez votre numéro de téléphone...",
                  obscureText: false,
                ),

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
                Divider(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  thickness: 1,
                ),

                const SizedBox(height: 10),
                GestureDetector(
                  onTap: signInWithGoogle,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Theme.of(context).colorScheme.primary),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/google.png', // Ton logo Google (à ajouter dans assets)
                          height: 24,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "Continuer avec Google",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
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
      ),
    );
  }
}