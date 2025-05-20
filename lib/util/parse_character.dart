

class Character {
  //final String characterName;
  String name;
  String looks;
  String bgStory;
  String motivation;
  String imageUrl;

  Character(
      {
      //required this.characterName,
      required this.name,
      required this.looks,
      required this.bgStory,
      required this.motivation,
      required this.imageUrl});

  factory Character.fromMap(Map<String, dynamic> map) {
    // Assigning map values to local variables first
    final name = map['Name'] ?? '';
    final String looks = map['Looks'] ?? '';
    final String bgStory = map['BGStory'] ?? '';
    final String motivation = map['Motivation'] ?? '';
    final String imageUrl = map['imageUrl'] ?? '';

    return Character(
      name: name,
      looks: looks,
      bgStory: bgStory,
      motivation: motivation,
      imageUrl: imageUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'Name': name,
      'Looks': looks,
      'BGStory': bgStory,
      'Motivation': motivation,
      'imageUrl': imageUrl,
    };
  }

  @override
  String toString() {
    return 'Character(name: $name, looks: $looks, bgStory: $bgStory, motivation: $motivation)';
  }
}
