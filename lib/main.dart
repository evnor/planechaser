import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:planechaser/app.dart';
import 'package:fast_cached_network_image/fast_cached_network_image.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String storageLocation = (await getApplicationDocumentsDirectory()).path;
  await FastCachedImageConfig.init(
      subDir: storageLocation, clearCacheAfter: const Duration(days: 60));
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) => runApp(const PlanechaserApp()));
}
