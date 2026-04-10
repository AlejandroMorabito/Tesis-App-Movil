import 'package:flutter/material.dart';
import '../services/database_service.dart';
import 'control_modal.dart';

class ValoresScreen extends StatelessWidget {
  final DatabaseService dbService;
  const ValoresScreen({super.key, required this.dbService});

  @override
  Widget build(BuildContext context) {
    final chips = dbService.devicesState.keys
        .where((c) => dbService.userPermissions[c] == true)
        .toList();

    if (chips.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🔒', style: TextStyle(fontSize: 64)),
            SizedBox(height: 20),
            Text('No tienes acceso a dispositivos', style: TextStyle(fontSize: 18, color: Color(0xFF666666))),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('📈 Valores en Vivo',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
        const SizedBox(height: 4),
        Text('${chips.length} dispositivo(s) con acceso',
            style: const TextStyle(fontSize: 12, color: Color(0xFF666666))),
        const SizedBox(height: 16),
        ...chips.map((chipId) => _DeviceCard(chipId: chipId, dbService: dbService)),
      ],
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final String chipId;
  final DatabaseService dbService;

  const _DeviceCard({required this.chipId, required this.dbService});

  @override
  Widget build(BuildContext context) {
    final device = dbService.devicesState[chipId] ?? DeviceState();
    final sensors = dbService.sensorStates[chipId] ?? {};
    final deviceName = device.name.isNotEmpty ? device.name : chipId;

    // Status
    Color statusColor; String statusIcon, statusText, statusDesc;
    final hasActiveSensors = List.generate(5, (i) => sensors['c${i + 1}'] == true).any((v) => v);
    final hasAlarm = sensors['alarma'] == true || device.alarm;

    if (hasAlarm) {
      statusColor = const Color(0xFFDC3545); statusIcon = '🚨'; statusText = 'ALARMA'; statusDesc = '¡Atención inmediata!';
    } else if (hasActiveSensors) {
      statusColor = const Color(0xFFFF9500); statusIcon = '⚠️'; statusText = 'INTRUSIÓN'; statusDesc = 'Alarma silenciosa';
    } else if (sensors['armado'] == true || device.armed) {
      statusColor = const Color(0xFF28A745); statusIcon = '🛡️'; statusText = 'ARMADO'; statusDesc = 'Sistema vigilando';
    } else {
      statusColor = const Color(0xFF6C757D); statusIcon = '🔓'; statusText = 'DESARMADO'; statusDesc = 'Sistema inactivo';
    }

    // Signal
    String signalQuality; Color signalColor;
    if (device.rssi >= -50) { signalQuality = 'Excelente'; signalColor = const Color(0xFF28A745); }
    else if (device.rssi >= -65) { signalQuality = 'Buena'; signalColor = const Color(0xFF4CD964); }
    else if (device.rssi >= -75) { signalQuality = 'Regular'; signalColor = const Color(0xFFFFC107); }
    else { signalQuality = 'Débil'; signalColor = const Color(0xFFDC3545); }

    int activeSensors = 0;
    for (var i = 1; i <= 5; i++) { if (sensors['c$i'] == true) activeSensors++; }

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(15))),
          builder: (_) => ControlModal(chipId: chipId, dbService: dbService),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border(left: BorderSide(color: statusColor, width: 4)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(deviceName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(16)),
                  child: Text('$statusIcon $statusText',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(statusDesc, style: const TextStyle(fontSize: 12, color: Color(0xFF666666))),
            const SizedBox(height: 16),

            // Status circle + info
            Row(
              children: [
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [statusColor, statusColor.withOpacity(0.5)]),
                  ),
                  child: Center(child: Text(statusIcon, style: const TextStyle(fontSize: 28))),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('📶 Señal', style: TextStyle(fontSize: 12, color: Color(0xFF666666))),
                          Text('$signalQuality (${device.rssi}dBm)',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: signalColor)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('🔋 Sensores', style: TextStyle(fontSize: 12, color: Color(0xFF666666))),
                          Text('$activeSensors/5 activos',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                                  color: activeSensors > 0 ? const Color(0xFFDC3545) : const Color(0xFF28A745))),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Sensors
            const Text('📊 CERCOS:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF666666))),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (i) {
                final active = sensors['c${i + 1}'] == true;
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: active ? const Color(0xFFDC3545) : const Color(0xFF28A745),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text('C${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        Text(active ? '🔴' : '🟢', style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),

            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('🕒 ${_formatTimestamp(device.lastSeen)}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
                Text(device.ip, style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(int ms) {
    if (ms == 0) return 'N/A';
    final date = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}