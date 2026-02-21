import 'package:connectivity_plus/connectivity_plus.dart';

/// Minimal online/offline checker.
class NetworkInfo {
  NetworkInfo(this._connectivity);
  final Connectivity _connectivity;

  Future<bool> isOnline() async {
    final List<ConnectivityResult> results = await _connectivity.checkConnectivity();
    if (results.isEmpty) return false;
    return !results.contains(ConnectivityResult.none);
  }
}
