import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/sismo_feedback.dart';
import '../services/sismo_theme.dart';

class ControlModal extends StatefulWidget {
  final String chipId;
  final DatabaseService dbService;
  const ControlModal({super.key, required this.chipId, required this.dbService});

  @override
  State<ControlModal> createState() => _ControlModalState();
}

class _ControlModalState extends State<ControlModal> {
  @override
  void initState() { super.initState(); widget.dbService.addListener(_refresh); }
  @override
  void dispose() { widget.dbService.removeListener(_refresh); super.dispose(); }
  void _refresh() { if (mounted) setState(() {}); }

  // Muestra "procesando..." arriba, ejecuta la acción y confirma el resultado.
  Future<void> _sendCmd(String label, Future<void> Function() action) async {
    SismoFeedback.show(context, '⏳ $label...', color: SismoColors.blue);
    try {
      await action();
      if (mounted) SismoFeedback.show(context, '✅ $label', color: SismoColors.green);
    } catch (_) {
      if (mounted) SismoFeedback.show(context, '❌ Error: $label', color: SismoColors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.sismo;
    final chipId = widget.chipId;
    final device = widget.dbService.devicesState[chipId];
    final sensors = widget.dbService.sensorStates[chipId] ?? {};

    if (device == null) {
      return Container(
        decoration: BoxDecoration(color: s.bgCard, borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('❌', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 12),
          Text('Dispositivo no encontrado', style: TextStyle(fontSize: 16, color: s.textPrimary)),
        ]),
      );
    }

    final deviceName = device.name.isNotEmpty ? device.name : chipId;
    Color statusColor; String statusText, statusIcon;
    if (device.alarm) { statusColor = SismoColors.red; statusText = 'ALARMA ACTIVA'; statusIcon = '🚨'; }
    else if (device.intrusion) { statusColor = SismoColors.amber; statusText = 'INTRUSIÓN'; statusIcon = '⚠️'; }
    else if (device.armed) { statusColor = SismoColors.green; statusText = 'ARMADO'; statusIcon = '🛡️'; }
    else { statusColor = SismoColors.grayAccent; statusText = 'DESARMADO'; statusIcon = '🔓'; }

    int activos = 0;
    for (var i = 1; i <= 5; i++) { if (sensors['c$i'] == true) activos++; }
    String signalQ; Color signalC;
    if (device.rssi >= -50) { signalQ = 'Excelente'; signalC = SismoColors.green; }
    else if (device.rssi >= -65) { signalQ = 'Buena'; signalC = SismoColors.green; }
    else if (device.rssi >= -75) { signalQ = 'Regular'; signalC = SismoColors.amber; }
    else { signalQ = 'Débil'; signalC = SismoColors.red; }
    final connected = (DateTime.now().millisecondsSinceEpoch - device.lastSeen) < 300000;

    return DraggableScrollableSheet(
      initialChildSize: 0.85, minChildSize: 0.5, maxChildSize: 0.95, expand: false,
      builder: (_, sc) => Container(
        decoration: BoxDecoration(color: s.bgCard, borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
        child: SingleChildScrollView(
          controller: sc, padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: s.borderColor, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Control de Dispositivo', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: s.textPrimary)),
              IconButton(icon: Icon(Icons.close, color: s.textMuted), onPressed: () => Navigator.pop(context)),
            ]),
            const SizedBox(height: 16),

            // Status card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: s.bgInset, borderRadius: BorderRadius.circular(14), border: Border.all(color: s.borderColor)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(deviceName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: s.textPrimary)),
                    Text('ID: $chipId', style: TextStyle(fontSize: 11, color: s.textMuted, fontFamily: 'monospace')),
                  ]),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                    child: Text('$statusIcon $statusText', style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w500)),
                  ),
                ]),
                const SizedBox(height: 16),
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [statusColor, statusColor.withOpacity(0.5)]), boxShadow: [BoxShadow(color: statusColor.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))]),
                  child: Center(child: Text(statusIcon, style: const TextStyle(fontSize: 30))),
                ),
                const SizedBox(height: 16),
                Row(children: [
                  _QuickStat(s, 'SEÑAL WIFI', signalQ, '${device.rssi} dBm', signalC),
                  const SizedBox(width: 10),
                  _QuickStat(s, 'SENSORES', '$activos/5', activos > 0 ? 'Activos' : 'Normales', activos > 0 ? SismoColors.red : SismoColors.green),
                ]),
              ]),
            ),
            const SizedBox(height: 20),

            Text('CONTROL DE CERCOS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: s.textPrimary)),
            const SizedBox(height: 12),
            Row(children: List.generate(5, (i) {
              final sName = 'c${i + 1}'; final active = sensors[sName] == true;
              return Expanded(child: GestureDetector(
                onTap: () => _sendCmd(
                  active ? 'Desactivando ${sName.toUpperCase()}' : 'Activando ${sName.toUpperCase()}',
                  () => widget.dbService.toggleSensor(chipId, sName),
                ),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4), padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(color: active ? SismoColors.red : SismoColors.green, borderRadius: BorderRadius.circular(8)),
                  child: Column(children: [
                    Text('C${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(active ? '🔴' : '🟢', style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 4),
                    Text(active ? 'ACTIVO' : 'NORMAL', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 10)),
                  ]),
                ),
              ));
            })),
            const SizedBox(height: 20),

            // Action buttons
            Row(children: [
              Expanded(child: _ActionBtn(device.alarm ? 'DESACTIVAR ALARMA' : 'ACTIVAR ALARMA', device.alarm ? SismoColors.red : SismoColors.green, () => _sendCmd(device.alarm ? 'Desactivando alarma' : 'Activando alarma', () => widget.dbService.sendCommand(chipId, device.alarm ? 'DESACTIVAR_ALARMA' : 'ACTIVAR_ALARMA')))),
              const SizedBox(width: 10),
              Expanded(child: _ActionBtn(device.armed ? 'DESARMAR' : 'ARMAR', device.armed ? SismoColors.green : SismoColors.grayAccent, () => _sendCmd(device.armed ? 'Desarmando sistema' : 'Armando sistema', () => widget.dbService.sendCommand(chipId, device.armed ? 'DESARMAR_SISTEMA' : 'ARMAR_SISTEMA')))),
            ]),
            const SizedBox(height: 16),

            // Device info
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: s.bgInset, borderRadius: BorderRadius.circular(10), border: Border.all(color: s.borderColor)),
              child: Column(children: [
                _InfoRow(s, 'ÚLTIMA CONEXIÓN', _formatTs(device.lastSeen)),
                Divider(color: s.borderColor, height: 16),
                _InfoRow(s, 'DIRECCIÓN IP', device.ip),
                Divider(color: s.borderColor, height: 16),
                _InfoRow(s, 'DIRECCIÓN MAC', device.mac, mono: true),
                Divider(color: s.borderColor, height: 16),
                _InfoRow(s, 'ESTADO', connected ? 'CONECTADO' : 'DESCONECTADO', valueColor: connected ? SismoColors.green : SismoColors.red),
              ]),
            ),
            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: SismoColors.blue.withOpacity(0.08), borderRadius: BorderRadius.circular(8), border: Border(left: BorderSide(color: SismoColors.blue, width: 3))),
              child: Text('Haz clic en cualquier cerco para cambiar su estado.', style: TextStyle(fontSize: 12, color: s.textSecondary)),
            ),
            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }

  Widget _QuickStat(SismoThemeExtension s, String label, String value, String sub, Color color) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: s.bgCard, borderRadius: BorderRadius.circular(10), border: Border.all(color: s.borderColor)),
      child: Column(children: [
        Text(label, style: TextStyle(fontSize: 10, color: s.textMuted)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: color)),
        Text(sub, style: TextStyle(fontSize: 10, color: s.textFaint)),
      ]),
    ));
  }

  Widget _ActionBtn(String label, Color color, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(backgroundColor: color, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12), textAlign: TextAlign.center),
    );
  }

  Widget _InfoRow(SismoThemeExtension s, String label, String value, {Color? valueColor, bool mono = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(fontSize: 11, color: s.textMuted)),
      Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: valueColor ?? s.textPrimary, fontFamily: mono ? 'monospace' : null)),
    ]);
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