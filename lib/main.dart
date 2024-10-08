import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart' show rootBundle;
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
  var current = WordPair.random();

  void getNext() {
    current = WordPair.random();
    notifyListeners();
  }

  var favorites = <WordPair>[];

  void toggleFavorite() {
    if (favorites.contains(current)) {
      favorites.remove(current);
    } else {
      favorites.add(current);
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
  String questionText = "";
  String userInput = "";

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var pair = appState.current;

    IconData icon;
    if (appState.favorites.contains(pair)) {
      icon = Icons.turned_in;
    } else {
      icon = Icons.turned_in_not;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Question(question: questionText),
          SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  appState.toggleFavorite();
                },
                icon: Icon(icon),
                label: Text('Save'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    questionText = Question.getRandomQuestion();
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
                print("buzzed");
              },
              child: Text('Buzz'),
            ),
          ]),
        ],
      ),
    );
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

  static String getRandomQuestion() {
    return tossups[rng.nextInt(200)]["question"];
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
    return Text(
      widget.question,
      style: TextStyle(height: 5, fontSize: 10),
      semanticsLabel: "q",
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
