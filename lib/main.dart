import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siamatic_vending/src/app.dart';

void main() {
  runApp(MultiBlocProvider(
    providers: const [],
    child: const VendingTestToolsApp(),
  ));
}
