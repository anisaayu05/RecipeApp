import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

// Model for video data
class VideoData {
  final String videoPath;
  final String videoUrl;
  final String thumbnailUrl;

  VideoData({
    required this.videoPath,
    required this.videoUrl,
    required this.thumbnailUrl,
  });
}

class ActivityView extends StatefulWidget {
  @override
  _ActivityViewState createState() => _ActivityViewState();
}

class _ActivityViewState extends State<ActivityView> {
  final ImagePicker _picker = ImagePicker();
  final List<VideoData> _videoList = [];
  bool _isUploading = false; // Indicates if a video is uploading

  @override
  void initState() {
    super.initState();
    _loadVideoDataFromLocal(); // Load video data from SharedPreferences on app startup
    _loadVideosFromFirebase();
  }

  // Function to pick a video and upload it to Firebase Storage
  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() {
        _isUploading = true; // Indicating upload is in progress
      });

      // Upload the video to Firebase
      String videoUrl = await _uploadVideoToFirebase(File(video.path));

      if (videoUrl.isNotEmpty) {
        // Prompt the user to select a thumbnail image
        XFile? image = await _picker.pickImage(source: ImageSource.gallery);
        String thumbnailUrl = '';
        if (image != null) {
          thumbnailUrl = await _uploadImageToFirebase(File(image.path));
        }

        setState(() {
          _isUploading = false; // Indicating upload is finished
        });

        setState(() {
          _videoList.add(VideoData(
            videoPath: video.path,
            videoUrl: videoUrl,
            thumbnailUrl: thumbnailUrl.isEmpty ? 'default_thumbnail.jpg' : thumbnailUrl,
          ));
        });

        // Save video data to SharedPreferences
        _saveVideoDataToLocal(_videoList);
      } else {
        print("No video URL obtained.");
      }
    }
  }

  // Function to upload the video to Firebase Storage
  Future<String> _uploadVideoToFirebase(File videoFile) async {
    try {
      String fileName = basename(videoFile.path);
      Reference storageRef = FirebaseStorage.instance.ref().child('gallery/videos/$fileName');
      await storageRef.putFile(videoFile);
      String videoUrl = await storageRef.getDownloadURL();
      return videoUrl;
    } catch (e) {
      print("Failed to upload video: $e");
      return "";
    }
  }

  // Function to upload the thumbnail image to Firebase Storage
  Future<String> _uploadImageToFirebase(File imageFile) async {
    try {
      String fileName = basename(imageFile.path);
      Reference storageRef = FirebaseStorage.instance.ref().child('gallery/thumbnails/$fileName');
      await storageRef.putFile(imageFile);
      String imageUrl = await storageRef.getDownloadURL();
      return imageUrl;
    } catch (e) {
      print("Failed to upload image: $e");
      return "";
    }
  }

  // Function to save video data to SharedPreferences
  Future<void> _saveVideoDataToLocal(List<VideoData> videoList) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> videoUrls = videoList.map((video) => video.videoUrl).toList();
    List<String> thumbnailUrls = videoList.map((video) => video.thumbnailUrl).toList();

    await prefs.setStringList('videoUrls', videoUrls);
    await prefs.setStringList('thumbnailUrls', thumbnailUrls);
  }

  // Function to load video data from SharedPreferences
  Future<void> _loadVideoDataFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? videoUrls = prefs.getStringList('videoUrls');
    List<String>? thumbnailUrls = prefs.getStringList('thumbnailUrls');

    if (videoUrls != null && thumbnailUrls != null) {
      setState(() {
        _videoList.clear();
        for (int i = 0; i < videoUrls.length; i++) {
          _videoList.add(VideoData(
            videoPath: '', // If you want to save the path, you can also add it here
            videoUrl: videoUrls[i],
            thumbnailUrl: thumbnailUrls[i],
          ));
        }
      });
    }
  }

  // Function to load videos and thumbnails from Firebase Storage
  Future<void> _loadVideosFromFirebase() async {
  try {
    // List all video files from the 'gallery/videos' folder
    ListResult videoResult = await FirebaseStorage.instance.ref('gallery/videos').listAll();
    for (var videoItem in videoResult.items) {
      String videoUrl = await videoItem.getDownloadURL();

      // Assume thumbnail has the same name but stored in 'gallery/thumbnails'
      String thumbnailName = basename(videoItem.fullPath);
      String thumbnailPath = 'gallery/thumbnails/$thumbnailName';
      String thumbnailUrl = await FirebaseStorage.instance.ref(thumbnailPath).getDownloadURL().catchError((e) {
        print("Thumbnail not found for $thumbnailName: $e");
        return 'default_thumbnail.jpg'; // Fallback to default thumbnail
      });

      // Check if this video is already in the list
      if (!_videoList.any((video) => video.videoUrl == videoUrl)) {
        setState(() {
          _videoList.add(VideoData(
            videoPath: '', // No local path needed
            videoUrl: videoUrl,
            thumbnailUrl: thumbnailUrl,
          ));
        });
      }
    }
  } catch (e) {
    print("Error loading videos: $e");
  }
}


  // Function to navigate to full-screen video page
  void _navigateToFullScreen(BuildContext context, String videoUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenVideoPage(videoUrl: videoUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _isUploading ? null : _pickVideo, // Disable button when uploading
            child: _isUploading
                ? CircularProgressIndicator() // Show loading during upload
                : Text('Upload Video'),
          ),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Display 2 columns
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _videoList.length,
              itemBuilder: (context, index) {
                VideoData videoData = _videoList[index];
                return GestureDetector(
                  onTap: () => _navigateToFullScreen(context, videoData.videoUrl),
                  child: Card(
                    margin: EdgeInsets.all(8),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          height: 120,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: NetworkImage(videoData.thumbnailUrl), // Using the thumbnail
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ),
                        Text("Video ${index + 1}", style: TextStyle(color: Colors.black)),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            setState(() {
                              _videoList.removeAt(index);
                            });
                            _saveVideoDataToLocal(_videoList);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class FullScreenVideoPage extends StatefulWidget {
  final String videoUrl;

  FullScreenVideoPage({required this.videoUrl});

  @override
  _FullScreenVideoPageState createState() => _FullScreenVideoPageState();
}

class _FullScreenVideoPageState extends State<FullScreenVideoPage> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {
          _controller.play();
          _isPlaying = true;
        });
      }).catchError((error) {
        print("Failed to load video: $error");
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Full Screen Video')),
      body: Center(
        child: _controller.value.isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : CircularProgressIndicator(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            if (_isPlaying) {
              _controller.pause();
            } else {
              _controller.play();
            }
            _isPlaying = !_isPlaying;
          });
        },
        child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
