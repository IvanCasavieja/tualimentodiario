import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:intl/intl.dart';

import '../../core/models/daily_food.dart';
import '../../core/ui_utils.dart';
import '../../core/text_filters.dart'; // normalizeDisplayText
import '../../core/daily_food_translations.dart';
import '../../core/i18n.dart'; // stringsProvider
import '../../core/share_helper.dart';
import '../common/favorite_heart.dart';

class FoodDetailDialog extends ConsumerStatefulWidget {
  const FoodDetailDialog({super.key, required this.item, required this.lang});

  final DailyFood item;
  final String lang;

  @override
  ConsumerState<FoodDetailDialog> createState() => _FoodDetailDialogState();
}

class _FoodDetailDialogState extends ConsumerState<FoodDetailDialog>
    with SingleTickerProviderStateMixin {
  final _scrollCtrl = ScrollController();
  bool _canScroll = false;
  bool _atEnd = false;
  final FlutterTts _tts = FlutterTts();
  bool _ttsReady = false;
  bool _isSpeaking = false;
  bool _isConfiguringTts = false;
  static const double _kMaxSpeechVolume = 1.0;

  late final AnimationController _hintAnim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  late final Animation<double> _hintOffset = Tween<double>(
    begin: 0,
    end: 6,
  ).animate(CurvedAnimation(parent: _hintAnim, curve: Curves.easeInOut));

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _configureTts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollCtrl.hasClients) return;
      final canScroll = _scrollCtrl.position.maxScrollExtent > 0;
      setState(() {
        _canScroll = canScroll;
        _atEnd =
            _scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 2;
      });
    });
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final atEnd =
        _scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 2;
    if (atEnd != _atEnd) setState(() => _atEnd = atEnd);
  }

  @override
  void dispose() {
    _hintAnim.dispose();
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    _stopSpeech(silent: true);
    super.dispose();
  }

  void _logTts(String message) {
    if (kDebugMode) {
      debugPrint('[TTS] $message');
    }
  }

  String? _lastTtsError;

  Future<void> _configureTts() async {
    if (_isConfiguringTts) return;
    _isConfiguringTts = true;
    try {
      final locale = await _resolveAvailableLocale();
      await _tts.setLanguage(locale);
      await _tts.setSpeechRate(_speechRate());
      await _tts.setPitch(1.0);
      await _tts.setVolume(_kMaxSpeechVolume);
      try {
        await _tts.awaitSpeakCompletion(true);
      } catch (e) {
        _logTts('awaitSpeakCompletion no soportado: $e');
      }
      if (mounted) setState(() => _ttsReady = true);
      _lastTtsError = null;
    } on PlatformException catch (e) {
      _logTts('Platform error: ${e.code} - ${e.message}');
      _lastTtsError = e.code == 'no_engine'
          ? 'No hay motor de voz instalado. Instala Speech Services by Google.'
          : e.message;
      if (mounted) setState(() => _ttsReady = false);
    } catch (e) {
      _logTts('Error: $e');
      _lastTtsError = e.toString();
      if (mounted) setState(() => _ttsReady = false);
    } finally {
      _isConfiguringTts = false;
    }
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });
    _tts.setCancelHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });
    _tts.setErrorHandler((msg) {
      _logTts('error handler: $msg');
      if (mounted) setState(() => _isSpeaking = false);
    });
  }

  Future<void> _handleSpeechTap(String text) async {
    if (!_ttsReady) {
      await _configureTts();
      if (!_ttsReady) {
        if (!mounted) return;
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text(
              _lastTtsError?.isNotEmpty == true
                  ? 'No se pudo activar la lectura: $_lastTtsError'
                  : 'No se pudo activar la lectura en voz alta.',
            ),
          ),
        );
        return;
      }
    }
    await _toggleSpeech(text);
  }

  Future<void> _toggleSpeech(String text) async {
    if (!_ttsReady) return;
    if (_isSpeaking) {
      await _stopSpeech();
      return;
    }
    if (text.trim().isEmpty) return;
    setState(() => _isSpeaking = true);
    await _tts.stop();
    await _tts.setVolume(_kMaxSpeechVolume); // máximo permitido por el motor
    await _tts.speak(text);
  }

  Future<void> _closeDialog() async {
    await _stopSpeech(silent: true);
    if (mounted) Navigator.of(context).maybePop();
  }

  Future<void> _stopSpeech({bool silent = false}) async {
    await _tts.stop();
    if (mounted && !silent) {
      setState(() => _isSpeaking = false);
    } else if (silent) {
      _isSpeaking = false;
    }
  }

  String _ttsLocale(String lang) {
    switch (lang) {
      case 'en':
        return 'en-US';
      case 'pt':
        return 'pt-BR';
      case 'it':
        return 'it-IT';
      case 'es':
      default:
        return 'es-ES';
    }
  }

  double _speechRate() {
    switch (widget.lang) {
      case 'en':
        return 0.58;
      default:
        return 0.72;
    }
  }

  Future<String> _resolveAvailableLocale() async {
    final desired = _ttsLocale(widget.lang);
    try {
      final isDesiredAvailable =
          await _tts.isLanguageAvailable(desired) ?? false;
      if (isDesiredAvailable) return desired;
    } catch (e) {
      _logTts('isLanguageAvailable failed: $e');
    }
    const fallbacks = ['es-ES', 'en-US', 'pt-BR', 'it-IT'];
    for (final code in fallbacks) {
      try {
        final ok = await _tts.isLanguageAvailable(code) ?? false;
        if (ok) return code;
      } catch (_) {}
    }
    return 'en-US';
  }

  String _verseLabel(String lang) {
    switch (lang) {
      case 'en':
        return 'Verse';
      case 'pt':
        return 'Versiculo';
      case 'it':
        return 'Versetto';
      case 'es':
      default:
        return 'Versiculo';
    }
  }

  String _reflectionLabel(String lang) {
    switch (lang) {
      case 'en':
        return 'Reflection';
      case 'pt':
        return 'Reflexao';
      case 'it':
        return 'Riflessione';
      case 'es':
      default:
        return 'Reflexion';
    }
  }

  String _buildSpeechText({
    required String header,
    required String verse,
    required String description,
    required String prayer,
    required String reflection,
    required String farewell,
    required String verseLabel,
    required String prayerLabel,
    required String reflectionLabel,
  }) {
    final parts = <String>[];
    if (header.isNotEmpty) parts.add(header);
    if (verse.isNotEmpty && verse != header) {
      parts.add('$verseLabel: $verse');
    }
    if (description.isNotEmpty) parts.add(description);
    if (prayer.isNotEmpty) parts.add('$prayerLabel: $prayer');
    if (reflection.isNotEmpty) parts.add('$reflectionLabel: $reflection');
    if (farewell.isNotEmpty) parts.add(farewell);
    return parts.join('. ');
  }

  String _formatDate(String raw) {
    try {
      final dt = DateFormat('yyyy-MM-dd').parseStrict(raw);
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(stringsProvider);

    final item = widget.item;
    final tr = pickDailyFoodTranslation(
      Map<String, dynamic>.from(item.translations),
      primary: widget.lang,
    );
    final verse = normalizeDisplayText((tr['verse'] ?? '').toString().trim());
    final title = normalizeDisplayText((tr['title'] ?? '').toString().trim());
    final headerText = verse.isNotEmpty ? verse : title;
    final descriptionRaw = (tr['description'] ?? '').toString().trim();
    final description = normalizeDisplayText(descriptionRaw);
    final prayerText = normalizeDisplayText((tr['prayer'] ?? '').toString().trim());
    final prayerDisplay = prayerText.isNotEmpty ? 'Ora así: $prayerText' : '';
    final reflection = normalizeDisplayText(
      (tr['reflection'] ?? '').toString().trim(),
    );
    final farewell = langFarewell(widget.lang);
    final speechText = _buildSpeechText(
      header: headerText,
      verse: verse,
      description: description,
      prayer: prayerDisplay,
      reflection: reflection,
      farewell: farewell,
      verseLabel: _verseLabel(widget.lang),
      prayerLabel: t.prayerTitle,
      reflectionLabel: _reflectionLabel(widget.lang),
    );

    const sectionSpacing = 12.0;
    final descriptionParagraphs = descriptionRaw
        .split(RegExp(r'\n\s*\n'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    final sectionWidgets = <Widget>[];
    void addSection(Widget widget) {
      sectionWidgets.add(widget);
    }
    if (title.isNotEmpty && title != verse) {
      addSection(
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      );
    }
    for (final paragraph in descriptionParagraphs) {
      addSection(
        Text(
          paragraph,
          textAlign: TextAlign.left,
          style: const TextStyle(
            fontSize: 15,
            height: 1.35,
          ),
        ),
      );
    }
    if (reflection.isNotEmpty) {
      addSection(
        Text(
          reflection,
          textAlign: TextAlign.left,
          style: const TextStyle(
            fontSize: 15,
            height: 1.35,
          ),
        ),
      );
    }
    if (prayerDisplay.isNotEmpty) {
      addSection(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.prayerTitle,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              prayerDisplay,
              textAlign: TextAlign.left,
              style: const TextStyle(
                fontSize: 15,
                height: 1.35,
              ),
            ),
          ],
        ),
      );
    }
    if (farewell.isNotEmpty) {
      addSection(
        Text(
          '$farewell.',
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.primary,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    final spacedSections = <Widget>[];
    for (var i = 0; i < sectionWidgets.length; i++) {
      final isFirst = i == 0;
      final isLast = i == sectionWidgets.length - 1;
      spacedSections.add(
        Container(
          width: double.infinity,
          margin: EdgeInsets.only(
            top: isFirst ? sectionSpacing : 0,
            bottom: isLast ? 0 : sectionSpacing,
          ),
          child: sectionWidgets[i],
        ),
      );
    }

    final meta = (item.date.isNotEmpty) ? _formatDate(item.date) : '';

    final mq = MediaQuery.of(context);
    final maxWidth = mq.size.width.clamp(320.0, 560.0);
    final maxHeight = mq.size.height * 0.82;
    final contentScrollMaxHeight = (maxHeight - 140).clamp(140.0, 800.0);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) async {
        await _stopSpeech(silent: true);
      },
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        headerText.isEmpty ? '---' : headerText,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FavoriteHeart(foodId: item.id, iconSize: 24),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: Icon(
                        _isSpeaking ? Icons.stop_circle : Icons.volume_up,
                      ),
                      tooltip: _isSpeaking
                          ? 'Detener lectura'
                          : 'Escuchar contenido',
                      onPressed: () => _handleSpeechTap(speechText),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.ios_share),
                      tooltip: 'Compartir',
                      onPressed: () {
                        ShareHelper.openShareSheet(
                          context: context,
                          langCode: widget.lang,
                          item: item,
                          prayerLabel: t.prayerTitle,
                        );
                      },
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: t.close,
                      onPressed: _closeDialog,
                    ),
                  ],
                ),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      meta,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ],
                // Content with scroll
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: contentScrollMaxHeight,
                  ),
                  child: Stack(
                    children: [
                      Scrollbar(
                        controller: _scrollCtrl,
                        thumbVisibility: false,
                        child: SingleChildScrollView(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.only(right: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (spacedSections.isNotEmpty) ...spacedSections,
                            ],
                          ),
                        ),
                      ),

                      // Scroll hint
                      if (_canScroll && !_atEnd) ...[
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: IgnorePointer(
                            child: Container(
                              height: 36,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    (Theme.of(
                                              context,
                                            ).dialogTheme.backgroundColor ??
                                            Colors.white)
                                        .withValues(alpha: 0.0),
                                    (Theme.of(
                                              context,
                                            ).dialogTheme.backgroundColor ??
                                            Colors.white)
                                        .withValues(alpha: 0.9),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 6,
                          left: 0,
                          right: 0,
                          child: IgnorePointer(
                            child: AnimatedBuilder(
                              animation: _hintAnim,
                              builder: (context, _) {
                                return Transform.translate(
                                  offset: Offset(0, _hintOffset.value),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.keyboard_arrow_down,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        t.scrollHint,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
