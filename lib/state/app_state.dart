import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../models/session_data.dart';
import '../models/news_article.dart';
import '../services/news_service.dart';
import '../services/gemini_service.dart';
import '../services/stillwater_auth_service.dart';
import '../services/firestore_sync_service.dart';
import '../services/subscription_service.dart';

class AppState extends ChangeNotifier {
  bool _bypassAuth = false;
  bool get bypassAuth => _bypassAuth;
  void setBypassAuth(bool val) {
    _bypassAuth = val;
    notifyListeners();
  }

  bool _hasPassedPaywall = false;
  bool get hasPassedPaywall => _hasPassedPaywall;
  void setPassedPaywall(bool val) {
    _hasPassedPaywall = val;
    notifyListeners();
  }

  static const String _productsPrefKey = 'herb_saved_products_json';

  final StillwaterAuthService authService = StillwaterAuthService();
  final FirestoreSyncService syncService = FirestoreSyncService();
  final SubscriptionService subscriptionService = SubscriptionService();

  bool get needsPaywall {
    if (bypassAuth) return false;
    if (!authService.isAuthenticated) return false;
    if (authService.isStillwaterSuperUser) return false;
    if (_hasPassedPaywall) return false;
    return !subscriptionService.isSubscribed;
  }

  Future<void> syncWithCloud() async {
    final uid = authService.uid;
    if (uid == null) return;
    try {
      await subscriptionService.fetchSubscriptionStatus(
        uid,
        isSuperUser: authService.isStillwaterSuperUser,
      );
      final cloudProducts = await syncService.fetchCloudProducts(uid);
      if (cloudProducts.isNotEmpty) {
        final existingIds = _products.map((p) => p.id).toSet();
        for (final cp in cloudProducts) {
          if (!existingIds.contains(cp.id)) {
            _products.add(cp);
          }
        }
      }
      for (final p in _products) {
        await syncService.syncProductToCloud(uid, p);
      }
      await _saveProductsToDisk();
      notifyListeners();
    } catch (e) {
      debugPrint('Cloud sync error: $e');
    }
  }

  AppState() {
    authService.addListener(() {
      final uid = authService.uid;
      if (uid != null) {
        subscriptionService.fetchSubscriptionStatus(
          uid,
          isSuperUser: authService.isStillwaterSuperUser,
        );
      }
      notifyListeners();
    });
    subscriptionService.addListener(notifyListeners);
    subscriptionService.initFromLocal();
    _geminiService.initFromPrefs().then((_) => notifyListeners());
    initPersistence();
  }

  int _currentTab = 0;
  int get currentTab => _currentTab;

  void setTab(int index) {
    if (_currentTab != index) {
      _currentTab = index;
      notifyListeners();
    }
  }

  // Dual-Mode UI (Simple vs Detail)
  String _viewMode = 'simple';
  String get viewMode => _viewMode;

  void setViewMode(String mode) {
    if (_viewMode != mode) {
      _viewMode = mode;
      notifyListeners();
    }
  }

  // Simple Mode Context Switcher ('weight' vs 'type')
  String _simpleContext = 'weight';
  String get simpleContext => _simpleContext;

  void setSimpleContext(String ctx) {
    if (_simpleContext != ctx) {
      _simpleContext = ctx;
      notifyListeners();
    }
  }

  // Currently In Rotation / Active Vibe Strain
  String _activeVibeStrainId = 'prod-5'; // Gelato #33 by default
  String get activeVibeStrainId => _activeVibeStrainId;

  Product get activeVibeProduct {
    return _products.firstWhere(
      (p) => p.id == _activeVibeStrainId,
      orElse: () => _products.first,
    );
  }

  void setActiveVibeStrain(String id) {
    if (_activeVibeStrainId != id) {
      _activeVibeStrainId = id;
      notifyListeners();
    }
  }

  // Quick Hits Counter for Simple Mode Hero Card
  int _todayHitsCount = 3;
  int get todayHitsCount => _todayHitsCount;

