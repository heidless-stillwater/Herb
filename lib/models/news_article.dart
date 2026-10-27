class NewsArticle {
  final String id;
  final String title;
  final String journal;
  final String date;
  final String category;
  final String summaryPreview;
  final String objective;
  final String finding;
  final String takeaway;
  final String? stashStrainMatch;
  final String url;
  final bool isBookmarked;
  final bool isSpotlight;

  const NewsArticle({
    required this.id,
    required this.title,
    required this.journal,
    required this.date,
    required this.category,
    required this.summaryPreview,
    required this.objective,
    required this.finding,
    required this.takeaway,
    this.stashStrainMatch,
    required this.url,
    this.isBookmarked = false,
    this.isSpotlight = false,
  });

  NewsArticle copyWith({
    String? id,
    String? title,
    String? journal,
    String? date,
    String? category,
    String? summaryPreview,
    String? objective,
    String? finding,
    String? takeaway,
    String? stashStrainMatch,
    String? url,
    bool? isBookmarked,
    bool? isSpotlight,
  }) {
    return NewsArticle(
      id: id ?? this.id,
      title: title ?? this.title,
      journal: journal ?? this.journal,
      date: date ?? this.date,
      category: category ?? this.category,
      summaryPreview: summaryPreview ?? this.summaryPreview,
      objective: objective ?? this.objective,
      finding: finding ?? this.finding,
      takeaway: takeaway ?? this.takeaway,
      stashStrainMatch: stashStrainMatch ?? this.stashStrainMatch,
      url: url ?? this.url,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      isSpotlight: isSpotlight ?? this.isSpotlight,
    );
  }
}
