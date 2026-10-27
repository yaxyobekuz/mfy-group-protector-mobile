/// ASOSIY QOBIQ — pastki menyu va markazdagi "+" tugmasi.
///
/// ⚠️ EKRANLAR `IndexedStack` DA SAQLANADI: har almashganda qaytadan
/// qurilsa, ro'yxat boshiga qaytib, server so'rovi qayta ketardi —
/// fuqaro xaritadan qaytganda joyini yo'qotardi.
library;

import 'package:flutter/material.dart';

import '../shared/config/theme.dart';
import 'appeals_screen.dart';
import 'home_screen.dart';
import 'map_screen.dart';
import 'new_appeal_screen.dart';
import 'news_screen.dart';
import 'profile_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  /// ⚠️ KALIT ORQALI YANGILASH: murojaat yuborilgandan keyin bosh
  /// sahifa va ro'yxat eski sonlarni ko'rsatib turardi.
  int _version = 0;

  void _openNew() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const NewAppealScreen()),
    );
    if (created == true && mounted) {
      setState(() {
        _version += 1;
        _index = 1; // "Murojaatlarim"
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomeScreen(
        key: ValueKey('home-$_version'),
        onNewAppeal: _openNew,
        onOpenTab: (i) => setState(() => _index = i),
      ),
      AppealsScreen(key: ValueKey('appeals-$_version')),
      MapScreen(key: ValueKey('map-$_version')),
      NewsScreen(key: ValueKey('news-$_version')),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      floatingActionButton: FloatingActionButton(
        onPressed: _openNew,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: AppColors.card,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        height: 68,
        padding: EdgeInsets.zero,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.home_outlined,
              active: Icons.home,
              label: 'Bosh sahifa',
              selected: _index == 0,
              onTap: () => setState(() => _index = 0),
            ),
            _NavItem(
              icon: Icons.description_outlined,
              active: Icons.description,
              label: 'Murojaatlar',
              selected: _index == 1,
              onTap: () => setState(() => _index = 1),
            ),
            // ⚠️ MARKAZDA BO'SHLIQ: "+" tugmasi shu yerda turadi.
            const SizedBox(width: 56),
            _NavItem(
              icon: Icons.map_outlined,
              active: Icons.map,
              label: 'Xarita',
              selected: _index == 2,
              onTap: () => setState(() => _index = 2),
            ),
            _NavItem(
              icon: Icons.person_outline,
              active: Icons.person,
              label: 'Profil',
              selected: _index == 4,
              onTap: () => setState(() => _index = 4),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.active,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData active;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.mutedForeground;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? active : icon, size: 24, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
