import 'package:flutter/material.dart';
import 'package:planechaser/screens/deck_edit_screen.dart';
import 'package:planechaser/screens/play_screen.dart';
import 'package:provider/provider.dart';

import 'models.dart';
import 'screens/home_screen.dart';

class PlanechaserApp extends StatelessWidget {
  const PlanechaserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => DeckListModel()..init(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        routes: {
          HomeScreen.routeName: (context) => const HomeScreen(),
          DeckEditScreen.routeName: (context) => DeckEditScreen(),
          PlayScreen.routeName: (context) => const PlayScreen(),
        },
      ),
    );
  }
}
