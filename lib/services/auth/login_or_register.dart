import 'package:flutter/material.dart';
import '../../pages/login_page.dart';
import '../../pages/register_page.dart';

/*
*
* This service will figure if we display the login or the register page*/

class LoginOrRegister extends StatefulWidget {
  const LoginOrRegister({super.key});

  @override
  State<LoginOrRegister> createState() => _LoginOrRegisterState();
}

class _LoginOrRegisterState extends State<LoginOrRegister> {
  // Initial state will be the login page

  bool showLoginPage=true;

  //toggle login et register page

  void togglePages() {
    setState(() {
      showLoginPage =!showLoginPage;
    });
  }

  //UI
  @override
  Widget build(BuildContext context) {
    if(showLoginPage) {
      return LoginPage(
        onTap: togglePages,
      );
    } else {
      return RegisterPage(
        onTap: togglePages,
      );
    }
  }
}
