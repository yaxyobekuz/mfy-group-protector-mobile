/// YANGILIKLAR VA NATIJALAR.
///
/// ⚠️ KO'RISH BELGISI OCHILGANDA YUBORILADI (`/news/:id/view`),
/// ro'yxatda emas: ro'yxat ochilishi bilan hamma yangilik
/// "o'qilgan" bo'lib, ko'rishlar soni ma'nosini yo'qotardi.
library;

import 'package:flutter/material.dart';

import '../shared/api/client.dart';
import '../shared/api/models.dart';
import '../shared/config/theme.dart';
import '../shared/util/date_uz.dart';
import '../shared/ui/widgets.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  late Future<List<NewsItem>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = ApiClient.get('/mobile/news').then(
      (d) => (d as List<dynamic>)
          .map((e) => NewsItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Yangiliklar')),
    body: AsyncView<List<NewsItem>>(
      future: _future,
      loadingLabel: 'Yuklanmoqda…',
      onRetry: () => setState(_load),
      emptyWhen: (data) => data.isEmpty,
      emptyIcon: Icons.article_outlined,
      emptyTitle: 'Yangilik yo\'q',
      emptyMessage: 'Hududingiz bo\'yicha e\'lonlar shu yerda chiqadi.',
      builder: (context, items) => RefreshIndicator(
        onRefresh: () async {
          setState(_load);
          await _future;
        },
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _NewsCard(item: items[index]),
        ),
      ),
    ),
  );
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.item});
  final NewsItem item;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: EdgeInsets.zero,
    onTap: () {
      // ⚠️ NATIJA KUTILMAYDI: ko'rish sanoqchisi ikkinchi darajali
      // va u sekin javob bersa, sahifa ochilishi kechikardi.
      ApiClient.post('/mobile/news/${item.id}/view').catchError((_) => null);
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => _NewsDetail(item: item)),
      );
    },
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (item.coverUrl != null)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: Image.network(
              fileUrl(item.coverUrl!),
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.isPinned)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Muhim',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentForeground,
                    ),
                  ),
                ),
              Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.mutedForeground,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    formatDateUz(item.publishedAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.visibility_outlined,
                    size: 14,
                    color: AppColors.mutedForeground,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${item.viewCount}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _NewsDetail extends StatelessWidget {
  const _NewsDetail({required this.item});
  final NewsItem item;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Yangilik')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        if (item.coverUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.network(
              fileUrl(item.coverUrl!),
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        const SizedBox(height: 16),
        Text(
          item.title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          formatDateUz(item.publishedAt),
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.mutedForeground,
          ),
        ),
        const SizedBox(height: 16),
        Text(item.body, style: const TextStyle(height: 1.6, fontSize: 15)),
      ],
    ),
  );
}
