import 'package:flutter/material.dart';
import '../services/video_calling_socket_service.dart';

class SocketConnectionIndicator extends StatefulWidget {
  final VideoCallingSocketService socketService;
  final VoidCallback? onRetry;

  const SocketConnectionIndicator({
    Key? key,
    required this.socketService,
    this.onRetry,
  }) : super(key: key);

  @override
  State<SocketConnectionIndicator> createState() => _SocketConnectionIndicatorState();
}

class _SocketConnectionIndicatorState extends State<SocketConnectionIndicator> {
  bool _isConnected = false;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _checkConnection();
    widget.socketService.onConnectionStatus.listen((connected) {
      if (mounted) {
        setState(() => _isConnected = connected);
      }
    });
    _setupPeriodicCheck();
  }

  void _setupPeriodicCheck() {
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        _checkConnection();
        _setupPeriodicCheck();
      }
    });
  }

  Future<void> _checkConnection() async {
    setState(() => _isVerifying = true);
    final isConnected = widget.socketService.isConnected;
    if (isConnected) {
      try {
        final isVerified = await widget.socketService.verifyConnection();
        if (mounted) {
          setState(() {
            _isConnected = isVerified;
            _isVerifying = false;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _isConnected = false;
            _isVerifying = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isConnected = false;
          _isVerifying = false;
        });
      }
    }
  }

  Future<void> _retryConnection() async {
    setState(() => _isVerifying = true);
    try {
      final reconnected = await widget.socketService.checkConnectionHealth();
      if (mounted) {
        setState(() {
          _isConnected = reconnected;
          _isVerifying = false;
        });
      }
      widget.onRetry?.call();
    } catch (_) {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _isConnected ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isConnected ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _isConnected ? 'Connected' : 'Disconnected',
            style: TextStyle(
              color: _isConnected ? Colors.green.shade900 : Colors.red.shade900,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          if (_isVerifying)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            IconButton(
              iconSize: 16,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(
                Icons.refresh,
                color: _isConnected ? Colors.green.shade700 : Colors.red.shade700,
              ),
              onPressed: _retryConnection,
            ),
        ],
      ),
    );
  }
}
