import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/reader_providers.dart';
import '../../data/repositories/reader_repository.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  final String novelId;
  final String chapterId;

  const ReaderScreen({super.key, required this.novelId, required this.chapterId});

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  // Theme state
  Color _backgroundColor = const Color(0xFFF4ECD8); // Sepia default
  Color _textColor = const Color(0xFF433422);
  double _fontSize = 18.0;
  String _fontFamily = 'Georgia';

  bool _isMenuVisible = true;
  double _progress = 0.0;

  void _toggleMenu() {
    setState(() {
      _isMenuVisible = !_isMenuVisible;
    });
  }

  void _changeTheme(String type) {
    setState(() {
      if (type == 'light') {
        _backgroundColor = Colors.white;
        _textColor = Colors.black87;
      } else if (type == 'dark') {
        _backgroundColor = const Color(0xFF121212);
        _textColor = Colors.white70;
      } else {
        _backgroundColor = const Color(0xFFF4ECD8);
        _textColor = const Color(0xFF433422);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    // Periodically update progress or on dispose
  }

  @override
  void dispose() {
    // Final progress sync
    _syncProgress();
    super.dispose();
  }

  Future<void> _syncProgress() async {
    await ref.read(readerRepositoryProvider).updateProgress(widget.novelId, widget.chapterId, _progress);
  }

  @override
  Widget build(BuildContext context) {
    final chapterAsync = ref.watch(chapterContentProvider(ChapterParams(widget.novelId, widget.chapterId)));

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: chapterAsync.when(
        data: (chapter) {
          if (chapter == null) return const Center(child: Text('Chapter content unavailable'));
          
          return NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollUpdateNotification) {
                final metrics = notification.metrics;
                final newProgress = (metrics.pixels / metrics.maxScrollExtent);
                if ((newProgress - _progress).abs() > 0.05) {
                  setState(() {
                    _progress = newProgress;
                  });
                   _syncProgress();
                }
              }
              return true;
            },
            child: Stack(
              children: [
                // Content Area
                GestureDetector(
                  onTap: _toggleMenu,
                  child: SafeArea(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            chapter.title,
                            style: TextStyle(
                              fontSize: _fontSize + 6,
                              fontWeight: FontWeight.bold,
                              fontFamily: _fontFamily,
                              color: _textColor,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            chapter.content,
                            style: TextStyle(
                              fontSize: _fontSize,
                              fontFamily: _fontFamily,
                              color: _textColor,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 64),
                          
                          // Previous / Next Chapter Controls
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton.icon(
                                onPressed: () {},
                                icon: Icon(Icons.arrow_back, color: _textColor),
                                label: Text('Prev', style: TextStyle(color: _textColor)),
                              ),
                              TextButton.icon(
                                onPressed: () {},
                                icon: Icon(Icons.arrow_forward, color: _textColor),
                                label: Text('Next', style: TextStyle(color: _textColor)),
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Top & Bottom Bars Overlay
                if (_isMenuVisible) ...[
                  // Top App Bar
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      color: Colors.black87,
                      child: SafeArea(
                        bottom: false,
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () {
                                _syncProgress();
                                Navigator.of(context).pop();
                              },
                            ),
                            const Expanded(
                              child: Text(
                                'Reading Mode',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.bookmark_border, color: Colors.white),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Bottom Settings Bar
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      color: Colors.black87,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.text_decrease, color: Colors.white),
                                onPressed: () => setState(() {
                                  if (_fontSize > 12) _fontSize -= 2;
                                }),
                              ),
                              Text('${_fontSize.toInt()}', style: const TextStyle(color: Colors.white)),
                              IconButton(
                                icon: const Icon(Icons.text_increase, color: Colors.white),
                                onPressed: () => setState(() {
                                  if (_fontSize < 32) _fontSize += 2;
                                }),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildThemeButton('Light', Colors.white, Colors.black, 'light'),
                              _buildThemeButton('Sepia', const Color(0xFFF4ECD8), const Color(0xFF433422), 'sepia'),
                              _buildThemeButton('Dark', const Color(0xFF121212), Colors.white, 'dark'),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Text('${(_progress * 100).toInt()}%', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                              Expanded(
                                child: Slider(
                                  value: _progress.clamp(0.0, 1.0),
                                  onChanged: (val) {
                                    setState(() {
                                      _progress = val;
                                    });
                                  },
                                  activeColor: Colors.amber,
                                  inactiveColor: Colors.white24,
                                ),
                              ),
                              const Text('100%', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ]
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }


  Widget _buildThemeButton(String label, Color bg, Color fn, String type) {
    return GestureDetector(
      onTap: () => _changeTheme(type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey),
        ),
        child: Text(label, style: TextStyle(color: fn, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

