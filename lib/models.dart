import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:scryfall_api/scryfall_api.dart';
import 'package:localstore/localstore.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class DeckListModel extends ChangeNotifier with WidgetsBindingObserver {
  final ScryfallApiClient client = ScryfallApiClient();
  final Localstore db = Localstore.instance;

  final List<DeckModel> _decks = [];
  final Map<String, MtgCard> _cards = {};
  List<DeckModel> get decks => List.unmodifiable(_decks);
  Map<String, MtgCard> get cards => _cards;
  List<String> get allIds => _cards.keys.toList();
  Iterable<MtgCard> get allCards => _cards.values;

  DeckListModel();
  DeckListModel.fromJson(Map<String, dynamic> json) {
    final decks = json["decks"] as List<dynamic>;
    _decks.addAll(decks.map((e) => DeckModel.fromJson(e)));
  }

  Map<String, dynamic> toJson() {
    return {
      "decks": _decks.map((deck) => deck.toJson()).toList(),
    };
  }

  void init() {
    loadCards();
    loadDecks();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.resumed:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.paused:
        await saveDecks();
    }
  }

  void loadDecks() async {
    final json = await db.collection("Planechaser").doc("decks").get();
    if (json == null) return;
    final decks = DeckListModel.fromJson(json);
    addFromDeckList(decks);
  }

  Future<void> saveDecks() async {
    await db.collection("Planechaser").doc("decks").set(toJson());
  }

  void loadCards() async {
    var paginableList = await client.searchCards(
      "t:plane OR t:phenomenon",
      sortingOrder: SortingOrder.set,
      rollupMode: RollupMode.cards,
    );
    _cards.addAll(paginableList.data
        .asMap()
        .map((key, value) => MapEntry(value.id, value)));
    var delay = const Duration(milliseconds: 75);
    while (paginableList.hasMore) {
      await Future.delayed(delay, () {
        http.get(paginableList.nextPage!).then((response) {
          if (response.statusCode != 200) {
            if (response.statusCode == 429) {
              delay *= 1.4;
            }
            return;
          }
          final json = jsonDecode(response.body);
          paginableList = PaginableList.fromJson(
            json,
            (card) => MtgCard.fromJson(card as Map<String, dynamic>),
          );
          _cards.addAll(paginableList.data
              .asMap()
              .map((key, value) => MapEntry(value.id, value)));
        });
      });
    }
    notifyListeners();
  }

  void swap(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = _decks.removeAt(oldIndex);
    _decks.insert(newIndex, item);
    notifyListeners();
  }

  void addDeck(DeckModel deck, {int? index}) {
    if (index == null) {
      _decks.add(deck);
    } else {
      _decks.insert(index, deck);
    }
    notifyListeners();
  }

  void addFromDeckList(DeckListModel deckList) {
    if (deckList.decks.isNotEmpty) {
      _decks.addAll(deckList.decks);
      notifyListeners();
    }
  }

  void deleteDeck(DeckModel deck) {
    final len = _decks.length;
    _decks.remove(deck);
    if (len != _decks.length) {
      notifyListeners();
    }
  }

  @override
  void dispose() async {
    client.close();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

// Should this have ChangeNotifier?
class DeckModel extends ChangeNotifier {
  static final Uuid uuid = Uuid();
  List<String> _cardIds = [];
  List<String> get cardIds => List.unmodifiable(_cardIds);
  String _name = "New Deck";
  String get name => _name;
  final id = uuid.v1();

  DeckModel();

  DeckModel.fromJson(Map<String, dynamic> json) {
    _name = json["name"];
    _cardIds = (json["cards"] as List<dynamic>).whereType<String>().toList();
  }

  Map<String, dynamic> toJson() {
    return {
      "name": _name,
      "cards": _cardIds,
    };
  }

  void addCard(String id) {
    _cardIds.add(id);
    notifyListeners();
  }

  void removeCard(String id) {
    _cardIds.remove(id);
    notifyListeners();
  }

  void setName(String name) {
    _name = name;
    notifyListeners();
  }
}
