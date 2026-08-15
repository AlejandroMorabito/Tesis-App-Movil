import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/sismo_theme.dart';
import 'control_modal.dart';

class DashboardScreen extends StatelessWidget {
  final DatabaseService dbService;
  const DashboardScreen({super.key, required this.dbService});

  @override
  Widget build(BuildContext context) {
    final authorized = dbService.authorizedChips;
    if (authorized.isEmpty) return _buildNoAccess(context);
    return _buildDashboard(context);
  }

  Widget _buildNoAccess(BuildContext context) {
    final s = context.sismo;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
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
            const SizedBox(height: 8),
            Text('Contacta al administrador para obtener permisos', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: s.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context) {
    final s = context.sismo;
    final authorized = dbService.authorizedChips;
    final totalDisp = authorized.length;
    final alarmas = authorized.where((c) => dbService.devicesState[c]?.alarm == true).length;
    final armados = authorized.where((c) => dbService.devicesState[c]?.armed == true).length;
    int sensActivos = 0;
    final totalSens = totalDisp * 5;
    for (var chipId in authorized) {
      final sensors = dbService.sensorStates[chipId] ?? {};
      for (var i = 1; i <= 5; i++) { if (sensors['c$i'] == true) sensActivos++; }
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final conectados = authorized.where((c) => (now - (dbService.devicesState[c]?.lastSeen ?? 0)) < 300000).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stat cards
          GridView.count(
            crossAxisCount: 2, shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.5,
            children: [
              _StatCard(context, 'Dispositivos', '$totalDisp', '$conectados/$totalDisp online', SismoColors.blue, Icons.devices),
              _StatCard(context, 'Alarmas', '$alarmas', alarmas > 0 ? 'Atención' : 'Todo en orden', alarmas > 0 ? SismoColors.red : SismoColors.green, Icons.shield),
              _StatCard(context, 'Armados', '$armados', armados > 0 ? 'Vigilando' : 'Inactivos', SismoColors.teal, Icons.lock),
              _StatCard(context, 'Cercos', '$sensActivos/$totalSens', sensActivos > 0 ? '$sensActivos activos' : 'Normales', sensActivos > 0 ? SismoColors.amber : SismoColors.green, Icons.bolt),
            ],
          ),
          const SizedBox(height: 20),

          // Section title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Estado detallado', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: s.textPrimary)),
              Text('Tiempo real', style: TextStyle(fontSize: 12, color: s.textMuted)),
            ],
          ),
          const SizedBox(height: 12),

          // Device cards
          ...authorized.map((chipId) => _buildDeviceCard(context, chipId)),

          // Status bar
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: (alarmas > 0 ? SismoColors.red : SismoColors.green).withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: (alarmas > 0 ? SismoColors.red : SismoColors.green).withOpacity(0.15)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: (alarmas > 0 ? SismoColors.red : SismoColors.green).withOpacity(0.12)),
                  child: Icon(alarmas > 0 ? Icons.warning_amber : Icons.check, color: alarmas > 0 ? SismoColors.red : SismoColors.green, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(alarmas > 0 ? 'Atención requerida' : 'Sistema operativo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: s.textPrimary)),
                      Text(alarmas > 0 ? '$alarmas alarma(s) activa(s)' : 'Sin alertas críticas', style: TextStyle(fontSize: 11, color: s.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _StatCard(BuildContext context, String label, String value, String sub, Color color, IconData icon) {
    final s = context.sismo;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: s.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: s.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: color.withOpacity(0.12)),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(fontSize: 11, color: s.textMuted, letterSpacing: 0.3)),
            ],
          ),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: color)),
          const SizedBox(height: 2),
          Text(sub, style: TextStyle(fontSize: 11, color: s.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(BuildContext context, String chipId) {
    final s = context.sismo;
    final device = dbService.devicesState[chipId] ?? DeviceState();
    final sensors = dbService.sensorStates[chipId] ?? {};
    final deviceName = device.name.isNotEmpty ? device.name : chipId;

    String estado; Color estadoColor; String statusClass;
    if (device.alarm) { estado = 'Alarma'; estadoColor = SismoColors.red; statusClass = 'alarm'; }
    else if (device.intrusion) { estado = 'Intrusión'; estadoColor = SismoColors.amber; statusClass = 'intrusion'; }
    else if (device.armed) { estado = 'Armado'; estadoColor = SismoColors.green; statusClass = 'armed'; }
    else { estado = 'Desarmado'; estadoColor = SismoColors.grayAccent; statusClass = 'disarmed'; }

    final now = DateTime.now().millisecondsSinceEpoch;
    final conectado = (now - device.lastSeen) < 300000;
    final intermitente = !conectado && (now - device.lastSeen) < 600000;

    return GestureDetector(
      onTap: () => _openControl(context, chipId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: s.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: statusClass == 'alarm' ? SismoColors.red.withOpacity(0.3) : s.borderColor),
        ),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(deviceName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: s.textPrimary)),
                      const SizedBox(height: 2),
                      Text(chipId, style: TextStyle(fontSize: 10, color: s.textFaint, fontFamily: 'monospace')),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: estadoColor.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                  child: Text(estado, style: TextStyle(color: estadoColor, fontSize: 11, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Connection + Fences
            Row(
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: conectado ? SismoColors.green : (intermitente ? SismoColors.amber : SismoColors.red),
                    boxShadow: [BoxShadow(color: (conectado ? SismoColors.green : intermitente ? SismoColors.amber : SismoColors.red).withOpacity(0.5), blurRadius: 4)],
                  ),
                ),
                const SizedBox(width: 6),
                Text(conectado ? 'Conectado' : (intermitente ? 'Intermitente' : 'Desconectado'), style: TextStyle(fontSize: 11, color: s.textSecondary)),
                const Spacer(),
                // Fence bars
                ...List.generate(5, (i) => Container(
                  width: 20, height: 6, margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: sensors['c${i + 1}'] == true ? SismoColors.red : SismoColors.green,
                    borderRadius: BorderRadius.circular(3),
                  ),
                )),
              ],
            ),
            const SizedBox(height: 8),
            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${device.rssi} dBm', style: TextStyle(fontSize: 10, color: s.textFaint)),
                Text(device.ip, style: TextStyle(fontSize: 10, color: s.textFaint)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openControl(BuildContext context, String chipId) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ControlModal(chipId: chipId, dbService: dbService),
    );
  }
}