import 'package:flutter/material.dart';
import '../services/database_service.dart';

class ControlModal extends StatefulWidget {
  final String chipId;
  final DatabaseService dbService;

  const ControlModal({super.key, required this.chipId, required this.dbService});

  @override
  State<ControlModal> createState() => _ControlModalState();
}

class _ControlModalState extends State<ControlModal> {
  @override
  void initState() {
    super.initState();
    widget.dbService.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.dbService.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final chipId = widget.chipId;
    final device = widget.dbService.devicesState[chipId];
    final sensors = widget.dbService.sensorStates[chipId] ?? {};

    if (device == null) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('❌', style: TextStyle(fontSize: 36)),
            SizedBox(height: 15),
            Text('Dispositivo no encontrado', style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    final deviceName = device.name.isNotEmpty ? device.name : chipId;

    // Status
    Color statusColor;
    String statusText, statusIcon;
    Color statusBg;

    if (device.alarm) {
      statusColor = const Color(0xFFDC3545);
      statusText = 'ALARMA ACTIVA'; statusIcon = '🚨'; statusBg = const Color(0xFFFFF5F5);
    } else if (device.intrusion) {
      statusColor = const Color(0xFFFF9500);
      statusText = 'INTRUSIÓN'; statusIcon = '⚠️'; statusBg = const Color(0xFFFFFAF0);
    } else if (device.armed) {
      statusColor = const Color(0xFF28A745);
      statusText = 'ARMADO'; statusIcon = '🛡️'; statusBg = const Color(0xFFF0FFF4);
    } else {
      statusColor = const Color(0xFF6C757D);
      statusText = 'DESARMADO'; statusIcon = '🔓'; statusBg = const Color(0xFFF8F9FA);
    }

    int activeSensors = 0;
    for (var i = 1; i <= 5; i++) {
      if (sensors['c$i'] == true) activeSensors++;
    }

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

    final connected = (DateTime.now().millisecondsSinceEpoch - device.lastSeen) < 300000;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('🎛️ Control de Dispositivo',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Device status card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: statusColor.withOpacity(0.4), width: 2),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(deviceName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                            Text('ID: $chipId', style: const TextStyle(fontSize: 12, color: Color(0xFF666666))),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('$statusIcon $statusText',
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Status circle
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [statusColor, statusColor.withOpacity(0.5)]),
                        boxShadow: [BoxShadow(color: statusColor.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 6))],
                      ),
                      child: Center(child: Text(statusIcon, style: const TextStyle(fontSize: 32))),
                    ),
                    const SizedBox(height: 20),

                    // Quick stats
                    Row(
                      children: [
                        _QuickStat('📶 SEÑAL WIFI', signalQuality, '${device.rssi} dBm', signalColor),
                        const SizedBox(width: 15),
                        _QuickStat('🔋 SENSORES', '$activeSensors/5',
                            activeSensors > 0 ? 'Activos' : 'Normales',
                            activeSensors > 0 ? const Color(0xFFDC3545) : const Color(0xFF28A745)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // Control de cercos
              const Row(
                children: [
                  Text('📡', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 10),
                  Text('CONTROL DE CERCOS',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
                ],
              ),
              const SizedBox(height: 15),

              Row(
                children: List.generate(5, (i) {
                  final sName = 'c${i + 1}';
                  final active = sensors[sName] == true;
                  final cercoColor = active ? const Color(0xFFDC3545) : const Color(0xFF28A745);

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => widget.dbService.toggleSensor(chipId, sName),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          color: cercoColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text('C${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 5),
                            Text(active ? '🔴' : '🟢', style: const TextStyle(fontSize: 20)),
                            const SizedBox(height: 5),
                            Text(active ? 'ACTIVO' : 'NORMAL',
                                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 11)),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 25),

              // Alarm / Arm buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => widget.dbService.sendCommand(
                          chipId, device.alarm ? 'DESACTIVAR_ALARMA' : 'ACTIVAR_ALARMA'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: device.alarm ? const Color(0xFFDC3545) : const Color(0xFF28A745),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        '🚨 ${device.alarm ? "DESACTIVAR ALARMA" : "ACTIVAR ALARMA"}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => widget.dbService.sendCommand(
                          chipId, device.armed ? 'DESARMAR_SISTEMA' : 'ARMAR_SISTEMA'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: device.armed ? const Color(0xFF28A745) : const Color(0xFF6C757D),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        device.armed ? '🔒 DESARMAR' : '🔓 ARMAR',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Device info
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    _InfoRow('🕒 ÚLTIMA CONEXIÓN', _formatTimestamp(device.lastSeen)),
                    const Divider(),
                    _InfoRow('📍 DIRECCIÓN IP', device.ip),
                    const Divider(),
                    _InfoRow('📡 DIRECCIÓN MAC', device.mac),
                    const Divider(),
                    _InfoRow('🔌 ESTADO', connected ? 'CONECTADO' : 'DESCONECTADO',
                        valueColor: connected ? const Color(0xFF28A745) : const Color(0xFFDC3545)),
                  ],
                ),
              ),
              const SizedBox(height: 15),

              // Tip
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F4FD),
                  borderRadius: BorderRadius.circular(8),
                  border: const Border(left: BorderSide(color: Color(0xFF3498DB), width: 4)),
                ),
                child: const Row(
                  children: [
                    Text('💡', style: TextStyle(fontSize: 14)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('Haz clic en cualquier cerco para cambiar su estado. Los cambios se aplicarán inmediatamente.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF2C3E50))),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  String _formatTimestamp(int ms) {
    if (ms == 0) return 'N/A';
    final date = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _QuickStat extends StatelessWidget {
  final String label, value, subtitle;
  final Color color;
  const _QuickStat(this.label, this.value, this.subtitle, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF666666))),
            const SizedBox(height: 5),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  const _InfoRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF666666))),
          Text(value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: valueColor ?? const Color(0xFF333333),
                fontFamily: label.contains('MAC') ? 'monospace' : null,
              )),
        ],
      ),
    );
  }
}
