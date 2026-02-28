import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Connectivity status enum.
enum ConnectivityStatus { online, offline }

/// Provider that streams connectivity status.
final connectivityProvider =
    StreamNotifierProvider<ConnectivityNotifier, ConnectivityStatus>(
  ConnectivityNotifier.new,
);

class ConnectivityNotifier extends StreamNotifier<ConnectivityStatus> {
  @override
  Stream<ConnectivityStatus> build() {
    return Connectivity()
        .onConnectivityChanged
        .map(_mapConnectivity);
  }

  ConnectivityStatus _mapConnectivity(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.none) || results.isEmpty) {
      return ConnectivityStatus.offline;
    }
    return ConnectivityStatus.online;
  }
}

/// Simple provider to check current status once.
final isOnlineProvider = FutureProvider<bool>((ref) async {
  final results = await Connectivity().checkConnectivity();
  return !results.contains(ConnectivityResult.none) && results.isNotEmpty;
});
