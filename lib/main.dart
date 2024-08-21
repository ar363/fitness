import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:relative_time/relative_time.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:uuid/uuid.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox("settings");
  await Hive.openBox("workouts");
  runApp(const MyApp());
}

enum WorkoutType {
  walking,
  running,
  cycling,
  swimming,
  yoga,
  benchPress,
  deadlift,
  squat,
  pullUpOrPushUp,
}

const workoutTypeData = {
  WorkoutType.walking: {
    'name': 'Walking',
    'icon': Icons.directions_walk,
  },
  WorkoutType.running: {
    'name': 'Running',
    'icon': Icons.directions_run,
  },
  WorkoutType.cycling: {
    'name': 'Cycling',
    'icon': Icons.directions_bike,
  },
  WorkoutType.swimming: {
    'name': 'Swimming',
    'icon': Icons.pool,
  },
  WorkoutType.yoga: {
    'name': 'Yoga',
    'icon': Icons.self_improvement,
  },
  WorkoutType.benchPress: {
    'name': 'Bench Press',
    'icon': Icons.fitness_center,
  },
  WorkoutType.deadlift: {
    'name': 'Deadlift',
    'icon': Icons.fitness_center,
  },
  WorkoutType.pullUpOrPushUp: {
    'name': 'Pull-ups / Push-ups',
    'icon': Icons.fitness_center,
  },
};

