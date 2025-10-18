import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Simple trigger provider to notify screens that pet pings changed and should refresh.
final pingsRefreshProvider = StateProvider<int>((ref) => 0);
