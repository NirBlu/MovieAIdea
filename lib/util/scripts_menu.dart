

import 'package:flutter/material.dart';
//import 'package:movie_aidea/screens/all_in_one_screen.dart';
//import 'package:movie_aidea/screens/script_section_screen.dart';
import 'package:http/http.dart' as http;
//import 'package:movie_aidea/util/app_const.dart';
import 'dart:convert';
import 'package:movie_aidea/widget/script_button.dart';

Future<List<ScriptButton>> loadScripts(BuildContext context) async {
  final url = Uri.https(
      'frameforge-7288a-default-rtdb.firebaseio.com', '/scripts.json');
  final response = await http.get(url);
  final Map<String, dynamic> scriptList = json.decode(response.body);

  // Use map() with null-aware operators to handle potential null values
  return scriptList.entries.map((item) {
    final title = item.value['title'] as String?;
    //final moviekey = item.value['name'] as String?;
    return ScriptButton(
      title: title ?? 'No Title', // Default to 'No Title' if title is null
      onPressed: () {},
      onDeleted: () {},
    );
  }).toList();
}
