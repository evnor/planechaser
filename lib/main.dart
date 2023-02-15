import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:planechaser/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) => runApp(const PlanechaserApp()));
}
