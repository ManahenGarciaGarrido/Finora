import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Network information utility
/// Provides information about the device's network connectivity
abstract class NetworkInfo {
  Future<bool> get isConnected;
  Stream<bool> get onConnectivityChanged;
}

class NetworkInfoImpl implements NetworkInfo {
  final Connectivity connectivity;

  NetworkInfoImpl(this.connectivity);

  @override
  Future<bool> get isConnected async {
    final result = await connectivity.checkConnectivity();
    return _isConnectedResult(result);
  }

  @override
  Stream<bool> get onConnectivityChanged {
    return connectivity.onConnectivityChanged.map(_isConnectedResult);
  }

  bool _isConnectedResult(ConnectivityResult result) {
    // Check if there's any active connection (WiFi, Mobile, Ethernet, etc.)
    return result == ConnectivityResult.wifi ||
           result == ConnectivityResult.mobile ||
           result == ConnectivityResult.ethernet;
  }
}
