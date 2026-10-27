/// BOSH SAHIFA.
///
/// ⚠️ SONLAR SERVERDAN OLINADI (`/mobile/stats`), MIJOZDA
/// HISOBLANMAYDI: ro'yxat sahifalab keladi va mijozdagi hisob
/// faqat birinchi sahifani sanab, "3 ta murojaat" deb ko'rsatardi.
library;

import 'package:flutter/material.dart';

import '../shared/api/client.dart';
import '../shared/api/models.dart';
import '../shared/config/theme.dart';
import '../shared/ui/widgets.dart';
import '../entities/session/session.dart';
import 'rating_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onNewAppeal,
    required this.onOpenTab,
  });

  final VoidCallback onNewAppeal;
  final void Function(int index) onOpenTab;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<HomeStats> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = ApiClient.get(
      '/mobile/stats',
    ).then((d) => HomeStats.fromJson(d as Map<String, dynamic>));
  }

  Future<void> _refresh() async {
    setState(_load);
    await _future;
    await SessionController.instance.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionController.instance;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _Hero(
              district: session.profile?.districtName,
              onNewAppeal: widget.onNewAppeal,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _QuickCard(
                          icon: Icons.map_outlined,
                          color: AppColors.success,
                          title: 'Xarita',
                          subtitle: 'Murojaatlar xaritasi',
                          onTap: () => widget.onOpenTab(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickCard(
                          icon: Icons.description_outlined,
                          color: const Color(0xFF7C3AED),
                          title: 'Mening murojaatlarim',
                          subtitle: 'Holatini kuzating',
                          onTap: () => widget.onOpenTab(1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickCard(
                          icon: Icons.article_outlined,
                          color: AppColors.primary,
                          title: 'Yangiliklar',
                          subtitle: 'Va natijalar',
                          onTap: () => widget.onOpenTab(3),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickCard(
                          icon: Icons.emoji_events_outlined,
                          color: AppColors.warning,
                          title: 'Reyting',
                          subtitle: 'Faol fuqarolar',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const RatingScreen(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),
                  AppCard(
                    child: AsyncView<HomeStats>(
                      future: _future,
                      onRetry: () => setState(_load),
                      builder: (context, stats) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Viloyat bo\'yicha',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _Stat(value: stats.total, label: 'Jami murojaat'),
                              _divider(),
                              _Stat(
                                value: stats.resolved,
                                label: 'Hal qilindi',
                              ),
                              _divider(),
                              _Stat(value: stats.last30, label: 'Oxirgi 30 kun'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  AnimatedBuilder(
                    animation: session,
                    builder: (context, _) {
                      final stats = session.profile?.stats;
                      return AppCard(
                        onTap: () => widget.onOpenTab(1),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Sizning murojaatlaringiz',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    stats == null
                                        ? '—'
                                        : '${stats.resolved} ta hal qilindi',
                                    style: const TextStyle(
                                      color: AppColors.mutedForeground,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${stats?.total ?? 0}',
                                style: const TextStyle(
                                  color: AppColors.accentForeground,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward,
                              color: AppColors.mutedForeground,
                              size: 20,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Container(
    width: 1,
    height: 40,
    color: AppColors.border,
    margin: const EdgeInsets.symmetric(horizontal: 4),
  );
}

class _Hero extends StatelessWidget {
  const _Hero({required this.district, required this.onNewAppeal});
  final String? district;
  final VoidCallback onNewAppeal;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: EdgeInsets.fromLTRB(
      24,
      MediaQuery.of(context).padding.top + 24,
      24,
      28,
    ),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2463EB), Color(0xFF13A5E1)],
      ),
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(28),
        bottomRight: Radius.circular(28),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (district != null)
          Text(
            district!,
            style: const TextStyle(color: Colors.white70, fontSize: 15),
          ),
        const SizedBox(height: 8),
        const Text(
          'Toza va qulay\nhudud uchun birga!',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            height: 1.25,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Hududingizdagi muammolarni fotosurat bilan yuboring. '
          'Biz ularni hal qilishga yordam beramiz.',
          style: TextStyle(color: Colors.white70, height: 1.5),
        ),
        const SizedBox(height: 22),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onNewAppeal,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                children: [
                  Icon(Icons.add, color: AppColors.primary),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Murojaat yuborish',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward, color: AppColors.primary),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _QuickCard extends StatelessWidget {
  const _QuickCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AppCard(
    onTap: onTap,
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(height: 10),
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.mutedForeground,
          ),
        ),
      ],
    ),
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          '$value',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.mutedForeground,
          ),
        ),
      ],
    ),
  );
}
