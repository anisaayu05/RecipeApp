import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:iconsax/iconsax.dart';
import 'package:get/get.dart';
import 'package:recipe_app/app/modules/favorite/controllers/favorite_controller.dart';
import 'package:flutter_tts/flutter_tts.dart';

class StartCookingView extends StatefulWidget {
  final Map<String, dynamic> food;

  const StartCookingView({Key? key, required this.food}) : super(key: key);

  @override
  _StartCookingViewState createState() => _StartCookingViewState();
}

class _StartCookingViewState extends State<StartCookingView> {
  late YoutubePlayerController _youtubeController;
  late WebViewController _webViewController;
  final FavoriteController favoriteController = Get.find<FavoriteController>();
  final FlutterTts flutterTts = FlutterTts();
  bool _isReadingAll = false;
  int _currentStepIndex = 0;
  List<String> _instructionsSteps = [];

  @override
  void initState() {
    super.initState();

    // Extract video ID from YouTube URL
    final videoId =
        YoutubePlayer.convertUrlToId(widget.food['strYoutube'] ?? '');

    // Initialize YouTube player
    _youtubeController = YoutubePlayerController(
      initialVideoId: videoId ?? '',
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
      ),
    );

    // Initialize WebViewController for WebView
    _webViewController = WebViewController()
      ..loadRequest(
          Uri.parse(widget.food['strSource'] ?? 'https://www.example.com'));

    // Parse instructions into steps
    if (widget.food['strInstructions']?.contains('STEP') == true) {
      try {
        _instructionsSteps = (widget.food['strInstructions']
                .split(RegExp(r'\r\n\r\nSTEP \d+\r\n')) as List)
            .map((e) => e.toString().trim())
            .toList();
      } catch (e) {
        print("Error parsing instructions: $e");
        _instructionsSteps = [];
      }
    } else {
      _instructionsSteps = [widget.food['strInstructions'] ?? ''];
    }

    flutterTts.setCompletionHandler(() {
      // Callback when TTS finishes speaking
      if (_isReadingAll && _currentStepIndex < _instructionsSteps.length - 1) {
        _currentStepIndex++;
        _readCurrentStep();
      } else {
        setState(() {
          _isReadingAll = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _youtubeController.dispose();
    flutterTts.stop();
    super.dispose();
  }

  Future<void> _speak(String text) async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(text);
  }

  Future<void> _readCurrentStep() async {
    if (_currentStepIndex >= 0 &&
        _currentStepIndex < _instructionsSteps.length) {
      await _speak(_instructionsSteps[_currentStepIndex]);
    }
  }

  Future<void> _readAllSteps() async {
    setState(() {
      _isReadingAll = true;
      _currentStepIndex = 0;
    });
    await _readCurrentStep();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return DefaultTabController(
      length: 2, // Number of tabs
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: primaryColor),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            widget.food['strMeal'] ?? 'Meal',
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          actions: [
            Obx(() {
              final isFavorite =
                  favoriteController.isFavorite(widget.food['idMeal']);
              return IconButton(
                icon: Icon(isFavorite ? Iconsax.heart5 : Iconsax.heart,
                    color: primaryColor),
                onPressed: () {
                  favoriteController.toggleFavorite(widget.food);
                },
              );
            }),
          ],
        ),
        body: Column(
          children: [
            TabBar(
              labelColor: primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: primaryColor,
              tabs: const [
                Tab(text: 'Instructions'),
                Tab(text: 'Article'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  Column(
                    children: [
                      // YouTube player
                      YoutubePlayer(
                        controller: _youtubeController,
                        showVideoProgressIndicator: true,
                      ),
                      // Instructions with TTS functionality
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _buildInstructionCards(
                                widget.food['strInstructions'], primaryColor),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                if (_currentStepIndex > 0) {
                                  setState(() {
                                    _currentStepIndex--;
                                  });
                                  _readCurrentStep();
                                }
                              },
                              child: const Text("Previous"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => _readAllSteps(),
                              child: Text(_isReadingAll ? "Stop" : "Read All"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                if (_currentStepIndex <
                                    _instructionsSteps.length - 1) {
                                  setState(() {
                                    _currentStepIndex++;
                                  });
                                  _readCurrentStep();
                                }
                              },
                              child: const Text("Next"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Article WebView
                  WebViewWidget(
                    controller: _webViewController,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildInstructionCards(String instructions, Color primaryColor) {
    return _instructionsSteps
        .asMap()
        .entries
        .map((entry) => Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  margin:
                      const EdgeInsets.symmetric(vertical: 25, horizontal: 15),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    gradient: LinearGradient(
                      colors: [Colors.white, Colors.grey.shade100],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        blurRadius: 12,
                        spreadRadius: 5,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.value,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                            height: 1.6,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _speak(entry.value),
                          icon: const Icon(Icons.volume_up),
                          label: const Text('Listen'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ))
        .toList();
  }
}
