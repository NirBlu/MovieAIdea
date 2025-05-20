

class SceneParsing {
  //final String characterName;
  String sceneNumber;
  String sceneText;
  String prompt;

  String imageUrl;

  SceneParsing(
      {
      //required this.characterName,
      required this.sceneNumber,
      required this.sceneText,
      required this.prompt,
      required this.imageUrl});

  factory SceneParsing.fromMap(Map<String, dynamic> map) {
    return SceneParsing(
      // characterName: map['Character Name'] ?? '',
      sceneNumber: map['Number'].toString(),
      sceneText: map['Text'] ?? '',
      prompt: map['Prompt'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'Number': sceneNumber,
      'Text': sceneText,
      'Prompt': prompt,
      'imageUrl': imageUrl,
    };
  }

  @override
  String toString() {
    return '$sceneNumber, $sceneText, $prompt';
  }
}
