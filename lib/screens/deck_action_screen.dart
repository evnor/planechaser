import 'package:flutter/material.dart';
import 'package:planechaser/models.dart';
import 'package:planechaser/screens/play_screen.dart';

class DeckActionScreen extends StatefulWidget {
  final DeckModel deck;
  final List<int> permutation;
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
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
