import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:planechaser/models.dart';
import 'package:planechaser/screens/deck_edit_screen.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

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
              Provider.of<DeckListModel>(context, listen: false).addDeck(deck);
              Navigator.pushNamed(context, DeckEditScreen.routeName,
                  arguments: deck);
            },
            icon: const Icon(Icons.add),
          ),
          IconButton(
            onPressed: () async {
              final json =
                  Provider.of<DeckListModel>(context, listen: false).toJson();
              final text = jsonEncode(json);
              Share.share(text);
            },
            icon: const Icon(Icons.share),
          ),
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return const Dialog(
                    child: Text("Temporary"),
                  );
                },
              );
            },
            icon: const Icon(Icons.content_paste),
          ),
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

class ImportDialog extends StatefulWidget {
  const ImportDialog({super.key});

  @override
  State<ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<ImportDialog> {
  final Future<ClipboardData?> _clip = Clipboard.getData("text/plain");
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _clip.then((value) {
      final data = value?.text;
      if (data == null) return;
      _controller.text = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
            ),
            Row(children: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  final decklists =
                      DeckListModel.fromJson(jsonDecode(_controller.text));
                  Provider.of<DeckListModel>(context, listen: false)
                      .addFromDeckList(decklists);
                  Navigator.pop(context);
                },
                child: const Text("Load"),
              ),
            ])
          ],
        ),
      ),
    );
  }
}
