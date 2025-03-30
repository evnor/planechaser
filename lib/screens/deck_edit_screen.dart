import 'package:collection/collection.dart';
import 'package:dice_icons/dice_icons.dart';
import 'package:fast_cached_network_image/fast_cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:number_selector/number_selector.dart';
import 'package:planechaser/models.dart';
import 'package:planechaser/screens/play_screen.dart';
import 'package:provider/provider.dart';
import 'package:scryfall_api/scryfall_api.dart';

class DeckEditScreen extends StatefulWidget {
  const DeckEditScreen({super.key});

  static const routeName = "/deckEdit";

  @override
  State<DeckEditScreen> createState() => _DeckEditScreenState();
}

class _DeckEditScreenState extends State<DeckEditScreen> {
  final ScrollController _scrollController = ScrollController();

  final TextEditingController _searchController = TextEditingController();

  Future<List<MtgCard>>? _searchResult;
  RandomizeDeckDialogState randomizeDeckDialogState =
      RandomizeDeckDialogState();

  int compareCards(MtgCard a, MtgCard b) {
    //
    final deprioritised = ["unk", "pssc"];
    final prio = (deprioritised.contains(a.set) ? 1 : 0)
        .compareTo(deprioritised.contains(b.set) ? 1 : 0);
    if (prio != 0) {
      return prio;
    }
    return a.name.compareTo(b.name);
  }

  @override
  Widget build(BuildContext context) {
    final deck = ModalRoute.of(context)!.settings.arguments as DeckModel;
    return PopScope(
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) {
          await Provider.of<DeckListModel>(context, listen: false).saveDecks();
        }
      },
      child: ChangeNotifierProvider.value(
        value: deck,
        child: Scaffold(
          appBar: AppBar(
            title: TextField(
              controller: TextEditingController(text: deck.name),
              onChanged: (value) => deck.setName(value),
            ),
            actions: [
              IconButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) =>
                        RandomizeDeckDialog(deck, randomizeDeckDialogState),
                  );
                },
                icon: const Icon(DiceIcons.dice5),
              ),
              IconButton(
                onPressed: () => Navigator.pushNamed(
                    context, PlayScreen.routeName,
                    arguments: deck),
                icon: const Icon(Icons.play_arrow),
              ),
            ],
          ),
          bottomNavigationBar: BottomAppBar(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Selector<DeckModel, int>(
                  selector: (_, deck) => deck.cardIds.length,
                  builder: (context, value, child) => Text(
                    "Cards: $value",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(
                  width: 8.0,
                ),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                        hintText: 'Search', border: InputBorder.none),
                    onChanged: (text) => onSearchTextChanged(context, text),
                  ),
                ),
              ],
            ),
          ),
          body: Scrollbar(
            controller: _scrollController,
            child: FutureBuilder(
                future: _searchResult,
                builder: (context, result) {
                  if (_searchResult == null) {
                    return Consumer<DeckListModel>(
                      builder: (context, value, child) {
                        final cardList = value.allIds
                            .where((id) => deck.cardIds.contains(id))
                            .map((id) => value.cards[id])
                            .whereType<MtgCard>()
                            .toList()
                          ..sort(compareCards);
                        cardList.addAll(value.allIds
                            .where((id) => !deck.cardIds.contains(id))
                            .map((id) => value.cards[id])
                            .whereType<MtgCard>()
                            .toList()
                          ..sort(compareCards));
                        return ListView.builder(
                          controller: _scrollController,
                          itemCount: cardList.length,
                          itemBuilder: (context, index) => CardListView(
                            cardList[index],
                            key: ValueKey(cardList[index].id),
                          ),
                          prototypeItem: value.allCards.isNotEmpty
                              ? CardListView(value.allCards.first)
                              : null,
                        );
                      },
                    );
                  } else if (result.hasData && result.data != null) {
                    return ListView.builder(
                      controller: _scrollController,
                      itemCount: result.data!.length,
                      itemBuilder: (context, index) =>
                          CardListView(result.data![index]),
                      prototypeItem: result.data!.isNotEmpty
                          ? CardListView(result.data!.first)
                          : null,
                    );
                  } else if (result.hasError) {
                    return Scaffold(
                      backgroundColor: Colors.red,
                      body: Text(result.error.toString()),
                    );
                  } else {
                    return const CircularProgressIndicator();
                  }
                }),
          ),
        ),
      ),
    );
  }

  void onSearchTextChanged(BuildContext context, String text) async {
    final model = Provider.of<DeckListModel>(context, listen: false);
    if (text.isEmpty || model.cards.isEmpty) {
      setState(() {
        _searchResult = null;
      });
      return;
    }
    setState(() {
      _searchResult = Future.microtask(() {
        final reg = RegExp(text, caseSensitive: false);
        final value = model.allCards
            .where((card) =>
                card.name.contains(reg) || card.typeLine.contains(reg))
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
        return value;
      });
    });
  }
}

class CardListView extends StatelessWidget {
  final MtgCard card;
  const CardListView(this.card, {super.key});

