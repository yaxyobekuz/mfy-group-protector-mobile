/// MENING MUROJAATLARIM.
///
/// ⚠️ SANOQLAR SERVERDAN KELADI (`counts`): mijozda sanalsa, filtr
/// qo'yilgan ro'yxatdan hisoblanib, "Hammasi 3" bo'lib qolardi.
library;

import 'package:flutter/material.dart';

import '../shared/api/client.dart';
import '../shared/api/models.dart';
import '../shared/config/labels.dart';
import '../shared/config/theme.dart';
import '../shared/util/date_uz.dart';
import '../shared/ui/widgets.dart';
import 'appeal_detail_screen.dart';

const List<({String key, String label})> _tabs = [
  (key: '', label: 'Hammasi'),
  (key: 'new', label: 'Yangi'),
  (key: 'in_progress', label: 'Bajarilmoqda'),
  (key: 'resolved', label: 'Hal qilindi'),
];

class AppealsScreen extends StatefulWidget {
  const AppealsScreen({super.key});

  @override
  State<AppealsScreen> createState() => _AppealsScreenState();
}

class _AppealsScreenState extends State<AppealsScreen> {
  String _status = '';
  late Future<AppealListResponse> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = ApiClient.get('/mobile/appeals', {'status': _status}).then(
      (d) => AppealListResponse.fromJson(d as Map<String, dynamic>),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Mening murojaatlarim')),
    body: Column(
      children: [
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _tabs.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final tab = _tabs[index];
              final selected = tab.key == _status;

              return ChoiceChip(
                label: Text(tab.label),
                selected: selected,
                showCheckmark: false,
                backgroundColor: AppColors.card,
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : AppColors.foreground,
                  fontWeight: FontWeight.w600,
                ),
                side: const BorderSide(color: AppColors.border),
                onSelected: (_) => setState(() {
                  _status = tab.key;
                  _load();
                }),
              );
            },
          ),
        ),
        Expanded(
          child: AsyncView<AppealListResponse>(
            future: _future,
            loadingLabel: 'Murojaatlar yuklanmoqda…',
            onRetry: () => setState(_load),
            emptyWhen: (data) => data.items.isEmpty,
            emptyIcon: Icons.inbox_outlined,
            emptyTitle: 'Murojaat yo\'q',
            emptyMessage:
                'Pastdagi "+" tugmasi orqali birinchi murojaatingizni '
                'yuboring.',
            builder: (context, data) => RefreshIndicator(
              onRefresh: () async {
                setState(_load);
                await _future;
              },
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                itemCount: data.items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) =>
                    _AppealCard(item: data.items[index], onChanged: () => setState(_load)),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _AppealCard extends StatelessWidget {
  const _AppealCard({required this.item, required this.onChanged});
  final AppealListItem item;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => AppCard(
    onTap: () async {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => AppealDetailScreen(id: item.id)),
      );
      onChanged();
    },
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorOf(item.category.color).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                iconOf(item.category.icon),
                size: 21,
                color: colorOf(item.category.color),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.category.name,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                  Text(
                    item.publicNo,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            StatusBadge(item.status),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          item.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 15, height: 1.4),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(
              Icons.schedule,
              size: 14,
              color: AppColors.mutedForeground,
            ),
            const SizedBox(width: 4),
            Text(
              formatDateUz(item.createdAt),
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.mutedForeground,
              ),
            ),
            if (item.commentCount > 0) ...[
              const SizedBox(width: 14),
              const Icon(
                Icons.chat_bubble_outline,
                size: 14,
                color: AppColors.mutedForeground,
              ),
              const SizedBox(width: 4),
              Text(
                '${item.commentCount}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.mutedForeground,
                ),
              ),
            ],
            const Spacer(),
            // ⚠️ MUDDAT FAQAT OCHIQ MUROJAATDA: yopilganida "muddati
            // o'tdi" deb ko'rsatish fuqaroni bekorga tashvishga
            // solardi.
            if (item.dueAt != null && item.resolvedAt == null)
              Text(
                formatDueUz(item.dueAt),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ],
    ),
  );
}
