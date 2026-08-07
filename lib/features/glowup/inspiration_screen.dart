import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'glow_models.dart';

class InspirationGalleryScreen extends StatefulWidget {
  const InspirationGalleryScreen({super.key});

  @override
  State<InspirationGalleryScreen> createState() =>
      _InspirationGalleryScreenState();
}

class _InspirationGalleryScreenState extends State<InspirationGalleryScreen> {
  String _selectedCategory = 'All';
  final Set<String> _savedItems = <String>{};

  late final List<String> _categories;
  late final Future<void> _loadSaved;

  @override
  void initState() {
    super.initState();
    final cats = <String>{'All'};
    for (final item in inspirationItems) {
      cats.add(item.category);
    }
    _categories = cats.toList();
    _loadSaved = _loadSavedItems();
  }

  Future<void> _loadSavedItems() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('glowup_saved_inspiration') ?? const [];
    if (mounted) {
      setState(() => _savedItems.addAll(saved));
    }
  }

  Future<void> _toggleSave(String id) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_savedItems.contains(id)) {
        _savedItems.remove(id);
      } else {
        _savedItems.add(id);
      }
    });
    await prefs.setStringList('glowup_saved_inspiration', _savedItems.toList());
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedCategory == 'All'
        ? inspirationItems
        : inspirationItems
              .where((item) => item.category == _selectedCategory)
              .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inspiration'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_rounded),
            tooltip: 'Saved items',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => _SavedInspirationScreen(
                    savedIds: _savedItems,
                    onToggleSave: _toggleSave,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<void>(
        future: _loadSaved,
        builder: (context, snapshot) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Find your next glow-up inspo. Save what you love and learn how to recreate it.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _categories
                      .map(
                        (cat) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(cat),
                            selected: _selectedCategory == cat,
                            onSelected: (_) {
                              setState(() => _selectedCategory = cat);
                            },
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: MediaQuery.sizeOf(context).width > 650 ? 3 : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.9,
                children: filtered.map((item) {
                  final isSaved = _savedItems.contains(item.id);
                  return _InspirationTile(
                    item: item,
                    isSaved: isSaved,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => InspirationDetailScreen(
                            item: item,
                            isSaved: isSaved,
                            onToggleSave: () => _toggleSave(item.id),
                          ),
                        ),
                      );
                    },
                    onSave: () => _toggleSave(item.id),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InspirationTile extends StatelessWidget {
  const _InspirationTile({
    required this.item,
    required this.isSaved,
    required this.onTap,
    required this.onSave,
  });

  final InspirationItem item;
  final bool isSaved;
  final VoidCallback onTap;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                item.color.withValues(alpha: 0.85),
                item.color.withValues(alpha: 0.5),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, color: Colors.white, size: 44),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  item.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.category,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              IconButton(
                icon: Icon(
                  isSaved ? Icons.bookmark_rounded : Icons.bookmark_border,
                  color: Colors.white,
                  size: 22,
                ),
                onPressed: onSave,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InspirationDetailScreen extends StatelessWidget {
  const InspirationDetailScreen({
    required this.item,
    required this.isSaved,
    required this.onToggleSave,
    super.key,
  });

  final InspirationItem item;
  final bool isSaved;
  final VoidCallback onToggleSave;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(item.title),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              isSaved ? Icons.bookmark_rounded : Icons.bookmark_border,
              color: isSaved ? const Color(0xFFFF5FA2) : null,
            ),
            onPressed: onToggleSave,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  item.color.withValues(alpha: 0.85),
                  item.color.withValues(alpha: 0.5),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
              child: Icon(item.icon, color: Colors.white, size: 72),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'How to recreate this look',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          ...item.recreateSteps.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${entry.key + 1}',
                        style: TextStyle(
                          color: item.color,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: item.color.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_rounded, color: item.color),
                    const SizedBox(width: 8),
                    Text(
                      'Pro Tips',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...item.tips.map(
                  (tip) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(top: 7),
                          decoration: BoxDecoration(
                            color: item.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(tip)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedInspirationScreen extends StatelessWidget {
  const _SavedInspirationScreen({
    required this.savedIds,
    required this.onToggleSave,
  });

  final Set<String> savedIds;
  final ValueChanged<String> onToggleSave;

  @override
  Widget build(BuildContext context) {
    final savedItems = inspirationItems
        .where((item) => savedIds.contains(item.id))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Saved Inspiration'), centerTitle: true),
      body: savedItems.isEmpty
          ? const Center(child: Text('No saved items yet. Save some inspo!'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: savedItems.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _SavedItemTile(
                    item: item,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => InspirationDetailScreen(
                            item: item,
                            isSaved: true,
                            onToggleSave: () => onToggleSave(item.id),
                          ),
                        ),
                      );
                    },
                    onRemove: () => onToggleSave(item.id),
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _SavedItemTile extends StatelessWidget {
  const _SavedItemTile({
    required this.item,
    required this.onTap,
    required this.onRemove,
  });

  final InspirationItem item;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: item.color.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(item.icon, color: item.color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.category,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: onRemove,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
