import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:localstore/localstore.dart';
import 'package:relative_time/relative_time.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

final db = Localstore.instance;

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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routes: {
        '/': (context) => const MyHomePage(title: 'Fitness Tracker'),
        '/addWorkout': (context) =>
            const AddWorkoutPage(title: 'Add Workout', isEdit: false),
        '/editWorkout': (context) =>
            const AddWorkoutPage(title: 'View/Edit Workout', isEdit: true),
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

class _MyHomePageState extends State<MyHomePage> {
  String _name = '';
  String _greeting = '';
  bool _nameNotSet = true;
  List _workouts = [];

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

  void _saveName() {
    db.collection('users').doc('user').set({'name': _name});
    setState(() {
      _nameNotSet = false;
    });
  }

  void _getName() async {
    final doc = await db.collection('users').doc('user').get();

    setState(() {
      _name = doc?['name'] ?? '';
      _nameNotSet = doc?['name'] is String ? false : true;
    });
  }

  void _getWorkouts() async {
    final docs = await db.collection('workouts').get();
    var sortedDocs = [];

    for (var docid in docs!.keys) {
      sortedDocs.add({
        'id': docid,
        ...docs[docid],
        'typeinfo': workoutTypeData[WorkoutType.values.firstWhere((element) =>
            element.toString() == 'WorkoutType.' + docs[docid]['type'])]
      });
    }

    sortedDocs.sort((a, b) =>
        DateTime.parse(b['datetime']).compareTo(DateTime.parse(a['datetime'])));

    setState(() {
      _workouts = sortedDocs;
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
      body: (_nameNotSet)
          ? new Center(
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
          : new Container(
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '$_greeting, $_name',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 20),
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
  double _caloriesBurned = 0.0;
  int _yogaDuration = 0;
  int _workoutWeight = 0;
  int _workoutReps = 0;
  int _workoutSets = 0;
  String? _currentWorkoutId;

  void _calculateCaloriesBurned() {
    if (_workoutType == WorkoutType.walking) {
      setState(() {
        _caloriesBurned = _distanceCovered * 50;
      });
    } else if (_workoutType == WorkoutType.running) {
      setState(() {
        _caloriesBurned = _distanceCovered * 100;
      });
    } else if (_workoutType == WorkoutType.cycling) {
      setState(() {
        _caloriesBurned = _distanceCovered * 75;
      });
    } else if (_workoutType == WorkoutType.swimming) {
      setState(() {
        _caloriesBurned = _distanceCovered * 120;
      });
    } else if (_workoutType == WorkoutType.yoga) {
      setState(() {
        _caloriesBurned = _yogaDuration * 5;
      });
    } else if (_workoutType == WorkoutType.benchPress ||
        _workoutType == WorkoutType.deadlift ||
        _workoutType == WorkoutType.pullUpOrPushUp) {
      setState(() {
        _caloriesBurned = _workoutWeight * _workoutReps * _workoutSets * 0.5;
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
      id = db.collection('todos').doc().id;
      dt = DateTime.now().toIso8601String();
    }

    if (_workoutType == WorkoutType.walking ||
        _workoutType == WorkoutType.running ||
        _workoutType == WorkoutType.cycling ||
        _workoutType == WorkoutType.swimming) {
      await db.collection('workouts').doc(id).set({
        'datetime': dt,
        'type': _workoutType.name,
        'distanceCovered': _distanceCovered,
        'caloriesBurned': _caloriesBurned,
      }, SetOptions(merge: false));
    } else if (_workoutType == WorkoutType.yoga) {
      await db.collection('workouts').doc(id).set({
        'datetime': dt,
        'type': _workoutType.name,
        'duration': _yogaDuration,
        'caloriesBurned': _caloriesBurned,
      }, SetOptions(merge: false));
      print(_yogaDuration);
    } else if (_workoutType == WorkoutType.benchPress ||
        _workoutType == WorkoutType.deadlift ||
        _workoutType == WorkoutType.pullUpOrPushUp) {
      await db.collection('workouts').doc(id).set({
        'datetime': dt,
        'type': _workoutType.name,
        'weight': _workoutWeight,
        'reps': _workoutReps,
        'sets': _workoutSets,
        'caloriesBurned': _caloriesBurned,
      }, SetOptions(merge: false));
    }

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
                        initialValue: _distanceCovered.toString(),
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
                        initialValue: _yogaDuration.toString(),
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
                        initialValue: _workoutWeight.toString(),
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
                        initialValue: _workoutReps.toString(),
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
                        initialValue: _workoutSets.toString(),
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
                      child:
                          Text(widget.isEdit ? 'Save changes' : 'Add workout'),
                      style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10))),
                    ))
              ],
            ),
          )),
    );
  }
}
