import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:planechaser/models.dart';
import 'package:planechaser/screens/deck_edit_screen.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const routeName = "/";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Decks"),
        actions: [
          IconButton(
              onPressed: () {
                final deck = DeckModel();
                Provider.of<DeckListModel>(context, listen: false)
                    .addDeck(deck);
                Navigator.pushNamed(context, DeckEditScreen.routeName,
                    arguments: deck);
              },
              icon: const Icon(Icons.add))
        ],
      ),
      body: Consumer<DeckListModel>(
        builder: (context, value, child) {
          final model = Provider.of<DeckListModel>(context, listen: false);
          return ListView(
              children: value.decks
                  .map(
                    (deck) => ChangeNotifierProvider.value(
                      value: deck,
                      child: Consumer<DeckModel>(
                        builder: (context, deck, child) => ListTile(
                          title: Text(deck.name),
                          trailing: Text(deck.cardIds.length.toString()),
                          onTap: () => Navigator.pushNamed(
                            context,
                            DeckEditScreen.routeName,
                            arguments: deck,
                          ),
                          onLongPress: () async {
                            var shouldDelete = await showDialog(
                                context: context,
                                builder: (context) => DeleteDialog(deck));
                            if (shouldDelete) {
                              model.deleteDeck(deck);
                            }
                          },
                        ),
                      ),
                    ),
                  )
                  .toList());
        },
      ),
    );
  }
}

class DeleteDialog extends StatelessWidget {
  final DeckModel deck;

  const DeleteDialog(this.deck, {super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Delete "${deck.name}?"'),
      // content: const Text('AlertDialog description'),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
