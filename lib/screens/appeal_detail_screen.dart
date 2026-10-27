/// MUROJAAT TAFSILOTI — bosqichlar, suratlar, izohlar.
///
/// ⚠️ IZOH QO'SHILGANDAN KEYIN BUTUN SAHIFA QAYTA O'QILADI:
/// mahalliy ro'yxatga qo'shib qo'yilsa, server rad etgan izoh ham
/// ekranda turaverardi (uzunlik cheklovi, bloklangan hisob).
library;

import 'package:flutter/material.dart';

import '../shared/api/client.dart';
import '../shared/api/models.dart';
import '../shared/config/labels.dart';
import '../shared/config/theme.dart';
import '../shared/util/date_uz.dart';
import '../shared/ui/widgets.dart';

class AppealDetailScreen extends StatefulWidget {
  const AppealDetailScreen({super.key, required this.id});
  final String id;

  @override
  State<AppealDetailScreen> createState() => _AppealDetailScreenState();
}

class _AppealDetailScreenState extends State<AppealDetailScreen> {
  late Future<AppealDetail> _future;
  final TextEditingController _comment = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  void _load() {
    _future = ApiClient.get(
      '/mobile/appeals/${widget.id}',
    ).then((d) => AppealDetail.fromJson(d as Map<String, dynamic>));
  }

  Future<void> _send() async {
    final body = _comment.text.trim();
    if (body.length < 2 || _sending) return;

    setState(() => _sending = true);
    try {
      await ApiClient.post('/mobile/appeals/${widget.id}/comments', {
        'body': body,
      });
      _comment.clear();
      setState(_load);
    } on ApiException catch (error) {
      if (mounted) showToast(context, error.message, error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Murojaat')),
    body: AsyncView<AppealDetail>(
      future: _future,
      onRetry: () => setState(_load),
      builder: (context, appeal) => Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              appeal.publicNo,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          StatusBadge(appeal.status),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        appeal.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        appeal.body,
                        style: const TextStyle(height: 1.55),
                      ),
                      const SizedBox(height: 14),
                      _Meta(
                        icon: iconOf(appeal.category.icon),
                        text: appeal.category.name,
                      ),
                      if (appeal.category.orgName != null)
                        _Meta(
                          icon: Icons.account_balance_outlined,
                          text: appeal.category.orgName!,
                        ),
                      if (appeal.address != null)
                        _Meta(
                          icon: Icons.place_outlined,
                          text: appeal.address!,
                        ),
                      _Meta(
                        icon: Icons.schedule,
                        text: formatDateTimeUz(appeal.createdAt),
                      ),
                      if (appeal.dueAt != null && appeal.resolvedAt == null)
                        _Meta(
                          icon: Icons.timer_outlined,
                          text: 'Javob muddati: ${formatDueUz(appeal.dueAt)}',
                        ),
                    ],
                  ),
                ),

                if (appeal.attachments.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 140,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: appeal.attachments.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final file = appeal.attachments[index];
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(
                            fileUrl(file.url),
                            width: 180,
                            height: 140,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              width: 180,
                              color: AppColors.muted,
                              child: const Icon(
                                Icons.broken_image_outlined,
                                color: AppColors.mutedForeground,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],

                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bosqichlar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      for (final step in appeal.timeline)
                        _TimelineRow(
                          step: step,
                          last: step == appeal.timeline.last,
                        ),
                    ],
                  ),
                ),

                if (appeal.resolution != null) ...[
                  const SizedBox(height: 12),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Natija',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          appeal.resolution!,
                          style: const TextStyle(height: 1.55),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Izohlar (${appeal.comments.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (appeal.comments.isEmpty)
                        const Text(
                          'Hozircha izoh yo\'q.',
                          style: TextStyle(color: AppColors.mutedForeground),
                        ),
                      for (final comment in appeal.comments)
                        _CommentRow(comment: comment),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ⚠️ YOPILGAN MUROJAATGA IZOH YOZILMAYDI: server ham rad
          // etadi va maydonni ko'rsatish bekorga urinishga undardi.
          if (appeal.status != 'resolved' && appeal.status != 'rejected')
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _comment,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.newline,
                        decoration: const InputDecoration(
                          hintText: 'Izoh yozing…',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _sending ? null : _send,
                      icon: _sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.mutedForeground),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.mutedForeground,
            ),
          ),
        ),
      ],
    ),
  );
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.step, required this.last});
  final TimelineStep step;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final color = step.done ? AppColors.success : AppColors.border;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: step.done ? AppColors.success : AppColors.card,
                  border: Border.all(color: color, width: 2),
                  shape: BoxShape.circle,
                ),
                child: step.done
                    ? const Icon(Icons.check, size: 11, color: Colors.white)
                    : null,
              ),
              if (!last)
                Expanded(child: Container(width: 2, color: color)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 18),
              child: Text(
                step.label,
                style: TextStyle(
                  fontWeight: step.done ? FontWeight.w600 : FontWeight.w400,
                  color: step.done
                      ? AppColors.foreground
                      : AppColors.mutedForeground,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentRow extends StatelessWidget {
  const _CommentRow({required this.comment});
  final AppealComment comment;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: comment.mine ? AppColors.accent : AppColors.muted,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                comment.mine ? 'Siz' : comment.author,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              formatRelativeUz(comment.createdAt),
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.mutedForeground,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(comment.body, style: const TextStyle(height: 1.45)),
      ],
    ),
  );
}
