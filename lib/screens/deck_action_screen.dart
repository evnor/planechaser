import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:planechaser/models.dart';
import 'package:planechaser/screens/play_screen.dart';

class DeckActionScreen extends StatefulWidget {
  static const String routeName = "/deckAction";
  final DeckModel deck;
  final DoubleLinkedQueue<int> permutation;
  final DeckActionKind deckActionKind;
  final int valueX;
  const DeckActionScreen({
    super.key,
    required this.deck,
    required this.permutation,
    required this.deckActionKind,
    required this.valueX,
  });

  @override
  State<DeckActionScreen> createState() => _DeckActionScreenState();
}

class _DeckActionScreenState extends State<DeckActionScreen> {
  bool randomizeRemaining = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.check))],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 0.0),
                  child: Text(
                    "Remaining go to bottom. Randomize them?",
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Switch(
                  onChanged: (value) {
                    setState(() {
                      randomizeRemaining = value;
                    });
                  },
                  value: randomizeRemaining,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Divider(
              thickness: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
