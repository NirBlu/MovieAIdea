
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:movie_aidea/util/parse_character.dart';
import 'package:movie_aidea/util/parse_scenes.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

Future<void> createPdf(
    List<Map<String, dynamic>> scenes,
    List<Map<String, dynamic>> characters,
    String title,
    String synopsis) async {
  final pdf = pw.Document();

  // Load the custom font
  final fontData = await rootBundle.load('assets/fonts/NotoSans.ttf');
  final ttf = pw.Font.ttf(fontData);

  // Fetch character images asynchronously
  await Future.wait(characters.map((character) async {
    if (character['imageUrl'] != null && character['imageUrl'].isNotEmpty) {
      try {
        final imageBytes = await networkImage(character['imageUrl']);
        character['imageBytes'] = imageBytes;
        print('Fetched character image: ${character['imageUrl']}');
      } catch (e) {
        character['imageBytes'] = null;
        print(
            'Failed to load character image: ${character['imageUrl']}, Error: $e');
      }
    }
  }));

  // Fetch scene images asynchronously
  await Future.wait(scenes.map((scene) async {
    if (scene['imageUrl'] != null && scene['imageUrl'].isNotEmpty) {
      try {
        final imageBytes = await networkImage(scene['imageUrl']);
        scene['imageBytes'] = imageBytes;
        print('Fetched scene image: ${scene['imageUrl']}');
      } catch (e) {
        scene['imageBytes'] = null;
        print('Failed to load scene image: ${scene['imageUrl']}, Error: $e');
      }
    }
  }));

  // Debugging: Print character and scene details
  for (var character in characters) {
    print(
        'Character: ${character['Name']}, Image Bytes: ${character['imageBytes'] != null ? character['imageBytes'].length : 'None'}');
  }
  for (var scene in scenes) {
    print(
        'Scene: ${scene['Number']}, Image Bytes: ${scene['imageBytes'] != null ? scene['imageBytes'].length : 'None'}, Text: ${scene['Text']}');
  }

  // Add movie title and synopsis page
  pdf.addPage(
    pw.Page(
      build: (pw.Context context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Align(
            alignment: pw.Alignment.center,
            child: pw.Text(title, style: pw.TextStyle(fontSize: 24, font: ttf)),
          ),
          pw.SizedBox(height: 10),
          pw.Text(synopsis, style: pw.TextStyle(fontSize: 12, font: ttf)),
          pw.SizedBox(height: 20),
        ],
      ),
    ),
  );

  // Add characters page
  pdf.addPage(
    pw.MultiPage(
      build: (pw.Context context) => [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Align(
              alignment: pw.Alignment.center,
              child: pw.Text('Characters',
                  style: pw.TextStyle(fontSize: 24, font: ttf)),
            ),
            pw.SizedBox(height: 10),
            ...characters.map((character) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  pw.Align(
                    alignment: pw.Alignment.center,
                    child: pw.Text('Name: ${character['Name']}',
                        style: pw.TextStyle(fontSize: 12, font: ttf)),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Divider(),
                  if (character['Looks'] != null &&
                      character['Looks'].isNotEmpty)
                    pw.Align(
                      alignment: pw.Alignment.center,
                      child: pw.Text('Looks: ${character['Looks']}',
                          style: pw.TextStyle(fontSize: 12, font: ttf)),
                    ),
                  pw.SizedBox(height: 10),
                  pw.Divider(),
                  if (character['BGStory'] != null &&
                      character['BGStory'].isNotEmpty)
                    pw.Align(
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                          'Background Story: ${character['BGStory']}',
                          style: pw.TextStyle(fontSize: 12, font: ttf)),
                    ),
                  pw.SizedBox(height: 10),
                  pw.Divider(),
                  if (character['Motivation'] != null &&
                      character['Motivation'].isNotEmpty)
                    pw.Align(
                      alignment: pw.Alignment.center,
                      child: pw.Text('Motivation: ${character['Motivation']}',
                          style: pw.TextStyle(fontSize: 12, font: ttf)),
                    ),
                  if (character['imageBytes'] != null)
                    pw.Container(
                      alignment: pw.Alignment.center,
                      height: 200,
                      child: pw.Image(pw.MemoryImage(character['imageBytes'])),
                    ),
                  pw.SizedBox(height: 20),
                ],
              );
            }).toList(),
          ],
        ),
      ],
    ),
  );

  // Add scenes pages
  for (var scene in scenes) {
    await processScene(pdf, scene, ttf);
  }

  final output = await getTemporaryDirectory();
  final file = File('${output.path}/$title.pdf');
  await file.writeAsBytes(await pdf.save());
  await Printing.sharePdf(bytes: await pdf.save(), filename: '$title.pdf');
}

Future<void> processScene(
    pw.Document pdf, Map<String, dynamic> scene, pw.Font ttf) async {
  Uint8List? sceneImageBytes = scene['imageBytes'];

  pdf.addPage(
    pw.Page(
      build: (pw.Context context) {
        print('Adding Scene: ${scene['Number']}');
        print('Scene Text: ${scene['Text']}');
        print(
            'Scene Image Bytes: ${sceneImageBytes != null ? sceneImageBytes.length : 'None'}');

        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Align(
              alignment: pw.Alignment.center,
              child: pw.Text('Scene Number: ${scene['Number']}',
                  style: pw.TextStyle(fontSize: 12, font: ttf)),
            ),
            pw.SizedBox(height: 10),
            pw.Divider(),
            pw.Container(
              alignment: pw.Alignment.center,
              child: pw.Text('Description: ${scene['Prompt']}',
                  style: pw.TextStyle(fontSize: 8, font: ttf)),
            ),
            pw.SizedBox(height: 10),
            pw.Divider(),
            if (scene['Text'] != null && scene['Text'].isNotEmpty)
              pw.Align(
                alignment: pw.Alignment.center,
                child: pw.Text(' ${scene['Text']}',
                    style: pw.TextStyle(fontSize: 6, font: ttf),
                    textAlign: pw.TextAlign.center),
              ),
            if (sceneImageBytes != null) ...[
              pw.SizedBox(height: 20),
              pw.Container(
                alignment: pw.Alignment.center,
                height: 200,
                child: pw.Image(pw.MemoryImage(sceneImageBytes)),
              ),
            ],
            pw.SizedBox(height: 20),
          ],
        );
      },
    ),
  );
}

Future<Uint8List> networkImage(String url) async {
  final response = await http.get(Uri.parse(url));
  if (response.statusCode == 200) {
    return response.bodyBytes;
  } else {
    throw Exception('Failed to load image from $url');
  }
}

// Example usage
Future<void> saveScenesAndCharactersToPdf(String title, String synopsis,
    List<SceneParsing> scenes, List<Character> characters) async {
  List<Map<String, dynamic>> scenesAsMap =
      scenes.map((scene) => scene.toMap()).toList();
  List<Map<String, dynamic>> charactersAsMap =
      characters.map((character) => character.toMap()).toList();

  await createPdf(scenesAsMap, charactersAsMap, title, synopsis);
}
