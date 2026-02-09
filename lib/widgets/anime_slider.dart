import 'dart:async';
import 'package:flutter/material.dart';

class AnimeSlider extends StatefulWidget {
  const AnimeSlider({super.key});

  @override
  State<AnimeSlider> createState() => _AnimeSliderState();
}

class _AnimeSliderState extends State<AnimeSlider> {
  late PageController _pageController;
  int _currentPage = 0;
  List<Map<String, dynamic>> _featuredAnime = [];
  Timer? _autoSlideTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.8);
    _loadAnimeData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoSlide();
    });
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _loadAnimeData() {
    _featuredAnime = [
      {
        'id': '1',
        'title': 'Attack on Titan',
        'synopsis':
            'In a world where humanity lives inside cities surrounded by enormous walls due to the Titans, gigantic humanoid creatures who devour humans seemingly without reason. The story follows Eren Yeager, who vows to exterminate the Titans after they destroy his hometown and kill his mother.',
        'imageAsset': 'assets/anime/attack_on_titan.jpg',
        'color': Colors.red,
      },
      {
        'id': '2',
        'title': 'Demon Slayer',
        'synopsis':
            'A family is attacked by demons and only two members survive - Tanjiro and his sister Nezuko, who is turning into a demon slowly. Tanjiro sets out to become a demon slayer to avenge his family and cure his sister.',
        'imageAsset': 'assets/anime/demon_slayer.jpg',
        'color': Colors.orange,
      },
      {
        'id': '3',
        'title': 'Jujutsu Kaisen',
        'synopsis':
            'A boy swallows a cursed talisman - the finger of a demon - and becomes cursed himself. He enters a shaman\'s school to be able to locate the demon\'s other body parts and thus exorcise himself.',
        'imageAsset': 'assets/anime/jujutsu_kaisen.webp',
        'color': Colors.purple,
      },
      {
        'id': '4',
        'title': 'My Hero Academia',
        'synopsis':
            'In a world where most people have superpowers, middle school student Izuku Midoriya has none. However, his dream to become a hero is realized when the greatest hero in the world bestows his powers upon him.',
        'imageAsset': 'assets/anime/my_hero_academia.webp',
        'color': Colors.green,
      },
      {
        'id': '5',
        'title': 'Death Note',
        'synopsis':
            'A high school student discovers a supernatural notebook that allows him to kill anyone whose name he writes in it. He begins a secret crusade to eliminate criminals, but soon a genius detective tracks him down.',
        'imageAsset': 'assets/anime/death_note.jpg',
        'color': Colors.blueGrey,
      },
    ];
  }

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();

    _autoSlideTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && _featuredAnime.isNotEmpty) {
        if (_pageController.hasClients) {
          try {
            final currentPage = _pageController.page?.round() ?? 0;
            final nextPage = (currentPage + 1) % _featuredAnime.length;

            _pageController.animateToPage(
              nextPage,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          } catch (e) {
            print('Error in auto-slide: $e');
            timer.cancel();
          }
        }
      } else if (!mounted) {
        timer.cancel();
      }
    });
  }

  void _nextPage() {
    if (_pageController.hasClients && _featuredAnime.isNotEmpty) {
      final currentPage = _pageController.page?.round() ?? 0;
      final nextPage = (currentPage + 1) % _featuredAnime.length;

      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_pageController.hasClients && _featuredAnime.isNotEmpty) {
      final currentPage = _pageController.page?.round() ?? 0;
      final prevPage =
          (currentPage - 1 + _featuredAnime.length) % _featuredAnime.length;

      _pageController.animateToPage(
        prevPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_featuredAnime.isEmpty) {
      return SizedBox(
        height: 200,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Featured Anime',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: _previousPage,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  IconButton(
                    onPressed: _nextPage,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        SizedBox(
          height: 300,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _featuredAnime.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return _AnimeCard(
                anime: _featuredAnime[index],
                isActive: index == _currentPage,
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // Page Indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _featuredAnime.length,
            (index) => GestureDetector(
              onTap: () {
                if (_pageController.hasClients) {
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
              child: Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPage == index
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey[300],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AnimeCard extends StatefulWidget {
  final Map<String, dynamic> anime;
  final bool isActive;

  const _AnimeCard({required this.anime, required this.isActive});

  @override
  State<_AnimeCard> createState() => __AnimeCardState();
}

class __AnimeCardState extends State<_AnimeCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: MouseRegion(
        onEnter: (_) {
          setState(() {
            _isHovered = true;
          });
        },
        onExit: (_) {
          setState(() {
            _isHovered = false;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Positioned.fill(
                  child: widget.anime.containsKey('imageAsset')
                      ? Image.asset(
                          widget.anime['imageAsset'] as String,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildFallbackImage();
                          },
                        )
                      : _buildFallbackImage(),
                ),

                if (_isHovered)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.85),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.anime['title'] as String,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 20),

                            Expanded(
                              child: SingleChildScrollView(
                                child: Text(
                                  widget.anime['synopsis'] as String,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                if (!_isHovered)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.9),
                          ],
                        ),
                      ),
                      child: Text(
                        widget.anime['title'] as String,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackImage() {
    final color = widget.anime['color'] as Color? ?? Colors.grey;

    return Container(
      color: color.withOpacity(0.1),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, color: color, size: 48),
            const SizedBox(height: 8),
            Text(
              widget.anime['title'] as String,
              textAlign: TextAlign.center,
              style: TextStyle(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