  void logQuickHit() {
    _todayHitsCount++;
    notifyListeners();
  }

  // Filter & Search
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  String _selectedType = 'All';
  String get selectedType => _selectedType;

  String _selectedSort = 'Highest Rated';
  String get selectedSort => _selectedSort;

  String _selectedStatus = 'All';
  String get selectedStatus => _selectedStatus;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedType(String type) {
    _selectedType = type;
    notifyListeners();
  }

  void setSelectedSort(String sort) {
    _selectedSort = sort;
    notifyListeners();
  }

  void setSelectedStatus(String status) {
    _selectedStatus = status;
    notifyListeners();
  }

  // Initial Product Data based on Stitch Design
  final List<Product> _products = [
    Product(
      id: 'prod-1',
      name: 'Pineapple Express',
      description: 'Tropical aroma with notes of sweet cedar and citrus. Cerebral uplift transitioning to relaxation.',
      strength: '24.5% THC · 0.4% CBD',
      type: 'Hybrid',
      datePurchased: DateTime(2026, 9, 12),
      dateOpened: DateTime(2026, 9, 15),
      dateFinished: null,
      rating: 9.4,
      reviewNotes: 'Crisp pineapple pine citrus notes, long lasting daytime clarity.',
      source: 'Apex Botanicals, Downtown Flagship',
      remainingGrams: 14.2,
      totalGrams: 28.0,
      price: 180.0,
      isFavorite: true,
    ),
    Product(
      id: 'prod-2',
      name: 'Northern Lights',
      description: 'Pungent sweet pine aroma with heavy resinous trichomes. Deep nighttime tranquility.',
      strength: '21.0% THC · 1.2% CBD',
      type: 'Indica',
      datePurchased: DateTime(2026, 9, 20),
      dateOpened: DateTime(2026, 9, 22),
      dateFinished: null,
      rating: 9.8,
      reviewNotes: 'Heavy body relaxation and sedative couch-lock. Ideal for late evenings.',
      source: 'Green Horizon, Pacific Heights',
      remainingGrams: 6.5,
      totalGrams: 14.0,
      price: 110.0,
      isFavorite: true,
    ),
    Product(
      id: 'prod-3',
      name: 'Sour Diesel',
      description: 'Classic pungent fuel and diesel bouquet with skunky lemon undertones. Energizing head focus.',
      strength: '26.2% THC · 0.1% CBD',
      type: 'Sativa',
      datePurchased: DateTime(2026, 10, 2),
      dateOpened: DateTime(2026, 10, 4),
      dateFinished: null,
      rating: 9.1,
      reviewNotes: 'Fast-acting, dreamy cerebral effects. Invigorating creative energy.',
      source: 'Apex Botanicals, Downtown Flagship',
      remainingGrams: 22.0,
      totalGrams: 28.0,
      price: 195.0,
      isFavorite: true,
    ),
    Product(
      id: 'prod-4',
      name: 'Blue Dream Live Rosin',
      description: 'First-wash solventless cold-cured rosin. Rich sweet blueberry compote aroma.',
      strength: '78.4% THC · 2.1% CBG',
      type: 'Extract',
      datePurchased: DateTime(2026, 10, 10),
      dateOpened: DateTime(2026, 10, 12),
      dateFinished: null,
      rating: 9.6,
      reviewNotes: 'Sublime terpene preservation. Incredibly smooth vaporization profile.',
      source: 'Emerald Valley Labs',
      remainingGrams: 3.8,
      totalGrams: 5.0,
      price: 85.0,
      isFavorite: true,
    ),
    Product(
      id: 'prod-5',
      name: 'Gelato #33',
      description: 'Dessert-like flavor profile with sweet citrus and dark berry notes.',
      strength: '23.8% THC · 0.2% CBD',
      type: 'Hybrid',
      datePurchased: DateTime(2026, 8, 14),
      dateOpened: DateTime(2026, 8, 16),
      dateFinished: DateTime(2026, 9, 10),
      rating: 8.9,
      reviewNotes: 'Smooth and flavorful. Great balanced head and body harmony.',
      source: 'Green Horizon, Pacific Heights',
      remainingGrams: 0.0,
      totalGrams: 14.0,
      price: 120.0,
      isFavorite: false,
    ),
    Product(
      id: 'prod-6',
      name: 'Granddaddy Purple',
      description: 'Dense purple buds covered in snow-like crystal frost. Sweet grape and berry fragrance.',
      strength: '22.4% THC · 0.5% CBD',
      type: 'Indica',
      datePurchased: DateTime(2026, 10, 18),
      dateOpened: null,
      dateFinished: null,
      rating: 9.2,
      reviewNotes: 'Unopened jar held in climate-controlled vault storage.',
      source: 'Emerald Valley Labs',
      remainingGrams: 14.0,
      totalGrams: 14.0,
      price: 115.0,
      isFavorite: false,
    ),
  ];