  @override
  Widget build(BuildContext context) {
    final image = card.imageUris != null
        ? AspectRatio(
            aspectRatio: 5 / 3.5,
            child: RotatedBox(
              quarterTurns: 1,
              child: FastCachedImage(
                fit: BoxFit.contain,
                url: card.imageUris!.normal.toString(),
                fadeInDuration: const Duration(milliseconds: 150),
                loadingBuilder: (context, progress) => RotatedBox(
                  quarterTurns: 3,
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
              ),
            ),
          )
        : AspectRatio(
            aspectRatio: 22 / 16,
            child: Container(
              color: Colors.red,
              width: double.infinity,
            ),
          );
    return Selector<DeckModel, bool>(
      builder: (context, isInDeck, child) => GestureDetector(
        onTap: () {
          if (isInDeck) {
            Provider.of<DeckModel>(context, listen: false)
                .removeCard(card.oracleId);
          } else {
            Provider.of<DeckModel>(context, listen: false)
                .addCard(card.oracleId);
          }
        },
        child: Stack(
          children: [
            image,
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                color: isInDeck
                    ? Colors.black.withAlpha(0)
                    : Colors.black.withAlpha(100),
              ),
            )
          ],
        ),
      ),
      selector: (_, deck) => deck.cardIds.contains(card.oracleId),
    );
  }
}

enum RandomizeDeckSelectionOption {
  bySet,
  byType,
}

class RandomizeDeckDialogState {
  RandomizeDeckSelectionOption selectionOption =
      RandomizeDeckSelectionOption.bySet;
  int cardCount = 10;
  Map<RandomizeDeckSelectionOption, List<String>> selection = {
    RandomizeDeckSelectionOption.bySet: [],
    RandomizeDeckSelectionOption.byType: [],
  };
}

class RandomizeDeckDialog extends StatefulWidget {
  final DeckModel deck;
  final RandomizeDeckDialogState state;

  const RandomizeDeckDialog(this.deck, this.state, {super.key});

  @override
  State<RandomizeDeckDialog> createState() => _RandomizeDeckDialogState();
}

class _RandomizeDeckDialogState extends State<RandomizeDeckDialog> {
  static const Map<RandomizeDeckSelectionOption, String> selectionOptionName = {
    RandomizeDeckSelectionOption.bySet: "Set",
    RandomizeDeckSelectionOption.byType: "Type",
  };
  final List<String> sets = [];
  final List<int> setCounts = [];
  final List<String> planes = [];
  final List<int> planeCounts = [];

  bool allSelected = true;

  List<String> selectedList() {
    return widget.state.selectionOption == RandomizeDeckSelectionOption.bySet
        ? sets
        : planes;
  }

  List<String> selectionList() {
    return widget.state.selection[widget.state.selectionOption]!;
  }

  List<List<Object>> selectedListWithCounts() {
    return widget.state.selectionOption == RandomizeDeckSelectionOption.bySet
        ? IterableZip([sets, setCounts]).toList()
        : IterableZip([planes, planeCounts]).toList();
  }

  String mapTypeLine(String typeline) {
    if (typeline.length <= 5) {
      return typeline;
    }
    return typeline.codeUnitAt(6) == 8212 ? typeline.substring(8) : typeline;
  }

  void applyToDeck(context) {
    final model = Provider.of<DeckListModel>(context, listen: false);
    List<String>? options;
    final filter = selectionList();
    if (widget.state.selectionOption == RandomizeDeckSelectionOption.bySet) {
      options = model.cards.entries
          .where((entry) => filter.contains(entry.value.set))
          .map((e) => e.key)
          .toList();
    } else {
      options = model.cards.entries
          .where((entry) => filter.contains(entry.value.typeLine))
          .map((e) => e.key)
          .toList();
    }
    options.shuffle();
    widget.deck.setCards(options.take(widget.state.cardCount).toList());
  }

  @override
  void initState() {
    final model = Provider.of<DeckListModel>(context, listen: false);
    sets.addAll(
      model.allCards.map((c) => c.set).toSet().toList()..sort(),
    );
    planes.addAll((model.allCards.map((c) => c.typeLine).toSet().toList()
          ..sort())
        .toList());
    setCounts.addAll(Iterable.generate(sets.length, (i) => 0));
    planeCounts.addAll(Iterable.generate(planes.length, (i) => 0));
    for (var card in model.allCards) {
      setCounts[sets.indexOf(card.set)]++;
      planeCounts[planes.indexOf(card.typeLine)]++;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Randomize Deck"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          applyToDeck(context);
          Navigator.of(context).pop();
        },
        child: Icon(Icons.check),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NumberSelector(
            min: 1,
            width: null,
            height: 45.0,
            textStyle: TextStyle(fontSize: 25),
            current: widget.state.cardCount,
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
                widget.state.cardCount = number;
              });
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                DropdownMenu(
                  initialSelection: widget.state.selectionOption,
                  onSelected: (v) {
                    if (v is RandomizeDeckSelectionOption) {
                      setState(() {
                        widget.state.selectionOption = v;
                      });
                    }
                  },
                  dropdownMenuEntries: RandomizeDeckSelectionOption.values
                      .map(
                        (v) => DropdownMenuEntry(
                            value: v, label: selectionOptionName[v] ?? ""),
                      )
                      .toList(),
                ),
                Expanded(
                  child: Container(),
                ),
                CheckboxMenuButton(
                    value: selectedList().length == selectionList().length,
                    child: Text("All"),
                    onChanged: (v) {
                      if (v is bool) {
                        setState(() {
                          if (v) {
                            (selectionList()..clear()).addAll(selectedList());
                          } else {
                            selectionList().clear();
                          }
                        });
                      }
                    })
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: selectedListWithCounts().map((tup) {
                final value = tup[0] as String;
                final count = tup[1] as int;
                return CheckboxListTile(
                  title: Text("($count) ${mapTypeLine(value)}"),
                  value: selectionList().contains(value),
                  onChanged: (v) {
                    setState(() {
                      if (v == null || !v) {
                        selectionList().remove(value);
                      } else {
                        selectionList().add(value);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          )
        ],
      ),
    );
  }
}
