import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../pages/home_page.dart';
import 'login_or_register.dart';

/*
Auth Gate

Verify if the user is connected or not
----------------------------------------------------

Connected => redirect to homepage
Not connected => to login
*/

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  // UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(stream: FirebaseAuth.instance.authStateChanges(), builder: (context, snapshot){
        // utilisateur connecté
        if(snapshot.hasData){
          return const HomePage();
        } else {
          return LoginOrRegister();
        }
      }),
    );
  }
}