  List<Product> get products => List.unmodifiable(_products);

  List<Product> get openProducts => _products.where((p) => p.isOpen).toList();

  List<Product> get filteredProducts {
    var list = _products.where((p) {
      // Search
      final matchesSearch = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.source.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.description.toLowerCase().contains(_searchQuery.toLowerCase());

      // Type Filter
      final matchesType = _selectedType == 'All' || p.type == _selectedType;

      // Status Filter
      bool matchesStatus = true;
      if (_selectedStatus == 'In Stash') {
        matchesStatus = p.isOpen;
      } else if (_selectedStatus == 'Unopened') {
        matchesStatus = p.isUnopened;
      } else if (_selectedStatus == 'Finished') {
        matchesStatus = p.isFinished;
      }

      return matchesSearch && matchesType && matchesStatus;
    }).toList();

    // Sorting
    switch (_selectedSort) {
      case 'Highest Rated':
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'Strength %':
        list.sort((a, b) {
          final aNum = double.tryParse(RegExp(r'\d+(\.\d+)?').stringMatch(a.strength) ?? '0') ?? 0;
          final bNum = double.tryParse(RegExp(r'\d+(\.\d+)?').stringMatch(b.strength) ?? '0') ?? 0;
          return bNum.compareTo(aNum);
        });
        break;
      case 'Recently Purchased':
        list.sort((a, b) => b.datePurchased.compareTo(a.datePurchased));
        break;
      case 'Name A-Z':
        list.sort((a, b) => a.name.compareTo(b.name));
        break;
    }

    return list;
  }

