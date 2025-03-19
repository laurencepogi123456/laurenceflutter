import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Todo App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // Todo list items
  final List<TodoItem> _todoItems = [];
  final TextEditingController _todoController = TextEditingController();
  
  // Background color state
  int _colorIndex = 0;
  final List<Color> _backgroundColors = [
    const Color(0xFFE3F2FD), // Light Blue
    const Color(0xFFE8F5E9), // Light Green
    const Color(0xFFFCE4EC), // Light Pink
    const Color(0xFFFFF8E1), // Light Amber
    const Color(0xFFEFEBE9), // Light Brown
  ];
  
  // Audio player setup
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  
  // Animation controllers
  late AnimationController _fabAnimationController;
  late AnimationController _colorChangeController;
  late Animation<double> _colorAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Set up audio player
    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        _isPlaying = state == PlayerState.playing;
      });
    });
    
    // Initialize animation controllers
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _colorChangeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _colorAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _colorChangeController, curve: Curves.easeInOut)
    );
    
    _colorChangeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _colorChangeController.reset();
      }
    });
  }
  
  @override
  void dispose() {
    _todoController.dispose();
    _audioPlayer.dispose();
    _fabAnimationController.dispose();
    _colorChangeController.dispose();
    super.dispose();
  }
  
  // Play the audio file
  void _playAudio() async {
    if (_isPlaying) {
      await _audioPlayer.stop();
    } else {
      await _audioPlayer.play(AssetSource('wagkang.mp3'));
    }
  }
  
  // Change background color
  void _changeBackgroundColor() {
    setState(() {
      _colorIndex = (_colorIndex + 1) % _backgroundColors.length;
    });
    _colorChangeController.forward();
  }
  
  // Add a new todo item
  void _addTodoItem() {
    if (_todoController.text.isNotEmpty) {
      setState(() {
        _todoItems.add(TodoItem(text: _todoController.text));
        _todoController.clear();
      });
      
      // Animate FAB
      _fabAnimationController.forward(from: 0.0);
    }
  }
  
  // Toggle completion status of a todo item
  void _toggleTodoCompletion(int index) {
    setState(() {
      _todoItems[index].isCompleted = !_todoItems[index].isCompleted;
    });
  }
  
  // Delete a todo item
  void _deleteTodoItem(int index) {
    setState(() {
      _todoItems.removeAt(index);
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: _backgroundColors[_colorIndex],
          appBar: AppBar(
            title: const Text(
              'My Tasks',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            backgroundColor: _backgroundColors[_colorIndex],
            actions: [
              IconButton(
                icon: const Icon(Icons.color_lens),
                onPressed: _changeBackgroundColor,
                tooltip: 'Change Theme',
              ),
              IconButton(
                icon: Icon(_isPlaying ? Icons.pause_circle : Icons.play_circle),
                onPressed: _playAudio,
                tooltip: 'Play Audio',
              ),
            ],
          ),
          body: Column(
            children: [
              // Search/Add task field
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _todoController,
                    decoration: InputDecoration(
                      hintText: 'Add a new task...',
                      prefixIcon: const Icon(Icons.task),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.add_circle),
                        color: Theme.of(context).primaryColor,
                        onPressed: _addTodoItem,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    ),
                    onSubmitted: (_) => _addTodoItem(),
                  ),
                ),
              ),
              
              // Todo list or empty state
              Expanded(
                child: _todoItems.isEmpty 
                  ? _buildEmptyState()
                  : _buildTodoList(),
              ),
              
              // Audio player and color controls
              _buildBottomControls(),
            ],
          ),
          floatingActionButton: ScaleTransition(
            scale: CurvedAnimation(
              parent: _fabAnimationController,
              curve: Curves.elasticOut,
            ),
            child: FloatingActionButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => _buildBottomSheet(),
                  backgroundColor: Colors.transparent,
                );
              },
              child: const Icon(Icons.dashboard_customize),
              tooltip: 'More options',
            ),
          ),
        );
      }
    );
  }
  
  // Empty state widget
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: Colors.grey.withOpacity(0.6),
          ),
          const SizedBox(height: 20),
          Text(
            'No tasks yet!',
            style: TextStyle(
              fontSize: 22,
              color: Colors.grey.withOpacity(0.8),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Add a new task using the field above',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
  
  // Todo list widget
  Widget _buildTodoList() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _todoItems.length,
      itemBuilder: (context, index) {
        final item = _todoItems[index];
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Dismissible(
            key: Key(item.id),
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: Colors.red.shade300,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.delete,
                color: Colors.white,
                size: 30,
              ),
            ),
            direction: DismissDirection.endToStart,
            onDismissed: (direction) => _deleteTodoItem(index),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, 3),
                    blurRadius: 5,
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: InkWell(
                  onTap: () => _toggleTodoCompletion(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: item.isCompleted 
                          ? Colors.green.withOpacity(0.2) 
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: item.isCompleted 
                            ? Colors.green 
                            : Colors.grey.shade400,
                        width: 2,
                      ),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: item.isCompleted 
                        ? const Icon(Icons.check, color: Colors.green, size: 20)
                        : const SizedBox(width: 20, height: 20),
                  ),
                ),
                title: Text(
                  item.text,
                  style: TextStyle(
                    decoration: item.isCompleted 
                        ? TextDecoration.lineThrough 
                        : TextDecoration.none,
                    fontSize: 18,
                    color: item.isCompleted 
                        ? Colors.grey 
                        : Colors.black87,
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _deleteTodoItem(index),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  // Bottom controls widget
  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -3),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            icon: Icons.color_lens,
            label: 'Theme',
            onPressed: _changeBackgroundColor,
          ),
          _buildControlButton(
            icon: _isPlaying ? Icons.pause : Icons.play_arrow,
            label: _isPlaying ? 'Pause' : 'Play',
            onPressed: _playAudio,
          ),
          _buildControlButton(
            icon: Icons.playlist_add_check,
            label: 'Tasks: ${_todoItems.length}',
            onPressed: () {},
          ),
        ],
      ),
    );
  }
  
  // Control button widget
  Widget _buildControlButton({required IconData icon, required String label, required VoidCallback onPressed}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: _backgroundColors[_colorIndex].withOpacity(0.8),
          shape: const CircleBorder(),
          elevation: 4,
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(
                icon,
                size: 26,
                color: Colors.black87,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  
  // Bottom sheet for additional options
  Widget _buildBottomSheet() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'App Settings',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          // Color theme options
          const Text(
            'Choose Theme Color',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _backgroundColors.length,
              (index) => GestureDetector(
                onTap: () {
                  setState(() {
                    _colorIndex = index;
                  });
                  Navigator.pop(context);
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _backgroundColors[index],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _colorIndex == index 
                          ? Colors.blue 
                          : Colors.grey.shade300,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _colorIndex == index 
                      ? const Icon(Icons.check, size: 20)
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          
          // Audio controls
          ElevatedButton.icon(
            onPressed: _playAudio,
            icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
            label: Text(_isPlaying ? 'Pause Audio' : 'Play Audio'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              backgroundColor: _backgroundColors[_colorIndex],
              foregroundColor: Colors.black87,
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

// Todo item model
class TodoItem {
  final String id;
  final String text;
  bool isCompleted;
  
  TodoItem({
    required this.text,
    this.isCompleted = false,
  }) : id = DateTime.now().millisecondsSinceEpoch.toString();
}