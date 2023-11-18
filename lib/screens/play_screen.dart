import 'package:cached_network_image/cached_network_image.dart';
import 'package:scryfall_api/scryfall_api.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';

class PlayScreen extends StatefulWidget {
  const PlayScreen({super.key});

  static const routeName = "/play";
  static const cardBackUrl =
      "https://humpheh.com/magic/p/res/W500/Planechase%20Back-W500.jpg";

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  late DeckModel deck;
  late List<int> permutation;
  int index = 0;
  bool isVisible = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    deck = ModalRoute.of(context)!.settings.arguments as DeckModel;
    permutation = List.generate(deck.cardIds.length, (index) => index)
      ..shuffle();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WakelockPlus.enable();
    return Consumer<DeckListModel>(builder: (context, model, _) {
      final MtgCard? currentCard;
      if (permutation.isNotEmpty) {
        currentCard = model.cards[deck.cardIds[permutation[index]]]!;
      } else {
        currentCard = null;
      }
      return Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
              onPressed: () {
                setState(() {
                  if (!isVisible) {
                    index = (index - 1) % permutation.length;
                  }
                  isVisible = !isVisible;
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
              if (isVisible) {
                index = (index + 1) % permutation.length;
              }
              isVisible = !isVisible;
            });
          },
          child: SizedBox(
            height: double.infinity,
            width: double.infinity,
            child: AspectRatio(
              aspectRatio: 3.5 / 5,
              child: isVisible
                  ? (currentCard?.imageUris != null
                      ? CachedNetworkImage(
                          fadeInDuration: const Duration(milliseconds: 200),
                          imageUrl: currentCard!.imageUris!.normal.toString(),
                          fit: BoxFit.contain,
                        )
                      : Container(
                          color: Colors.red,
                        ))
                  : RotatedBox(
                      quarterTurns: 3,
                      child: CachedNetworkImage(
                          imageUrl: PlayScreen.cardBackUrl,
                          fit: BoxFit.contain),
                    ),
            ),
          ),
        ),
      );
    });
  }
}
