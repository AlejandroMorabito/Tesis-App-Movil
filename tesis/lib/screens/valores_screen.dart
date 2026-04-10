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
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔒', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 20),
            const Text('No tienes acceso a dispositivos',
                style: TextStyle(fontSize: 18, color: Color(0xFF666666))),
            const SizedBox(height: 10),
            Text('Permisos actuales: ${dbService.userPermissions.length} dispositivos registrados',
                style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📈 Valores en Vivo',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F4FD),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text('Tienes acceso a ${chips.length} dispositivo(s)',
                    style: const TextStyle(fontSize: 14, color: Color(0xFF666666))),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('✅ Mostrando solo dispositivos con acceso autorizado',
                style: TextStyle(fontSize: 11, color: Color(0xFF28A745))),
          ),
          const SizedBox(height: 10),
          const Text('💡 Haz clic en cualquier tarjeta para controlar el dispositivo',
              style: TextStyle(fontSize: 12, color: Color(0xFF888888))),
          const SizedBox(height: 25),

          // Grid de tarjetas
          LayoutBuilder(
            builder: (context, constraints) {
              final crossCount = constraints.maxWidth > 700 ? 2 : 1;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossCount,
                  crossAxisSpacing: 25,
                  mainAxisSpacing: 25,
                  childAspectRatio: crossCount == 1 ? 0.85 : 0.75,
                ),
                itemCount: chips.length,
                itemBuilder: (_, i) => _DeviceCard(
                  chipId: chips[i],
                  dbService: dbService,
                ),
              );
            },
          ),
        ],
      ),
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
    Color statusColor;
    String statusIcon, statusText, statusDesc;
    final hasActiveSensors = List.generate(5, (i) => sensors['c${i + 1}'] == true).any((v) => v);
    final hasAlarm = sensors['alarma'] == true || device.alarm;

    if (hasAlarm) {
      statusColor = const Color(0xFFDC3545);
      statusIcon = '🚨'; statusText = 'ALARMA ACTIVA'; statusDesc = '¡Se requiere atención inmediata!';
    } else if (hasActiveSensors) {
      statusColor = const Color(0xFFFF9500);
      statusIcon = '⚠️'; statusText = 'INTRUSIÓN'; statusDesc = 'Intrusión detectada - Alarma silenciosa';
    } else if (sensors['armado'] == true || device.armed) {
      statusColor = const Color(0xFF28A745);
      statusIcon = '🛡️'; statusText = 'ARMADO'; statusDesc = 'Sistema vigilando';
    } else {
      statusColor = const Color(0xFF6C757D);
      statusIcon = '🔓'; statusText = 'DESARMADO'; statusDesc = 'Sistema inactivo';
    }

    // Signal quality
    String signalQuality; Color signalColor;
    if (device.rssi >= -50) {
      signalQuality = 'Excelente'; signalColor = const Color(0xFF28A745);
    } else if (device.rssi >= -65) {
      signalQuality = 'Buena'; signalColor = const Color(0xFF4CD964);
    } else if (device.rssi >= -75) {
      signalQuality = 'Regular'; signalColor = const Color(0xFFFFC107);
    } else {
      signalQuality = 'Débil'; signalColor = const Color(0xFFDC3545);
    }

    int activeSensors = 0;
    for (var i = 1; i <= 5; i++) {
      if (sensors['c$i'] == true) activeSensors++;
    }

    return GestureDetector(
      onTap: () {
        if (dbService.userPermissions[chipId] != true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('🔒 No tienes acceso a $chipId')),
          );
          return;
        }
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
          ),
          builder: (_) => ControlModal(chipId: chipId, dbService: dbService),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border(left: BorderSide(color: statusColor.withOpacity(0.4), width: 2)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(deviceName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
                      overflow: TextOverflow.ellipsis),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('$statusIcon $statusText',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Status circle
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [statusColor, statusColor.withOpacity(0.5)]),
                      boxShadow: [BoxShadow(color: statusColor.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 6))],
                    ),
                    child: Center(child: Text(statusIcon, style: const TextStyle(fontSize: 40))),
                  ),
                  const SizedBox(height: 10),
                  Text(statusDesc, style: const TextStyle(color: Color(0xFF666666), fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // Sensors
            const Text('📊 ESTADO DE CERCOS:',
                style: TextStyle(fontSize: 14, color: Color(0xFF666666), fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Row(
              children: List.generate(5, (i) {
                final sName = 'c${i + 1}';
                final active = sensors[sName] == true;
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: active ? const Color(0xFFDC3545) : const Color(0xFF28A745),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text('C${i + 1}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(active ? '🔴' : '🟢', style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 15),

            // Info grid
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFF8F9FA), Color(0xFFE9ECEF)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('📶 Señal WiFi', style: TextStyle(color: Color(0xFF666666), fontSize: 13)),
                        const SizedBox(height: 3),
                        Text(signalQuality, style: TextStyle(fontWeight: FontWeight.bold, color: signalColor)),
                        Text('${device.rssi} dBm', style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('🔋 Sensores', style: TextStyle(color: Color(0xFF666666), fontSize: 13)),
                        const SizedBox(height: 3),
                        Text('$activeSensors/5 activos',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: activeSensors > 0 ? const Color(0xFFDC3545) : const Color(0xFF28A745))),
                        Text(activeSensors > 0 ? '⚠️ Atención' : '✅ Normal',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Divider(color: Colors.grey[200]),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('🕒 ${_formatTimestamp(device.lastSeen)}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
                Text(device.ip, style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
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
