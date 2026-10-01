import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppStatusService extends GetxController {
  AppStatusService();

  final Connectivity _connectivity = Connectivity();
  final Battery _battery = Battery();

  final Rx<ConnectivityResult> networkStatus = ConnectivityResult.wifi.obs;
  final RxInt batteryLevel = 100.obs;
  final Rx<BatteryState> batteryState = BatteryState.full.obs;
  final RxBool isOnline = true.obs;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<BatteryState>? _batterySubscription;

  bool _lowBatteryAlertShown = false;
  bool _isStartupInitialization = true;

  @override
  void onInit() {
    super.onInit();
    start();
  }

  void start() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (results) {
        final current = results.isEmpty ? ConnectivityResult.none : results.first;
        final hasConnection = current != ConnectivityResult.none;

        networkStatus.value = current;
        isOnline.value = hasConnection;

        if (_isStartupInitialization) {
          return;
        }

        if (hasConnection) {
          _showNotification(
            title: 'Network restored',
            message: 'Your internet connection is back online.',
            color: const Color(0xFF1B8E5A),
          );
        } else {
          _showNotification(
            title: 'No internet connection',
            message: 'Please check your connection and try again.',
            color: const Color(0xFFB86B00),
          );
        }
      },
      onError: (_) {
        if (_isStartupInitialization) return;
        _showNotification(
          title: 'Connection status unavailable',
          message: 'Unable to detect network state right now.',
          color: const Color(0xFF6D4C41),
        );
      },
    );

    _batterySubscription = _battery.onBatteryStateChanged.listen(
      (state) async {
        final level = await _battery.batteryLevel;
        batteryState.value = state;
        batteryLevel.value = level;

        final isLowBattery = state == BatteryState.discharging && level <= 15;
        if (isLowBattery && !_lowBatteryAlertShown) {
          if (!_isStartupInitialization) {
            _showNotification(
              title: 'Battery low',
              message: 'Battery is at $level%. Connect the charger soon.',
              color: const Color(0xFFB00020),
            );
          }
          _lowBatteryAlertShown = true;
          return;
        }

        if (state == BatteryState.charging || state == BatteryState.full) {
          _lowBatteryAlertShown = false;
        }
      },
      onError: (_) {
        if (_isStartupInitialization) return;
        _showNotification(
          title: 'Battery status unavailable',
          message: 'Unable to read battery info right now.',
          color: const Color(0xFF455A64),
        );
      },
    );

    _initializeStatus();
  }

  Future<void> _initializeStatus() async {
    final connectivityResults = await _connectivity.checkConnectivity();
    networkStatus.value = connectivityResults.isEmpty
        ? ConnectivityResult.none
        : connectivityResults.first;
    isOnline.value = networkStatus.value != ConnectivityResult.none;

    final state = await _battery.batteryState;
    final level = await _battery.batteryLevel;
    batteryState.value = state;
    batteryLevel.value = level;

    _isStartupInitialization = false;

    if (!isOnline.value) {
      _showNotification(
        title: 'No internet connection',
        message: 'Please check your connection and try again.',
        color: const Color(0xFFB86B00),
      );
    }

    if (state == BatteryState.discharging && level <= 15) {
      _showNotification(
        title: 'Battery low',
        message: 'Battery is at $level%. Connect the charger soon.',
        color: const Color(0xFFB00020),
      );
      _lowBatteryAlertShown = true;
    }
  }

  void stop() {
    _connectivitySubscription?.cancel();
    _batterySubscription?.cancel();
  }

  void _showNotification({
    required String title,
    required String message,
    required Color color,
  }) {
    if (Get.context == null) return;

    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: color,
      colorText: Colors.white,
      margin: const EdgeInsets.all(12),
      borderRadius: 12,
      duration: const Duration(seconds: 3),
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      icon: const Icon(Icons.notifications_active_rounded, color: Colors.white),
    );
  }
}

class AppStatusBar extends StatelessWidget {
  const AppStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    final service = Get.find<AppStatusService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? Colors.black.withOpacity(0.55)
        : Colors.white.withOpacity(0.82);
    final foregroundColor = isDark ? Colors.white : Colors.black87;
    final accentColor = isDark ? Colors.white : Colors.black87;

    return Obx(() {
      final data = service.networkStatus.value;
      final battery = service.batteryLevel.value;
      final batteryState = service.batteryState.value;
      final online = service.isOnline.value;

      return Container(
        margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.black : Colors.grey).withOpacity(0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(
              _networkIcon(data, online),
              color: foregroundColor,
              size: 18,
            ),
            const SizedBox(width: 8),
            Icon(
              _batteryIcon(batteryState, battery),
              color: _batteryColor(battery),
              size: 18,
            ),
            const SizedBox(width: 4),
            Text(
              '$battery%',
              style: TextStyle(
                color: accentColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    });
  }

  IconData _networkIcon(ConnectivityResult status, bool online) {
    if (!online) return Icons.signal_wifi_off_rounded;

    switch (status) {
      case ConnectivityResult.wifi:
        return Icons.wifi_rounded;
      case ConnectivityResult.mobile:
        return Icons.signal_cellular_4_bar_rounded;
      case ConnectivityResult.ethernet:
        return Icons.settings_ethernet_rounded;
      case ConnectivityResult.vpn:
        return Icons.vpn_key_rounded;
      default:
        return Icons.signal_wifi_connected_no_internet_4_rounded;
    }
  }

  IconData _batteryIcon(BatteryState state, int value) {
    if (state == BatteryState.charging) {
      return Icons.battery_charging_full_rounded;
    }
    if (value >= 80) return Icons.battery_full_rounded;
    if (value >= 60) return Icons.battery_5_bar_rounded;
    if (value >= 40) return Icons.battery_4_bar_rounded;
    if (value >= 20) return Icons.battery_2_bar_rounded;
    return Icons.battery_1_bar_rounded;
  }

  Color _batteryColor(int value) {
    if (value <= 15) return Colors.redAccent;
    if (value <= 35) return Colors.orangeAccent;
    return Colors.greenAccent;
  }
}