String formatRelativeDateTime(String datetime) {
  final dt = DateTime.parse(datetime);
  return RelativeTime.locale(const Locale('en')).format(dt);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      routes: {
        '/': (context) => const MyHomePage(title: 'Fitness Tracker'),
        '/addWorkout': (context) =>
            const AddWorkoutPage(title: 'Add Workout', isEdit: false),
        '/editWorkout': (context) =>
            const AddWorkoutPage(title: 'View/Edit Workout', isEdit: true),
        '/stats': (context) => const StatsPage(title: 'Stats'),
      },
      initialRoute: '/',
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

var uuid = const Uuid();
String generateRandomId() {
  return uuid.v4();
}

Map<String, int> getWorkoutGoals() {
  const calorieGoals = 2500;
  const countGoals = 5;

  return {
    'calories': calorieGoals,
    'count': countGoals,
  };
}

class _MyHomePageState extends State<MyHomePage> {
  String _name = '';
  String _greeting = '';
  bool _nameNotSet = true;
  List _workouts = [];
  final Map<String, int> _goals = getWorkoutGoals();
  Map _todaysProgress = {
    'calories': 0,
    'count': 0,
  };

  void _setName(String name) {
    setState(() {
      _name = name;
    });
  }

  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    }
    if (hour < 17) {
      return 'Good afternoon';
    }
    return 'Good evening';
  }

  void _saveName() async {
    await Hive.box("settings").put('name', _name);

    setState(() {
      _nameNotSet = false;
    });
  }

  void _getName() async {
    final name = Hive.box("settings").get("name");

    setState(() {
      _name = name ?? '';
      _nameNotSet = (name is String && name.isNotEmpty) ? false : true;
    });
  }

  void _getWorkouts() async {
    var docs = Hive.box("workouts").toMap();

    var sortedDocs = [];

    for (var docid in docs.keys) {
      sortedDocs.add({
        'id': docid,
        ...docs[docid],
        'typeinfo': workoutTypeData[WorkoutType.values.firstWhere((element) =>
            element.toString() == 'WorkoutType.${docs[docid]['type']}')]
      });
    }

    sortedDocs.sort((a, b) =>
        DateTime.parse(b['datetime']).compareTo(DateTime.parse(a['datetime'])));

    setState(() {
      _workouts = sortedDocs;
    });

    _calculateTodaysProgress();
  }

  void _calculateTodaysProgress() {
    var todaysWorkouts = _workouts.where((workout) {
      final workoutDate = DateTime.parse(workout['datetime']);
      final now = DateTime.now();
      return workoutDate.year == now.year &&
          workoutDate.month == now.month &&
          workoutDate.day == now.day;
    });

    var caloriesBurned = 0;
    var count = 0;

    for (var workout in todaysWorkouts) {
      caloriesBurned += workout['caloriesBurned'] as int;
      count += 1;
    }

    setState(() {
      _todaysProgress = {
        'calories': caloriesBurned,
        'count': count,
      };
    });
  }

  @override
  void initState() {
    super.initState();

    setState(() {
      _greeting = _getGreeting();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getName();
      _getWorkouts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        title: Text(widget.title),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Text(
                'Fitness Tracker',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              title: const Text('Home'),
              leading: const Icon(Icons.home),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Add workout'),
              leading: const Icon(Icons.add),
              onTap: () {
                Navigator.pushNamed(context, '/addWorkout')
                    .then((_) => {_getWorkouts()});
              },
            ),
            ListTile(
              title: const Text('Stats'),
              leading: const Icon(Icons.bar_chart),
              onTap: () {
                Navigator.pushNamed(context, '/stats');
              },
            ),
          ],
        ),
      ),
      body: (_nameNotSet)
          ? Center(
              child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextField(
                        onChanged: (value) {
                          _setName(value);
                        },
                        decoration: const InputDecoration(
                          labelText: 'Please enter your name to Sign Up',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: () {
                          _saveName();
                        },
                        child: const Text('Sign Up'),
                      ),
                    ],
                  )))
          : Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '$_greeting, $_name!',
                    style: const TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text.rich(
                    TextSpan(
                      text: '${_todaysProgress['calories']}',
                      style: Theme.of(context).textTheme.headlineMedium,
                      children: [
                        TextSpan(
                          text:
                              '   / ${_goals['calories']} calories burnt today',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  LinearProgressIndicator(
                    value: _todaysProgress['calories'] > _goals['calories']
                        ? 1
                        : _todaysProgress['calories'] / _goals['calories']!,
                    minHeight: 20,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  const SizedBox(height: 30),
                  Text.rich(
                    TextSpan(
                      text: '${_todaysProgress['count']}',
                      style: Theme.of(context).textTheme.headlineMedium,
                      children: [
                        TextSpan(
                          text: '   / ${_goals['count']} workouts done today',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  LinearProgressIndicator(
                    value: _todaysProgress['count'] > _goals['count']
                        ? 1
                        : _todaysProgress['count'] / _goals['count']!,
                    minHeight: 20,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Past workouts:',
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _workouts.length,
                      itemBuilder: (context, index) {
                        final workout = _workouts[index];
                        return Card(
                          child: ListTile(
                            title: Text(workout['typeinfo']['name'] as String),
                            subtitle: Text(
                                'Calories burned: ${workout['caloriesBurned']}\n${formatRelativeDateTime(workout['datetime'])}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.info),
                              tooltip: "View/edit workout info",
                              onPressed: () {
                                Navigator.of(context)
                                    .push(MaterialPageRoute(
                                        builder: (context) => AddWorkoutPage(
                                              title: 'View/Edit Workout',
                                              isEdit: true,
                                              workout: workout,
                                            )))
                                    .then((_) => {_getWorkouts()});
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: (!_nameNotSet)
          ? FloatingActionButton.extended(
              onPressed: () => {
                Navigator.pushNamed(context, '/addWorkout')
                    .then((_) => {_getWorkouts()})
              },
              icon: const Icon(Icons.add),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              label: const Text("Add workout"),
            )
          : null,
    );
  }
}

class AddWorkoutPage extends StatefulWidget {
  const AddWorkoutPage(
      {super.key, required this.title, required this.isEdit, this.workout});

  final String title;
  final bool isEdit;
  final Map? workout;

  @override
  State<AddWorkoutPage> createState() => _AddWorkoutPageState();
}

class _AddWorkoutPageState extends State<AddWorkoutPage> {
  WorkoutType _workoutType = WorkoutType.walking;
  double _distanceCovered = 0.0;
  int _caloriesBurned = 0;
  int _yogaDuration = 0;
  int _workoutWeight = 0;
  int _workoutReps = 0;
  int _workoutSets = 0;
  String? _currentWorkoutId;

  void _calculateCaloriesBurned() {
    if (_workoutType == WorkoutType.walking) {
      setState(() {
        _caloriesBurned = (_distanceCovered * 50).round();
      });
    } else if (_workoutType == WorkoutType.running) {
      setState(() {
        _caloriesBurned = (_distanceCovered * 100).round();
      });
    } else if (_workoutType == WorkoutType.cycling) {
      setState(() {
        _caloriesBurned = (_distanceCovered * 75).round();
      });
    } else if (_workoutType == WorkoutType.swimming) {
      setState(() {
        _caloriesBurned = (_distanceCovered * 120).round();
      });
    } else if (_workoutType == WorkoutType.yoga) {
      setState(() {
        _caloriesBurned = (_yogaDuration * 5).round();
      });
    } else if (_workoutType == WorkoutType.benchPress ||
        _workoutType == WorkoutType.deadlift ||
        _workoutType == WorkoutType.pullUpOrPushUp) {
      setState(() {
        _caloriesBurned =
            (_workoutWeight * _workoutReps * _workoutSets * 0.5).round();
      });
    }
  }

  Future<void> addWorkout() async {
    String id;
    String dt;
    if (widget.isEdit) {
      id = _currentWorkoutId!;
      dt = widget.workout!['datetime'];
    } else {
      id = generateRandomId();
      dt = DateTime.now().toIso8601String();
    }

    if (_workoutType == WorkoutType.walking ||
        _workoutType == WorkoutType.running ||
        _workoutType == WorkoutType.cycling ||
        _workoutType == WorkoutType.swimming) {
      await Hive.box("workouts").put(id, {
        'datetime': dt,
        'type': _workoutType.name,
        'distanceCovered': _distanceCovered,
        'caloriesBurned': _caloriesBurned,
      });
    } else if (_workoutType == WorkoutType.yoga) {
      await Hive.box("workouts").put(id, {
        'datetime': dt,
        'type': _workoutType.name,
        'duration': _yogaDuration,
        'caloriesBurned': _caloriesBurned,
      });
    } else if (_workoutType == WorkoutType.benchPress ||
        _workoutType == WorkoutType.deadlift ||
        _workoutType == WorkoutType.pullUpOrPushUp) {
      await Hive.box("workouts").put(id, {
        'datetime': dt,
        'type': _workoutType.name,
        'weight': _workoutWeight,
        'reps': _workoutReps,
        'sets': _workoutSets,
        'caloriesBurned': _caloriesBurned,
      });
    }

    if (!mounted) {
      return;
    }
    Navigator.pop(context, true);
  }

  Future<void> dropCurrentWorkout() async {
    await Hive.box("workouts").delete(_currentWorkoutId);

    if (!mounted) {
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  void initState() {
    super.initState();

    if (widget.isEdit) {
      final workout = widget.workout!;
      setState(() {
        _workoutType = WorkoutType.values.firstWhere((element) =>
            element.toString() == 'WorkoutType.' + workout['type']);
        _currentWorkoutId = workout['id'];

        if (_workoutType == WorkoutType.walking ||
            _workoutType == WorkoutType.running ||
            _workoutType == WorkoutType.cycling ||
            _workoutType == WorkoutType.swimming) {
          _distanceCovered = workout['distanceCovered'];
        } else if (_workoutType == WorkoutType.yoga) {
          _yogaDuration = workout['duration'];
        } else if (_workoutType == WorkoutType.benchPress ||
            _workoutType == WorkoutType.deadlift ||
            _workoutType == WorkoutType.pullUpOrPushUp) {
          _workoutWeight = workout['weight'];
          _workoutReps = workout['reps'];
          _workoutSets = workout['sets'];
        }
        _calculateCaloriesBurned();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Text(
                'Fitness Tracker',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              title: const Text('Home'),
              leading: const Icon(Icons.home),
              onTap: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Add workout'),
              leading: const Icon(Icons.add),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Stats'),
              leading: const Icon(Icons.bar_chart),
              onTap: () {
                Navigator.pushNamed(context, '/stats');
              },
            ),
          ],
        ),
      ),
      body: Container(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const Text(
                  'Pick a workout type:',
                ),
                const SizedBox(height: 10),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (var type in workoutTypeData.keys)
                      ActionChip(
                        side: BorderSide(
                          color: _workoutType == type
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.surfaceContainer,
                        ),
                        onPressed: () {
                          setState(() {
                            _workoutType = type;
                          });
                          _calculateCaloriesBurned();
                        },
                        backgroundColor: _workoutType == type
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.surface,
                        label: Text(workoutTypeData[type]!['name'] as String,
                            style: TextStyle(
                                color: _workoutType == type
                                    ? Theme.of(context).colorScheme.surface
                                    : Theme.of(context).colorScheme.primary)),
                        avatar: Icon(
                          workoutTypeData[type]!['icon'] as IconData,
                          color: _workoutType == type
                              ? Theme.of(context).colorScheme.surface
                              : Theme.of(context).colorScheme.primary,
                        ),
                      )
                  ],
                ),
                if (_workoutType == WorkoutType.walking ||
                    _workoutType == WorkoutType.running ||
                    _workoutType == WorkoutType.cycling ||
                    _workoutType == WorkoutType.swimming)
                  Column(
                    children: [
                      const SizedBox(height: 40),
                      const Text('Enter distance covered:'),
                      const SizedBox(height: 10),
                      TextFormField(
                        initialValue: _distanceCovered == 0
                            ? ""
                            : _distanceCovered.toString(),
                        onChanged: (value) => {
                          setState(() {
                            _distanceCovered =
                                double.parse(value.isEmpty ? '0' : value);
                            _calculateCaloriesBurned();
                          })
                        },
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r"[0-9.]")),
                          TextInputFormatter.withFunction((oldValue, newValue) {
                            final text = newValue.text;
                            return text.isEmpty
                                ? newValue
                                : double.tryParse(text) == null
                                    ? oldValue
                                    : newValue;
                          }),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Distance (in km)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  )
                else if (_workoutType == WorkoutType.yoga)
                  Column(
                    children: [
                      const SizedBox(height: 40),
                      const Text('Enter duration (mins):'),
                      const SizedBox(height: 10),
                      TextFormField(
                        initialValue:
                            _yogaDuration == 0 ? "" : _yogaDuration.toString(),
                        onChanged: (value) => {
                          setState(() {
                            _yogaDuration =
                                int.parse(value.isEmpty ? '0' : value);
                            _calculateCaloriesBurned();
                          })
                        },
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r"[0-9]")),
                          TextInputFormatter.withFunction((oldValue, newValue) {
                            final text = newValue.text;
                            return text.isEmpty
                                ? newValue
                                : int.tryParse(text) == null
                                    ? oldValue
                                    : newValue;
                          }),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Duration (in minutes)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  )
                else if (_workoutType == WorkoutType.benchPress ||
                    _workoutType == WorkoutType.deadlift ||
                    _workoutType == WorkoutType.pullUpOrPushUp)
                  Column(
                    children: [
                      const SizedBox(height: 30),
                      const Text('Enter weight:'),
                      const SizedBox(height: 10),
                      TextFormField(
                        initialValue: _workoutWeight == 0
                            ? ""
                            : _workoutWeight.toString(),
                        onChanged: (value) => {
                          setState(() {
                            _workoutWeight =
                                int.parse(value.isEmpty ? '0' : value);
                            _calculateCaloriesBurned();
                          })
                        },
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r"[0-9.]")),
                          TextInputFormatter.withFunction((oldValue, newValue) {
                            final text = newValue.text;
                            return text.isEmpty
                                ? newValue
                                : int.tryParse(text) == null
                                    ? oldValue
                                    : newValue;
                          }),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Weight (in kg)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Text('Enter number of reps:'),
                      const SizedBox(height: 10),
                      TextFormField(
                        initialValue:
                            _workoutReps == 0 ? "" : _workoutReps.toString(),
                        onChanged: (value) => {
                          setState(() {
                            _workoutReps =
                                int.parse(value.isEmpty ? '0' : value);
                            _calculateCaloriesBurned();
                          })
                        },
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r"[0-9]")),
                          TextInputFormatter.withFunction((oldValue, newValue) {
                            final text = newValue.text;
                            return text.isEmpty
                                ? newValue
                                : int.tryParse(text) == null
                                    ? oldValue
                                    : newValue;
                          }),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'No of reps done',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Text('Enter number of sets per rep:'),
                      const SizedBox(height: 10),
                      TextFormField(
                        initialValue:
                            _workoutSets == 0 ? "" : _workoutSets.toString(),
                        onChanged: (value) => {
                          setState(() {
                            _workoutSets =
                                int.parse(value.isEmpty ? '0' : value);
                            _calculateCaloriesBurned();
                          })
                        },
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r"[0-9]")),
                          TextInputFormatter.withFunction((oldValue, newValue) {
                            final text = newValue.text;
                            return text.isEmpty
                                ? newValue
                                : int.tryParse(text) == null
                                    ? oldValue
                                    : newValue;
                          }),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Sets per rep',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 20),
                Text(
                  'Calories burned (calculated): $_caloriesBurned',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),
                SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: FilledButton(
                      onPressed: () async => addWorkout(),
                      style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10))),
                      child:
                          Text(widget.isEdit ? 'Save changes' : 'Add workout'),
                    )),
                const SizedBox(height: 16),
                if (widget.isEdit)
                  SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: FilledButton(
                        onPressed: () async => dropCurrentWorkout(),
                        style: FilledButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.error,
                            foregroundColor:
                                Theme.of(context).colorScheme.onError,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10))),
                        child: const Text('Delete workout'),
                      )),
              ],
            ),
          )),
    );
  }
}

