import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:http/retry.dart';
import 'package:logger/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:scryfall_api/scryfall_api.dart';
import 'package:localstore/localstore.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import 'screens/deck_action_screen.dart';

class PlanechaserClient extends http.BaseClient {
  final String userAgent;
  final http.Client _inner;
  Duration delay = Duration(milliseconds: 75);
  Future<void>? lock = Future<void>.value();

  PlanechaserClient(this.userAgent) : _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    request.headers['User-Agent'] = userAgent;
    request.headers['Accept'] = "application/json";
    await lock;
    lock = Future.delayed(delay);
    final response = await _inner.send(request);
    if (response.statusCode == 429) {
      delay *= 1.4;
    }
    return response;
  }
}

class DeckListModel extends ChangeNotifier with WidgetsBindingObserver {
  late final ScryfallApiClient client;
  final Localstore db = Localstore.instance;

  final List<DeckModel> _decks = [];
  final Map<String, MtgCard> _cards = {};
  List<DeckModel> get decks => List.unmodifiable(_decks);
  Map<String, MtgCard> get cards => Map.unmodifiable(_cards);
  Iterable<String> get allIds => _cards.keys;
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

  void init() async {
    final packageInfo = await PackageInfo.fromPlatform();
    client = ScryfallApiClient(
      httpClient: RetryClient(
        PlanechaserClient("${packageInfo.packageName}/${packageInfo.version}"),
        delay: (_) => Duration.zero,
        when: (resp) => resp.statusCode != 200,
        onRetry: (req, resp, r) {
          Logger().w("Retrying request ($r)");
        },
      ),
    );
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
      case AppLifecycleState.hidden:
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
    Logger().i("Loaded ${decks._decks.length} decks");
  }

  Future<void> saveDecks() async {
    await db.collection("Planechaser").doc("decks").set(toJson());
    Logger().i("Saved ${_decks.length} decks");
  }

  void loadCards() async {
    int page = 0;
    late PaginableList<MtgCard> paginableList;
    do {
      paginableList = await client.searchCards("layout:planar",
          sortingOrder: SortingOrder.name,
          rollupMode: RollupMode.cards,
          page: page);
      _cards.addAll(paginableList.data
          .asMap()
          .map((key, value) => MapEntry(value.oracleId, value)));
      if (paginableList.warnings != null) {
        Logger().w("Scryfall warning: ${paginableList.warnings}");
      }
    } while (paginableList.hasMore);
    Logger().i("Loaded ${_cards.length} cards");
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
    Logger().i("Added deck at ${index == null ? "end" : "index $index"}");
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
      Logger().i("Removed deck '${deck._name}'");
      notifyListeners();
    }
  }

  Future<MtgCard?> fetchId(String id) async {
    var card = _cards[id];
    if (card != null) return card;
    Logger().i("Fetching $id");
    try {
      var list = await client.searchCards("oracleid:$id");
      if (list.data.isNotEmpty) {
        return list.data.first;
      }
    } on ScryfallException {
      Logger().i("Trying to search for card (not oracle) id: $id");
      var card = await client.getCardById(id);
      return card;
    } catch (e) {
      Logger().e("Failed to get id $id", error: e);
    }
    return null;
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
  // ignore: prefer_const_constructors
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

  int? indexOfId(String id) {
    var idx = _cardIds.indexOf(id);
    if (idx == -1) return null;
    return idx;
  }
}

class PlayState extends ChangeNotifier {
  List<int> openCards = [];
  late DoubleLinkedQueue<int> permutation;
  DoubleLinkedQueue<(List<int>, List<int>)> history = DoubleLinkedQueue();

  PlayState(DeckModel deck) {
    permutation = DoubleLinkedQueue.from(
        List.generate(deck.cardIds.length, (index) => index)..shuffle());
  }

  void _trimHistory() {
    while (history.length > 30) {
      history.removeLast();
    }
  }

  void _saveHistory() {
    history.addFirst((List.from(openCards), List.from(permutation)));
  }

  void nextCard() {
    _saveHistory();
    _trimHistory();
    if (openCards.isEmpty) {
      openCards = [permutation.removeFirst()];
    } else {
      for (int i in openCards..shuffle()) {
        permutation.addLast(i);
      }
      openCards = [];
    }
    Logger().i((history.length, openCards));
    notifyListeners();
  }

  void undo() {
    if (history.isNotEmpty) {
      var (openCards_, permutation_) = history.removeFirst();
      openCards = openCards_;
      permutation = DoubleLinkedQueue.from(permutation_);
    } else {
      if (openCards.isEmpty) {
        openCards = [permutation.removeLast()];
      } else {
        for (int i in openCards..shuffle()) {
          permutation.addFirst(i);
        }
        openCards = [];
      }
    }
    Logger().i((history.length, openCards));
    notifyListeners();
  }

  void applyAction(
    Map<String, CardAction> cardActions,
    List<String> otherRevealedCards,
    bool randomizeRemaining,
    bool planeswalkAway,
    DeckModel deck,
  ) {
    _saveHistory();
    var toBottom = otherRevealedCards
        .map((e) => deck.indexOfId(e))
        .whereType<int>()
        .toList();
    var actions = cardActions.entries
        .map((e) => (deck.indexOfId(e.key), e.value))
        .where((e) => e.$1 != null);
    List<int> goTo = [];
    for (var (idx, action) in actions) {
      switch (action) {
        case CardAction.bottom:
          toBottom.add(idx!);
        case CardAction.goTo:
          goTo.add(idx!);
      }
    }
    permutation.removeWhere(
        (element) => toBottom.contains(element) || goTo.contains(element));
    var prevCards = openCards;
    if (planeswalkAway) {
      openCards = [];
    }
    openCards.addAll(goTo);
    permutation.addAll(toBottom..shuffle());
    if (planeswalkAway) {
      permutation.addAll(prevCards..shuffle());
    }
    Logger().i((history.length, openCards));
    notifyListeners();
  }
}
