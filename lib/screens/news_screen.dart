import 'package:flutter/material.dart';
import '../models/news_article.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/ai_summary_modal.dart';

class NewsScreen extends StatelessWidget {
  final AppState state;

  const NewsScreen({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final articles = state.filteredNewsArticles;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Top App Bar / Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'RESEARCH & INTELLIGENCE',
                              style: textTheme.labelSmall?.copyWith(
                                color: AppColors.primary,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Clinical Insights',
                              style: textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            // Gemini API Configuration Button
                            IconButton(
                              onPressed: () => _showGeminiSettings(context),
                              icon: Icon(
                                Icons.auto_awesome,
                                size: 20,
                                color: state.geminiService.hasApiKey
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                              tooltip: 'Gemini AI Configuration',
                            ),
                            const SizedBox(width: 4),
                            // Live Web Scan Button
                            InkWell(
                              onTap: state.isScanning ? null : () => state.scanNewSources(),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceElevation2,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: state.isScanning ? AppColors.primary : AppColors.border,
                                    width: 1,
                                  ),
                                  boxShadow: state.isScanning
                                      ? [
                                          BoxShadow(
                                            color: AppColors.primary.withValues(alpha: 0.3),
                                            blurRadius: 10,
                                            spreadRadius: 1,
                                          )
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (state.isScanning)
                                      const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                        ),
                                      )
                                    else
                                      const Icon(
                                        Icons.radar_rounded,
                                        size: 16,
                                        color: AppColors.primary,
                                      ),
                                    const SizedBox(width: 6),
                                    Text(
                                      state.isScanning ? 'Scanning...' : 'Live Scan',
                                      style: textTheme.labelSmall?.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevation1,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                      child: TextField(
                        onChanged: (val) => state.setNewsSearchQuery(val),
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search PubMed trials, cannabinoids, terpenes...',
                          hintStyle: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          suffixIcon: state.newsSearchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18, color: AppColors.textSecondary),
                                  onPressed: () => state.setNewsSearchQuery(''),
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Horizontal Category Filter Pills
            SliverToBoxAdapter(
              child: SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildFilterChip('All'),
                    _buildFilterChip('Pain & Neuropathy'),
                    _buildFilterChip('Sleep Architecture'),
                    _buildFilterChip('Anxiety & Mood'),
                    _buildFilterChip('Terpene Synergy'),
                    _buildFilterChip('Bookmarked'),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Empty State
            if (articles.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.menu_book_outlined,
                          size: 48,
                          color: AppColors.textMuted.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No clinical studies found',
                          style: textTheme.titleMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Try adjusting your search terms or filter selection.',
                          style: textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              // Studies List
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final article = articles[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _buildStudyCard(context, article),
                      );
                    },
                    childCount: articles.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = state.selectedNewsCategory == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => state.setSelectedNewsCategory(label),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surfaceElevation2,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStudyCard(BuildContext context, NewsArticle article) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevation2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: article.isSpotlight
              ? AppColors.primary.withValues(alpha: 0.4)
              : AppColors.border,
          width: 1,
        ),
        boxShadow: article.isSpotlight
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 16,
                  spreadRadius: 2,
                )
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header with Category and Bookmark
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 8),
            child: Row(
              children: [
                if (article.isSpotlight) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'SPOTLIGHT',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevation3,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Text(
                    article.category.toUpperCase(),
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => state.toggleArticleBookmark(article.id),
                  icon: Icon(
                    article.isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    color: article.isBookmarked ? AppColors.primary : AppColors.textMuted,
                    size: 20,
                  ),
                  splashRadius: 18,
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              article.title,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                height: 1.3,
              ),
            ),
          ),

          // Citation
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
            child: Row(
              children: [
                const Icon(
                  Icons.menu_book_rounded,
                  size: 13,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    '${article.journal} · ${article.date}',
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Stash Match Banner
          if (article.stashStrainMatch != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.electric_bolt_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Matches Stash: ${article.stashStrainMatch}',
                        style: textTheme.labelSmall?.copyWith(
                          color: AppColors.primaryLight,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Layperson Summary Preview
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              article.summaryPreview,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(height: 12),

          // Bottom Action
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  AiSummaryModal.show(
                    context,
                    article,
                    () => state.toggleArticleBookmark(article.id),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surfaceElevation3,
                  foregroundColor: AppColors.primaryLight,
                  elevation: 0,
                  side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                ),
                icon: const Icon(
                  Icons.auto_awesome,
                  size: 15,
                  color: AppColors.primary,
                ),
                label: const Text(
                  'AI Clinical Breakdown',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showGeminiSettings(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final controller = TextEditingController(text: state.geminiService.apiKey);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevation2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        title: Row(
          children: [
            const Icon(Icons.auto_awesome, color: AppColors.primary, size: 22),
            const SizedBox(width: 8),
            Text(
              'Gemini AI Setup',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Google Gemini synthesizes medical cannabis trials into structured clinical takeaways and matches them against your active stash.',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: state.geminiService.hasApiKey
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.surfaceElevation1,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: state.geminiService.hasApiKey
                      ? AppColors.primary.withValues(alpha: 0.3)
                      : AppColors.border,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    state.geminiService.hasApiKey
                        ? Icons.check_circle_rounded
                        : Icons.info_outline_rounded,
                    size: 16,
                    color: state.geminiService.hasApiKey
                        ? AppColors.primary
                        : AppColors.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    state.geminiService.hasApiKey
                        ? 'Gemini 1.5 Flash Connected'
                        : 'Using Local Synthesis (No Key)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: state.geminiService.hasApiKey
                          ? AppColors.primaryLight
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Gemini API Key',
              style: textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'AIzaSy...',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                filled: true,
                fillColor: AppColors.surfaceElevation1,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              state.updateGeminiApiKey(controller.text);
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Save Key', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
