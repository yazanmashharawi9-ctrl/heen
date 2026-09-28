import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "Now", injectable so tests can pin the date.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
