import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/database_service.dart';

class PrayerStatsPage extends StatelessWidget {
  const PrayerStatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Statistiques - Prières', style: GoogleFonts.lora()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statistiques principales
            FutureBuilder<Map<String, dynamic>>(
              future: _loadStats(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final stats = snapshot.data!;
                return Column(
                  children: [
                    _StatCard(
                      title: 'Prières totales',
                      value: stats['total'].toString(),
                      color: Colors.blue,
                      icon: Icons.favorite,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'Exaucées',
                            value: stats['answered'].toString(),
                            color: Colors.green,
                            icon: Icons.check_circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            title: 'En attente',
                            value: stats['unanswered'].toString(),
                            color: Colors.orange,
                            icon: Icons.schedule,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _StatCard(
                      title: 'Taux d\'exaucement',
                      value: '${stats['rate'].toStringAsFixed(1)}%',
                      color: Colors.purple,
                      icon: Icons.trending_up,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),
            Text(
              'Répartition par priorité',
              style: GoogleFonts.lora(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _PriorityBreakdown(),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _loadStats() async {
    final total = await DatabaseService.db.getPrayerCount();
    final answered = await DatabaseService.db.getAnsweredCount();
    final unanswered = await DatabaseService.db.getUnansweredCount();
    final rate = await DatabaseService.db.getAnswerRate();

    return {
      'total': total,
      'answered': answered,
      'unanswered': unanswered,
      'rate': rate,
    };
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriorityBreakdown extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadPriorityBreakdown(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        final breakdown = snapshot.data!;
        return Column(
          children: breakdown.map((item) {
            final total = breakdown.fold<int>(0, (sum, x) => sum + (x['count'] as int));
            final percentage = total > 0 ? ((item['count'] as int) / total * 100).toStringAsFixed(1) : '0.0';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item['label']),
                      Text('${item['count']} ($percentage%)'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: double.parse(percentage) / 100,
                      minHeight: 8,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(item['color']),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _loadPriorityBreakdown() async {
    final all = await DatabaseService.db.watchAllPrayers().first;
    final critiques = all.where((p) => p.priority == 3).length;
    final importantes = all.where((p) => p.priority == 2).length;
    final normales = all.where((p) => p.priority == 1).length;

    return [
      {'label': 'Critique', 'count': critiques, 'color': Colors.red},
      {'label': 'Importante', 'count': importantes, 'color': Colors.orange},
      {'label': 'Normale', 'count': normales, 'color': Colors.grey},
    ];
  }
}
