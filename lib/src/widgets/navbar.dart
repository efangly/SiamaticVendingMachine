import 'package:flutter/material.dart';

class Navbar extends StatelessWidget {
  const Navbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.fromARGB(255, 0, 63, 252),
            Color.fromARGB(255, 0, 77, 192),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 1.0],
        ),
      ),
      child: const SafeArea(
          child: Text(
        "Vending Machine TestTools",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 50,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      )),
    );
  }
}
