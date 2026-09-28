import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models.dart';

const contentAssetPath = 'assets/content/moments.json';

/// Only format 1 exists; an unknown format means the app is older than the
/// bundle and must not guess at its shape.
const supportedBundleFormat = 1;

ContentBundle parseBundle(String source) {
  final bundle = ContentBundle.fromJson(jsonDecode(source) as JsonMap);
  if (bundle.format != supportedBundleFormat) {
    throw FormatException('unsupported content bundle format ${bundle.format}');
  }
  return bundle;
}

final contentBundleProvider = FutureProvider<ContentBundle>(
  (ref) async => parseBundle(await rootBundle.loadString(contentAssetPath)),
);
