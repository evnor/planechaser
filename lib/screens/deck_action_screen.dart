import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:planechaser/models.dart';
import 'package:planechaser/screens/play_screen.dart';
import 'package:provider/provider.dart';

enum CardAction {
  goTo,
  bottom,
}

class DeckActionScreen extends StatefulWidget {
  static const String routeName = "/deckAction";
  final DeckModel deck;
  final PlayState state;
  final DeckActionDialogState dialogState;
  const DeckActionScreen({
    super.key,
    required this.state,
    required this.dialogState,
    required this.deck,
  });

  @override
  State<DeckActionScreen> createState() => _DeckActionScreenState();
}

class _DeckActionScreenState extends State<DeckActionScreen> {
  bool randomizeRemaining = true;
  bool planeswalkAway = true;
  late DeckListModel deckListModel;
  List<String> actionableCards = [];
  Map<String, CardAction> cardActions = {};
  List<String> otherRevealedCards = [];

  @override
  void initState() {
    super.initState();
    deckListModel = Provider.of<DeckListModel>(context, listen: false);
    switch (widget.dialogState.selectedLookAhead) {
      case DeckActionKind.lookAtTopX:
        actionableCards = widget.state.permutation
            .take(widget.dialogState.valueX)
            .map((e) => widget.deck.cardIds[e])
            .toList();
        break;
      case DeckActionKind.revealXPlanes:
        int numPlanes = 0;
        var iter = widget.state.permutation
            .map((e) => deckListModel.cards[widget.deck.cardIds[e]])
            .iterator;
        while (numPlanes < widget.dialogState.valueX) {
          if (!iter.moveNext()) break;
          var card = iter.current;
          if (card == null) break;
          if (card.typeLine.contains("Plane")) {
            actionableCards.add(card.id);
            numPlanes++;
          } else {
            otherRevealedCards.add(card.id);
          }
        }
        break;
    }
    for (var id in actionableCards) {
      cardActions[id] = CardAction.bottom;
    }
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {
              widget.state.applyAction(
                cardActions,
                otherRevealedCards,
                randomizeRemaining,
                planeswalkAway,
                widget.deck,
              );
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      body: ListView(
        children: [
          // Row(
          //   mainAxisSize: MainAxisSize.max,
          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //   crossAxisAlignment: CrossAxisAlignment.center,
          //   children: [
          // Expanded(
          //   child: Padding(
          //     padding: const EdgeInsets.symmetric(
          //         horizontal: 16.0, vertical: 0.0),
          //     child: Text(
          //       "Remaining go to bottom. Randomize them?",
          //       style: Theme.of(context).textTheme.bodyLarge,
          //     ),
          //   ),
          // ),
          //     Padding(
          //       padding: const EdgeInsets.all(8.0),
          //       child: Switch(
          //         onChanged: (value) {
          //           setState(() {
          //             randomizeRemaining = value;
          //           });
          //         },
          //         value: randomizeRemaining,
          //       ),
          //     ),
          //   ],
          // ),
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
                    "Planeswalk away?",
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Switch(
                  onChanged: (value) {
                    setState(() {
                      planeswalkAway = value;
                    });
                  },
                  value: planeswalkAway,
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
          for (String id in actionableCards)
            Stack(
              children: [
                CardDisplay(
                  card: deckListModel.cards[id],
                  rotated: false,
                ),
                Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: width / 5 * 3.5 * 0.15),
                    child: SizedBox(
                      width: width * 0.92,
                      child: SegmentedButton(
                        style: SegmentedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.background,
                            elevation: 5,
                            textStyle: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(fontSize: width / 5 * 3.5 * 0.1),
                            padding: EdgeInsets.symmetric(
                                vertical: width / 5 * 3.5 * 0.04)),
                        segments: const [
                          ButtonSegment(
                            value: CardAction.goTo,
                            label: Text(
                              "Go to",
                            ),
                          ),
                          ButtonSegment(
                            value: CardAction.bottom,
                            label: Text("Bottom"),
                          ),
                        ],
                        onSelectionChanged: (selection) {
                          setState(() {
                            cardActions[id] = selection.first!;
                          });
                        },
                        selected: {cardActions[id]},
                      ),
                    ),
                  ),
                ),
              ],
            ),
          if (otherRevealedCards.isNotEmpty) ...[
            const SizedBox(
              height: 16,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Divider(
                thickness: 1.0,
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
              child: Text(
                "Other revealed cards",
                style: Theme.of(context).textTheme.displaySmall,
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            for (String id in otherRevealedCards)
              CardDisplay(
                card: deckListModel.cards[id],
                rotated: false,
              ),
          ]
        ],
      ),
    );
  }
}
