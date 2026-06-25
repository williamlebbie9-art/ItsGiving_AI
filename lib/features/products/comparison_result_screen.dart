import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/models/decision_models.dart';
import '../../core/services/decision_engine.dart';
import '../../core/storage/comparison_repository.dart';
import 'comparison_chat_screen.dart';

class ComparisonResultScreen extends StatefulWidget {
  const ComparisonResultScreen({
    required this.comparison,
    required this.decisionEngine,
    required this.comparisonRepository,
    this.startChatExpanded = false,
    this.isCosmetic = false,
    this.isGeneral = false,
    super.key,
  });

  final ProductComparison comparison;
  final DecisionEngine decisionEngine;
  final ComparisonRepository comparisonRepository;
  final bool startChatExpanded;
  final bool isCosmetic;
  final bool isGeneral;

  @override
  State<ComparisonResultScreen> createState() => _ComparisonResultScreenState();
}

class _ComparisonResultScreenState extends State<ComparisonResultScreen> {
  late bool _isSaved;
  late bool _chatExpanded;

  @override
  void initState() {
    super.initState();
    _chatExpanded = widget.startChatExpanded;
    _checkIfSaved();
  }

  Future<void> _checkIfSaved() async {
    final saved = await widget.comparisonRepository.getById(
      widget.comparison.id,
    );
    if (mounted) {
      setState(() {
        _isSaved = saved != null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
    final formattedDate = dateFormat.format(widget.comparison.createdAt);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comparison Result'),
        actions: [
          IconButton(
            icon: Icon(_isSaved ? Icons.bookmark : Icons.bookmark_outline),
            onPressed: _toggleSave,
            tooltip: _isSaved ? 'Remove from saved' : 'Save comparison',
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                onTap: _shareComparison,
                child: const Text('Share'),
              ),
              PopupMenuItem(
                onTap: _openChat,
                child: const Text('Ask Questions'),
              ),
            ],
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Hero header with product images
          SliverToBoxAdapter(child: _buildHeroHeader(theme, formattedDate)),

          // AI Score section with modern design
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _buildModernScoreCard(theme),
            ),
          ),

          // Verdict section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _buildModernVerdictCard(theme),
            ),
          ),

