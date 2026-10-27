/// REYTING — faol fuqarolar.
///
/// ⚠️ BALLAR SERVERDA HISOBLANADI (`common/points.ts` yagona manba):
/// mijozda hisoblansa, ikki ilova ikki xil son ko'rsatardi.
library;

import 'package:flutter/material.dart';

import '../entities/session/session.dart';
import '../shared/api/client.dart';
import '../shared/api/models.dart';
import '../shared/config/labels.dart';
import '../shared/config/theme.dart';
import '../shared/ui/widgets.dart';

class RatingScreen extends StatefulWidget {
  const RatingScreen({super.key});

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  String _scope = '';
  late Future<List<RatingRow>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = ApiClient.get('/mobile/rating', {'scope': _scope}).then(
      (d) => (d as List<dynamic>)
          .map((e) => RatingRow.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myId = SessionController.instance.profile?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Faol fuqarolar')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _ScopeChip(
                  label: 'Viloyat',
                  selected: _scope.isEmpty,
                  onTap: () => setState(() {
                    _scope = '';
                    _load();
                  }),
                ),
                const SizedBox(width: 8),
                _ScopeChip(
                  label: 'Tumanim',
                  selected: _scope == 'district',
                  onTap: () => setState(() {
                    _scope = 'district';
                    _load();
                  }),
                ),
              ],
            ),
          ),
          Expanded(
            child: AsyncView<List<RatingRow>>(
              future: _future,
              onRetry: () => setState(_load),
              emptyWhen: (data) => data.isEmpty,
              emptyIcon: Icons.emoji_events_outlined,
              emptyTitle: 'Reyting bo\'sh',
              builder: (context, rows) => ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                itemCount: rows.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final row = rows[index];
                  final mine = row.id == myId;

                  return AppCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 34,
                          child: _Rank(rank: row.rank),
                        ),
                        const SizedBox(width: 6),
                        Avatar(url: row.photoUrl, name: row.name, size: 40),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                mine ? '${row.name} (siz)' : row.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: mine
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                ),
                              ),
                              Text(
                                plural(row.appeals, 'murojaat'),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.mutedForeground,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${row.points}',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Text(
                          'ball',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Rank extends StatelessWidget {
  const _Rank({required this.rank});
  final int rank;

  @override
  Widget build(BuildContext context) {
    // ⚠️ FAQAT UCHTA BIRINCHISI RANGLI: hammasi ranglansa, ro'yxat
    // ola-bula bo'lib, birinchi o'rinlar ajralib turmasdi.
    const medals = <int, Color>{
      1: Color(0xFFD4A017),
      2: Color(0xFF9AA5B1),
      3: Color(0xFFB06C3A),
    };
    final color = medals[rank];

    if (color == null) {
      return Text(
        '$rank',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.mutedForeground,
        ),
      );
    }

    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Text(
        '$rank',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ScopeChip extends StatelessWidget {
  const _ScopeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ChoiceChip(
    label: Text(label),
    selected: selected,
    showCheckmark: false,
    backgroundColor: AppColors.card,
    selectedColor: AppColors.primary,
    side: const BorderSide(color: AppColors.border),
    labelStyle: TextStyle(
      color: selected ? Colors.white : AppColors.foreground,
      fontWeight: FontWeight.w600,
    ),
    onSelected: (_) => onTap(),
  );
}
