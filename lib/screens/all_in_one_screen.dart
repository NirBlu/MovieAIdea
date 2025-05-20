

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:movie_aidea/screens/user_dashboard.dart';

import 'package:movie_aidea/util/expendable_button.dart';
import 'package:movie_aidea/util/expendable_scene_button.dart';
import 'package:movie_aidea/util/expendable_short_bttn.dart';

import 'package:movie_aidea/util/extract.dart';

import 'package:movie_aidea/util/parse_character.dart';
import 'package:movie_aidea/util/app_const.dart';
import 'package:movie_aidea/util/parse_scenes.dart';
import 'package:movie_aidea/util/print_pdf.dart';
import 'package:movie_aidea/util/subtle_texture.dart';
import 'package:movie_aidea/util/thought_bubble_loader.dart';
import 'package:movie_aidea/widget/add_scene.dart';

import 'package:movie_aidea/widget/script_text_form_field.dart';
import 'package:flutter/services.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:movie_aidea/util/character_expandable_button.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:movie_aidea/util/styles.dart';
import 'package:movie_aidea/util/names_not_to_use.dart';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
//import 'package:firebase_core/firebase_core.dart';

//import 'package:firebase_auth/firebase_auth.dart';

enum Phase {
  synopsis,
  storyarc,
  characters,
  logline,
  firstscenes,
  initscenes,
  risescenes,
  climaxscenes,
  fallscenes,
  resolution,
  ending,
  expandscenes,
}

class AllInOneScreen extends StatefulWidget {
  //String? uniqueKey;
  final User userCredentials;
  final String id;
  const AllInOneScreen(
      {super.key, required this.userCredentials, required this.id});

  @override
  State<AllInOneScreen> createState() => _AllInOneScreenState();
}

enum TtsState { playing, stopped, paused, continued }

class _AllInOneScreenState extends State<AllInOneScreen> {
  /////TTS
  late FlutterTts flutterTts;
  String? language;
  String? engine;
  double volume = 1.0;
  double pitch = 1.0;
  double rate = 0.5;
  bool isCurrentLanguageInstalled = false;

  // String? _newVoiceText;
  //int? _inputLength;

  TtsState ttsState = TtsState.stopped;

  bool get isPlaying => ttsState == TtsState.playing;
  bool get isStopped => ttsState == TtsState.stopped;
  bool get isPaused => ttsState == TtsState.paused;
  bool get isContinued => ttsState == TtsState.continued;

  bool get isIOS => !kIsWeb && Platform.isIOS;
  bool get isAndroid => !kIsWeb && Platform.isAndroid;
  bool get isWindows => !kIsWeb && Platform.isWindows;
  bool get isWeb => kIsWeb;
  bool isReading = false;

  /////
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  //String uniqueKey = 'abc';
  //final database = FirebaseDatabase.instance;
  var dataRef;
  var synopsisRef;
  var arcRef;
  var beginingRef;
  var initial_incidentRef;
  var rising_actionRef;
  var climaxRef;
  var falling_actionRef;
  var resolusionRef;
  var endingRef;
  //late final ScrollController _scrollController;
  late final GenerativeModel _model;
  late ChatSession _chatSession;
  late final TextEditingController _textEditingController;
  late FocusNode _focusNode;
  late bool _isLoading;
  String movieKey = '';
  Stage stage = Stage.start;
  String about = '';
  String title = '';
  String synopsis = '';
  //String _lastestSynopsis = '';
  String text = '';
  String arc = '';
  String begining = '';
  String initial_incident = '';
  String rising_action = '';
  String climax = '';
  String falling_action = '';
  String resolusion = '';
  String ending = '';
  List<String> story_arc = [];
  List<String> arc_categories = [
    'beginning',
    'initial incident',
    'rising action',
    'climax',
    'falling action',
    'resolusion',
    'ending'
  ];
  List<SceneParsing> scenes = [];
  var characterRef;
  var loglineRef;
  bool isCharactersExtracted = false;
  bool isLoglineExtracted = false;
  String logLine = '';
  List<Character> characters = [];
  bool isCharacterGenerationFailed = false;
  Map<String, dynamic> allScenesData = {};
  Map<String, dynamic> characterData = {};
  Map<String, dynamic> treatmentData = {};
  //List<String> story_arc = [];
  Map<String, String> story_arc_map = {};
  bool editText = false;
  bool isStoryArcGenerated = false;
  Phase currentPhase = Phase.synopsis;
  String currentPhotoDescription = '';
  int numberOfScenes = 0;
  String writtenMessage = '';
  String currentId = '';
  double _progress = 0.0;
  Color progressColorTop = Color.fromARGB(255, 114, 240, 249);

  ////Initialize TTS
  dynamic initTTs() {
    flutterTts = FlutterTts();
    _setAwaitOptions();
    //flutterTts.stop();

    if (isAndroid) {
      _getDefaultEngine();
      _getDefaultVoice();
    }

    flutterTts.setStartHandler(() {
      setState(() {
        //print("Playing");
        ttsState = TtsState.playing;
      });
    });

    flutterTts.setCompletionHandler(() {
      setState(() {
        // print("Complete");
        ttsState = TtsState.stopped;
      });
    });

    flutterTts.setCancelHandler(() {
      setState(() {
        ////print("Cancel");
        ttsState = TtsState.stopped;
      });
    });

    flutterTts.setPauseHandler(() {
      setState(() {
        // //print("Paused");
        ttsState = TtsState.paused;
      });
    });

    flutterTts.setContinueHandler(() {
      setState(() {
        //print("Continued");
        ttsState = TtsState.continued;
      });
    });

    flutterTts.setErrorHandler((msg) {
      setState(() {
        //print("error: $msg");
        ttsState = TtsState.stopped;
      });
    });
  }

  Future<dynamic> _getLanguages() async => await flutterTts.getLanguages;

  Future<dynamic> _getEngines() async => await flutterTts.getEngines;

  Future<void> _getDefaultEngine() async {
    var engine = await flutterTts.getDefaultEngine;
    if (engine != null) {
      //print(engine);
    }
  }

  Future<void> _getDefaultVoice() async {
    var voice = await flutterTts.getDefaultVoice;
    if (voice != null) {
      //print(voice);
    }
  }

  Future _stop() async {
    await flutterTts.stop();
  }

  Future<void> _speak(String text) async {
    await flutterTts.setVolume(volume);
    await flutterTts.setSpeechRate(rate);
    await flutterTts.setPitch(pitch);

    if (text.isNotEmpty) {
      await flutterTts.speak(text);
    }
  }

  Future<void> _setAwaitOptions() async {
    await flutterTts.awaitSpeakCompletion(true);
  }

  Future<void> _pause() async {
    var result = await flutterTts.pause();
    if (result == 1) setState(() => ttsState = TtsState.paused);
  }

  @override
  void initState() {
    initTTs();
    _pause();

    _isLoading = false;
    _textEditingController = TextEditingController();
    _focusNode = FocusNode();
    //Set Model
    _model = GenerativeModel(model: geminiModel, apiKey: apiKey);
    //stage = Stage.start;
    //Start The Chat
    _chatSession = _model.startChat();
    //_initializeAndSignIn();
    story_arc_map = {};

    if (widget.id == '') {
      return;
    } else {
      currentId = widget.id;
      fetchScript(currentId);
    }

    // _scrollController = ScrollController();

    super.initState();
  }

  Future<void> saveToFile(String textToSave) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/my_text_file.txt');

      // Write the file
      await file.writeAsString(textToSave);