          // Overview section (only for food — not cosmetic, not general)
          if (!widget.isCosmetic &&
              !widget.isGeneral &&
              widget.comparison.overview.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: _buildModernSection(
                  theme,
                  Icons.article_outlined,
                  'Overview',
                  widget.comparison.overview,
                ),
              ),
            ),

          // Side-by-side comparison cards (different sections per type)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _buildModernComparisonCards(theme),
            ),
          ),

          // Specifications
          if (widget.comparison.specifications.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: _buildModernSection(
                  theme,
                  Icons.settings_outlined,
                  'Specifications',
                  widget.comparison.specifications,
                ),
              ),
            ),

          // Recommendations badges
          if (widget.comparison.alternativeRecommendations.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: _buildModernRecommendations(theme),
              ),
            ),

          // Major Differences
          if (widget.comparison.majorDifferences.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: _buildModernSection(
                  theme,
                  Icons.compare_arrows,
                  'Major Differences',
                  widget.comparison.majorDifferences,
                ),
              ),
            ),

          // Value for Money
          if (widget.comparison.valueForMoney.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: _buildModernSection(
                  theme,
                  Icons.account_balance_wallet_outlined,
                  'Value for Money',
                  widget.comparison.valueForMoney,
                ),
              ),
            ),

          // Quality Assessment
          if (widget.comparison.qualityAssessment.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: _buildModernSection(
                  theme,
                  Icons.star_outline,
                  'Quality Assessment',
                  widget.comparison.qualityAssessment,
                ),
              ),
            ),

          // Summary
          if (widget.comparison.summary.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: _buildModernSection(
                  theme,
                  Icons.summarize_outlined,
                  'Summary',
                  widget.comparison.summary,
                ),
              ),
            ),

          // Inline collapsible chat for follow-up questions
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _buildChatSection(theme),
            ),
          ),

          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
          ),
        ],
      ),
    );
  }

  // ─── HERO HEADER ────────────────────────────────────────────────────────────

  Widget _buildHeroHeader(ThemeData theme, String formattedDate) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.08),
            theme.colorScheme.secondary.withValues(alpha: 0.05),
            theme.colorScheme.tertiary.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.25),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product A
              Expanded(child: _buildProductImageColumn(theme, isA: true)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 60),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.secondary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.3,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        'VS',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Product B
              Expanded(child: _buildProductImageColumn(theme, isA: false)),
            ],
          ),
          const SizedBox(height: 16),
          // Date badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.6,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.schedule_outlined,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  formattedDate,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImageColumn(ThemeData theme, {required bool isA}) {
    final image = isA
        ? widget.comparison.productAImage.originalPath
        : widget.comparison.productBImage.originalPath;
    final name = isA
        ? widget.comparison.productAName
        : widget.comparison.productBName;
    final accentColor = isA
        ? theme.colorScheme.primary
        : theme.colorScheme.secondary;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: accentColor.withValues(alpha: 0.3),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Image.file(
              File(image),
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                height: 150,
                color: theme.colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.image_outlined,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            name,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: accentColor,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ─── MODERN SCORE CARD ──────────────────────────────────────────────────────

  Widget _buildModernScoreCard(ThemeData theme) {
    String scoreA = '50';
    String scoreB = '50';
    final quality = widget.comparison.qualityAssessment;
    if (quality.isNotEmpty) {
      // Try multiple patterns to support different response formats
      final aMatch = RegExp(r'A:\s*([\d.]+)').firstMatch(quality);
      final bMatch = RegExp(r'B:\s*([\d.]+)').firstMatch(quality);
      if (aMatch != null) scoreA = aMatch.group(1)!;
      if (bMatch != null) scoreB = bMatch.group(1)!;

      // Fallback: try to extract any decimal numbers if A:/B: prefix is missing
      if (aMatch == null) {
        final numbers = RegExp(r'(\d+\.?\d*)').allMatches(quality).toList();
        if (numbers.length >= 2) {
          final first = double.tryParse(numbers[0].group(1)!);
          final second = double.tryParse(numbers[1].group(1)!);
          if (first != null && second != null) {
            // Normalize: if scores are > 1, treat as percentages, else as decimals
            scoreA = first > 1 ? (first / 100).toString() : first.toString();
            scoreB = second > 1 ? (second / 100).toString() : second.toString();
          }
        }
      }
    }

    final aVal = double.tryParse(scoreA) ?? 0.0;
    final bVal = double.tryParse(scoreB) ?? 0.0;
    final total = aVal + bVal;
    final aPercent = total > 0 ? (aVal / total * 100).round() : 50;
    final bPercent = total > 0 ? (bVal / total * 100).round() : 50;

    final isA = aPercent >= bPercent;
    final isTie = aPercent == bPercent;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.06),
            theme.colorScheme.secondary.withValues(alpha: 0.04),
          ],
        ),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.auto_awesome,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'AI Score',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              // Product A score circle
              Expanded(
                child: _buildScorePillar(
                  theme: theme,
                  percent: aPercent,
                  name: widget.comparison.productAName,
                  accent: theme.colorScheme.primary,
                  isWinner: !isTie && isA,
                ),
              ),
              const SizedBox(width: 8),
              // VS divider
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'VS',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurfaceVariant,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              // Product B score circle
              Expanded(
                child: _buildScorePillar(
                  theme: theme,
                  percent: bPercent,
                  name: widget.comparison.productBName,
                  accent: theme.colorScheme.secondary,
                  isWinner: !isTie && !isA,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Modern dual-gradient progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 14,
              child: Stack(
                children: [
                  // Background track
                  Container(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
                  ),
                  // A side (left to center)
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: aPercent / 100.0,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.primary.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // B side (right to center)
                  FractionallySizedBox(
                    alignment: Alignment.centerRight,
                    widthFactor: bPercent / 100.0,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.secondary.withValues(alpha: 0.7),
                            theme.colorScheme.secondary,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScorePillar({
    required ThemeData theme,
    required int percent,
    required String name,
    required Color accent,
    required bool isWinner,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isWinner)
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.emoji_events,
                  size: 12,
                  color: Colors.amber.shade700,
                ),
                const SizedBox(width: 3),
                Text(
                  'Winner',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.amber.shade700,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [accent, accent.withValues(alpha: 0.6)],
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '$percent%',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // ─── MODERN VERDICT CARD ────────────────────────────────────────────────────

  Widget _buildModernVerdictCard(ThemeData theme) {
    // Determine the recommended product name directly from recommendation,
    // or fall back to the quality assessment scores rather than checking
    // for the existence of arbitrary detail keys (which would always
    // point to Product B for food comparisons after price was removed).
    String determinePick() {
      if (widget.comparison.recommendation.isNotEmpty) {
        return widget.comparison.recommendation;
      }
      // Use confidence scores to pick the winner as fallback
      final quality = widget.comparison.qualityAssessment;
      if (quality.isNotEmpty) {
        final aMatch = RegExp(r'A:\s*([\d.]+)').firstMatch(quality);
        final bMatch = RegExp(r'B:\s*([\d.]+)').firstMatch(quality);
        if (aMatch != null && bMatch != null) {
          final aVal = double.tryParse(aMatch.group(1)!) ?? 0.0;
          final bVal = double.tryParse(bMatch.group(1)!) ?? 0.0;
          if (aVal > bVal) return widget.comparison.productAName;
          if (bVal > aVal) return widget.comparison.productBName;
        }
      }
      // If scores are tied or missing, use productADetails content length
      // as a heuristic for which product has more analysis data
      final aContentLen = widget.comparison.productADetails.values
          .where((v) => v.isNotEmpty)
          .fold(0, (sum, v) => sum + v.length);
      final bContentLen = widget.comparison.productBDetails.values
          .where((v) => v.isNotEmpty)
          .fold(0, (sum, v) => sum + v.length);
      return aContentLen >= bContentLen
          ? widget.comparison.productAName
          : widget.comparison.productBName;
    }

    final pick = determinePick();

    final reason =
        widget.comparison.alternativeRecommendations['Verdict'] ??
        widget.comparison.summary;

    final isA = pick.toLowerCase().contains(
      widget.comparison.productAName.toLowerCase(),
    );
    final isB = pick.toLowerCase().contains(
      widget.comparison.productBName.toLowerCase(),
    );

    final accentColor = isA
        ? theme.colorScheme.primary
        : isB
        ? theme.colorScheme.secondary
        : theme.colorScheme.tertiary;

    final icon = isA
        ? Icons.arrow_forward
        : isB
        ? Icons.arrow_back
        : Icons.swap_horiz;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withValues(alpha: 0.1),
            accentColor.withValues(alpha: 0.04),
            theme.colorScheme.surface.withValues(alpha: 0.3),
          ],
        ),
        border: Border.all(color: accentColor.withValues(alpha: 0.2), width: 1),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Verdict',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  pick,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.format_quote,
                size: 16,
                color: accentColor.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  reason,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── MODERN COMPARISON CARDS ───────────────────────────────────────────────

  Widget _buildModernComparisonCards(ThemeData theme) {
    // Per-product detail getters with product-specific fallbacks
    String detailA(String key, {String fallback = 'No details available.'}) =>
        widget.comparison.productADetails[key]?.isNotEmpty == true
        ? widget.comparison.productADetails[key]!
        : fallback;
    String detailB(String key, {String fallback = 'No details available.'}) =>
        widget.comparison.productBDetails[key]?.isNotEmpty == true
        ? widget.comparison.productBDetails[key]!
        : fallback;

    // Try to get price from per-product details, fall back to advantages/valueForMoney
    String priceA = detailA('priceAndPurchase');
    if (priceA.isEmpty || priceA == 'No details available.') {
      priceA = widget.comparison.advantagesA.isNotEmpty
          ? widget.comparison.advantagesA
          : '';
    }
    if (priceA.isEmpty) {
      priceA = widget.comparison.valueForMoney.isNotEmpty
          ? widget.comparison.valueForMoney
          : 'Price info not available';
    }

    String priceB = detailB('priceAndPurchase');
    if (priceB.isEmpty || priceB == 'No details available.') {
      priceB = widget.comparison.advantagesB.isNotEmpty
          ? widget.comparison.advantagesB
          : '';
    }
    if (priceB.isEmpty) {
      priceB = widget.comparison.valueForMoney.isNotEmpty
          ? widget.comparison.valueForMoney
          : 'Price info not available';
    }

    final effectsA = detailA(
      'effectsBenefits',
      fallback: widget.comparison.advantagesA.isNotEmpty
          ? widget.comparison.advantagesA
          : 'No effects/benefits available.',
    );
    final effectsB = detailB(
      'effectsBenefits',
      fallback: widget.comparison.advantagesB.isNotEmpty
          ? widget.comparison.advantagesB
          : 'No effects/benefits available.',
    );
    final ingredientsA = detailA('ingredients');
    final ingredientsB = detailB('ingredients');
    final prosConsA = detailA(
      'prosCons',
      fallback: widget.comparison.advantagesA.isNotEmpty
          ? widget.comparison.advantagesA
          : 'No pros/cons available.',
    );
    final prosConsB = detailB(
      'prosCons',
      fallback: widget.comparison.advantagesB.isNotEmpty
          ? widget.comparison.advantagesB
          : 'No pros/cons available.',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Icon(Icons.compare, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Detailed Comparison',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        // Price (only shown for general and cosmetic, hidden for food)
        if (widget.isGeneral || widget.isCosmetic)
          Column(
            children: [
              _buildModernComparisonRow(
                theme: theme,
                label: 'Price',
                nameA: widget.comparison.productAName,
                nameB: widget.comparison.productBName,
                contentA: priceA,
                contentB: priceB,
                iconA: Icons.attach_money,
                iconB: Icons.attach_money,
              ),
              const SizedBox(height: 12),
            ],
          ),
        // Effects / Benefits (shown for all types)
        _buildModernComparisonRow(
          theme: theme,
          label: 'Effects / Benefits',
          nameA: widget.comparison.productAName,
          nameB: widget.comparison.productBName,
          contentA: effectsA,
          contentB: effectsB,
          iconA: Icons.auto_awesome,
          iconB: Icons.auto_awesome,
        ),
        const SizedBox(height: 12),
        // Ingredients (shown for food and cosmetic, NOT for general)
        if (!widget.isGeneral)
          _buildModernComparisonRow(
            theme: theme,
            label: 'Ingredients',
            nameA: widget.comparison.productAName,
            nameB: widget.comparison.productBName,
            contentA: ingredientsA,
            contentB: ingredientsB,
            iconA: Icons.science_outlined,
            iconB: Icons.science_outlined,
          ),
        if (!widget.isGeneral) const SizedBox(height: 12),
        // Pros & Cons (shown for all types)
        _buildModernComparisonRow(
          theme: theme,
          label: 'Pros & Cons',
          nameA: widget.comparison.productAName,
          nameB: widget.comparison.productBName,
          contentA: prosConsA,
          contentB: prosConsB,
          iconA: Icons.thumb_up_outlined,
          iconB: Icons.thumb_up_outlined,
        ),
      ],
    );
  }

  Widget _buildModernComparisonRow({
    required ThemeData theme,
    required String label,
    required String nameA,
    required String nameB,
    required String contentA,
    required String contentB,
    required IconData iconA,
    required IconData iconB,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product A card
            Expanded(
              child: _buildCompactCard(
                theme: theme,
                name: nameA,
                content: contentA,
                accentColor: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            // Product B card
            Expanded(
              child: _buildCompactCard(
                theme: theme,
                name: nameB,
                content: contentB,
                accentColor: theme.colorScheme.secondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactCard({
    required ThemeData theme,
    required String name,
    required String content,
    required Color accentColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.15)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withValues(alpha: 0.04),
            theme.colorScheme.surface.withValues(alpha: 0.2),
          ],
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              name,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: accentColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.4,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  // ─── MODERN RECOMMENDATIONS ────────────────────────────────────────────────

  Widget _buildModernRecommendations(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.05),
            theme.colorScheme.tertiary.withValues(alpha: 0.03),
          ],
        ),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.recommend_outlined,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Recommendations',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: widget.comparison.alternativeRecommendations.entries
                .map(
                  (entry) => _buildModernBadge(theme, entry.key, entry.value),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildModernBadge(ThemeData theme, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
            theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  // ─── MODERN SECTION ─────────────────────────────────────────────────────────

  Widget _buildModernSection(
    ThemeData theme,
    IconData icon,
    String title,
    String content,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surface.withValues(alpha: 0.1),
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.15),
          ],
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  // ─── CHAT SECTION ───────────────────────────────────────────────────────────

  Widget _buildChatSection(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.secondary.withValues(alpha: 0.05),
            theme.colorScheme.primary.withValues(alpha: 0.03),
          ],
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _chatExpanded = !_chatExpanded),
            child: Row(
              children: [
                Icon(
                  Icons.chat_outlined,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ask follow-up questions',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _chatExpanded ? Icons.expand_less : Icons.expand_more,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () =>
                      setState(() => _chatExpanded = !_chatExpanded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: SizedBox(
              height: 360,
              child: ComparisonChatWidget(
                comparison: widget.comparison,
                decisionEngine: widget.decisionEngine,
              ),
            ),
            crossFadeState: _chatExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  // ─── ACTIONS ────────────────────────────────────────────────────────────────

  Future<void> _toggleSave() async {
    if (_isSaved) {
      await widget.comparisonRepository.delete(widget.comparison.id);
    } else {
      await widget.comparisonRepository.save(widget.comparison);
    }
    setState(() {
      _isSaved = !_isSaved;
    });
    _showMessage(_isSaved ? 'Comparison saved!' : 'Comparison removed!');
  }

  void _shareComparison() {
    _showMessage('Share feature coming soon');
  }

  void _openChat() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ComparisonChatScreen(
          comparison: widget.comparison,
          decisionEngine: widget.decisionEngine,
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
