import 'dart:async';
import 'package:flutter/material.dart';

/// Pantalla de precarga simple que muestra el nombre de la app.
class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    // Espera corto para que el usuario vea el nombre y luego navega al Home.
    // El App Open Ad se intentará mostrar al entrar al Home.
    Timer(const Duration(milliseconds: 400), () async {
      if (!mounted) return;
      // Al finalizar la splash, navegamos a la pantalla principal (Home)
      Navigator.of(context).pushReplacementNamed('/home');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Tu Alimento Diario',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// La navegación real ocurre en NavScaffold (definido en main.dart) mediante la ruta '/home'.