      // Show a confirmation dialog
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('File Saved'),
          content: const Text('Text has been saved to file.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      //print('Error saving file: $e');
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Error'),
          content: const Text('Failed to save text to file.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> fetchScenes(String key) async {
    //print('Fetching Scenes...');
    try {
      final response = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userCredentials.uid)
          .collection('Scripts')
          .doc(key)
          .collection('Scenes')
          .doc('Scenes')
          .get();

      QuerySnapshot scenesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userCredentials.uid)
          .collection('Scripts')
          .doc(key)
          .collection('Scenes')
          .get();

      // Fetch image URLs
      Map<String, String> scenesImagesUrlsMap = {};
      for (var doc in scenesSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>?;
        // //print('Doc Data: ${doc.data()}');
        if (data != null && data.containsKey('imageUrl')) {
          scenesImagesUrlsMap[doc.id] = doc['imageUrl'];
          //print(scenesImagesUrlsMap);
        }
      }

      if (response.exists) {
        final data = response.data();
        // //print('Document data: $data');

        Map<String, dynamic>? scenesData = data;
        if (scenesData != null) {
          numberOfScenes = scenesData['Scenes'].length;

          //print('Number of Scenes Loaded: $numberOfScenes');

          List<SceneParsing> sortedScenes = scenesData['Scenes']
              .map((entry) => SceneParsing.fromMap({
                    "Number": entry['Number'].toString(),
                    "Text": entry['Text'],
                    "Prompt": entry['Prompt'],
                    "imageUrl": scenesImagesUrlsMap[entry['Number'].toString()]
                  }))
              .toList()
              .cast<SceneParsing>();
          //print(scenes);
          scenes = sortedScenes;
          numberOfScenes = numberOfScenes;
          allScenesData['Scenes'] = (scenesData['Scenes']);
        } else {
          //print('Scenes data is null or not a map.');
        }
      } else {
        //print('Document does not exist.');
      }
    } catch (e) {
      //print('Try didn\'t succeed: $e');
    }
  }

  Future<void> fetchLogline(String key) async {
    try {
      final response = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userCredentials.uid)
          .collection('Scripts')
          .doc(key)
          .get();
      if (response.exists) {
        final data = response.data();
        title = data?['title'];

        String fetchLogLine = data?['logline']; // Access the LogLine field

        logLine = fetchLogLine;

        //print('LogLine: $logLine');
      } else {
        //print('Document does not exist.');
      }
    } catch (e) {}
  }

  Future<void> fetchCharacters(String key) async {
    try {
      final response = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userCredentials.uid)
          .collection('Scripts')
          .doc(key)
          .collection('Characters')
          .get();

      if (response.docs.isNotEmpty) {
        List<Character> characters = response.docs.map((doc) {
          Map<String, dynamic> data = doc.data();
          //print('this shold have looks bgstory etc $data');
          return Character(
              name: doc.id, // Assuming document ID is the character's name
              looks: data['Looks'] ?? '',
              bgStory: data['BGStory'] ?? '',
              motivation: data['Motivation'] ?? '',
              imageUrl: data['imageUrl'] ?? '');
          //return Character.fromMap(data);
        }).toList();

        this.characters = characters;

        //print('Characters fetched successfully: $characters');
      } else {
        //print('No characters found for key: $key');
      }
    } catch (e) {
      //print('Error fetching characters: $e');
    }
  }

  Future<void> fetchStoryArc(String key) async {
    try {
      // Fetch the documents from the StoryArc subcollection
      final response = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userCredentials.uid)
          .collection('Scripts')
          .doc(key)
          .collection('StoryArc')
          .get();

      // Check if the response contains any documents
      if (response.docs.isNotEmpty) {
        // Iterate over the documents in the response
        for (var doc in response.docs) {
          // Access the data of each document
          Map<String, dynamic> data = doc.data();
          ////print('Document ID: ${doc.id}');
          ////print('Document Data: $data');
          story_arc_map.clear();
          //story_arc_map['synopsis'] = synopsis;

          if (doc.id == 'Beginning') {
            begining = data['content'];

            //print(begining);
          }
          if (doc.id == 'Initial Incident') {
            initial_incident = data['content'];

            //print(initial_incident);
          }
          if (doc.id == 'Rising Action') {
            rising_action = data['content'];

            //print(rising_action);
          }
          if (doc.id == 'Climax') {
            climax = data['content'];

            //print(climax);
          }
          if (doc.id == 'Falling Action') {
            falling_action = data['content'];

            //print(falling_action);
          }
          if (doc.id == 'Resolution') {
            resolusion = data['content'];

            //print(resolusion);
          }
          if (doc.id == 'Ending') {
            ending = data['content'];

            //print(ending);
          }

          // Process the data as needed
          // For example, you can store it in variables, add it to a list, etc.
        }
        story_arc_map['beginning'] = begining;
        story_arc_map['initial_incident'] = initial_incident;
        story_arc_map['rising_action'] = rising_action;
        story_arc_map['climax'] = climax;
        story_arc_map['falling_action'] = falling_action;
        story_arc_map['resolution'] = resolusion;
        story_arc_map['ending'] = ending;
        //characters = await fetchCharacters(key);
        //fetchCharacters(key);
      } else {
        //print('No documents found in the StoryArc subcollection.');
      }
    } catch (error) {
      //print('Error fetching StoryArc: $error');
    }
    //fetchCharacters(key);
  }

  Future<void> fetchSynopsis(String key) async {
    try {
      final response = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userCredentials.uid)
          .collection('Scripts')
          .doc(key)
          .get();

      if (response.exists) {
        final data = response.data();
        synopsis = data!['synopsis'];
      }
    } catch (e) {
      //print(e);
    }
  }

  Future<void> fetchScript(String key) async {
    try {
      final response = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userCredentials.uid)
          .collection('Scripts')
          .doc(key)
          .get();

      if (response.exists) {
        final data = response.data();

        // //print('fetched data: $data');
        if (data != null) {
          await fetchSynopsis(key);
          await fetchStoryArc(key);
          await fetchCharacters(key);
          await fetchLogline(key);
          await fetchScenes(key);

          if (numberOfScenes >= 14) {
            setState(() {
              //print('State updated to expandscenes');
              currentPhase = Phase.expandscenes;
              _progress = 1;
            });
          } else if (numberOfScenes >= 12) {
            setState(() {
              //print('State updated to ending');
              currentPhase = Phase.ending;
              _progress = (1 - (1 / 12));
            });
          } else if (numberOfScenes >= 10) {
            setState(() {
              currentPhase = Phase.resolution;
              _progress = (1 - (2 / 12));
            });

            //print('State updated to resolution');
          } else if (numberOfScenes >= 8) {
            setState(() {
              currentPhase = Phase.fallscenes;
              _progress = (1 - (3 / 12));
            });

            //print('State updated to fallscenes');
          } else if (numberOfScenes >= 6) {
            setState(() {
              currentPhase = Phase.climaxscenes;
              _progress = (1 - (4 / 12));
            });

            //print('State updated to climaxscenes');
          } else if (numberOfScenes >= 4) {
            setState(() {
              //print('State updated to risescenes');
              currentPhase = Phase.risescenes;
              _progress = (1 - (5 / 12));
            });
          } else if (numberOfScenes >= 2) {
            setState(() {
              currentPhase = Phase.initscenes;
              _progress = (1 - (6 / 12));
            });

            //print('State updated to initscenes');
          } else if (logLine.isNotEmpty) {
            setState(() {
              currentPhase = Phase.firstscenes;
              _progress = (1 - (7 / 12));
            });
          } else if (characters.isNotEmpty) {
            setState(() {
              currentPhase = Phase.logline;
              _progress = (1 - (8 / 12));
            });
          } else if (story_arc_map.isNotEmpty) {
            setState(() {
              currentPhase = Phase.characters;
              _progress = (1 - (9 / 12));
            });
          } else if (synopsis.isNotEmpty) {
            setState(() {
              currentPhase = Phase.storyarc;
              _progress = (1 - (10 / 12));
            });
          } else {
            _progress = (1 - (11 / 12));
            synopsis = synopsis;
            title = title;
          }
          synopsis = synopsis;
          title = title;
        }
      }
    } catch (error) {
      //print('Error fetching script: $error');
    }
    synopsis = synopsis;
    title = title;
  }

  void _setLoading(bool isLoading) {
    setState(() {
      _isLoading = isLoading;
    });
  }

  @override
  void dispose() {
    // _scrollController.dispose();
    _textEditingController.dispose();
    _focusNode.dispose();
    super.dispose();

    //super.dispose();
    flutterTts.stop();
  }

  // bool _isStoryArcExpanded = false;
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: SubtleNoisePainter(Theme.of(context).brightness),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
            //toolbarHeight: 180,
            leading: Padding(
              padding: const EdgeInsets.all(1.0),
              child: Image.asset(
                'assets/images/MovieAIdea.png', // Replace with the path to your image
                // fit: BoxFit.fitHeight,
              ),
            ),
            actions: <Widget>[
              IconButton(
                  onPressed: () {
                    showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            shadowColor: Colors.red,
                            buttonPadding: const EdgeInsets.all(10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.0),
                              side: const BorderSide(
                                  color: Color.fromARGB(255, 189, 47, 37),
                                  width: 6.0),
                            ),
                            title: const Text(
                              'You are about to step back, this would delete the last step. It will delete all scenes if any were created.',
                              style: TextStyle(fontSize: 16),
                            ),
                            content: const Text('Do you want to continue?'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context)
                                      .pop(); // Dismiss the dialog
                                },
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  if (currentPhase == Phase.expandscenes ||
                                      currentPhase == Phase.ending ||
                                      currentPhase == Phase.resolution ||
                                      currentPhase == Phase.fallscenes ||
                                      currentPhase == Phase.climaxscenes ||
                                      currentPhase == Phase.risescenes ||
                                      currentPhase == Phase.initscenes) {
                                    setState(() {
                                      currentPhase = Phase.firstscenes;
                                      _progress = (1 - (7 / 12));
                                    });
                                  } else if (currentPhase ==
                                      Phase.firstscenes) {
                                    setState(() {
                                      currentPhase = Phase.logline;
                                      _progress = (1 - (8 / 12));
                                    });
                                  } else if (currentPhase == Phase.logline) {
                                    setState(() {
                                      currentPhase = Phase.characters;
                                      _progress = (1 - (9 / 12));
                                    });
                                  } else if (currentPhase == Phase.characters) {
                                    setState(() {
                                      currentPhase = Phase.storyarc;
                                      _progress = (1 - (10 / 12));
                                    });
                                  } else if (currentPhase == Phase.storyarc) {
                                    setState(() {
                                      currentPhase = Phase.synopsis;
                                      _progress = (1 - (11 / 12));
                                    });
                                  }
                                },
                                child: Text('Continue'),
                              ),
                            ],
                          );
                        });
                  },
                  icon: const Icon(Icons.arrow_upward_rounded)),
              IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          shadowColor: Colors.red,
                          buttonPadding: const EdgeInsets.all(10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.0),
                            side: const BorderSide(
                                color: Color.fromARGB(255, 189, 47, 37),
                                width: 6.0),
                          ),
                          title: const Text('Logging out'),
                          content: const Text('Do you want to continue?'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context)
                                    .pop(); // Dismiss the dialog
                              },
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                setState(() {
                                  FirebaseAuth.instance.signOut();
                                  Navigator.of(context).pop();
                                });
                              },
                              child: Text('Continue'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.logout_outlined)),
            ],
            title: title != ''
                ? FittedBox(child: Text(title))
                : const FittedBox(child: Text('Movie AIdea'))),
        body: CustomPaint(
            painter: SubtleNoisePainter(Theme.of(context).brightness),
            child: Scrollbar(thickness: 10, child: _buildContent())),
      ),
    );
  }

  String _getMessageFromContent(Content content) {
    return content.parts.whereType<TextPart>().map((e) => e.text).join('');
  }

  void refresh(value) {
    setState(() {
      synopsis = value;
    });
  }

  void _sendChatMessage(Phase phase, String message) async {
    if (currentPhase == Phase.synopsis) {
      final isValid = _formKey.currentState?.validate() ?? false;
      if (!isValid) {
        return;
      }
    }

    _setLoading(true);
    try {
      final response = await _chatSession.sendMessage(
        Content.text(message),
      );
      text = response.text ?? '';
      if (text.isEmpty) {
        _showError('No response');
        _setLoading(false);
      } else {
        switch (phase) {
          case Phase.synopsis:
            recieveSynopsis();
          //break;
          case Phase.storyarc:
            //print('storyARc');
            recieveStoryArcFunction();
          //break;
          case Phase.characters:
            //print('characters');
            receiveCharacters();
          // break;
          case Phase.logline:
            recieveLogLing();
          // break;
          case Phase.firstscenes:
            recieveFirstScene();

          case Phase.initscenes:
            recieveInitScenes();

          case Phase.risescenes:
            recieveRisingScenes();

          case Phase.climaxscenes:
            recieveClimax();

          case Phase.fallscenes:
            recieveFallScenes();

          case Phase.resolution:
            recieveResolution();
          case Phase.ending:
            recieveEnding();

          default:
          //break;
        }

        _setLoading(false);
      }
    } catch (e) {
      _showError(e.toString());

      _setLoading(false);
    } finally {
      //_scrollToBottom();

      _textEditingController.clear();
      _focusNode.requestFocus();
      _setLoading(false);
    }
  }

  Future<String> makeChanges(String text) async {
    _setLoading(true);
    try {
      final response = await _chatSession.sendMessage(
        Content.text(text),
      );
      text = response.text ?? '';
      if (text.isEmpty) {
        _showError('No response');
        _setLoading(false);
        return '';
      } else {
        _setLoading(false);
        ////print(text);
        return text;
      }
    } catch (e) {
      _setLoading(false);
      if (mounted) {
        showErrorPopup(context, e.toString());
      }
      return '';
    }
  }

  void showErrorPopup(BuildContext context, String errorMessage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(errorMessage),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the popup
                Navigator.of(context).pop(); // Go back to the previous screen
              },
            ),
          ],
        );
      },
    );
  }

  Future<String> makePhotoDescription(String text) async {
    _setLoading(true);
    try {
      final response = await _chatSession.sendMessage(
        Content.text(text),
      );
      text = response.text ?? '';
      if (text.isEmpty) {
        _showError('No response');
        _setLoading(false);
        return '';
      } else {
        _setLoading(false);
        //print(text);
        return text;
      }
    } catch (e) {
      return '';
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Error'),
          content: SingleChildScrollView(
            child: Text(message),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _textEditingController.text = '';

                  writtenMessage = '';
                });

                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => UserDashboard(
                            userCredentials: widget.userCredentials,
                          )),
                );
              },
              child: const Text('OK'),
            )
          ],
        );
      },
    );
  }

  // void _scrollToBottom() {
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     _scrollController.animateTo(
  //       _scrollController.position.maxScrollExtent,
  //       duration: const Duration(milliseconds: 300),
  //       curve: Curves.easeOut,
  //     );
  //   });
  // }

  Future<void> recieveSynopsis() async {
    synopsis = extractSynopsis(text);
    title = extractTitle(text);

    // Update the latest synopsis
    //_lastestSynopsis = text;
    //print(_lastestSynopsis);
    // Define the Firebase URL for updating

    //synopsisRef.set(synopsis);
    //titleRef.set(title);
    //print(text);

    ///final body = json.encode({uniqueKey: {}});
    var doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userCredentials.uid)
        .collection('Scripts')
        .add({'synopsis': synopsis, 'title': title});
    currentId = doc.id;
    dataRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userCredentials.uid)
        .collection('Scripts')
        .doc(doc.id);
    // Check if the update was successful

    setState(() {
      currentPhase = Phase.storyarc;
    });
  }

  String generateUniqueKey() {
    final random = Random();
    final key = List<int>.generate(10, (index) => random.nextInt(256));
    return base64Url.encode(key);
  }

  Future<void> recieveStoryArcFunction() async {
    //arcRef.set(text);
    List<String> sections = text.split('\n');
    for (String section in sections) {
      String trimmedSection = section.trim();
      if (trimmedSection.isEmpty) {
        continue;
      }
      //print('Section: $section');
      story_arc.add(section);
    }
    //story_arc_map['Synopsis'] = synopsis;
    String beginingCheck1 =
        extractBeginning(text).replaceAll("```json", '').trim();
    String beginingCheck2 = beginingCheck1.replaceAll("```", "");
    if (beginingCheck2.isEmpty) {
      //print('Failed to extract beginning');
      return;
    } else {
      dataRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userCredentials.uid)
          .collection('Scripts')
          .doc(currentId)
          .collection('StoryArc');
      await dataRef.doc('Beginning').set({'content': extractBeginning(text)});
      begining = extractBeginning(text);
      story_arc_map['Beginning'] = extractBeginning(text);
      initial_incident = extractInitialIncident(text);
      story_arc_map['Initial Incident'] = extractInitialIncident(text);
      await dataRef
          .doc('Initial Incident')
          .set({'content': extractInitialIncident(text)});
      await dataRef
          .doc('Rising Action')
          .set({'content': extractRisingAction(text)});
      rising_action = extractRisingAction(text);

      story_arc_map['Rising Action'] = (extractRisingAction(text));
      await dataRef.doc('Climax').set({'content': extractClimax(text)});
      climax = extractClimax(text);
      story_arc_map['Climax'] = (extractClimax(text));
      await dataRef
          .doc('Falling Action')
          .set({'content': extractFallingAction(text)});
      story_arc_map['Falling Action'] = (extractFallingAction(text));
      falling_action = extractFallingAction(text);
      await dataRef.doc('Resolution').set({'content': extractResolution(text)});
      story_arc_map['Resolution'] = (extractResolution(text));
      resolusion = extractResolution(text);
      await dataRef.doc('Ending').set({'content': extractEnding(text)});
      story_arc_map['Ending'] = (extractEnding(text));
      ending = extractEnding(text);

      //_lastestSynopsis = text;

      setState(() {
        currentPhase = Phase.characters;
        _progress = (1 - (9 / 12));
      });
    }
  }

  Future<void> receiveCharacters() async {
    String originalText = text.replaceAll("```JSON", '').trim();
    String moreText = originalText.replaceAll("json", '');
    String trimmedText = moreText.replaceAll("```", "");
    isCharactersExtracted = true;

    //print(trimmedText);

    Map<String, dynamic> characterData = json.decode(trimmedText);

    characters = (characterData["Characters"] as List).map((char) {
      var character = Character.fromMap(char);

      return character;
    }).toList();

    dataRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userCredentials.uid)
        .collection('Scripts')
        .doc(currentId)
        .collection('Characters');
    //print(characters);

    for (var character in characters) {
      await dataRef.doc(character.name).set({
        'BGStory': character.bgStory,
        'Looks': character.looks,
        'Motivation': character.motivation,
        'imageUrl': ''
      });
    }

    isCharacterGenerationFailed = false;

    setState(() {
      currentPhase = Phase.logline;
      _progress = (1 - (8 / 12));
    });
  }

  Future<void> recieveLogLing() async {
    String originalText = text.replaceAll("```json", '').trim();
    String almostTrimmedText = originalText.replaceAll("**", "");
    String trimmedText = almostTrimmedText.replaceAll("```", "");
    String trimmedText2 = trimmedText.replaceAll("Logline:", "");
    //isCharactersExtracted = true;
    //print(trimmedText2);
    logLine = trimmedText2;
    //loglineRef.set(trimmedText2);
    dataRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userCredentials.uid)
        .collection('Scripts')
        .doc(currentId);
    dataRef.update({'logline': logLine});

    setState(() {
      currentPhase = Phase.firstscenes;
      _progress = (1 - (7 / 12));
    });
  }

  Future<void> recieveFirstScene() async {
    dataRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userCredentials.uid)
        .collection('Scripts')
        .doc(currentId)
        .collection('Scenes');

    String trimmedText = text
        .replaceAll('</center>', '')
        .replaceAll('<center>', '')
        .replaceAll("json", '')
        .replaceAll("```JSON", '')
        .replaceAll('**', '')
        .replaceAll('*', '')
        .replaceAll('\n', '')
        .replaceAll('/n', '')
        .replaceAll('```', '')
        .trim();
    allScenesData.clear();
    Map<String, dynamic> scenesData = json.decode(trimmedText);
    allScenesData['Scenes'] = (scenesData['Scenes']);
    final firstScenes = scenesData['Scenes']
        .map((entry) {
          var scene = SceneParsing.fromMap({
            "Number": entry['Number'],
            "Text": entry['Text'],
            "Prompt": entry['Prompt']
          });
          return scene;
        })
        .toList()
        .cast<SceneParsing>();

    scenes = firstScenes;

    //print('All scenes Data: $allScenesData');
    dataRef.doc('Scenes').set(allScenesData);
    //dataRef.collection('Scenes').doc('Scenes').set({'Scenes': scenesData});

    setState(() {
      currentPhase = Phase.initscenes;
      _progress = (1 - (6 / 12));
    });
  }

  Future<void> recieveInitScenes() async {
    //print(text);

    recieveScene(text);
    setState(() {
      currentPhase = Phase.risescenes;
      _progress = (1 - (5 / 12));
    });
  }

  Future<void> recieveRisingScenes() async {
    //print(text);

    recieveScene(text);
    setState(() {
      currentPhase = Phase.climaxscenes;
      _progress = (1 - (4 / 12));
    });
  }

  Future<void> recieveClimax() async {
    recieveScene(text);
    setState(() {
      currentPhase = Phase.fallscenes;
      _progress = (1 - (3 / 12));
    });
  }

  Future<void> recieveFallScenes() async {
    recieveScene(text);
    setState(() {
      currentPhase = Phase.resolution;
      _progress = (1 - (2 / 12));
    });
  }

  Future<void> recieveResolution() async {
    //print(text);

    recieveScene(text);
    setState(() {
      currentPhase = Phase.ending;
      _progress = (1 - (1 / 12));
    });
  }

  Future<void> recieveEnding() async {
    //print(text);
    // dataRef = FirebaseFirestore.instance
    //     .collection('users')
    //     .doc(widget.userCredentials.uid)
    //     .collection('Scripts')
    //     .doc(currentId);

    recieveScene(text);
    //dataRef.collection('Scenes').doc('Scenes').set({'Scenes': allScenesData});

    setState(() {
      currentPhase = Phase.expandscenes;
      _progress = 1.0;
    });
  }

  void recieveScene(String text) {
    dataRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userCredentials.uid)
        .collection('Scripts')
        .doc(currentId)
        .collection('Scenes');

    String trimmedText = text
        .replaceAll('</center>', '')
        .replaceAll('<center>', '')
        .replaceAll("json", '')
        .replaceAll("```JSON", '')
        .replaceAll('**', '')
        .replaceAll('*', '')
        .replaceAll('\n', '')
        .replaceAll('/n', '')
        .replaceAll('```', '')
        .trim();

    Map<String, dynamic> scenesData = json.decode(trimmedText);
    allScenesData['Scenes'].addAll(scenesData['Scenes']);
    //print(allScenesData);
    final newScenes = scenesData['Scenes']
        .map((entry) {
          var scene = SceneParsing.fromMap({
            "Number": entry['Number'],
            "Text": entry['Text'],
            "Prompt": entry['Prompt']
          });
          return scene;
        })
        .toList()
        .cast<SceneParsing>();

    scenes.addAll(newScenes);

    dataRef.doc('Scenes').update(allScenesData);
  }

  Future<dynamic> convertTextToImage(
    String prompt,
    String name,
    BuildContext context,
    Reference storageReference,
    CollectionReference dataReference,
  ) async {
    Uint8List imageData = Uint8List(0);

    const baseUrl = 'https://api.stability.ai';
    final url =
        Uri.parse('$baseUrl/v1/generation/stable-diffusion-v1-6/text-to-image');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Place Stability Key Here for image generation',
        'Accept': 'image/png',
      },
      body: jsonEncode({
        'cfg_scale': 7,
        'clip_guidance_preset': 'FAST_BLUE',
        'height': 512,
        'width': 512,
        'sampler': "K_DPM_2_ANCESTRAL",
        'samples': 1,
        'steps': 30,
        'seed': 0,
        'style_preset': selectedStyle,
        'text_prompts': [
          {
            'text': 'make $prompt in the style of $selectedStyle',
            'weight': 1,
          }
        ],
      }),
    );

    if (response.statusCode == 200) {
      imageData = (response.bodyBytes);

      try {
        final storageRef = storageReference.child('$name.jpg');
        File file = await _writeToFile(imageData, ('$name.jpg'));
        await storageRef.putFile(file);
        final imageUrl = await storageRef.getDownloadURL();

        // Check if the document exists before updating it
        //final docSnapshot = await dataReference.get();

        await dataReference
            .doc(name)
            .set({'imageUrl': imageUrl}, SetOptions(merge: true));

        return imageData;
      } catch (e) {
        return showErrorDialog(
            'Failed to generate image: ${e.toString()}', context);
      }
    } else {
      return showErrorDialog(
          'Failed to generate image: ${response.reasonPhrase}', context);
    }
  }

  void showErrorDialog(String message, context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
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

  Widget _buildContent() {
    switch (currentPhase) {
      case Phase.synopsis:
        return CustomPaint(
          painter:
              SubtleBiggerRectanglesPainterShade(Theme.of(context).brightness),
          child: Row(children: [
            Flexible(
              flex: 3,
              child: Form(
                key: _formKey,
                child: ScriptTextFormField(
                  controller: _textEditingController,
                  isReadyOnly: _isLoading,
                  focusNode: _focusNode,
                  onFieldSubmitted: (value) {
                    about = value;
                    writtenMessage =
                        ('write a synopsis for a movie about ${value}, make sure to have Title: and Synopsis: so I could split in code');

                    _sendChatMessage(Phase.synopsis, writtenMessage);
                  },
                ),
              ),
            ),
            const SizedBox(
              width: 8.0,
            ),
            _isLoading
                ? const ThoughtBubbleLoader()
                : ElevatedButton(
                    onPressed: () {
                      String synopsisMessage =
                          'write a synopsis for a movie about ${_textEditingController.text},make sure to have Title: and Synopsis: so I could split in code ';

                      _sendChatMessage(Phase.synopsis, synopsisMessage);
                    },
                    child: const Text('Start'),
                  )
          ]),
        );

      case Phase.storyarc:
        _progress = (1 - (11 / 12));
        return SingleChildScrollView(
          child: Column(children: [
            const SizedBox(
              height: 10,
            ),
            LinearProgressIndicator(
              value: _progress, // 0.0 to 1.0 (determinate)
              backgroundColor: Colors.grey,
              color: progressColorTop,
            ),
            _isLoading
                ? const ThoughtBubbleLoader()
                : ElevatedButton(
                    onPressed: () {
                      String message =
                          '$synopsis --please write a synopsis for each stage of the story arc : Begining, initial incident, rising action, climax, falling action, resolution, end. output should only have those categories so its easy to split the text';

                      _sendChatMessage(Phase.storyarc, message);
                    },
                    child: const Text('Expand Story Arc'),
                  ),
            ExpandableButton(
              title: 'Synopsis',
              speak: _speak,
              stop: _pause,
              description: synopsis,
              refresh: refresh,
              textRef: FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.userCredentials.uid)
                  .collection('Scripts')
                  .doc(currentId),

              value: 'synopsis',
              onGoPressed: makeChanges,
              //currentRef: synopsisRef
            ),
          ]),
        );

      case Phase.characters:
        _progress = (1 - (10 / 12));
        return SingleChildScrollView(
          child: Column(children: [
            const SizedBox(
              height: 10,
            ),
            LinearProgressIndicator(
                value: _progress, // 0.0 to 1.0 (determinate)
                backgroundColor: Colors.grey,
                color: progressColorTop),
            _isLoading
                ? const ThoughtBubbleLoader()
                : ElevatedButton(
                    onPressed: () {
                      String charactersMessage =
                          'take $synopsis and find the characters, take each character and elbaorate on them, give them a back story and describe how they look and what motivates them, output shold be in the format of json with the following structure: {Characters:[ Name: ...{ Looks:..., BGStory:... Motivation:.. }]}, characters looks is decribed ready for image generation prompt. do not use any of the names from this list:$namesToNotUse';

                      _sendChatMessage(Phase.characters, charactersMessage);
                    },
                    child: const Text('Find Characters'),
                  ),
            ExpandableButton(
              title: 'Synopsis',
              description: synopsis,
              speak: _speak,
              stop: _pause,
              refresh: refresh,
              textRef: FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.userCredentials.uid)
                  .collection('Scripts')
                  .doc(currentId),
              value: 'synopsis',
              onGoPressed: makeChanges,
            ),
            ExpansionTile(
                title: const Text(
                  'Story Arc',
                  textAlign: TextAlign.center,
                ),
                children: story_arc_map.keys.map((key) {
                  return ExpandableShortButton(
                    title: key,
                    description: story_arc_map[key]!,
                    speak: _speak,
                    stop: _pause,
                  );
                }).toList()),
          ]),
        );

      case Phase.logline:
        _progress = (1 - (9 / 12));
        return SingleChildScrollView(
          child: Column(children: [
            const SizedBox(
              height: 10,
            ),
            LinearProgressIndicator(
                value: _progress, // 0.0 to 1.0 (determinate)
                backgroundColor: Colors.grey,
                color: progressColorTop),
            _isLoading
                ? const ThoughtBubbleLoader()
                : ElevatedButton(
                    onPressed: () {
                      String message =
                          ' we have the $synopsis please write a logline for this movie ';

                      _sendChatMessage(Phase.logline, message);
                    },
                    child: const Text('Make Logline'),
                  ),
            ExpandableButton(
              title: 'Synopsis',
              description: synopsis,
              speak: _speak,
              stop: _pause,
              refresh: refresh,
              textRef: FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.userCredentials.uid)
                  .collection('Scripts')
                  .doc(currentId),
              value: 'synopsis',
              onGoPressed: makeChanges,
              //currentRef: synopsisRef
            ),
            ExpansionTile(
                title: const Text(
                  'Story Arc',
                  textAlign: TextAlign.center,
                ),
                children: story_arc_map.keys.map((key) {
                  return ExpandableShortButton(
                    title: key,
                    description: story_arc_map[key]!,
                    speak: _speak,
                    stop: _pause,
                  );
                }).toList()),
            ExpansionTile(
                title: const Text(
                  'Characters',
                  textAlign: TextAlign.center,
                ),
                children: characters.map((key) {
                  return CharacterExpandableButton(
                    id: currentId,
                    user: widget.userCredentials.uid,
                    name: key.name,
                    backgroundStory: key.bgStory,
                    looks: key.looks,
                    imageUrl: key.imageUrl,
                    speak: _speak,
                    stop: _pause,
                    onLooksChanged: (newLooks) {
                      setState(() {
                        key.looks =
                            newLooks; // Update the looks variable dynamically
                      });
                    },
                    createImageCallback: () => convertTextToImage(
                      key.looks,
                      key.name,
                      context,
                      FirebaseStorage.instance
                          .ref()
                          .child('users')
                          .child(widget.userCredentials.uid)
                          .child('Scripts')
                          .child(currentId)
                          .child('Characters'),
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(widget.userCredentials.uid)
                          .collection('Scripts')
                          .doc(currentId)
                          .collection('Characters'),
                    ),
                  );
                }).toList()),
          ]),
        );

      case Phase.firstscenes:
        _progress = 1 - (8 / 12);
        return SingleChildScrollView(
          child: Column(children: [
            const SizedBox(
              height: 10,
            ),
            LinearProgressIndicator(
                value: _progress, // 0.0 to 1.0 (determinate)
                backgroundColor: Colors.grey,
                color: progressColorTop),
            _isLoading
                ? const ThoughtBubbleLoader()
                : ElevatedButton(
                    onPressed: () {
                      String charactersMessage =
                          'take this synopsis: $synopsis and these characters :$characters. and use them to expand $begining into  (2 scenes), write each scene for a well written movie with places, dialogs etc. and output it in json format that has the scene number and the whole scene as a text value (and a prompt to generate an image that represents the scene), make sure the text is plain json fields should be exactly Scenes, Number,Prompt, Text';

                      _sendChatMessage(Phase.firstscenes, charactersMessage);
                    },
                    child: const Text('Write First Scene'),
                  ),
            Text(textAlign: TextAlign.center, logLine),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  if (isReading) {
                    isReading = false;
                    _pause();
                  } else {
                    _speak(logLine);
                    isReading = true;
                  }
                },
                label: isReading ? const Text('Stop') : const Text('Read'),
                icon: isReading
                    ? const Icon(Icons.stop)
                    : const Icon(Icons.speaker),
              ),
            ),
            ExpandableButton(
              title: 'Synopsis',
              description: synopsis,
              speak: _speak,
              stop: _pause,
              refresh: refresh,
              textRef: FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.userCredentials.uid)
                  .collection('Scripts')
                  .doc(currentId),
              value: 'synopsis',
              onGoPressed: makeChanges,
              //currentRef: synopsisRef
            ),
            ExpansionTile(
                title: const Text(
                  'Story Arc',
                  textAlign: TextAlign.center,
                ),
                children: story_arc_map.keys.map((key) {
                  return ExpandableShortButton(
                    title: key,
                    description: story_arc_map[key]!,
                    speak: _speak,
                    stop: _pause,
                  );
                }).toList()),
            ExpansionTile(
                title: const Text(
                  'Characters',
                  textAlign: TextAlign.center,
                ),
                children: characters.map((key) {
                  return CharacterExpandableButton(
                    id: currentId,
                    user: widget.userCredentials.uid,
                    name: key.name,
                    backgroundStory: key.bgStory,
                    looks: key.looks,
                    imageUrl: key.imageUrl,
                    speak: _speak,
                    stop: _pause,
                    onLooksChanged: (newLooks) {
                      setState(() {
                        key.looks =
                            newLooks; // Update the looks variable dynamically
                      });
                    },
                    createImageCallback: () => convertTextToImage(
                      key.looks,
                      key.name,
                      context,
                      FirebaseStorage.instance
                          .ref()
                          .child('users')
                          .child(widget.userCredentials.uid)
                          .child('Scripts')
                          .child(currentId)
                          .child('Characters'),
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(widget.userCredentials.uid)
                          .collection('Scripts')
                          .doc(currentId)
                          .collection('Characters'),
                    ),
                  );
                }).toList()),
          ]),
        );

      case Phase.initscenes:
        _progress = 1 - (7 / 12);
        return SingleChildScrollView(
          child: Column(children: [
            const SizedBox(
              height: 10,
            ),
            LinearProgressIndicator(
                value: _progress, // 0.0 to 1.0 (determinate)
                backgroundColor: Colors.grey,
                color: progressColorTop),
            _isLoading
                ? const ThoughtBubbleLoader()
                : ElevatedButton(
                    onPressed: () {
                      String charactersMessage =
                          'take this synopsis: $synopsis and these characters :$characters. and use them to expand $initial_incident into 2 scenes, write each scene for a well written movie with places, dialogs etc. and output it in json format that has the scene number and the whole scene as a text value (and a prompt to generate an image that represents the scene), make sure the text is plain json fields should be exactly Scenes, Number,Prompt, Text, scenes numbers are 3 and 4';

                      _sendChatMessage(Phase.initscenes, charactersMessage);
                    },
                    child: const Text('Write Initial Incident Scenes'),
                  ),
            Text(textAlign: TextAlign.center, logLine),
            TextButton.icon(
              onPressed: () {
                if (isReading) {
                  isReading = false;
                  _pause();
                } else {
                  _speak(logLine);
                  isReading = true;
                }
              },
              label: isReading ? const Text('Stop') : const Text('Read'),
              icon: isReading
                  ? const Icon(Icons.stop)
                  : const Icon(Icons.speaker),
            ),
            ExpandableButton(
              title: 'Synopsis',
              description: synopsis,
              speak: _speak,
              stop: _pause,
              refresh: refresh,
              textRef: FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.userCredentials.uid)
                  .collection('Scripts')
                  .doc(currentId),
              value: 'synopsis',
              onGoPressed: makeChanges,
              //currentRef: synopsisRef
            ),
            ExpansionTile(
                title: const Text(
                  'Story Arc',
                  textAlign: TextAlign.center,
                ),
                children: story_arc_map.keys.map((key) {
                  return ExpandableShortButton(
                    title: key,
                    description: story_arc_map[key]!,
                    speak: _speak,
                    stop: _pause,
                  );
                }).toList()),
            ExpansionTile(
                title: const Text(
                  'Characters',
                  textAlign: TextAlign.center,
                ),
                children: characters.map((key) {
                  return CharacterExpandableButton(
                    id: currentId,
                    user: widget.userCredentials.uid,
                    name: key.name,
                    backgroundStory: key.bgStory,
                    looks: key.looks,
                    imageUrl: key.imageUrl,
                    speak: _speak,
                    stop: _pause,
                    onLooksChanged: (newLooks) {
                      setState(() {
                        key.looks =
                            newLooks; // Update the looks variable dynamically
                      });
                    },
                    createImageCallback: () => convertTextToImage(
                      key.looks,
                      key.name,
                      context,
                      FirebaseStorage.instance
                          .ref()
                          .child('users')
                          .child(widget.userCredentials.uid)
                          .child('Scripts')
                          .child(currentId)
                          .child('Characters'),
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(widget.userCredentials.uid)
                          .collection('Scripts')
                          .doc(currentId)
                          .collection('Characters'),
                    ),
                  );
                }).toList()),
            ExpansionTile(
                title: const Text(
                  'Scenes',
                  textAlign: TextAlign.center,
                ),
                children: scenes.map((key) {
                  return ExpandableSceneButton(
                      key: ValueKey(key),
                      speak: _speak,
                      stop: _pause,
                      title: key.sceneNumber,
                      imageUrl: key.imageUrl,
                      prompt: key.prompt,
                      description: key.sceneText,
                      onLooksChanged: (newLooks) {
                        setState(() {
                          key.prompt =
                              newLooks; // Update the looks variable dynamically
                        });
                      },
                      textRef: FirebaseFirestore.instance
                          .collection('users')
                          .doc(widget.userCredentials.uid)
                          .collection('Scripts')
                          .doc(currentId),
                      onGoPressed: makeChanges,
                      value: 'Scenes',
                      makeImageDescription: makePhotoDescription,
                      createImageCallback: () {
                        return convertTextToImage(
                          key.prompt,
                          key.sceneNumber,
                          context,
                          FirebaseStorage.instance
                              .ref()
                              .child('users')
                              .child(widget.userCredentials.uid)
                              .child('Scripts')
                              .child(currentId)
                              .child('Scenes'),
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(widget.userCredentials.uid)
                              .collection('Scripts')
                              .doc(currentId)
                              .collection('Scenes'),
                        );
                      });
                }).toList()),
          ]),
        );

      case Phase.risescenes:
        _progress = 1 - (6 / 12);
        return SingleChildScrollView(
          child: Column(children: [
            const SizedBox(
              height: 10,
            ),
            LinearProgressIndicator(
                value: _progress, // 0.0 to 1.0 (determinate)
                backgroundColor: Colors.grey,
                color: progressColorTop),
            _isLoading
                ? const ThoughtBubbleLoader()
                : ElevatedButton(
                    onPressed: () {
                      String charactersMessage =
                          'take this synopsis: $synopsis and these characters :$characters. and use them to expand $rising_action into 2 scenes, write each scene for a well written movie with places, dialogs etc. and output it in json format that has the scene number and the whole scene as a text value (and a prompt to generate an image that represents the scene), make sure the text is plain json fields should be exactly Scenes, Number,Prompt, Text, scenes numbers are 5 and 6';

                      _sendChatMessage(Phase.risescenes, charactersMessage);
                    },
                    child: const Text('Write Rising Action Scenes'),
                  ),
            Text(textAlign: TextAlign.center, logLine),
            TextButton.icon(
              onPressed: () {
                if (isReading) {
                  isReading = false;
                  _pause();
                } else {
                  _speak(logLine);
                  isReading = true;
                }
              },
              label: isReading ? const Text('Stop') : const Text('Read'),
              icon: isReading
                  ? const Icon(Icons.stop)
                  : const Icon(Icons.speaker),
            ),
            ExpandableButton(
              title: 'Synopsis',
              description: synopsis,
              speak: _speak,
              stop: _pause,
              refresh: refresh,
              textRef: FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.userCredentials.uid)
                  .collection('Scripts')
                  .doc(currentId),
              value: 'synopsis',
              onGoPressed: makeChanges,
              //currentRef: synopsisRef
            ),
            ExpansionTile(
                title: const Text(
                  'Story Arc',
                  textAlign: TextAlign.center,
                ),
                children: story_arc_map.keys.map((key) {
                  return ExpandableShortButton(
                    title: key,
                    description: story_arc_map[key]!,
                    speak: _speak,
                    stop: _pause,
                  );
                }).toList()),
            ExpansionTile(
                title: const Text(
                  'Characters',
                  textAlign: TextAlign.center,
                ),
                children: characters.map((key) {
                  return CharacterExpandableButton(
                    id: currentId,
                    user: widget.userCredentials.uid,
                    name: key.name,
                    backgroundStory: key.bgStory,
                    looks: key.looks,
                    imageUrl: key.imageUrl,
                    speak: _speak,
                    stop: _pause,
                    onLooksChanged: (newLooks) {
                      setState(() {
                        key.looks =
                            newLooks; // Update the looks variable dynamically
                      });
                    },
                    createImageCallback: () => convertTextToImage(
                      key.looks,
                      key.name,
                      context,
                      FirebaseStorage.instance
                          .ref()
                          .child('users')
                          .child(widget.userCredentials.uid)
                          .child('Scripts')
                          .child(currentId)
                          .child('Characters'),
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(widget.userCredentials.uid)
                          .collection('Scripts')
                          .doc(currentId)
                          .collection('Characters'),
                    ),
                  );
                }).toList()),
            ExpansionTile(
                title: const Text(
                  'Scenes',
                  textAlign: TextAlign.center,
                ),
                children: scenes.map((key) {
                  return ExpandableSceneButton(
                      key: ValueKey(key),
                      speak: _speak,
                      stop: _pause,
                      prompt: key.prompt,
                      title: key.sceneNumber,
                      imageUrl: key.imageUrl,
                      description: key.sceneText,
                      onLooksChanged: (newLooks) {
                        setState(() {
                          key.prompt =
                              newLooks; // Update the looks variable dynamically
                        });
                      },
                      textRef: FirebaseFirestore.instance
                          .collection('users')
                          .doc(widget.userCredentials.uid)
                          .collection('Scripts')
                          .doc(currentId),
                      onGoPressed: makeChanges,
                      value: 'Scenes',
                      makeImageDescription: makePhotoDescription,
                      createImageCallback: () {
                        return convertTextToImage(
                          key.prompt,
                          key.sceneNumber,
                          context,
                          FirebaseStorage.instance
                              .ref()
                              .child('users')
                              .child(widget.userCredentials.uid)
                              .child('Scripts')
                              .child(currentId)
                              .child('Scenes'),
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(widget.userCredentials.uid)
                              .collection('Scripts')
                              .doc(currentId)
                              .collection('Scenes'),
                        );
                      });
                }).toList()),
          ]),
        );

      case Phase.climaxscenes:
        _progress = 1 - (5 / 12);
        return SingleChildScrollView(
          child: Column(children: [
            const SizedBox(
              height: 10,
            ),
            LinearProgressIndicator(
                value: _progress, // 0.0 to 1.0 (determinate)
                backgroundColor: Colors.grey,
                color: progressColorTop),
            _isLoading
                ? const ThoughtBubbleLoader()
                : ElevatedButton(
                    onPressed: () {
                      String charactersMessage =
                          'take this synopsis: $synopsis and these characters :$characters. and use them to expand $climax into 2 scenes, write each scene for a well written movie with places, dialogs etc. and output it in json format that has the scene number and the whole scene as a text value (and a prompt to generate an image that represents the scene), make sure the text is plain json fields should be exactly Scenes, Number,Prompt, Text, scenes numbers are 7 and 8';

                      _sendChatMessage(Phase.climaxscenes, charactersMessage);
                    },
                    child: const Text('Write Climax Scenes'),
                  ),
            Text(textAlign: TextAlign.center, logLine),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  if (isReading) {
                    isReading = false;
                    _pause();
                  } else {
                    _speak(logLine);
                    isReading = true;
                  }
                },
                label: isReading ? const Text('Stop') : const Text('Read'),
                icon: isReading
                    ? const Icon(Icons.stop)
                    : const Icon(Icons.speaker),
              ),
            ),
            ExpandableButton(
              title: 'Synopsis',
              description: synopsis,
              speak: _speak,
              stop: _pause,
              refresh: refresh,
              textRef: FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.userCredentials.uid)
                  .collection('Scripts')
                  .doc(currentId),
              value: 'synopsis',
              onGoPressed: makeChanges,
              //currentRef: synopsisRef
            ),
            ExpansionTile(
                title: const Text(
                  'Story Arc',
                  textAlign: TextAlign.center,
                ),
                children: story_arc_map.keys.map((key) {
                  return ExpandableShortButton(
                    title: key,
                    description: story_arc_map[key]!,
                    speak: _speak,
                    stop: _pause,
                  );
                }).toList()),
            ExpansionTile(
                title: const Text(
                  'Characters',
                  textAlign: TextAlign.center,
                ),
                children: characters.map((key) {
                  return CharacterExpandableButton(
                    id: currentId,
                    user: widget.userCredentials.uid,
                    name: key.name,
                    backgroundStory: key.bgStory,
                    looks: key.looks,
                    imageUrl: key.imageUrl,
                    speak: _speak,
                    stop: _pause,
                    onLooksChanged: (newLooks) {
                      setState(() {
                        key.looks =
                            newLooks; // Update the looks variable dynamically
                      });
                    },
                    createImageCallback: () => convertTextToImage(
                      key.looks,
                      key.name,
                      context,
                      FirebaseStorage.instance
                          .ref()
                          .child('users')
                          .child(widget.userCredentials.uid)
                          .child('Scripts')
                          .child(currentId)
                          .child('Characters'),
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(widget.userCredentials.uid)
                          .collection('Scripts')
                          .doc(currentId)
                          .collection('Characters'),
                    ),
                  );
                }).toList()),
            ExpansionTile(
                title: const Text(
                  'Scenes',
                  textAlign: TextAlign.center,
                ),
                children: scenes.map((key) {
                  return ExpandableSceneButton(
                      key: ValueKey(key),
                      speak: _speak,
                      stop: _pause,
                      prompt: key.prompt,
                      title: key.sceneNumber,
                      imageUrl: key.imageUrl,
                      description: key.sceneText,
                      onLooksChanged: (newLooks) {
                        setState(() {
                          key.prompt =
                              newLooks; // Update the looks variable dynamically
                        });
                      },
                      textRef: FirebaseFirestore.instance
                          .collection('users')
                          .doc(widget.userCredentials.uid)
                          .collection('Scripts')
                          .doc(currentId),
                      onGoPressed: makeChanges,
                      value: 'Scenes',
                      makeImageDescription: makePhotoDescription,
                      createImageCallback: () {
                        return convertTextToImage(
                          key.prompt,
                          key.sceneNumber,
                          context,
                          FirebaseStorage.instance
                              .ref()
                              .child('users')
                              .child(widget.userCredentials.uid)
                              .child('Scripts')
                              .child(currentId)
                              .child('Scenes'),
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(widget.userCredentials.uid)
                              .collection('Scripts')
                              .doc(currentId)
                              .collection('Scenes'),
                        );
                      });
                }).toList()),
          ]),
        );
      case Phase.fallscenes:
        _progress = 1 - (4 / 12);
        return SingleChildScrollView(
          child: Column(children: [
            const SizedBox(
              height: 10,
            ),
            LinearProgressIndicator(
                value: _progress, // 0.0 to 1.0 (determinate)
                backgroundColor: Colors.grey,
                color: progressColorTop),
            _isLoading
                ? const ThoughtBubbleLoader()
                : ElevatedButton(
                    onPressed: () {
                      String charactersMessage =
                          'take this synopsis: $synopsis and these characters :$characters. and use them to expand $falling_action into 2 scenes, write each scene for a well written movie with places, dialogs etc. and output it in json format that has the scene number and the whole scene as a text value (and a prompt to generate an image that represents the scene), make sure the text is plain json fields should be exactly Scenes, Number,Prompt, Text, scenes numbers are 9 and 10';

                      _sendChatMessage(Phase.fallscenes, charactersMessage);
                    },
                    child: const Text('Write Falling Action Scenes'),
                  ),
            Text(textAlign: TextAlign.center, logLine),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  if (isReading) {
                    isReading = false;
                    _pause();
                  } else {
                    _speak(logLine);
                    isReading = true;
                  }
                },
                label: isReading ? const Text('Stop') : const Text('Read'),
                icon: isReading
                    ? const Icon(Icons.stop)
                    : const Icon(Icons.speaker),
              ),
            ),
            ExpandableButton(
              title: 'Synopsis',
              description: synopsis,
              speak: _speak,
              stop: _pause,
              refresh: refresh,
              textRef: FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.userCredentials.uid)
                  .collection('Scripts')
                  .doc(currentId)
                  .collection('Scenes')
                  .doc('Scenes'),
              onGoPressed: makeChanges,
              value: 'Scenes',
              //currentRef: synopsisRef
            ),
            ExpansionTile(
                title: const Text(
                  'Story Arc',
                  textAlign: TextAlign.center,
                ),
                children: story_arc_map.keys.map((key) {
                  return ExpandableShortButton(
                    title: key,
                    description: story_arc_map[key]!,
                    speak: _speak,
                    stop: _pause,
                  );
                }).toList()),
            ExpansionTile(
                title: const Text(
                  'Characters',
                  textAlign: TextAlign.center,
                ),
                children: characters.map((key) {
                  return CharacterExpandableButton(
                    id: currentId,
                    user: widget.userCredentials.uid,
                    name: key.name,
                    backgroundStory: key.bgStory,
                    looks: key.looks,
                    imageUrl: key.imageUrl,
                    speak: _speak,
                    stop: _pause,
                    onLooksChanged: (newLooks) {
                      setState(() {
                        key.looks =
                            newLooks; // Update the looks variable dynamically
                      });
                    },
                    createImageCallback: () => convertTextToImage(
                      key.looks,
                      key.name,
                      context,
                      FirebaseStorage.instance
                          .ref()
                          .child('users')
                          .child(widget.userCredentials.uid)
                          .child('Scripts')
                          .child(currentId)
                          .child('Characters'),
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(widget.userCredentials.uid)
                          .collection('Scripts')
                          .doc(currentId)
                          .collection('Characters'),
                    ),
                  );
                }).toList()),
            ExpansionTile(
                title: const Text(
                  'Scenes',
                  textAlign: TextAlign.center,
                ),
                children: scenes.map((key) {
                  return ExpandableSceneButton(
                      key: ValueKey(key),
                      speak: _speak,
                      stop: _pause,
                      prompt: key.prompt,
                      title: key.sceneNumber,
                      imageUrl: key.imageUrl,
                      description: key.sceneText,
                      onLooksChanged: (newLooks) {
                        setState(() {
                          key.prompt =
                              newLooks; // Update the looks variable dynamically
                        });
                      },
                      textRef: FirebaseFirestore.instance
                          .collection('users')
                          .doc(widget.userCredentials.uid)
                          .collection('Scripts')
                          .doc(currentId),
                      onGoPressed: makeChanges,
                      value: 'Scenes',
                      makeImageDescription: makePhotoDescription,
                      createImageCallback: () {
                        return convertTextToImage(
                          key.prompt,
                          key.sceneNumber,
                          context,
                          FirebaseStorage.instance
                              .ref()
                              .child('users')
                              .child(widget.userCredentials.uid)
                              .child('Scripts')
                              .child(currentId)
                              .child('Scenes'),
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(widget.userCredentials.uid)
                              .collection('Scripts')
                              .doc(currentId)
                              .collection('Scenes'),
                        );
                      });
                }).toList()),
          ]),
        );

      case Phase.resolution:
        _progress = 1 - (3 / 12);
        return SingleChildScrollView(
          child: Column(children: [
            const SizedBox(
              height: 10,
            ),
            LinearProgressIndicator(
                value: _progress, // 0.0 to 1.0 (determinate)
                backgroundColor: Colors.grey,
                color: progressColorTop),
            _isLoading
                ? const ThoughtBubbleLoader()
                : ElevatedButton(
                    onPressed: () {
                      String charactersMessage =
                          'take this synopsis: $synopsis and these characters :$characters. and use them to expand $resolusion into 2 scenes, write each scene for a well written movie with places, dialogs etc. and output it in json format that has the scene number and the whole scene as a text value (and a prompt to generate an image that represents the scene), make sure the text is plain json fields should be exactly Scenes, Number,Prompt, Text, scenes numbers are 11 and 12';

                      _sendChatMessage(Phase.resolution, charactersMessage);
                    },
                    child: const Text('Write Resolution Scenes'),
                  ),
            Text(textAlign: TextAlign.center, logLine),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  if (isReading) {
                    isReading = false;
                    _pause();
                  } else {
                    _speak(logLine);
                    isReading = true;
                  }
                },
                label: isReading ? const Text('Stop') : const Text('Read'),
                icon: isReading
                    ? const Icon(Icons.stop)
                    : const Icon(Icons.speaker),
              ),
            ),
            ExpandableButton(
              title: 'Synopsis',
              description: synopsis,
              speak: _speak,
              stop: _pause,
              refresh: refresh,
              textRef: FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.userCredentials.uid)
                  .collection('Scripts')
                  .doc(currentId)
                  .collection('Scenes')
                  .doc('Scenes'),
              value: 'synopsis',
              onGoPressed: makeChanges,
              //currentRef: synopsisRef
            ),
            ExpansionTile(
                title: const Text(
                  'Story Arc',
                  textAlign: TextAlign.center,
                ),
                children: story_arc_map.keys.map((key) {
                  return ExpandableShortButton(
                    title: key,
                    description: story_arc_map[key]!,
                    speak: _speak,
                    stop: _pause,
                  );
                }).toList()),
            ExpansionTile(
                title: const Text(
                  'Characters',
                  textAlign: TextAlign.center,
                ),
                children: characters.map((key) {
                  return CharacterExpandableButton(
                    id: currentId,
                    user: widget.userCredentials.uid,
                    name: key.name,
                    backgroundStory: key.bgStory,
                    looks: key.looks,
                    imageUrl: key.imageUrl,
                    speak: _speak,
                    stop: _pause,
                    onLooksChanged: (newLooks) {
                      setState(() {
                        key.looks =
                            newLooks; // Update the looks variable dynamically
                      });
                    },
                    createImageCallback: () => convertTextToImage(
                      key.looks,
                      key.name,
                      context,
                      FirebaseStorage.instance
                          .ref()
                          .child('users')
                          .child(widget.userCredentials.uid)
                          .child('Scripts')
                          .child(currentId)
                          .child('Characters'),
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(widget.userCredentials.uid)
                          .collection('Scripts')
                          .doc(currentId)
                          .collection('Characters'),
                    ),
                  );
                }).toList()),
            ExpansionTile(
                title: const Text(
                  'Scenes',
                  textAlign: TextAlign.center,
                ),
                children: scenes.map((key) {
                  return ExpandableSceneButton(
                      key: ValueKey(key),
                      speak: _speak,
                      stop: _pause,
                      prompt: key.prompt,
                      title: key.sceneNumber,
                      imageUrl: key.imageUrl,
                      description: key.sceneText,
                      onLooksChanged: (newLooks) {
                        setState(() {
                          key.prompt =
                              newLooks; // Update the looks variable dynamically
                        });
                      },
                      textRef: FirebaseFirestore.instance
                          .collection('users')
                          .doc(widget.userCredentials.uid)
                          .collection('Scripts')
                          .doc(currentId),
                      onGoPressed: makeChanges,
                      value: 'Scenes',
                      makeImageDescription: makePhotoDescription,
                      createImageCallback: () {
                        return convertTextToImage(
                          key.prompt,
                          key.sceneNumber,
                          context,
                          FirebaseStorage.instance
                              .ref()
                              .child('users')
                              .child(widget.userCredentials.uid)
                              .child('Scripts')
                              .child(currentId)
                              .child('Scenes'),
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(widget.userCredentials.uid)
                              .collection('Scripts')
                              .doc(currentId)
                              .collection('Scenes'),
                        );
                      });
                }).toList()),
          ]),
        );
      case Phase.ending:
        _progress = 1 - (2 / 12);
        return SingleChildScrollView(
          child: Column(children: [
            const SizedBox(
              height: 10,
            ),
            LinearProgressIndicator(
                value: _progress, // 0.0 to 1.0 (determinate)
                backgroundColor: Colors.grey,
                color: progressColorTop),
            _isLoading
                ? const ThoughtBubbleLoader()
                : ElevatedButton(
                    onPressed: () {
                      String charactersMessage =
                          'take this synopsis: $synopsis and these characters :$characters. and use them to expand $ending into 2 scenes, write each scene for a well written movie with places, dialogs etc. and output it in json format that has the scene number and the whole scene as a text value (and a prompt to generate an image that represents the scene), make sure the text is plain json fields should be exactly Scenes, Number,Prompt, Text, scenes numbers are 13 and 14';

                      _sendChatMessage(Phase.ending, charactersMessage);
                    },
                    child: const Text('Write Ending Scenes'),
                  ),
            Text(textAlign: TextAlign.center, logLine),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  if (isReading) {
                    isReading = false;
                    _pause();
                  } else {
                    _speak(logLine);
                    isReading = true;
                  }
                },
                label: isReading ? const Text('Stop') : const Text('Read'),
                icon: isReading
                    ? const Icon(Icons.stop)
                    : const Icon(Icons.speaker),
              ),
            ),
            ExpandableButton(
              title: 'Synopsis',
              description: synopsis,
              speak: _speak,
              stop: _pause,
              refresh: refresh,
              textRef: FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.userCredentials.uid)
                  .collection('Scripts')
                  .doc(currentId),
              value: 'synopsis',
              onGoPressed: makeChanges,
              //currentRef: synopsisRef
            ),
            ExpansionTile(
                title: const Text(
                  'Story Arc',
                  textAlign: TextAlign.center,
                ),
                children: story_arc_map.keys.map((key) {
                  return ExpandableShortButton(
                    title: key,
                    description: story_arc_map[key]!,
                    speak: _speak,
                    stop: _pause,
                  );
                }).toList()),
            ExpansionTile(
                title: const Text(
                  'Characters',
                  textAlign: TextAlign.center,
                ),
                children: characters.map((key) {
                  return CharacterExpandableButton(
                    id: currentId,
                    user: widget.userCredentials.uid,
                    name: key.name,
                    backgroundStory: key.bgStory,
                    looks: key.looks,
                    imageUrl: key.imageUrl,
                    speak: _speak,
                    stop: _pause,
                    onLooksChanged: (newLooks) {
                      setState(() {
                        key.looks =
                            newLooks; // Update the looks variable dynamically
                      });
                    },
                    createImageCallback: () => convertTextToImage(
                      key.looks,
                      key.name,
                      context,
                      FirebaseStorage.instance
                          .ref()
                          .child('users')
                          .child(widget.userCredentials.uid)
                          .child('Scripts')
                          .child(currentId)
                          .child('Characters'),
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(widget.userCredentials.uid)
                          .collection('Scripts')
                          .doc(currentId)
                          .collection('Characters'),
                    ),
                  );
                }).toList()),
            ExpansionTile(
                title: const Text(
                  'Scenes',
                  textAlign: TextAlign.center,
                ),
                children: scenes.map((key) {
                  return ExpandableSceneButton(
                      key: ValueKey(key),
                      speak: _speak,
                      stop: _pause,
                      prompt: key.prompt,
                      title: key.sceneNumber,
                      imageUrl: key.imageUrl,
                      description: key.sceneText,
                      onLooksChanged: (newLooks) {
                        setState(() {
                          key.prompt =
                              newLooks; // Update the looks variable dynamically
                        });
                      },
                      textRef: FirebaseFirestore.instance
                          .collection('users')
                          .doc(widget.userCredentials.uid)
                          .collection('Scripts')
                          .doc(currentId),
                      onGoPressed: makeChanges,
                      value: 'Scenes',
                      makeImageDescription: makePhotoDescription,
                      createImageCallback: () {
                        return convertTextToImage(
                          key.prompt,
                          key.sceneNumber,
                          context,
                          FirebaseStorage.instance
                              .ref()
                              .child('users')
                              .child(widget.userCredentials.uid)
                              .child('Scripts')
                              .child(currentId)
                              .child('Scenes'),
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(widget.userCredentials.uid)
                              .collection('Scripts')
                              .doc(currentId)
                              .collection('Scenes'),
                        );
                      });
                }).toList()),
          ]),
        );
      case Phase.expandscenes:
        _progress = 1;
        return SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(
                height: 10,
              ),
              LinearProgressIndicator(
                  value: _progress, // 0.0 to 1.0 (determinate)
                  backgroundColor: Colors.grey,
                  color: progressColorTop),
              _isLoading
                  ? const ThoughtBubbleLoader()
                  : TextButton.icon(
                      onPressed: () async {
                        //print(characters);

                        setState(() {
                          _isLoading = true;
                        });

                        await saveScenesAndCharactersToPdf(
                          title,
                          synopsis,
                          scenes,
                          characters,
                        );
                        setState(() {
                          _isLoading = false;
                        });
                      },
                      label: const Text('Save to PDF'),
                      icon: const Icon(Icons.save),
                    ),
              Text(textAlign: TextAlign.center, logLine),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    if (isReading) {
                      isReading = false;
                      _pause();
                    } else {
                      _speak(logLine);
                      isReading = true;
                    }
                  },
                  label: isReading ? const Text('Stop') : const Text('Read'),
                  icon: isReading
                      ? const Icon(Icons.stop)
                      : const Icon(Icons.speaker),
                ),
              ),
              ExpandableButton(
                title: 'Synopsis',
                description: synopsis,
                speak: _speak,
                stop: _pause,
                refresh: refresh,
                textRef: FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.userCredentials.uid)
                    .collection('Scripts')
                    .doc(currentId),
                value: 'synopsis',
                onGoPressed: makeChanges,
                //currentRef: synopsisRef
              ),
              ExpansionTile(
                  title: const Text(
                    'Story Arc',
                    textAlign: TextAlign.center,
                  ),
                  children: story_arc_map.keys.map((key) {
                    return ExpandableShortButton(
                      title: key,
                      description: story_arc_map[key]!,
                      speak: _speak,
                      stop: _pause,
                    );
                  }).toList()),
              ExpansionTile(
                  title: const Text(
                    'Characters',
                    textAlign: TextAlign.center,
                  ),
                  children: characters.map((key) {
                    return CharacterExpandableButton(
                      id: currentId,
                      user: widget.userCredentials.uid,
                      name: key.name,
                      backgroundStory: key.bgStory,
                      looks: key.looks,
                      imageUrl: key.imageUrl,
                      speak: _speak,
                      stop: _pause,
                      onLooksChanged: (newLooks) {
                        setState(() {
                          key.looks =
                              newLooks; // Update the looks variable dynamically
                        });
                      },
                      createImageCallback: () => convertTextToImage(
                        key.looks,
                        key.name,
                        context,
                        FirebaseStorage.instance
                            .ref()
                            .child('users')
                            .child(widget.userCredentials.uid)
                            .child('Scripts')
                            .child(currentId)
                            .child('Characters'),
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(widget.userCredentials.uid)
                            .collection('Scripts')
                            .doc(currentId)
                            .collection('Characters'),
                      ),
                    );
                  }).toList()),
              ExpansionTile(
                title: const Text(
                  'Scenes',
                  textAlign: TextAlign.center,
                ),
                children: [
                  ReorderableListView.builder(
                    onReorder: (oldIndex, newIndex) {},
                    shrinkWrap:
                        true, // Add this to ensure the ListView takes up minimal space
                    physics:
                        const NeverScrollableScrollPhysics(), // Prevent ListView from scrolling, allowing ExpansionTile to handle it
                    itemCount: scenes.length * 2 - 1,
                    itemBuilder: (context, index) {
                      if (index % 2 == 0) {
                        int sceneIndex = index ~/ 2;
                        var val = ValueKey(index);
                        return ExpandableSceneButton(
                          key: val,
                          title: scenes[sceneIndex].sceneNumber,
                          description: scenes[sceneIndex].sceneText,
                          imageUrl: scenes[sceneIndex].imageUrl,
                          prompt: scenes[sceneIndex].prompt,
                          onLooksChanged: (newLooks) {
                            setState(() {
                              scenes[sceneIndex].prompt =
                                  newLooks; // Update the looks variable dynamically
                            });
                          },
                          textRef: FirebaseFirestore.instance
                              .collection('users')
                              .doc(widget.userCredentials.uid)
                              .collection('Scripts')
                              .doc(currentId),
                          value: 'Scenes',
                          onGoPressed: makeChanges,
                          speak: _speak,
                          stop: _pause,
                          makeImageDescription: makePhotoDescription,
                          createImageCallback: () {
                            return convertTextToImage(
                              scenes[sceneIndex].prompt,
                              scenes[sceneIndex].sceneNumber,
                              context,
                              FirebaseStorage.instance
                                  .ref()
                                  .child('users')
                                  .child(widget.userCredentials.uid)
                                  .child('Scripts')
                                  .child(currentId)
                                  .child('Scenes'),
                              FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(widget.userCredentials.uid)
                                  .collection('Scripts')
                                  .doc(currentId)
                                  .collection('Scenes'),
                            );
                          },
                        );
                      } else {
                        int sceneIndexBefore = (index - 1) ~/ 2;
                        int sceneIndexAfter = (index + 1) ~/ 2;

                        String textBefore = sceneIndexBefore >= 0
                            ? scenes[sceneIndexBefore].sceneText
                            : '';
                        String textAfter = sceneIndexAfter < scenes.length
                            ? scenes[sceneIndexAfter].sceneText
                            : '';

                        var val = ValueKey(index);
                        return AddSceneButton(
                          index: index,
                          key: val,
                          sceneRef: FirebaseFirestore.instance
                              .collection('users')
                              .doc(widget.userCredentials.uid)
                              .collection('Scripts')
                              .doc(currentId),
                          synopsis: synopsis,
                          textBefore: textBefore,
                          textAfter: textAfter,
                          onGoPressed: makeChanges,
                          userId: widget.userCredentials.uid,
                          currentId: currentId,
                          characters: characters,
                          updateScenes: (value) {
                            setState(() {
                              scenes = value;
                            });
                          },
                        );
                      }
                    },
                  )
                ],
              )
            ],
          ),
        );

      default:
        return const Text('Loading...');
    }
  }

  Future<File> _writeToFile(Uint8List data, String filename) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$filename');
    return file.writeAsBytes(data);
  }
}
