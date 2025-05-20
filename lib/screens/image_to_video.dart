

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:movie_aidea/util/thought_bubble_loader.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:image/image.dart' as img;

class VideoGenerationScreen extends StatefulWidget {
  final String imageUrl;
  final DocumentReference
      dataReference; // Accept the Firestore document reference

  VideoGenerationScreen({required this.imageUrl, required this.dataReference});

  @override
  _VideoGenerationScreenState createState() => _VideoGenerationScreenState();
}

class _VideoGenerationScreenState extends State<VideoGenerationScreen> {
  bool _isLoading = true;
  bool _isPolling = false;
  String? _videoUrl;
  VideoPlayerController? _videoController;
  int _pollingAttempts = 0;
  final int _maxPollingAttempts = 10;
  String? _generationId;
  final TextEditingController _generationIdController = TextEditingController();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  void initState() {
    super.initState();
    _generateVideoFromImage();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _generationIdController.dispose();
    super.dispose();
  }

  Future<File> _writeToFile(Uint8List data, String name) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$name');
    return file.writeAsBytes(data);
  }

  Future<void> _generateVideoFromImage() async {
    try {
      print('Starting image download...');
      Uint8List? imageData = await _downloadImage(widget.imageUrl);

      if (imageData != null) {
        print('Image downloaded successfully.');
        Uint8List resizedImageData = _resizeImage(imageData);

        final generationId =
            await createVideoFromImage(resizedImageData, context);
        if (generationId != null) {
          print('Generation ID received: $generationId');
          setState(() {
            _generationId = generationId;
            _generationIdController.text = generationId;
            _isPolling = false; // Change to false since polling is manual now
          });
        }
      }
    } catch (e) {
      showErrorDialogWithCopy(
          'Failed to generate video: ${e.toString()}', context);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Uint8List _resizeImage(Uint8List imageData) {
    img.Image? image = img.decodeImage(imageData);
    if (image != null) {
      img.Image resizedImage = img.copyResize(image, width: 1024, height: 576);
      return Uint8List.fromList(img.encodePng(resizedImage));
    }
    throw Exception('Failed to resize image');
  }

  Future<Uint8List?> _downloadImage(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        showErrorDialogWithCopy(
            'Failed to download image: ${response.reasonPhrase}', context);
        return null;
      }
    } catch (e) {
      showErrorDialogWithCopy(
          'Failed to download image: ${e.toString()}', context);
      return null;
    }
  }

  Future<String?> createVideoFromImage(
      Uint8List imageData, BuildContext context) async {
    const baseUrl = 'https://api.stability.ai/v2beta/image-to-video';
    final url = Uri.parse(baseUrl);

    final tempDir = await getTemporaryDirectory();
    final localImagePath = '${tempDir.path}/temp_image.png';
    final imageFile = File(localImagePath);
    await imageFile.writeAsBytes(imageData);

    final request = http.MultipartRequest('POST', url)
      ..headers['authorization'] =
          'Place API for Stability Here'
      ..files.add(await http.MultipartFile.fromPath('image', imageFile.path))
      ..fields['seed'] = '0'
      ..fields['cfg_scale'] = '1.8'
      ..fields['motion_bucket_id'] = '127';

    final streamedResponse = await request.send();

    final contentType = streamedResponse.headers['content-type'];
    final responseBody = await streamedResponse.stream.toBytes();

    if (contentType != null && !contentType.contains('application/json')) {
      showErrorDialogWithCopy(
          'Failed to generate video: ${utf8.decode(responseBody)}', context);
      return null;
    }

    if (streamedResponse.statusCode == 200) {
      try {
        final responseJson = jsonDecode(utf8.decode(responseBody));
        final generationId = responseJson['id'];
        print('Generation ID: $generationId');
        return generationId;
      } catch (e) {
        print('Failed to decode response: ${utf8.decode(responseBody)}');
        showErrorDialogWithCopy(
            'Failed to decode response: ${utf8.decode(responseBody)}', context);
        return null;
      }
    } else {
      print('Failed response: ${utf8.decode(responseBody)}');
      showErrorDialogWithCopy(
          'Failed to generate video: ${utf8.decode(responseBody)}', context);
      return null;
    }
  }

  Future<void> pollForResult() async {
    if (_pollingAttempts >= _maxPollingAttempts) {
      showErrorDialogWithCopy(
          'Polling limit reached. Please try again later.', context);
      return;
    }

    setState(() {
      _isPolling = true;
      _pollingAttempts++;
    });

    const baseUrl = 'https://api.stability.ai/v2beta/image-to-video/result/';
    final url = Uri.parse('$baseUrl${_generationIdController.text}');

    final response = await http.get(url, headers: {
      'authorization': 'Place API for Stability Here',
      'accept': 'application/json',
    });

    final responseBody = response.bodyBytes;
    print('Polling response: ${utf8.decode(responseBody)}');

    if (response.statusCode == 200) {
      try {
        final responseJson = jsonDecode(utf8.decode(responseBody));
        if (responseJson.containsKey('video')) {
          final base64Video = responseJson['video'];
          print('Base64 video received');
          final videoFile = await _writeToFile(
              base64Decode(base64Video), 'generated_video.mp4');
          final videoUrl = await _uploadVideoToFirebase(videoFile);
          await _saveVideoUrlToFirestore(videoUrl);
          _initializeVideoPlayer(videoFile.path);
        } else {
          final status = responseJson['status'];
          final finishReason = responseJson['finish_reason'];
          final seed = responseJson['seed'];
          print('Status: $status');
          print('Finish reason: $finishReason');
          print('Seed: $seed');
          setState(() {
            _isPolling = false;
          });
        }
      } catch (e) {
        print('Failed to decode response: ${utf8.decode(responseBody)}');
        showErrorDialogWithCopy(
            'Failed to decode response: ${utf8.decode(responseBody)}', context);
        setState(() {
          _isPolling = false;
        });
      }
    } else {
      print('Failed response: ${utf8.decode(responseBody)}');
      showErrorDialogWithCopy(
          'Failed to get video result: ${utf8.decode(responseBody)}', context);
      setState(() {
        _isPolling = false;
      });
    }
  }

  Future<String> _uploadVideoToFirebase(File videoFile) async {
    final storageRef =
        _storage.ref().child('videos/${videoFile.path.split('/').last}');
    await storageRef.putFile(videoFile);
    return await storageRef.getDownloadURL();
  }

  Future<void> _saveVideoUrlToFirestore(String videoUrl) async {
    await widget.dataReference
        .set({'videoUrl': videoUrl}, SetOptions(merge: true));
  }

  void _initializeVideoPlayer(String videoPath) {
    print('Initializing video player with path: $videoPath');
    if (videoPath.isNotEmpty) {
      _videoController = VideoPlayerController.file(File(videoPath))
        ..initialize().then((_) {
          print('Video player initialized successfully.');
          setState(() {});
          _videoController!.setLooping(true);
        }).catchError((error) {
          print('Failed to initialize video player: $error');
          showErrorDialogWithCopy(
              'Failed to initialize video player: $error', context);
        });
    } else {
      print('Video path is empty');
      showErrorDialogWithCopy(
          'Failed to load video: Video path is empty', context);
    }
  }

  void showErrorDialogWithCopy(String message, BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(message),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: message));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Error message copied to clipboard')),
                    );
                  },
                  child: Text('Copy to Clipboard'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Video Generation'),
      ),
      body: Center(
        child: _isLoading
            ? const ThoughtBubbleLoader()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _videoController != null &&
                          _videoController!.value.isInitialized
                      ? Column(
                          children: [
                            AspectRatio(
                              aspectRatio: _videoController!.value.aspectRatio,
                              child: VideoPlayer(_videoController!),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    _videoController!.value.isPlaying
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _videoController!.value.isPlaying
                                          ? _videoController!.pause()
                                          : _videoController!.play();
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        )
                      : _isPolling
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 20),
                                Text('Polling for video, please wait...')
                              ],
                            )
                          : const Text(
                              'Failed to load video or video generation is in progress'),
                  if (_generationId != null || !_isPolling)
                    Column(
                      children: [
                        TextField(
                          controller: _generationIdController,
                          decoration: InputDecoration(
                            labelText: 'Enter Generation ID',
                          ),
                        ),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: pollForResult,
                          child: Text('Check Video Status'),
                        ),
                      ],
                    ),
                ],
              ),
      ),
    );
  }
}
