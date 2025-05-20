

const String apiKey = "Place You Gemini APIKey Here";
const String geminiModel = "gemini-pro";
const String geminiVisionModel = "gemini-pro-vision";

enum Stage {
  start,
  first,
  second,
  third,
  complete,
  makeSinopsisChanges,
  mainEvent,
  characters,
  openingScene,
  endingScene,
  secondartEvents,
  fillGaps,
}
