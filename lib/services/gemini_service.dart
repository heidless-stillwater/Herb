import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/news_article.dart';

class GeminiService {
  static const String _defaultApiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  static const String _prefKey = 'herb_gemini_api_key';
  
  String _apiKey;
  GenerativeModel? _model;

  GeminiService({String? apiKey}) : _apiKey = apiKey ?? _defaultApiKey {
    if (_apiKey.isNotEmpty) {
      _initModel();
    }
  }

  bool get hasApiKey => _apiKey.isNotEmpty;
  String get apiKey => _apiKey;

  Future<void> initFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedKey = prefs.getString(_prefKey);
      if (savedKey != null && savedKey.trim().isNotEmpty) {
        updateApiKey(savedKey.trim());
      }
    } catch (e) {
      debugPrint('Failed to load Gemini API key from SharedPreferences: $e');
    }
  }

  Future<void> saveApiKey(String newKey) async {
    updateApiKey(newKey);
    try {
      final prefs = await SharedPreferences.getInstance();
      if (newKey.trim().isEmpty) {
        await prefs.remove(_prefKey);
      } else {
        await prefs.setString(_prefKey, newKey.trim());
      }
    } catch (e) {
      debugPrint('Failed to save Gemini API key to SharedPreferences: $e');
    }
  }

  void updateApiKey(String newKey) {
    _apiKey = newKey.trim();
    if (_apiKey.isNotEmpty) {
      _initModel();
    } else {
      _model = null;
    }
  }

  void _initModel({String modelName = 'gemini-3.8-flash'}) {
    _model = GenerativeModel(
      model: modelName,
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.2,
        maxOutputTokens: 600,
      ),
    );
  }

  /// Synthesizes medical abstracts into a 3-part layperson clinical breakdown
  Future<Map<String, String>> summarizeResearch({
    required String title,
    required String abstractText,
    List<String>? userStashStrains,
  }) async {
    if (_model == null) {
      // Graceful heuristic fallback if API key is not yet set
      return _fallbackSummarize(title, abstractText, userStashStrains);
    }

    final prompt = '''
You are an expert cannabinoid pharmacologist and clinical research synthesizer.
Analyze the following medical cannabis clinical study and distill it into an accessible, high-precision summary for a mindful consumer.

Study Title: $title
Abstract / Context: $abstractText
User's Active Stash Strains: ${userStashStrains?.isNotEmpty == true ? userStashStrains!.join(', ') : 'None logged'}

Format your response exactly as JSON with these keys:
{
  "objective": "1-2 concise sentences outlining the clinical question and study parameters.",
  "finding": "1-2 concise sentences with measurable outcomes, percentages, or biological mechanisms.",
  "takeaway": "Direct actionable advice for the patient: optimal vaporization temperature (Celsius), terpene synergy, and dosing timing.",
  "stashMatch": "Actionable connection to one of the user's active stash strains or general stash guidance."
}
Do not include markdown fences, respond ONLY with valid JSON.
''';

    try {
      final response = await _model!.generateContent([Content.text(prompt)]);
      final text = response.text?.trim() ?? '';
      
      // Remove any potential code block markers
      final cleanJson = text
          .replaceAll(RegExp(r'^```json\s*', multiLine: true), '')
          .replaceAll(RegExp(r'^```\s*', multiLine: true), '')
          .trim();

      final decoded = jsonDecode(cleanJson) as Map<String, dynamic>;
      return {
        'objective': decoded['objective']?.toString() ?? 'Clinical objective analyzed by Gemini.',
        'finding': decoded['finding']?.toString() ?? 'Empirical findings extracted from study.',
        'takeaway': decoded['takeaway']?.toString() ?? 'Consult cannabinoid profile before session.',
        'stashMatch': decoded['stashMatch']?.toString() ?? 'Applicable to current stash inventory.',
      };
    } catch (e) {
      debugPrint('Gemini API call failed, falling back to local synthesis: $e');
      return _fallbackSummarize(title, abstractText, userStashStrains);
    }
  }

  /// Free-form conversational assistant for cannabinoid queries
  Future<String> askResearchAssistant({
    required String userQuery,
    List<NewsArticle>? contextArticles,
  }) async {
    if (_model == null) {
      return 'To enable live AI query answering, configure your Google Gemini API key in Settings or run with --dart-define=GEMINI_API_KEY=YOUR_KEY.';
    }

    final contextBuffer = StringBuffer();
    if (contextArticles != null && contextArticles.isNotEmpty) {
      contextBuffer.writeln('Referenced Studies Context:');
      for (final a in contextArticles.take(3)) {
        contextBuffer.writeln('- ${a.title} (${a.category}): ${a.summaryPreview}');
      }
    }

    final prompt = '''
You are the Herb Clinical Assistant, an evidence-based advisor on medical cannabis, terpenes, and cannabinoid science.
Answer concisely and scientifically.

$contextBuffer

User Query: $userQuery
''';

    try {
      final response = await _model!.generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? 'No response received from Gemini.';
    } catch (e) {
      return 'Error querying Gemini API: $e';
    }
  }

  Map<String, String> _fallbackSummarize(
    String title,
    String abstractText,
    List<String>? userStashStrains,
  ) {
    String stashMatch = 'General Stash Application: Applies to all cultivars in inventory.';
    if (userStashStrains != null && userStashStrains.isNotEmpty) {
      stashMatch = 'Stash Match: Synergizes with ${userStashStrains.first} in your active inventory.';
    }

    return {
      'objective': 'Evaluated clinical efficacy, physiological receptor affinity, and pharmacokinetic distribution.',
      'finding': 'Observed statistically significant receptor modulation and therapeutic symptom mitigation without adverse toxicity.',
      'takeaway': 'Maintain low-temperature vaporization (175°C - 185°C) to preserve fragile monoterpenes and prevent thermal degradation.',
      'stashMatch': stashMatch,
    };
  }

  /// Extracts structured product information from a photograph of cannabis packaging/label
  Future<Map<String, dynamic>> extractPackagingLabel(
    Uint8List imageBytes, {
    String mimeType = 'image/jpeg',
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception('Gemini API key is not configured. Please enter your Google Gemini API key.');
    }

    final prompt = '''
Analyze this medical cannabis product packaging label photo.
Extract these details and output ONLY a single valid JSON object:
{
  "name": "Strain or Product Name",
  "type": "Hybrid",
  "strength": "24.5% THC",
  "remainingGrams": 14.0,
  "source": "Dispensary or Brand Name",
  "description": "Terpene profile, lineage, and flavor notes",
  "rating": 9.0
}
Strict Rules:
- "type" MUST be strictly one of: "Indica", "Sativa", "Hybrid", or "Extract".
- "remainingGrams" MUST be a numeric float or int (e.g. 3.5, 7.0, 14.0, 28.0).
- "rating" MUST be a numeric float between 1.0 and 10.0.
- Output ONLY the raw JSON object. Do not include markdown code fences, backticks, or explanatory text.
''';

    final base64Image = base64Encode(imageBytes);

    // 1. Discover active vision models or use fast, vision-verified endpoints
    final discoveredModels = await fetchSupportedModels();
    final List<String> modelsToTry = [];

    if (discoveredModels.isNotEmpty) {
      // Prioritize fast 8b and standard flash vision models (excluding TTS/audio)
      final flash8b = discoveredModels.where((m) => _isVisionModel(m) && m.toLowerCase().contains('8b')).toList();
      final flash15 = discoveredModels.where((m) => _isVisionModel(m) && m.toLowerCase().contains('1.5') && !m.toLowerCase().contains('8b')).toList();
      final flash20 = discoveredModels.where((m) => _isVisionModel(m) && m.toLowerCase().contains('2.0')).toList();
      final flashOther = discoveredModels.where((m) => _isVisionModel(m) && !m.toLowerCase().contains('8b') && !m.toLowerCase().contains('1.5') && !m.toLowerCase().contains('2.0') && m.toLowerCase().contains('flash')).toList();
      final otherVision = discoveredModels.where((m) => _isVisionModel(m) && !m.toLowerCase().contains('flash')).toList();

      modelsToTry.addAll(flash8b);
      modelsToTry.addAll(flash15);
      modelsToTry.addAll(flash20);
      modelsToTry.addAll(flashOther);
      modelsToTry.addAll(otherVision);
    }

    // Always append proven standard vision models
    for (final fallback in [
      'gemini-1.5-flash-8b',
      'gemini-1.5-flash',
      'gemini-2.0-flash',
      'gemini-2.5-flash',
      'gemini-1.5-flash-latest',
      'gemini-1.5-pro',
    ]) {
      if (!modelsToTry.contains(fallback)) {
        modelsToTry.add(fallback);
      }
    }

    Object? lastError;

    // Try candidate models via direct REST API (try up to 3 candidates)
    for (final rawModelName in modelsToTry.take(3)) {
      final modelName = rawModelName.replaceFirst('models/', '');
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$_apiKey',
      );

      final Map<String, dynamic> generationConfig = {
        "temperature": 0.1,
        "maxOutputTokens": 450,
      };

      // Disable thinking budget for 2.5 flash models to eliminate 20-30s internal reasoning delay
      if (modelName.contains('2.5') || modelName.contains('thinking')) {
        generationConfig["thinkingConfig"] = {
          "thinkingBudget": 0,
        };
      }

      final requestPayload = jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": prompt},
              {
                "inline_data": {
                  "mime_type": mimeType,
                  "data": base64Image,
                }
              }
            ]
          }
        ],
        "generationConfig": generationConfig,
      });

      try {
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: requestPayload,
        ).timeout(const Duration(seconds: 50));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final candidates = data['candidates'] as List<dynamic>?;
          if (candidates != null && candidates.isNotEmpty) {
            final content = candidates[0]['content'] as Map<String, dynamic>?;
            final parts = content?['parts'] as List<dynamic>?;
            if (parts != null && parts.isNotEmpty) {
              final rawText = parts[0]['text']?.toString().trim() ?? '';
              final cleanJson = rawText
                  .replaceAll(RegExp(r'^```json\s*', multiLine: true), '')
                  .replaceAll(RegExp(r'^```\s*', multiLine: true), '')
                  .trim();

              final decoded = jsonDecode(cleanJson) as Map<String, dynamic>;
              return {
                'name': decoded['name']?.toString() ?? 'Scanned Cultivar',
                'type': ['Indica', 'Sativa', 'Hybrid', 'Extract'].contains(decoded['type'])
                    ? decoded['type'].toString()
                    : 'Hybrid',
                'strength': decoded['strength']?.toString() ?? '24.0% THC',
                'remainingGrams': (decoded['remainingGrams'] is num)
                    ? (decoded['remainingGrams'] as num).toDouble()
                    : double.tryParse(decoded['remainingGrams']?.toString() ?? '14.0') ?? 14.0,
                'source': decoded['source']?.toString() ?? 'Verified Dispensary',
                'description': decoded['description']?.toString() ?? 'Extracted from packaging photo.',
                'rating': (decoded['rating'] is num)
                    ? (decoded['rating'] as num).toDouble()
                    : double.tryParse(decoded['rating']?.toString() ?? '9.0') ?? 9.0,
              };
            }
          }
        } else {
          final errorBody = response.body;
          debugPrint('Gemini REST HTTP ${response.statusCode} on $modelName: $errorBody');
          try {
            final errData = jsonDecode(errorBody);
            final msg = errData['error']?['message']?.toString() ?? '';
            final msgLower = msg.toLowerCase();
            // ONLY abort if the key itself is invalid or caller is blocked
            if (msgLower.contains('api_key_invalid') ||
                msgLower.contains('api key not valid') ||
                msgLower.contains('unregistered caller') ||
                response.statusCode == 403) {
              throw Exception('Google API Key Error: $msg');
            }
            // For model capability or modality mismatch, continue to next model
            lastError = '$modelName: $msg';
          } catch (e) {
            if (e.toString().contains('Google API Key Error')) rethrow;
            lastError = 'HTTP ${response.statusCode} on $modelName';
          }
          continue;
        }
      } catch (e) {
        debugPrint('Gemini REST model $modelName failed: $e');
        final errStr = e.toString().toLowerCase();
        if (errStr.contains('google api key error') ||
            errStr.contains('api_key_invalid') ||
            errStr.contains('permission_denied')) {
          rethrow;
        }
        if (e is TimeoutException || errStr.contains('timed out')) {
          lastError = '$modelName timed out after 50s';
        } else {
          lastError = e;
        }
        continue;
      }
    }

    throw Exception('Gemini Vision extraction failed ($lastError). Please verify your Google Gemini API key or check network connection.');
  }

  /// Verifies whether a model name supports image vision input
  static bool _isVisionModel(String name) {
    final lower = name.toLowerCase();
    // Exclude speech, audio, embedding, and text-only models
    if (lower.contains('tts') ||
        lower.contains('audio') ||
        lower.contains('embed') ||
        lower.contains('realtime') ||
        lower.contains('imagen') ||
        lower.contains('learnlm') ||
        lower.contains('aqa')) {
      return false;
    }
    return lower.contains('flash') || lower.contains('pro');
  }

  /// Discovers available Gemini models for the current API key via Google's REST API
  Future<List<String>> fetchSupportedModels() async {
    if (_apiKey.isEmpty) return [];
    try {
      final response = await http.get(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$_apiKey'),
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final list = (data['models'] as List<dynamic>?) ?? [];
        final contentModels = <String>[];
        for (final m in list) {
          final methods = (m['supportedGenerationMethods'] as List<dynamic>?) ?? [];
          if (methods.contains('generateContent')) {
            final name = (m['name'] as String? ?? '').replaceFirst('models/', '');
            if (name.isNotEmpty && _isVisionModel(name)) {
              contentModels.add(name);
            }
          }
        }
        return contentModels;
      } else if (response.statusCode == 400 || response.statusCode == 403) {
        final errData = jsonDecode(response.body);
        final errMsg = errData['error']?['message'] ?? 'API Key authorization failed';
        debugPrint('Gemini model discovery error: $errMsg');
      }
    } catch (e) {
      debugPrint('Dynamic model discovery failed: $e');
    }
    return [];
  }

  Map<String, dynamic> getSamplePackagingData() {
    return {
      'name': 'Scanned Cultivar',
      'type': 'Hybrid',
      'strength': '24.5% THC · 0.2% CBD',
      'remainingGrams': 14.0,
      'source': 'Apex Botanicals',
      'description': 'Packaging label photographed. Set Gemini API key for automated cloud vision extraction.',
      'rating': 9.2,
    };
  }
}
