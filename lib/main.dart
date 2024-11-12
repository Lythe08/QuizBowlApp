import 'dart:io';
import 'dart:math';
import 'dart:async';
import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:text_analysis/text_analysis.dart';
import 'dart:convert';
import 'dart:math';

//Written by Lysander Pineapple

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => SettingsModel(),
      child: MyApp(),
    ),
  );
  Question.loadJsonAsset();
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  dynamic colorScheme = ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 52, 193, 221));
  dynamic darkScheme = ColorScheme.fromSeed(seedColor: const Color.fromRGBO(255, 52, 193, 221), brightness: Brightness.dark);
  dynamic color = ColorScheme.fromSeed(seedColor: Colors.cyan.shade400);

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsModel>();

    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Trivia Practice',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: settings.darkMode ? darkScheme : colorScheme,
        ),
        home: MyHomePage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var favorites = [];

  void toggleFavorite(dynamic stuff) {
    if (favorites.contains(stuff)) {
      favorites.remove(stuff);
    } else {
      favorites.add(stuff);
    }
    notifyListeners();
  }
}

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsModel>();
    final appthingy = context.watch<MyAppState>();

    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          // Toggle Dark Mode Switch
          ListTile(
            title: Text('Dark Mode'),
            trailing: Switch(
              value: settings.darkMode,
              onChanged: (value) {
                settings.setDarkMode(value);
              },
            ),
          ),

          Divider(),

          // Slider for Text Size
          ListTile(
            title: Text('Text Size'),
            subtitle: Slider(
              value: settings.textSize,
              min: 10.0,
              max: 30.0,
              divisions: 20,
              label: '${settings.textSize.round()}',
              onChanged: (value) {
                settings.setTextSize(value);
              },
            ),
          ),

          Divider(),

          // Toggle Notifications
          ListTile(
            title: Text('Notifications'),
            trailing: Switch(
              value: settings.notificationsEnabled,
              onChanged: (value) {
                settings.setNotificationsEnabled(value);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Settings Model to manage state within the session
class SettingsModel with ChangeNotifier {
  bool _darkMode = false;
  double _textSize = 16.0;
  bool _notificationsEnabled = true;

  bool get darkMode => _darkMode;
  double get textSize => _textSize;
  bool get notificationsEnabled => _notificationsEnabled;

  void setDarkMode(bool value) {
    _darkMode = value;
    notifyListeners();
  }

  void setTextSize(double value) {
    _textSize = value;
    notifyListeners();
  }

  void setNotificationsEnabled(bool value) {
    _notificationsEnabled = value;
    notifyListeners();
  }
}
// ...

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = GeneratorPage();
        break;
      case 1:
        page = FavoritesPage();
        break;
      case 2:
        page = SettingsPage();
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }
    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        body: Row(
          children: [
            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: page,
              ),
            ),
          ],
        ),
        bottomNavigationBar: Container(
          color: Colors.black,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 40.0, vertical: 2.0),
            child: GNav(
              backgroundColor: Colors.black,
              color: Colors.grey[600],
              activeColor: Colors.white,
              padding: EdgeInsets.all(16),
              onTabChange: (index) {
                print(index);
                setState(() {
                  selectedIndex = index;
                });
              },
              tabs: const [
                GButton(icon: Icons.home),
                GButton(icon: Icons.grade),
                GButton(icon: Icons.settings),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class GeneratorPage extends StatefulWidget {
  @override
  State<GeneratorPage> createState() => _GeneratorPageState();
}

class _GeneratorPageState extends State<GeneratorPage> {
  final _textController = TextEditingController();
  dynamic questionStuff = null;
  String questionText = "";
  String userInput = "";
  String _displayedText = "";
  int currentWordIndex = 0;
  Timer? _timer;
  Color buttonColor = Colors.white;
  final FocusNode _focusNode = FocusNode();
  int points = 0;
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Add a listener to detect when the text field gains or loses focus
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _timer?.cancel();
      } else {
        startTyping();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    IconData icon;
    if (appState.favorites.contains(questionStuff)) {
      icon = Icons.turned_in;
    } else {
      icon = Icons.turned_in_not;
    }

    return Stack(
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Question(question: _displayedText),
            SizedBox(height: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    appState.toggleFavorite(questionStuff);
                  },
                  // icon: Icon(icon),
                  label: Text('Save'),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      if (buttonColor == Colors.red) {
                        _timer?.cancel();
                        _displayedText =
                            '${"Correct Answer: "}, ${questionStuff["answer_sanitized"]}';
                        buttonColor = Colors.white;
                      } else {
                        buttonColor = Colors.white;
                        questionStuff = Question.getRandomQuestion();
                        questionText = questionStuff["question"];
                        _timer?.cancel();
                        _displayedText = "";
                        currentWordIndex = 0;
                        startTyping();
                      }
                    });
                  },
                  child: Text('Next'),
                ),
              ],
            ),
            TextField(
              focusNode: _focusNode,
              controller: _textController,
              decoration: InputDecoration(
                  hintText: 'Answer',
                  contentPadding: EdgeInsets.symmetric(horizontal: 10.0),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                      onPressed: () {
                        _textController.clear();
                      },
                      icon: Icon(Icons.clear))),
            ),
            Row(mainAxisSize: MainAxisSize.min, children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: buttonColor),
                onPressed: () {
                  userInput = _textController.text;
                  //check if in answer
                  var answer = questionStuff["answer_sanitized"];
                  var lowerAnswer = answer.toLowerCase();
                  print(answer);
                  print(userInput);
                  int numCorrect = 0;

                  var splitAnswer = userInput
                      .toLowerCase()
                      .split(' '); //list of words in user answer
                  var splitCorrect =
                      lowerAnswer.split(' '); //list of words in correct ansewr

                  var indexList =
                      []; //list of indices in splitCorrect where 1st string in splitAnswer matches string in splitCorrect
                  for (int i = 0; i < splitCorrect.length; i++) {
                    var comparison =
                        TermSimilarity(splitAnswer[0], splitCorrect[i]);
                    print("edit distance for correct answer index $i:");
                    print(comparison.editDistance / splitAnswer[0].length);
                    if (comparison.editDistance / splitAnswer[0].length <= .25)
                      indexList.add(i);
                  }

                  var correct;
                  for (int k = 0; k < indexList.length; k++) {
                    //going through each index where user's 1st string matches string in answer
                    print("index in outer loop: $k");
                    for (int l = 0; l < splitAnswer.length; l++) {
                      //goes through the list of users answer string
                      var comparison = TermSimilarity(
                          splitAnswer[l], splitCorrect[indexList[k] + l]);
                      print("edit distance for user input index $l:");
                      print(comparison.editDistance / splitAnswer[l].length);
                      print(
                          "user input: ${splitAnswer[l]} || correct: ${splitCorrect[indexList[k] + l]}");
                      if (comparison.editDistance / splitAnswer[l].length > .25)
                        correct = false;
                      else
                        correct = true;
                      // //going through user answer strings
                      // //checking with corresponding following string in correct answer
                      // if (splitAnswer[l] != splitCorrect[k + l])
                      //   allCorrect = false;

                      if (correct)
                        numCorrect++; //if all strings in user answer match strings in correct strings
                      correct = true; //reset
                    }
                  }
                  print(numCorrect);
                  if (numCorrect >= splitAnswer.length * .75) {
                    print("CORRECT ANSWER!");
                    setState(() {
                      buttonColor = Colors.green;
                      points += 10;
                      _textController.clear();
                    });
                  } else {
                    print("WRONG");
                    setState(() {
                      buttonColor = Colors.red;
                      if (points >= 1) points -= 1;
                      _textController.clear();
                    });
                  }
                },
                child: Text('Submit'),
              ),
            ]),
          ],
        ),
        Positioned(
          top: 20,
          right: 20,
          child: Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blueAccent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Points: ${points}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void startTyping() {
    List<String> words = questionText.split(' ');

    _timer = Timer.periodic(Duration(milliseconds: 125), (timer) {
      if (currentWordIndex < words.length) {
        setState(() {
          if (words[currentWordIndex].contains("<") ||
              words[currentWordIndex].contains(">")) {
            words[currentWordIndex] =
                words[currentWordIndex].replaceAll("</b>", "");
            words[currentWordIndex] =
                words[currentWordIndex].replaceAll("<b>", "");
            words[currentWordIndex] =
                words[currentWordIndex].replaceAll("</i>", "");
            words[currentWordIndex] =
                words[currentWordIndex].replaceAll("<i>", "");
          }
          _displayedText +=
              (currentWordIndex == 0 ? "" : " ") + words[currentWordIndex];
          currentWordIndex++;
        });
      } else {
        // _displayedText = "";
        // currentWordIndex = 0;
        _timer?.cancel(); // Stop the timer once all words are displayed
      }
    });
  }
}

