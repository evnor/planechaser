import 'dart:collection';

import 'package:fast_cached_network_image/fast_cached_network_image.dart';
import 'package:number_selector/number_selector.dart';
import 'package:planechaser/screens/deck_action_screen.dart';
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
  late PlayState state;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    deck = ModalRoute.of(context)!.settings.arguments as DeckModel;
    state = PlayState(deck);
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  MtgCard? getCard(int idx, DeckListModel model, DeckModel deck) {
    return model.cards[deck.cardIds[idx]];
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
          return ChangeNotifierProvider.value(
            value: state,
            child: Scaffold(
              appBar: AppBar(
                actions: [
                  IconButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => DeckActionDialog(
                          deck: deck,
                          model: model,
                          state: state,
                        ),
                      );
                    },
                    icon: const Icon(Icons.remove_red_eye_outlined),
                  ),
                  IconButton(
                    onPressed: state.undo,
                    icon: const Icon(Icons.undo),
                  ),
                ],
              ),
              backgroundColor: Colors.black,
              body: Consumer<PlayState>(
                builder: (context, state, child) => GestureDetector(
                  onTap: state.nextCard,
                  child: ListView(
                    children: state.openCards.isNotEmpty
                        ? [
                            for (int i in state.openCards)
                              CardDisplay(
                                card: getCard(i, model, deck),
                                rotated: state.openCards.length <= 1,
                              ),
                          ]
                        : [
                            const CardDisplay(
                              rotated: true,
                            )
                          ],
                  ),
                ),
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
                child: FastCachedImage(
                  fadeInDuration: const Duration(milliseconds: 200),
                  url: card!.imageUris!.normal.toString(),
                  loadingBuilder: (context, progress) => RotatedBox(
                    quarterTurns: rotated ? 0 : 3,
                    child: AspectRatio(
                      aspectRatio: 3.5 / 5,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: CircularProgressIndicator(
                            color: Theme.of(context).highlightColor,
                            value: 0.25,
                          ),
                        ),
                      ),
                    ),
                  ),
                  errorBuilder: (context, obj, trace) => Card(
                    child: AspectRatio(
                      aspectRatio: 3.5 / 5,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 16.0),
                              child: Text(
                                card!.name,
                                style:
                                    Theme.of(context).textTheme.headlineSmall,
                              ),
                            ),
                            Text(
                              card!.oracleText ?? "",
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
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
        child: const FastCachedImage(
            url: PlayScreen.cardBackUrl, fit: BoxFit.contain),
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
  final DeckModel deck;
  final DeckListModel model;
  final PlayState state;
  const DeckActionDialog(
      {super.key,
      required this.deck,
      required this.model,
      required this.state});

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
                        min: 1,
                        width: null,
                        height: 36.0,
                        current: _valueX,
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
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => DeckActionScreen(
                        deck: widget.deck,
                        state: widget.state,
                        deckActionKind: _selectedLookAhead,
                        valueX: _valueX,
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
