import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

/// Widget that displays the current connectivity status
class ConnectivityIndicator extends StatefulWidget {
  final bool showAlways;
  
  const ConnectivityIndicator({
    super.key,
    this.showAlways = false,
  });

  @override
  State<ConnectivityIndicator> createState() => _ConnectivityIndicatorState();
}

class _ConnectivityIndicatorState extends State<ConnectivityIndicator>
    with SingleTickerProviderStateMixin {
  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _wasOffline = false;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _initConnectivity();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
        _updateConnectionStatus(result);
      },
    );
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initConnectivity() async {
    try {
      final results = await Connectivity().checkConnectivity();
      final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
      _updateConnectionStatus(result);
    } catch (e) {
      print('ConnectivityIndicator: Error checking connectivity: $e');
    }
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    if (!mounted) return;
    
    setState(() {
      final wasOnline = _connectionStatus != ConnectivityResult.none;
      _connectionStatus = result;
      final isOnline = _connectionStatus != ConnectivityResult.none;
      
      // Track offline/online transitions
      if (!wasOnline && isOnline && _wasOffline) {
        // Just came back online, show pulsing animation
        _pulseController.repeat(reverse: true);
        // Stop animation after 3 seconds
        Timer(const Duration(seconds: 3), () {
          if (mounted) _pulseController.stop();
        });
      } else if (wasOnline && !isOnline) {
        _wasOffline = true;
        _pulseController.stop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = _connectionStatus != ConnectivityResult.none;
    
    // Only show when offline or if showAlways is true
    if (isOnline && !widget.showAlways) {
      return const SizedBox.shrink();
    }
    
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor().withOpacity(
              isOnline ? _pulseAnimation.value * 0.2 : 0.2,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getStatusColor().withOpacity(
                isOnline ? _pulseAnimation.value * 0.5 : 0.5,
              ),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getStatusIcon(),
                size: 14,
                color: _getStatusColor(),
              ),
              const SizedBox(width: 4),
              Text(
                _getStatusText(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: _getStatusColor(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor() {
    switch (_connectionStatus) {
      case ConnectivityResult.wifi:
        return Colors.green;
      case ConnectivityResult.mobile:
        return Colors.blue;
      case ConnectivityResult.ethernet:
        return Colors.green;
      case ConnectivityResult.none:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (_connectionStatus) {
      case ConnectivityResult.wifi:
        return Icons.wifi;
      case ConnectivityResult.mobile:
        return Icons.signal_cellular_4_bar;
      case ConnectivityResult.ethernet:
        return Icons.lan;
      case ConnectivityResult.none:
        return Icons.wifi_off;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusText() {
    switch (_connectionStatus) {
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.mobile:
        return 'Mobile';
      case ConnectivityResult.ethernet:
        return 'Ethernet';
      case ConnectivityResult.none:
        return 'Offline';
      default:
        return 'Unknown';
    }
  }
}

/// Compact connectivity indicator for app bars
class CompactConnectivityIndicator extends StatefulWidget {
  const CompactConnectivityIndicator({super.key});

  @override
  State<CompactConnectivityIndicator> createState() => _CompactConnectivityIndicatorState();
}

class _CompactConnectivityIndicatorState extends State<CompactConnectivityIndicator>
    with SingleTickerProviderStateMixin {
  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  late AnimationController _animationController;
  bool _showOfflineIndicator = false;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _initConnectivity();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
        _updateConnectionStatus(result);
      },
    );
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initConnectivity() async {
    try {
      final results = await Connectivity().checkConnectivity();
      final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
      _updateConnectionStatus(result);
    } catch (e) {
      print('CompactConnectivityIndicator: Error checking connectivity: $e');
    }
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    if (!mounted) return;
    
    setState(() {
      _connectionStatus = result;
      _showOfflineIndicator = _connectionStatus == ConnectivityResult.none;
    });
    
    if (_showOfflineIndicator) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _animationController.value,
          child: Opacity(
            opacity: _animationController.value,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}