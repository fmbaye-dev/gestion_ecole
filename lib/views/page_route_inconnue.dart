import 'package:flutter/material.dart';

class PageRouteInconnue extends StatefulWidget {
  const PageRouteInconnue({super.key, required this.message});
  final String message;

  @override
  State<PageRouteInconnue> createState() => _PageRouteInconnueState();
}

class _PageRouteInconnueState extends State<PageRouteInconnue> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
