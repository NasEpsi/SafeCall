import 'package:flutter/material.dart';
import '../helper/permission_helper.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    bool hasPermissions = await PermissionService.checkPermissions();

    if (!hasPermissions) {
      bool granted = await PermissionService.requestPermissions();

      if (!granted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Permissions requises'),
            content: Text('Cette application a besoin d\'accéder aux appels et contacts pour fonctionner correctement.'),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await PermissionService.openAppSettings();
                },
                child: Text('Ouvrir les paramètres'),
              ),
            ],
          ),
        );
      }
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accueil'),
        centerTitle: true,
      ),
      body: Center(
        child: Text(
          'Bienvenue sur SafeCall !',
          style: TextStyle(
            fontSize: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}