class StatsPage extends StatefulWidget {
  const StatsPage({super.key, required this.title});

  final String title;

  @override
  State<StatsPage> createState() => _StatsPageState();
}

String camelToSentence(String text) {
  var result = text.replaceAll(RegExp(r'(?<!^)(?=[A-Z])'), r" ");
  var finalResult = result[0].toUpperCase() + result.substring(1);
  return finalResult;
}

class _StatsPageState extends State<StatsPage> {
  List _workouts = [];

  void _getWorkouts() {
    var docs = Hive.box("workouts").toMap();

    var filteredDocs = [];

    for (var docid in docs.keys) {
      var dt = DateTime.parse(docs[docid]['datetime']);
      var now = DateTime.now();

      if (now.difference(dt).inDays <= 7) {
        filteredDocs.add({
          'id': docid,
          ...docs[docid],
          'typeinfo': workoutTypeData[WorkoutType.values.firstWhere((element) =>
              element.toString() == 'WorkoutType.${docs[docid]['type']}')]
        });
      }
    }

    setState(() {
      _workouts = filteredDocs;
    });
  }

  List<PieChartSectionData> caloriesSections() {
    List<String> typenames = WorkoutType.values.map((x) => x.name).toList();
    List<int> calories = List.filled(typenames.length, 0);

    for (var workout in _workouts) {
      var index = typenames.indexOf(workout['type']);
      calories[index] += workout['caloriesBurned'] as int;
    }

    List<PieChartSectionData> sections = [];

    for (var i = 0; i < typenames.length; i++) {
      Color color = Colors.white;
      switch (i) {
        case 0:
          color = Colors.teal;
          break;
        case 1:
          color = Colors.purple;
          break;
        case 2:
          color = Colors.blue;
          break;
        case 3:
          color = Colors.yellow;
          break;
        case 4:
          color = Colors.green;
          break;
        case 5:
          color = Colors.orange;
          break;
        case 6:
          color = Colors.pink;
          break;
        case 7:
          color = Colors.red;
          break;
        case 8:
          color = Colors.indigo;
          break;
      }
      String realTypeName = "";

      if (typenames[i] == "pullUpOrPushUp") {
        realTypeName = "Pull-ups / Push-ups";
      } else {
        realTypeName = camelToSentence(typenames[i]);
      }

      var data = PieChartSectionData(
        color: color,
        value: calories[i].toDouble(),
        title: '$realTypeName\n${calories[i].toString()}',
        radius: 120,
        titleStyle: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
      sections.add(data);
    }

    return sections;
  }

  List<PieChartSectionData> countSections() {
    List<String> typenames = WorkoutType.values.map((x) => x.name).toList();
    List<int> count = List.filled(typenames.length, 0);

    for (var workout in _workouts) {
      var index = typenames.indexOf(workout['type']);
      count[index] += 1;
    }

    List<PieChartSectionData> sections = [];

    for (var i = 0; i < typenames.length; i++) {
      Color color = Colors.white;
      switch (i) {
        case 8:
          color = Colors.pink;
          break;
        case 7:
          color = Colors.purple;
          break;
        case 6:
          color = Colors.blue;
          break;
        case 5:
          color = Colors.indigo;
          break;
        case 4:
          color = Colors.green;
          break;
        case 3:
          color = Colors.yellow;
          break;
        case 2:
          color = Colors.red;
          break;
        case 1:
          color = Colors.deepOrange;
          break;
        case 0:
          color = Colors.deepPurple;
          break;
      }
      String realTypeName = "";

      if (typenames[i] == "pullUpOrPushUp") {
        realTypeName = "Pull-ups / Push-ups";
      } else {
        realTypeName = camelToSentence(typenames[i]);
      }

      var data = PieChartSectionData(
        color: color,
        value: count[i].toDouble(),
        title: '$realTypeName\n${count[i].toString()}',
        radius: 120,
        titleStyle: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
      sections.add(data);
    }

    return sections;
  }

  @override
  void initState() {
    super.initState();

    _getWorkouts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Text(
                'Fitness Tracker',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              title: const Text('Home'),
              leading: const Icon(Icons.home),
              onTap: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Add workout'),
              leading: const Icon(Icons.add),
              onTap: () {
                Navigator.pushNamed(context, '/addWorkout');
              },
            ),
            ListTile(
              title: const Text('Stats'),
              leading: const Icon(Icons.bar_chart),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 10),
              const Text("Calories burnt this week",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              SizedBox(
                height: 400,
                child: AspectRatio(
                  aspectRatio: 1.5,
                  child: PieChart(
                    PieChartData(
                      borderData: FlBorderData(
                        show: false,
                      ),
                      sectionsSpace: 0,
                      centerSpaceRadius: 80,
                      sections: caloriesSections(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              const Text("Workouts done this week",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              SizedBox(
                height: 400,
                child: AspectRatio(
                  aspectRatio: 1.5,
                  child: PieChart(
                    PieChartData(
                      borderData: FlBorderData(
                        show: false,
                      ),
                      sectionsSpace: 0,
                      centerSpaceRadius: 80,
                      sections: countSections(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
