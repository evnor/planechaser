import 'dart:collection';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:number_selector/number_selector.dart';
import 'package:scryfall_api/scryfall_api.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';

class PlayScreen extends StatefulWidget {
  const PlayScreen({super.key});

  static const routeName = '/play';
  static const cardBackUrl =
      'https://humpheh.com/magic/p/res/W500/Planechase%20Back-W500.jpg';

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  late DeckModel deck;
  late DoubleLinkedQueue<int> permutation;
  List<int> openCards = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    deck = ModalRoute.of(context)!.settings.arguments as DeckModel;
    permutation = DoubleLinkedQueue.from(
        List.generate(deck.cardIds.length, (index) => index)..shuffle());
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  MtgCard? getCard(int idx, DeckListModel model, DeckModel deck) {
    return model.cards[deck.cardIds[idx]];
  }

  void nextCard() {
    if (openCards.isEmpty) {
      openCards = [permutation.removeFirst()];
    } else {
      for (int i in openCards..shuffle()) {
        permutation.addLast(i);
      }
      openCards = [];
    }
  }

  void prevCard() {
    if (openCards.isEmpty) {
      openCards = [permutation.removeLast()];
    } else {
      for (int i in openCards..shuffle()) {
        permutation.addFirst(i);
      }
      openCards = [];
    }
  }

  @override
  Widget build(BuildContext context) {
    WakelockPlus.enable();
    return PopScope(
      onPopInvoked: (didPop) {
        if (didPop) {
          WakelockPlus.disable();
        }
      },
      child: Consumer<DeckListModel>(
        builder: (context, model, _) {
          return Scaffold(
            appBar: AppBar(
              actions: [
                IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const DeckActionDialog(),
                    );
                  },
                  icon: const Icon(Icons.remove_red_eye_outlined),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      prevCard();
                    });
                  },
                  icon: const Icon(Icons.undo),
                ),
              ],
            ),
            backgroundColor: Colors.black,
            body: GestureDetector(
              onTap: () {
                setState(() {
                  nextCard();
                });
              },
              child: ListView(
                children: openCards.isNotEmpty
                    ? [
                        for (int i in openCards)
                          CardDisplay(
                            card: getCard(i, model, deck),
                            rotated: openCards.length <= 1,
                          ),
                      ]
                    : [
                        const CardDisplay(
                          rotated: true,
                        )
                      ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class CardDisplay extends StatelessWidget {
  final MtgCard? card;
  final bool rotated;
  const CardDisplay({super.key, this.card, this.rotated = false});

  @override
  Widget build(BuildContext context) {
    final Widget child;
    if (card != null) {
      child = Hero(
        tag: card!.oracleId,
        child: card?.imageUris != null
            ? RotatedBox(
                quarterTurns: rotated ? 0 : 1,
                child: CachedNetworkImage(
                  fadeInDuration: const Duration(milliseconds: 200),
                  imageUrl: card!.imageUris!.normal.toString(),
                  fit: BoxFit.contain,
                ),
              )
            : Container(
                color: Colors.red,
              ),
      );
    } else {
      child = RotatedBox(
        quarterTurns: rotated ? 3 : 0,
        child: CachedNetworkImage(
            imageUrl: PlayScreen.cardBackUrl, fit: BoxFit.contain),
      );
    }
    return AspectRatio(aspectRatio: 3.5 / 5, child: child);
  }
}

enum DeckActionKind {
  lookAtTopX('First X cards', 'Look at top X cards'),
  revealXPlanes('First X planes', 'Reveal cards until you reveal X planes');

  const DeckActionKind(this.shortName, this.longName);

  final String shortName;
  final String longName;
}

class DeckActionDialog extends StatefulWidget {
  const DeckActionDialog({super.key});

  @override
  State<DeckActionDialog> createState() => _DeckActionDialogState();
}

class _DeckActionDialogState extends State<DeckActionDialog> {
  DeckActionKind _selectedLookAhead = DeckActionKind.lookAtTopX;
  int _valueX = 2;

  void _activate(DeckActionKind selection) {
    setState(() {
      _selectedLookAhead = selection;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            MenuAnchor(
              menuChildren: <Widget>[
                MenuItemButton(
                  child: Text(DeckActionKind.lookAtTopX.shortName),
                  onPressed: () => _activate(DeckActionKind.lookAtTopX),
                ),
                MenuItemButton(
                  child: Text(DeckActionKind.revealXPlanes.shortName),
                  onPressed: () => _activate(DeckActionKind.revealXPlanes),
                ),
              ],
              style: const MenuStyle(alignment: Alignment.topLeft),
              builder:
                  (BuildContext context, MenuController controller, child) {
                return TextButton(
                  onPressed: () {
                    if (controller.isOpen) {
                      controller.close();
                    } else {
                      controller.open();
                    }
                  },
                  child: Text(
                    _selectedLookAhead.longName,
                    textAlign: TextAlign.start,
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                children: [
                  Text(
                    "X =",
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: NumberSelector(
                        min: 0,
                        width: null,
                        height: 36.0,
                        backgroundColor: Colors.transparent,
                        borderColor: Theme.of(context).primaryColorDark,
                        decrementIcon: Icons.remove,
                        incrementIcon: Icons.add,
                        iconColor: Theme.of(context).colorScheme.onSurface,
                        showMinMax: false,
                        hasCenteredText: true,
                        hasBorder: false,
                        maxTooltip: null,
                        minTooltip: null,
                        onUpdate: (number) {
                          setState(() {
                            _valueX = number;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                child: const Text("Search"),
                onPressed: () async {
                  Navigator.of(context).pop();
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