// ...

class Question extends StatefulWidget {
  static dynamic tossups = null;
  static var rng = Random();
  String question;
  Question({required this.question});

  @override
  State<Question> createState() => _QuestionState();

  static Map getRandomQuestion() {
    return tossups[rng.nextInt(200)];
  }

  static void loadJsonAsset() async {
    final String jsonString = await rootBundle.loadString('assets/data.json');
    final Map dataList = jsonDecode(jsonString);
    tossups = dataList["tossups"];
    // return tossups;
  }
}

class _QuestionState extends State<Question> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Text(
        widget.question,
        style: TextStyle(height: 2.5, fontSize: 13.0),
      ),
    );
  }
}

class FavoritesPage extends StatelessWidget {
  @override
  static String sanitizeQuestion(dynamic question) {
    List<String> words = question["question"].split(' ');
    String text = "";
    for (int currentWordIndex = 0;
        currentWordIndex < words.length;
        currentWordIndex++) {
      if (words[currentWordIndex].contains("<") ||
          words[currentWordIndex].contains(">")) {
        words[currentWordIndex] =
            words[currentWordIndex].replaceAll("</b>", "");
        words[currentWordIndex] = words[currentWordIndex].replaceAll("<b>", "");
        words[currentWordIndex] =
            words[currentWordIndex].replaceAll("</i>", "");
        words[currentWordIndex] = words[currentWordIndex].replaceAll("<i>", "");
      }
      text += (currentWordIndex == 0 ? "" : " ") + words[currentWordIndex];
      currentWordIndex++;
    }
    return text;
  }

  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    if (appState.favorites.isEmpty) {
      return Center(child: Text('No saved questions yet.'));
    }

    return ListView(
      children: [
        Padding(
          padding: EdgeInsets.all(10),
          child: Text('Saved Questions:',
              style: TextStyle(height: 3.0, fontSize: 20)),
        ),
        for (dynamic question in appState.favorites)
          ListTile(
            title: Text(question["answer_sanitized"]),
            contentPadding: EdgeInsets.all(10),
            subtitle: Text(sanitizeQuestion(question)),
          ),
      ],
    );
  }
}
