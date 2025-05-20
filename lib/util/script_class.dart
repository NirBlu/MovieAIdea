

class Scene {
  final String title;
  final String description;

  Scene({required this.title, required this.description});

  factory Scene.fromMap(Map<String, dynamic> map) {
    return Scene(
      title: map['title'] ?? '',
      description: map['description'] ?? '',
    );
  }
}

class Script {
  final String title;
  final String synopsis;
  final Map<String, String> storyArc;
  final String logline;
  final String characters;
  final List<Scene> scenes;

  Script({
    required this.title,
    required this.synopsis,
    required this.storyArc,
    required this.logline,
    required this.characters,
    required this.scenes,
  });

  factory Script.fromMap(Map<String, dynamic> map) {
    Map<String, String> storyArc = {};
    if (map['beginning'] != null) {
      storyArc['Beginning'] = map['beginning'].toString();
    }
    if (map['initial_incident'] != null) {
      storyArc['Initial Incident'] = map['initial_incident'].toString();
    }
    if (map['rising_action'] != null) {
      storyArc['Rising Action'] = map['rising_action'].toString();
    }
    if (map['climax'] != null) {
      storyArc['Climax'] = map['climax'].toString();
    }
    if (map['falling_action'] != null) {
      storyArc['Falling Action'] = map['falling_action'].toString();
    }
    if (map['resolution'] != null) {
      storyArc['Resolution'] = map['resolution'].toString();
    }
    if (map['ending'] != null) {
      storyArc['Ending'] = map['ending'].toString();
    }

    // List<Character> characters = [];
    // if (map['characters'] != null) {
    //   characters = (map['characters'] as List<dynamic>).map((char) {
    //     return Character.fromMap(char as Map<String, dynamic>);
    //   }).toList();
    // }

    List<Scene> scenes = [];
    if (map['scenes'] != null) {
      scenes = (map['scenes'] as List<dynamic>).map((scene) {
        return Scene.fromMap(scene as Map<String, dynamic>);
      }).toList();
    }

    return Script(
      title: map['title'] ?? '',
      synopsis: map['synopsis'] ?? '',
      storyArc: storyArc,
      logline: map['logline'],
      characters: map['characters'],
      scenes: scenes,
    );
  }
}
