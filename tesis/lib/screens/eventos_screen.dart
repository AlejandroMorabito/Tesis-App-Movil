import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/sismo_theme.dart';

class EventosScreen extends StatefulWidget {
  final DatabaseService dbService;
  const EventosScreen({super.key, required this.dbService});

  @override
  State<EventosScreen> createState() => _EventosScreenState();
}

class _EventosScreenState extends State<EventosScreen> {
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
    final s = context.sismo;
    final events = widget.dbService.currentData;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Historial de Eventos',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: s.textPrimary)),
              const SizedBox(height: 2),
              Text(
                events.isEmpty
                    ? 'Alarmas, armado y cambios en los cercos'
                    : '${events.length} evento${events.length == 1 ? '' : 's'} registrado${events.length == 1 ? '' : 's'}',
                style: TextStyle(fontSize: 13, color: s.textMuted),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: SismoColors.teal,
            onRefresh: () => widget.dbService.refreshEvents(),
            child: events.isEmpty
                ? _emptyState(s)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: events.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) => _eventCard(s, events[i]),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _emptyState(SismoThemeExtension s) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        Icon(Icons.history, size: 48, color: s.textFaint),
        const SizedBox(height: 14),
        Text('Sin eventos todavía',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: s.textSecondary)),
        const SizedBox(height: 6),
        Text(
          'Aquí aparecerá el historial de alarmas, armado y cambios en los cercos de tus dispositivos.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: s.textMuted),
        ),
      ],
    );
  }

  Widget _eventCard(SismoThemeExtension s, AlarmEvent e) {
    final name = DatabaseService.getEventDisplayName(e.eventType);
    final deviceName = widget.dbService.devicesState[e.deviceId]?.name ?? e.deviceId;
    final activated = e.eventValue;
    final t = e.eventType.toLowerCase();

    Color color;
    IconData icon;
    if (t.contains('alarma')) {
      color = SismoColors.red;
      icon = Icons.notifications_active;
    } else if (t.contains('armado')) {
      color = SismoColors.teal;
      icon = Icons.shield;
    } else if (t.contains('sensor') || t.contains('cerco')) {
      color = activated ? SismoColors.red : SismoColors.green;
      icon = Icons.sensors;
    } else {
      color = SismoColors.blue;
      icon = Icons.info_outline;
    }

    final stateText = activated ? 'ACTIVADO' : 'DESACTIVADO';
    final stateColor = activated ? SismoColors.red : SismoColors.green;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: s.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: s.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: s.textPrimary)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.memory, size: 12, color: s.textMuted),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(deviceName,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: s.textSecondary)),
                    ),
                    const SizedBox(width: 10),
                    Icon(Icons.schedule, size: 12, color: s.textMuted),
                    const SizedBox(width: 4),
                    Text(_formatTime(e.timestamp),
                        style: TextStyle(fontSize: 12, color: s.textMuted)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: stateColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(stateText,
                style: TextStyle(color: stateColor, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _formatTime(int ms) {
    if (ms == 0) return 'N/A';
    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = now - ms;
    if (diff < 0) {
      // timestamp futuro (o formato distinto): mostrar fecha
      return _absolute(ms);
    }
    if (diff < 60000) return 'Hace ${(diff / 1000).floor()}s';
    if (diff < 3600000) return 'Hace ${(diff / 60000).floor()}m';
    if (diff < 86400000) return 'Hace ${(diff / 3600000).floor()}h';
    return _absolute(ms);
  }

  String _absolute(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final mn = d.minute.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year} $hh:$mn';
  }
}