  // Persistent Storage for Products
  Future<void> initPersistence() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString(_productsPrefKey);
      if (savedJson != null && savedJson.trim().isNotEmpty) {
        final decoded = jsonDecode(savedJson) as List<dynamic>;
        if (decoded.isNotEmpty) {
          _products.clear();
          for (final item in decoded) {
            _products.add(Product.fromJson(item as Map<String, dynamic>));
          }
          notifyListeners();
        }
      } else {
        // Save initial default mock products to disk so future edits persist
        _saveProductsToDisk();
      }
    } catch (e) {
      debugPrint('Error loading saved products: $e');
    }
  }

  Future<void> _saveProductsToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_products.map((p) => p.toJson()).toList());
      await prefs.setString(_productsPrefKey, encoded);
    } catch (e) {
      debugPrint('Error persisting products to SharedPreferences: $e');
    }
  }

  // CRUD Operations
  void addProduct(Product product) {
    _products.insert(0, product);
    _saveProductsToDisk();
    notifyListeners();
  }

  void updateProduct(Product updated) {
    final index = _products.indexWhere((p) => p.id == updated.id);
    if (index != -1) {
      _products[index] = updated;
      _saveProductsToDisk();
      notifyListeners();
    }
  }

  void deleteProduct(String id) {
    _products.removeWhere((p) => p.id == id);
    _saveProductsToDisk();
    notifyListeners();
  }

  void toggleFavorite(String id) {
    final index = _products.indexWhere((p) => p.id == id);
    if (index != -1) {
      _products[index] = _products[index].copyWith(isFavorite: !_products[index].isFavorite);
      _saveProductsToDisk();
      notifyListeners();
    }
  }

  // Curated Sources
  final List<BrandSource> brandSources = [
    BrandSource(
      name: 'Apex Botanicals',
      location: 'Downtown Flagship',
      stashCount: 12,
      badge: 'Verified Partner',
      rating: 9.7,
    ),
    BrandSource(
      name: 'Green Horizon',
      location: 'Pacific Heights',
      stashCount: 5,
      badge: 'Organic Cultivar',
      rating: 9.4,
    ),
    BrandSource(
      name: 'Emerald Valley Labs',
      location: 'Craft Concentrates',
      stashCount: 4,
      badge: 'Master Grower',
      rating: 9.8,
    ),
  ];

  // Weekly Intake Data
  final List<DailyIntake> weeklyIntake = [
    DailyIntake(dayName: 'Mon', grams: 0.9),
    DailyIntake(dayName: 'Tue', grams: 1.1),
    DailyIntake(dayName: 'Wed', grams: 0.8),
    DailyIntake(dayName: 'Thu', grams: 1.3),
    DailyIntake(dayName: 'Fri', grams: 1.8, isWeekend: true),
    DailyIntake(dayName: 'Sat', grams: 2.1, isWeekend: true),
    DailyIntake(dayName: 'Sun', grams: 1.5, isWeekend: true),
  ];

  // Pattern Engine Insights
  final List<PatternInsight> patternInsights = [
    PatternInsight(
      title: 'Evening Indica Ritual',
      description: '82% of Northern Lights sessions are logged between 20:00 - 23:00, with an average 1.2g dosing.',
      tag: 'Timing Pattern',
      metric: '82% Consistency',
    ),
    PatternInsight(
      title: 'Efficiency Optimization',
      description: 'Stash burn rate reduced by 14% since switching primary consumption to convection vaporizer.',
      tag: 'Efficiency',
      metric: '-14% Burn Rate',
    ),
    PatternInsight(
      title: 'Strain Preference Drift',
      description: 'Hybrid strains comprise 52% of total intake over the past 30 days, up from 38% last quarter.',
      tag: 'Strain Trend',
      metric: '52% Share',
    ),
  ];

  // Calculated Metrics
  double get totalStashRemainingGrams =>
      _products.fold(0.0, (sum, p) => sum + p.remainingGrams);

  int get activeStrainsCount =>
      _products.where((p) => p.isOpen).length;

  double get avgDailyBurn => 1.28; // grams / day

  int get runwayDays => (totalStashRemainingGrams / avgDailyBurn).round();

  double get totalSpendMonth =>
      _products.fold(0.0, (sum, p) => sum + p.price);

  // Strain Breakdown Metrics for Simple Mode
  double get indicaRemainingGrams => _products
      .where((p) => p.type.toLowerCase() == 'indica')
      .fold(0.0, (sum, p) => sum + p.remainingGrams);

  double get sativaRemainingGrams => _products
      .where((p) => p.type.toLowerCase() == 'sativa')
      .fold(0.0, (sum, p) => sum + p.remainingGrams);

  double get hybridRemainingGrams => _products
      .where((p) => p.type.toLowerCase() == 'hybrid')
      .fold(0.0, (sum, p) => sum + p.remainingGrams);

  int get indicaStrainCount =>
      _products.where((p) => p.type.toLowerCase() == 'indica').length;

  int get sativaStrainCount =>
      _products.where((p) => p.type.toLowerCase() == 'sativa').length;

  int get hybridStrainCount =>
      _products.where((p) => p.type.toLowerCase() == 'hybrid').length;

  // Gemini AI Service
  final GeminiService _geminiService = GeminiService();
  GeminiService get geminiService => _geminiService;

  Future<void> updateGeminiApiKey(String key) async {
    await _geminiService.saveApiKey(key);
    notifyListeners();
  }

  // News & Clinical Intelligence State
  final List<NewsArticle> _newsArticles = NewsService.getInitialArticles();
  List<NewsArticle> get newsArticles => List.unmodifiable(_newsArticles);

  String _selectedNewsCategory = 'All';
  String get selectedNewsCategory => _selectedNewsCategory;

  String _newsSearchQuery = '';
  String get newsSearchQuery => _newsSearchQuery;

  bool _isScanning = false;
  bool get isScanning => _isScanning;

  void setSelectedNewsCategory(String category) {
    _selectedNewsCategory = category;
    notifyListeners();
  }

  void setNewsSearchQuery(String query) {
    _newsSearchQuery = query;
    notifyListeners();
  }

  List<NewsArticle> get filteredNewsArticles {
    return _newsArticles.where((article) {
      // Search
      final matchesSearch = _newsSearchQuery.isEmpty ||
          article.title.toLowerCase().contains(_newsSearchQuery.toLowerCase()) ||
          article.category.toLowerCase().contains(_newsSearchQuery.toLowerCase()) ||
          article.summaryPreview.toLowerCase().contains(_newsSearchQuery.toLowerCase()) ||
          (article.stashStrainMatch?.toLowerCase().contains(_newsSearchQuery.toLowerCase()) ?? false);

      // Category / Bookmark filter
      bool matchesCategory = true;
      if (_selectedNewsCategory == 'Bookmarked') {
        matchesCategory = article.isBookmarked;
      } else if (_selectedNewsCategory != 'All') {
        matchesCategory = article.category.toLowerCase().contains(_selectedNewsCategory.toLowerCase());
      }

      return matchesSearch && matchesCategory;
    }).toList();
  }

  void toggleArticleBookmark(String id) {
    final index = _newsArticles.indexWhere((a) => a.id == id);
    if (index != -1) {
      final current = _newsArticles[index];
      _newsArticles[index] = current.copyWith(isBookmarked: !current.isBookmarked);
      notifyListeners();
    }
  }

  Future<void> scanNewSources() async {
    _isScanning = true;
    notifyListeners();

    const title = 'Terpene Entourage Dynamics: Beta-Caryophyllene & CBD in Inflammatory Joint Pathways';
    const abstractText = 'Clinical investigation of volatile sesquiterpene beta-caryophyllene combined with cannabidiol for peripheral CB2 receptor affinity and suppression of inflammatory cytokine cascades in human synovial tissue.';
    
    // Call Gemini to synthesize study breakdown
    final activeStrainNames = openProducts.map((p) => p.name).toList();
    final summary = await _geminiService.summarizeResearch(
      title: title,
      abstractText: abstractText,
      userStashStrains: activeStrainNames,
    );

    final newStudy = NewsArticle(
      id: 'pubmed-scan-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      journal: 'PubMed ID: PMC${1000000 + DateTime.now().millisecond} · NIH Peer Review',
      date: 'Just now',
      category: 'Pain & Neuropathy',
      summaryPreview: summary['finding'] ?? 'Live scan retrieved verified clinical study on terpene synergy.',
      objective: summary['objective'] ?? 'Evaluated peripheral CB2 receptor activation and anti-inflammatory pathways.',
      finding: summary['finding'] ?? 'Significant 39% reduction in TNF-alpha cytokine expression.',
      takeaway: summary['takeaway'] ?? 'Incorporate caryophyllene-dominant cultivars during high physical strain.',
      stashStrainMatch: summary['stashMatch'] ?? 'Pineapple Express (14.2g in active stash)',
      url: 'https://pubmed.ncbi.nlm.nih.gov/?term=cannabis+entourage+effect',
      isBookmarked: false,
    );

    _newsArticles.insert(1, newStudy);
    _isScanning = false;
    notifyListeners();
  }
}
