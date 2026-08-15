import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/sismo_theme.dart';
import 'control_modal.dart';

class ValoresScreen extends StatelessWidget {
  final DatabaseService dbService;
  const ValoresScreen({super.key, required this.dbService});

  @override
  Widget build(BuildContext context) {
    final s = context.sismo;
    final chips = dbService.devicesState.keys.where((c) => dbService.userPermissions[c] == true).toList();

    if (chips.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: SismoColors.amber.withOpacity(0.12)),
              child: const Center(child: Text('🔒', style: TextStyle(fontSize: 28))),
            ),
            const SizedBox(height: 16),
            Text('No tienes acceso a dispositivos', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: s.textPrimary)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Valores en Vivo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: s.textPrimary)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: SismoColors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Text('${chips.length} dispositivo(s) con acceso', style: TextStyle(fontSize: 12, color: SismoColors.blue)),
        ),
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
    final s = context.sismo;
    final device = dbService.devicesState[chipId] ?? DeviceState();
    final sensors = dbService.sensorStates[chipId] ?? {};
    final deviceName = device.name.isNotEmpty ? device.name : chipId;

    Color statusColor; String statusIcon, statusText, statusDesc;
    final hasActive = List.generate(5, (i) => sensors['c${i + 1}'] == true).any((v) => v);
    final hasAlarm = sensors['alarma'] == true || device.alarm;

    if (hasAlarm) { statusColor = SismoColors.red; statusIcon = '🚨'; statusText = 'ALARMA'; statusDesc = 'Atención inmediata'; }
    else if (hasActive) { statusColor = SismoColors.amber; statusIcon = '⚠️'; statusText = 'INTRUSIÓN'; statusDesc = 'Intrusión detectada'; }
    else if (sensors['armado'] == true || device.armed) { statusColor = SismoColors.green; statusIcon = '🛡️'; statusText = 'ARMADO'; statusDesc = 'Sistema vigilando'; }
    else { statusColor = SismoColors.grayAccent; statusIcon = '🔓'; statusText = 'DESARMADO'; statusDesc = 'Sistema inactivo'; }

    String signalQ; Color signalC;
    if (device.rssi >= -50) { signalQ = 'Excelente'; signalC = SismoColors.green; }
    else if (device.rssi >= -65) { signalQ = 'Buena'; signalC = SismoColors.green; }
    else if (device.rssi >= -75) { signalQ = 'Regular'; signalC = SismoColors.amber; }
    else { signalQ = 'Débil'; signalC = SismoColors.red; }

    int activos = 0;
    for (var i = 1; i <= 5; i++) { if (sensors['c$i'] == true) activos++; }

    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
        builder: (_) => ControlModal(chipId: chipId, dbService: dbService),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: s.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: hasAlarm ? SismoColors.red.withOpacity(0.3) : s.borderColor),
        ),
        child: Column(
          children: [
            // Top accent
            Container(height: 3, decoration: BoxDecoration(color: statusColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(12)))),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(deviceName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: s.textPrimary))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                        child: Text('$statusIcon $statusText', style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Align(alignment: Alignment.centerLeft, child: Text(statusDesc, style: TextStyle(fontSize: 12, color: s.textMuted))),
                  const SizedBox(height: 16),

                  // Status circle
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [statusColor, statusColor.withOpacity(0.5)]),
                      boxShadow: [BoxShadow(color: statusColor.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
                    ),
                    child: Center(child: Text(statusIcon, style: const TextStyle(fontSize: 32))),
                  ),
                  const SizedBox(height: 16),

                  // Cercos
                  Align(alignment: Alignment.centerLeft, child: Text('ESTADO DE CERCOS:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: s.textMuted))),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(5, (i) {
                      final active = sensors['c${i + 1}'] == true;
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(color: active ? SismoColors.red : SismoColors.green, borderRadius: BorderRadius.circular(8)),
                          child: Column(
                            children: [
                              Text('C${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                              Text(active ? '🔴' : '🟢', style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 14),

                  // Info row
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: s.bgInset, borderRadius: BorderRadius.circular(10), border: Border.all(color: s.borderColor)),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text('Señal WiFi', style: TextStyle(fontSize: 11, color: s.textMuted)),
                              const SizedBox(height: 4),
                              Text(signalQ, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: signalC)),
                              Text('${device.rssi} dBm', style: TextStyle(fontSize: 10, color: s.textFaint)),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 36, color: s.borderColor),
                        Expanded(
                          child: Column(
                            children: [
                              Text('Sensores', style: TextStyle(fontSize: 11, color: s.textMuted)),
                              const SizedBox(height: 4),
                              Text('$activos/5 activos', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: activos > 0 ? SismoColors.red : SismoColors.green)),
                              Text(activos > 0 ? 'Atención' : 'Normal', style: TextStyle(fontSize: 10, color: s.textFaint)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatTs(device.lastSeen), style: TextStyle(fontSize: 11, color: s.textFaint)),
                      Text(device.ip, style: TextStyle(fontSize: 11, color: s.textFaint)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTs(int ms) {
    if (ms == 0) return 'N/A';
    final diff = DateTime.now().millisecondsSinceEpoch - ms;
    if (diff < 60000) return 'Hace ${(diff / 1000).floor()}s';
    if (diff < 3600000) return 'Hace ${(diff / 60000).floor()}m';
    if (diff < 86400000) return 'Hace ${(diff / 3600000).floor()}h';
    return 'Hace ${(diff / 86400000).floor()}d';
  }
}