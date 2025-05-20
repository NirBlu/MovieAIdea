

String extractTitle(String text) {
  RegExp regExp =
      RegExp(r'Title:\s*(.*?)\s*Synopsis:', caseSensitive: false, dotAll: true);
  Match? match = regExp.firstMatch(text);
  if (match != null) {
    final extractedTitle = match.group(1)?.trim();
    if (extractedTitle != null && extractedTitle.isNotEmpty) {
      // Remove '**' from the extracted title
      final cleanedTitle = extractedTitle.replaceAll('**', '');
      // Remove newline characters from the extracted title
      final titleWithoutNewlines = cleanedTitle.replaceAll('\n', '');
      return titleWithoutNewlines;
    }
  }
  print('Title extraction failed for text: $text');
  return '';
}

String extractSynopsis(String text) {
  RegExp regExp =
      RegExp(r'Synopsis:\s*(.*)', caseSensitive: false, dotAll: true);
  Match? match = regExp.firstMatch(text);
  if (match != null) {
    final extractedSynopsis = match.group(1)?.trim();
    if (extractedSynopsis != null && extractedSynopsis.isNotEmpty) {
      // Remove '**' from the extracted synopsis
      final cleanedSynopsis = extractedSynopsis.replaceAll('**', '');
      return cleanedSynopsis;
    }
  }
  print('Synopsis extraction failed for text: $text');
  return '';
}

String extractBeginning(String text) {
  RegExp regExp = RegExp(
    r'\*\*Beginning:\*\*\s*(.*?)\s*(?=\*\*)',
    caseSensitive: false,
    dotAll: true,
  );
  Match? match = regExp.firstMatch(text);
  if (match != null) {
    final extractedBeginning = match.group(1)?.trim();
    if (extractedBeginning != null && extractedBeginning.isNotEmpty) {
      return extractedBeginning.trim();
    }
  }
  print('Beginning extraction failed for text: $text');
  return '';
}

String extractInitialIncident(String text) {
  RegExp regExp = RegExp(
    r'\*\*Initial Incident:\*\*\s*(.*?)\s*(?=\*\*)',
    caseSensitive: false,
    dotAll: true,
  );
  Match? match = regExp.firstMatch(text);
  if (match != null) {
    final extractedInitalIncident = match.group(1)?.trim();
    if (extractedInitalIncident != null && extractedInitalIncident.isNotEmpty) {
      return extractedInitalIncident.trim();
    }
  }
  print('Initial Incident extraction failed for text: $text');
  return '';
}

String extractRisingAction(String text) {
  RegExp regExp = RegExp(
    r'\*\*Rising Action:\*\*\s*(.*?)\s*(?=\*\*)',
    caseSensitive: false,
    dotAll: true,
  );
  Match? match = regExp.firstMatch(text);
  if (match != null) {
    final extractedRiseingAction = match.group(1)?.trim();
    if (extractedRiseingAction != null && extractedRiseingAction.isNotEmpty) {
      return extractedRiseingAction.trim();
    }
  }
  print('Rising Action extraction failed for text: $text');
  return '';
}

String extractClimax(String text) {
  RegExp regExp = RegExp(
    r'\*\*Climax:\*\*\s*(.*?)\s*(?=\*\*)',
    caseSensitive: false,
    dotAll: true,
  );
  Match? match = regExp.firstMatch(text);
  if (match != null) {
    final extractedClimax = match.group(1)?.trim();
    if (extractedClimax != null && extractedClimax.isNotEmpty) {
      return extractedClimax.trim();
    }
  }
  print('Climax extraction failed for text: $text');
  return '';
}

String extractFallingAction(String text) {
  RegExp regExp = RegExp(
    r'\*\*Falling Action:\*\*\s*(.*?)\s*(?=\*\*)',
    caseSensitive: false,
    dotAll: true,
  );
  Match? match = regExp.firstMatch(text);
  if (match != null) {
    final extractedFallingAction = match.group(1)?.trim();
    if (extractedFallingAction != null && extractedFallingAction.isNotEmpty) {
      return extractedFallingAction.trim();
    }
  }
  print('Falling Action extraction failed for text: $text');
  return '';
}

String extractResolution(String text) {
  RegExp regExp = RegExp(
    r'\*\*Resolution:\*\*\s*(.*?)\s*(?=\*\*)',
    caseSensitive: false,
    dotAll: true,
  );
  Match? match = regExp.firstMatch(text);
  if (match != null) {
    final extractedResolution = match.group(1)?.trim();
    if (extractedResolution != null && extractedResolution.isNotEmpty) {
      return extractedResolution.trim();
    }
  }
  print('Resolution extraction failed for text: $text');
  return '';
}

String extractEnding(String text) {
  RegExp regExp = RegExp(
    r'\*\*End:\*\*\s*(.*?)\s*(?=\*\*|$)',
    caseSensitive: false,
    dotAll: true,
  );
  Match? match = regExp.firstMatch(text);
  if (match != null) {
    final extractedEnding = match.group(1)?.trim();
    if (extractedEnding != null && extractedEnding.isNotEmpty) {
      return extractedEnding;
    }
  }
  print('Ending extraction failed for text: $text');
  return '';
}

String extractSection2(String sectionName, String text) {
  // Escape the section name to handle any special regex characters
  String escapedSectionName = RegExp.escape(sectionName);

  RegExp regExp = RegExp(
    '$escapedSectionName:\\s*((?:.|\n)*?)(?:\n\\s*\n|)',
    caseSensitive: false,
    dotAll: true,
  );

  Match? match = regExp.firstMatch(text);
  if (match != null) {
    final extractedSynopsis = match.group(1)?.trim();
    if (extractedSynopsis != null && extractedSynopsis.isNotEmpty) {
      // Remove '**' from the extracted synopsis
      final cleanedSynopsis = extractedSynopsis.replaceAll('**', '');
      return cleanedSynopsis;
    }
  }
  print('$sectionName extraction failed for text: $text');
  return '';
}

void extractSections(String text) {
  Map<String, String> sections = {
    'Beginning': '',
    'Initial Incident': '',
    'Rising Action': '',
    'Climax': '',
    'Falling Action': '',
    'Resolution': '',
    'Ending': '',
  };

  sections.forEach((sectionName, _) {
    sections[sectionName] = extractSection(sectionName, text);
  });

  String beginning = sections['Beginning']!;
  String initialIncident = sections['Initial Incident']!;
  String risingAction = sections['Rising Action']!;
  String climax = sections['Climax']!;
  String fallingAction = sections['Falling Action']!;
  String resolution = sections['Resolution']!;
  String ending = sections['Ending']!;

  print('Beginning: $beginning');
  print('Initial Incident: $initialIncident');
  print('Rising Action: $risingAction');
  print('Climax: $climax');
  print('Falling Action: $fallingAction');
  print('Resolution: $resolution');
  print('Ending: $ending');
}

String extractSection(String sectionName, String text) {
  String escapedSectionName = RegExp.escape(sectionName);

  RegExp regExp = RegExp(
    '$escapedSectionName:\\s*((?:.|\n)*?)(?:\n\\s*\n|)',
    caseSensitive: false,
    dotAll: true,
  );

  Match? match = regExp.firstMatch(text);
  if (match != null) {
    final extractedSynopsis = match.group(1)?.trim();
    if (extractedSynopsis != null && extractedSynopsis.isNotEmpty) {
      final cleanedSynopsis = extractedSynopsis.replaceAll('**', '');
      return cleanedSynopsis;
    }
  }
  print('$sectionName extraction failed for text: $text');
  return '';
}
