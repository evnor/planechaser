import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    final deck = ModalRoute.of(context)!.settings.arguments as DeckModel;
    return WillPopScope(
      onWillPop: () async {
        await Provider.of<DeckListModel>(context, listen: false).saveDecks();
        return Future.value(true);
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
                onPressed: () => Navigator.pushNamed(
                    context, PlayScreen.routeName,
                    arguments: deck),
                icon: const Icon(Icons.play_arrow),
              )
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
                          ..sort((a, b) => a.name.compareTo(b.name));
                        cardList.addAll(value.allIds
                            .where((id) => !deck.cardIds.contains(id))
                            .map((id) => value.cards[id])
                            .whereType<MtgCard>()
                            .toList()
                          ..sort((a, b) => a.name.compareTo(b.name)));
                        return ListView.builder(
                          controller: _scrollController,
                          itemCount: cardList.length,
                          itemBuilder: (context, index) =>
                              CardListView(cardList[index]),
                          prototypeItem: CardListView(value.allCards.first),
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
              child: CachedNetworkImage(
                fit: BoxFit.contain,
                imageUrl: card.imageUris!.normal.toString(),
                fadeInDuration: const Duration(milliseconds: 200),
                fadeOutDuration: const Duration(milliseconds: 200),
                placeholder: (context, url) => RotatedBox(
                  quarterTurns: 3,
                  child: AspectRatio(
                    aspectRatio: 3.5 / 5,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 16.0),
                            child: Text(
                              card.name,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                          Text(
                            card.oracleText ?? "",
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
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
            Provider.of<DeckModel>(context, listen: false).removeCard(card.id);
          } else {
            Provider.of<DeckModel>(context, listen: false).addCard(card.id);
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
      selector: (_, deck) => deck.cardIds.contains(card.id),
    );
  }
}
