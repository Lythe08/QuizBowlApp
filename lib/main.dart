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
  // Question.loadJsonAsset();
  runApp(MyApp());
  Question.loadJsonAsset();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Trivia Practice',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.cyan.shade400),
        ),
        home: MyHomePage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var favorites = [];

  void toggleFavorite(int add) {
    if (favorites.contains(add)) {
      favorites.remove(add);
    } else {
      favorites.add(add);
    }
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
        page = Placeholder();
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
  String displayedText = "";
  int currentWordIndex = 0;
  Timer? _timer;

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    IconData icon;
    // if (appState.favorites.contains(pair)) {
    //   icon = Icons.turned_in;
    // } else {
    //   icon = Icons.turned_in_not;
    // }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Question(question: displayedText),
          SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  appState.toggleFavorite(0);
                },
                // icon: Icon(icon),
                label: Text('Save'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    questionStuff = Question.getRandomQuestion();
                    questionText = questionStuff["question"];
                    _timer?.cancel();
                    displayedText = "";
                    currentWordIndex = 0;
                    startTyping();
                  });
                },
                child: Text('Next'),
              ),
            ],
          ),
          TextField(
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
              onPressed: () {
                userInput = _textController.text;
                //check if in answer
                var answer = questionStuff["answer_sanitized"];
                var lowerAnswer = answer.toLowerCase();
                print(answer);
                print(userInput);
                
                var splitAnswer = userInput
                    .toLowerCase()
                    .split(' '); //list of words in user answer
                var splitCorrect =
                    lowerAnswer.split(' '); //list of words in correct ansewr

                var indexList =
                    []; //list of indices in splitCorrect where 1st string in splitAnswer matches string in splitCorrect
                for (int i = 0; i < splitCorrect.length; i++) {
                  if (splitCorrect[i] == splitAnswer[0]) indexList.add(i);
                }
                if (splitAnswer.length == 1) {
                  if (indexList.length > 0)
                    print("answer is correct!");
                  else
                    print("answer is incorrect!");
                } else {
                  var correct = true;
                  int numCorrect = 0;
                  for (int k = 0; k < indexList.length; k++) {
                    //going through each index where user's 1st string matches string in answer
                    for (int l = 1; l < splitAnswer.length; l++) {
                      var comparison = TermSimilarity(splitAnswer[l], splitCorrect[k+l]);
                      if (comparison.editSimilarity > 1) correct = false;
                      // //going through user answer strings
                      // //checking with corresponding following string in correct answer
                      // if (splitAnswer[l] != splitCorrect[k + l])
                      //   allCorrect = false;

                    }
                    if (correct)
                      numCorrect++; //if all strings in user answer match strings in correct strings
                    correct = true; //reset
                  }
                  print(numCorrect);
                  if (numCorrect == splitAnswer.length)
                    print("CORRECT ANSWER!");
                  else
                    print("WRONG");
                }
              },
              child: Text('Submit'),
            ),
          ]),
        ],
      ),
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
          displayedText +=
              (currentWordIndex == 0 ? "" : " ") + words[currentWordIndex];
          currentWordIndex++;
        });
      } else {
        displayedText = "";
        currentWordIndex = 0;
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
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    if (appState.favorites.isEmpty) {
      return Center(child: Text('No saved questions yet.'));
    }

    return ListView(
      children: [
        Padding(
          padding: EdgeInsets.all(20),
          child: Text('You have ${appState.favorites.length} saved questions:'),
        ),
        for (var pair in appState.favorites)
          ListTile(
            leading: Icon(Icons.favorite),
            title: Text(pair.asLowerCase),
          ),
      ],
    );
  }
}
